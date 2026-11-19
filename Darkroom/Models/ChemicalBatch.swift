//
//  ChemicalBatch.swift
//  Darkroom
//
//  A mixed bottle of chemistry: what it is, how long it keeps, how much it can still
//  do, and every use it has had. Kept between launches.
//

import Foundation
import Observation

struct ChemicalUse: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var rolls: Int
    var note: String
}

struct ChemicalBatch: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var developer: String
    var litres: Double
    var mixedOn: Date
    var shelfLifeMonths: Int?
    var capacityRolls: Int
    var isReusable: Bool
    var notes: String
    var uses: [ChemicalUse] = []

    // MARK: - Ledger

    var useCount: Int { uses.count }

    var rollsDeveloped: Int {
        uses.reduce(0) { $0 + $1.rolls }
    }

    var remainingRolls: Int {
        max(0, capacityRolls - rollsDeveloped)
    }

    var isExhausted: Bool { remainingRolls == 0 }

    var rollsText: String {
        "\(rollsDeveloped) of \(capacityRolls) rolls"
    }

    // MARK: - Expiry

    var expiryDate: Date? {
        guard let months = shelfLifeMonths, months > 0 else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: mixedOn)
    }

    var daysToExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: expiry)
        return calendar.dateComponents([.day], from: today, to: end).day
    }

    var isExpired: Bool {
        guard let days = daysToExpiry else { return false }
        return days < 0
    }

    var expiryLabel: String? {
        guard let expiry = expiryDate else { return nil }
        if isExpired { return "expired" }
        return "keeps to " + expiry.formatted(.dateTime.day().month(.abbreviated).year())
    }

    // MARK: - Time penalty

    /// The use number the next session would be.
    var nextUseNumber: Int { uses.count + 1 }

    /// Each prior use compounds 10%, so the next use carries the whole history.
    var nextUseFactor: Double {
        DevelopmentSetup.reuseFactor(uses: nextUseNumber)
    }

    var nextUsePenaltyPercent: Int {
        Int(((nextUseFactor - 1) * 100).rounded())
    }

    var nextUsePenaltyText: String {
        if !isReusable {
            return "One-shot — mix fresh for each roll."
        }
        let prior = uses.count
        guard prior > 0 else { return "Fresh mix — no penalty on the next use." }
        let times = prior == 1 ? "once" : (prior == 2 ? "twice" : "\(prior) times")
        let step = Int((CompensationRules.reuseStep * 100).rounded())
        return "+\(nextUsePenaltyPercent)% — \(step)% compounded \(times)."
    }
}

@Observable
final class ChemistryStore {
    static let shared = ChemistryStore()

    private(set) var batches: [ChemicalBatch] = []

    private let fileURL: URL

    private init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("chemistry-batches.json")
        load()
    }

    func batch(_ id: UUID) -> ChemicalBatch? {
        batches.first { $0.id == id }
    }

    func add(_ batch: ChemicalBatch) {
        batches.append(batch)
        sortBatches()
        save()
    }

    func update(_ batch: ChemicalBatch) {
        guard let index = batches.firstIndex(where: { $0.id == batch.id }) else { return }
        batches[index] = batch
        sortBatches()
        save()
    }

    func delete(_ id: UUID) {
        batches.removeAll { $0.id == id }
        save()
    }

    func logUse(rolls: Int, note: String, for id: UUID) {
        guard let index = batches.firstIndex(where: { $0.id == id }) else { return }
        let use = ChemicalUse(date: Date(), rolls: max(1, rolls), note: note)
        batches[index].uses.append(use)
        save()
    }

    private func sortBatches() {
        batches.sort { $0.mixedOn > $1.mixedOn }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        batches = (try? decoder.decode([ChemicalBatch].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(batches) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
