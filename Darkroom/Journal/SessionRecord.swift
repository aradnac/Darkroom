//
//  SessionRecord.swift
//  Darkroom
//
//  A finished development session, kept. One record per session: what was
//  developed, in what, at what temperature and for how long, how it was agitated,
//  what the negatives turned out like, and — if one was added — a photograph.
//
//  The record keeps both the time that was actually used and the published time
//  it was compared against, so the statistics can be honest about the difference
//  rather than reconstructing it later.
//

import Foundation
import Observation

// MARK: - Record

struct SessionRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date

    // What was developed
    var filmID: String
    var filmName: String
    var developerID: String
    var developerName: String
    var dilutionID: String
    var dilutionLabel: String

    // How
    var temperature: Double
    var developmentSeconds: TimeInterval
    /// The time the app worked out for that temperature before the reuse penalty,
    /// when it had one. Nil when the time was entered by hand.
    var publishedSeconds: TimeInterval?
    var exposureIndex: Int
    var pushStops: Int
    var reuseCount: Int
    var rolls: Int
    var agitationLabel: String
    var washLabel: String

    // What came out
    var negativeNotes: String = ""
    /// The file in the journal's photo folder, not the image itself.
    var photoFilename: String?

    var filmLine: String {
        filmName.isEmpty ? filmID : filmName
    }

    var developerLine: String {
        let name = developerName.isEmpty ? developerID : developerName
        return dilutionLabel.isEmpty ? name : "\(name) \(dilutionLabel)"
    }

    var timeText: String {
        Clock.mmss(developmentSeconds)
    }

    /// Positive when the session ran longer than the published time.
    var deviation: TimeInterval? {
        guard let publishedSeconds, publishedSeconds > 0 else { return nil }
        return developmentSeconds - publishedSeconds
    }

    var deviationPercent: Double? {
        guard let deviation, let publishedSeconds, publishedSeconds > 0 else { return nil }
        return deviation / publishedSeconds * 100
    }

    var monthID: String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }
}

// MARK: - Store

@Observable
final class JournalStore {
    static let shared = JournalStore()

    private(set) var records: [SessionRecord] = []

    private let fileURL: URL
    private let photoFolder: URL

    private init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("journal-records.json")
        photoFolder = folder.appendingPathComponent("journal-photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: photoFolder, withIntermediateDirectories: true)
        load()
    }

    // MARK: Reading

    func record(_ id: UUID) -> SessionRecord? {
        records.first { $0.id == id }
    }

    /// Every film named in the journal, newest name first seen.
    var filmNames: [String] {
        uniqueNames(records.map(\.filmName))
    }

    /// Every developer named in the journal.
    var developerNames: [String] {
        uniqueNames(records.map(\.developerName))
    }

    private func uniqueNames(_ names: [String]) -> [String] {
        var seen: [String] = []
        for name in names where !name.isEmpty && !seen.contains(name) {
            seen.append(name)
        }
        return seen.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Sessions filtered and searched the way the journal tab asks for.
    func records(matching query: String, film: String?, developer: String?) -> [SessionRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return records.filter { record in
            if let film, record.filmName != film { return false }
            if let developer, record.developerName != developer { return false }
            guard !trimmed.isEmpty else { return true }
            let haystack = [
                record.filmName, record.filmID,
                record.developerName, record.developerID,
                record.dilutionLabel, record.agitationLabel,
                record.negativeNotes,
                record.date.formatted(date: .abbreviated, time: .omitted)
            ].joined(separator: " ")
            return haystack.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    // MARK: Writing

    /// Called by the session engine when a session reaches its end. Returns the
    /// new record's id.
    @discardableResult
    func log(_ plan: SessionPlan) -> UUID {
        let record = SessionRecord(
            date: Date(),
            filmID: plan.film.id,
            filmName: plan.film.fullName,
            developerID: plan.developer.id,
            developerName: plan.developer.name,
            dilutionID: plan.dilution.id,
            dilutionLabel: plan.dilution.label,
            temperature: plan.temperature,
            developmentSeconds: plan.developmentTime,
            publishedSeconds: plan.publishedSeconds,
            exposureIndex: plan.exposureIndex,
            pushStops: plan.film.iso > 0
                ? Int((log2(Double(plan.exposureIndex) / Double(plan.film.iso))).rounded())
                : 0,
            reuseCount: plan.reuseCount,
            rolls: plan.rollCount,
            agitationLabel: Self.agitationLabel(for: plan),
            washLabel: plan.washMethod.label
        )
        records.insert(record, at: 0)
        save()
        return record.id
    }

    /// "Normal · Interval" — the intensity and the scheme the developer stage
    /// was actually run with, not whatever Settings happens to hold now.
    private static func agitationLabel(for plan: SessionPlan) -> String {
        let intensity = plan.intensity.label
        guard let developer = plan.stages.first(where: { $0.kind == .develop }) else {
            return intensity
        }
        let style: String
        switch developer.agitation {
        case .off: style = "Stand"
        case .interval: style = "Interval"
        case .continuous: style = "Continuous"
        }
        return "\(intensity) · \(style)"
    }

    func update(_ record: SessionRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        save()
    }

    func setNotes(_ notes: String, for id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        guard records[index].negativeNotes != notes else { return }
        records[index].negativeNotes = notes
        save()
    }

    /// Stores the photograph beside the record. Passing nil removes it.
    func setPhoto(_ data: Data?, for id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        if let old = records[index].photoFilename {
            try? FileManager.default.removeItem(at: photoFolder.appendingPathComponent(old))
            records[index].photoFilename = nil
        }

        if let data {
            let filename = "\(id.uuidString).jpg"
            do {
                try data.write(to: photoFolder.appendingPathComponent(filename), options: .atomic)
                records[index].photoFilename = filename
            } catch {
                records[index].photoFilename = nil
            }
        }

        save()
    }

    func photoData(for record: SessionRecord) -> Data? {
        guard let filename = record.photoFilename else { return nil }
        return try? Data(contentsOf: photoFolder.appendingPathComponent(filename))
    }

    /// Removes a session the reader discarded straight after it finished.
    func discard(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        if let filename = records[index].photoFilename {
            try? FileManager.default.removeItem(at: photoFolder.appendingPathComponent(filename))
        }
        records.remove(at: index)
        save()
    }

    // MARK: Disk

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        records = (try? decoder.decode([SessionRecord].self, from: data)) ?? []
        records.sort { $0.date > $1.date }
    }

    private func save() {
        records.sort { $0.date > $1.date }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - Statistics

/// Everything the journal's statistics ask of the log, worked out from the
/// records themselves. Pure, so it can be checked without a screen.
struct JournalStatistics {
    struct Tally: Identifiable, Hashable {
        let id: String
        let name: String
        let sessions: Int
        let rolls: Int
    }

    struct Deviation {
        let count: Int
        let average: TimeInterval
        let averagePercent: Double?
    }

    struct BatchTotal: Identifiable, Hashable {
        let id: UUID
        let name: String
        /// Sessions in the journal whose developer matches this bottle.
        let sessions: Int
        let rolls: Int
        /// What the bottle's own ledger already records.
        let ledgerRolls: Int
        let ledgerUses: Int
    }

    struct ChemicalTotal: Identifiable, Hashable {
        let id: String
        let name: String
        let sessions: Int
        let rolls: Int
        let time: TimeInterval
        let batches: [BatchTotal]
    }

    let sessions: Int
    let rolls: Int
    let totalTime: TimeInterval
    let deviation: Deviation?
    let byFilm: [Tally]
    let byDeveloper: [Tally]
    let byMonth: [Tally]
    let chemicals: [ChemicalTotal]

    init(records: [SessionRecord], batches: [ChemicalBatch] = []) {
        sessions = records.count
        rolls = records.reduce(0) { $0 + $1.rolls }
        totalTime = records.reduce(0) { $0 + $1.developmentSeconds }

        // Deviation is only counted where there was a published time to
        // compare against, so a hand-entered time never drags the average.
        let deviations = records.compactMap { record -> (TimeInterval, TimeInterval)? in
            guard let deviation = record.deviation, let published = record.publishedSeconds else { return nil }
            return (deviation, published)
        }
        if deviations.isEmpty {
            deviation = nil
        } else {
            let total = deviations.reduce(0) { $0 + $1.0 }
            let publishedTotal = deviations.reduce(0) { $0 + $1.1 }
            let average = total / Double(deviations.count)
            deviation = Deviation(
                count: deviations.count,
                average: average,
                averagePercent: publishedTotal > 0 ? average / (publishedTotal / Double(deviations.count)) * 100 : nil
            )
        }

        byFilm = Self.tallies(records, id: { $0.filmID }, name: { $0.filmName })

        // The developer is grouped on its own name: a dilution changes the time,
        // not which chemical did the work.
        byDeveloper = {
            let grouped = Dictionary(grouping: records, by: \.developerName)
            return grouped
                .map { name, group in
                    Tally(
                        id: group.first?.developerID ?? name,
                        name: name,
                        sessions: group.count,
                        rolls: group.reduce(0) { $0 + $1.rolls }
                    )
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }()

        byMonth = {
            let grouped = Dictionary(grouping: records, by: \.monthID)
            return grouped
                .map { key, group in
                    Tally(
                        id: key,
                        name: Self.monthLabel(key),
                        sessions: group.count,
                        rolls: group.reduce(0) { $0 + $1.rolls }
                    )
                }
                .sorted { $0.id > $1.id }
        }()

        chemicals = {
            let grouped = Dictionary(grouping: records) { "\($0.developerName)|\($0.dilutionLabel)" }
            return grouped
                .map { key, group in
                    let first = group[0]
                    let developer = first.developerName
                    return ChemicalTotal(
                        id: key,
                        name: group.count > 0 && first.dilutionLabel.isEmpty
                            ? developer
                            : "\(developer) \(first.dilutionLabel)",
                        sessions: group.count,
                        rolls: group.reduce(0) { $0 + $1.rolls },
                        time: group.reduce(0) { $0 + $1.developmentSeconds },
                        batches: Self.batchTotals(for: developer, records: group, batches: batches)
                    )
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }()
    }

    private static func tallies(
        _ records: [SessionRecord],
        id: (SessionRecord) -> String,
        name: (SessionRecord) -> String
    ) -> [Tally] {
        let grouped = Dictionary(grouping: records, by: id)
        return grouped
            .map { key, group in
                Tally(
                    id: key,
                    name: name(group[0]),
                    sessions: group.count,
                    rolls: group.reduce(0) { $0 + $1.rolls }
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// A bottle is credited with the sessions that name the same developer. The
    /// bottle's own ledger is carried alongside so both histories can be read at
    /// once rather than one silently standing in for the other.
    private static func batchTotals(
        for developer: String,
        records: [SessionRecord],
        batches: [ChemicalBatch]
    ) -> [BatchTotal] {
        let needle = normalised(developer)
        guard !needle.isEmpty else { return [] }

        return batches
            .filter { batch in
                let candidate = normalised(batch.developer)
                guard !candidate.isEmpty else { return false }
                return candidate.contains(needle) || needle.contains(candidate)
            }
            .map { batch in
                BatchTotal(
                    id: batch.id,
                    name: batch.name,
                    sessions: records.count,
                    rolls: records.reduce(0) { $0 + $1.rolls },
                    ledgerRolls: batch.rollsDeveloped,
                    ledgerUses: batch.useCount
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func normalised(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    /// "2026-11" → "November 2026".
    static func monthLabel(_ id: String) -> String {
        let parts = id.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else { return id }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let date = Calendar.current.date(from: components) else { return id }
        return date.formatted(.dateTime.month(.wide).year())
    }
}


// MARK: - Re-running

/// Turns a recorded session back into the choices a new setup needs. The ids are
/// tried first so a renamed film still resolves, and the names are the fallback
/// for a record written before an import.
enum JournalRerun {
    static func film(for record: SessionRecord) -> Film? {
        StarterLibrary.films.first { $0.id == record.filmID }
            ?? StarterLibrary.films.first { $0.fullName == record.filmName }
    }

    static func developer(for record: SessionRecord) -> Developer? {
        StarterLibrary.developers.first { $0.id == record.developerID }
            ?? StarterLibrary.developers.first { $0.name == record.developerName }
    }

    static func dilution(for record: SessionRecord, in developer: Developer?) -> Dilution? {
        guard let developer else { return nil }
        return developer.dilutions.first { $0.id == record.dilutionID }
            ?? developer.dilutions.first { $0.label == record.dilutionLabel }
    }
}
