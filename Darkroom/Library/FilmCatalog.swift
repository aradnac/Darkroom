//
//  FilmCatalog.swift
//  Darkroom
//
//  The DX film index — every canister The Big Film Database knows, keyed by the
//  code printed on it. It is a separate catalogue from the development library:
//  it answers "which film is this?" without pretending to know development times
//  it was never given.
//

import Combine
import Foundation

struct CatalogFilm: Identifiable, Hashable {
    let id: String
    let dxExtract: String?
    let dxFull: String?
    let name: String
    let manufacturer: String
    let notes: String?
    let beginYear: String?
    let endYear: String?
    let country: String?
    let distributor: String?

    /// Pre-normalised for searching; computing these per keystroke over eight
    /// thousand rows would be felt.
    let searchKey: String
    let nameTokens: [String]

    var dxLine: String? {
        if let extract = dxExtract, let full = dxFull {
            return "DX \(extract) · \(full)"
        }
        if let extract = dxExtract { return "DX \(extract)" }
        if let full = dxFull { return "DX \(full)" }
        return nil
    }

    var yearsLine: String? {
        let begin = beginYear?.trimmingCharacters(in: .whitespaces)
        let end = endYear?.trimmingCharacters(in: .whitespaces)
        let hasBegin = !(begin ?? "").isEmpty
        let hasEnd = !(end ?? "").isEmpty
        if hasBegin, hasEnd { return "\(begin!) – \(end!)" }
        if hasBegin { return "From \(begin!)" }
        if hasEnd { return "To \(end!)" }
        return nil
    }

    /// "Ilford · Made in UK"
    var makerLine: String {
        [manufacturer, country]
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespaces) ?? ""
                return trimmed.isEmpty ? nil : trimmed
            }
            .joined(separator: " · ")
    }
}

final class FilmCatalog: ObservableObject {
    static let shared = FilmCatalog()

    @Published private(set) var entries: [CatalogFilm]
    @Published private(set) var isLoaded: Bool
    @Published private(set) var isUnavailable = false

    private var isLoading = false

    init(entries: [CatalogFilm] = []) {
        self.entries = entries
        self.isLoaded = !entries.isEmpty
    }

    // MARK: Loading

    func load() {
        guard !isLoaded, !isLoading else { return }
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let parsed = Self.parseBundled()
            DispatchQueue.main.async {
                self.entries = parsed
                self.isLoaded = true
                self.isUnavailable = parsed.isEmpty
                self.isLoading = false
            }
        }
    }

    // MARK: Search

    /// Name, manufacturer or the DX code printed on the canister.
    func search(_ query: String, limit: Int = 40) -> [CatalogFilm] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if isDXQuery(trimmed) {
            return matching(dx: trimmed, limit: limit)
        }

        let tokens = Self.tokens(trimmed)
        guard !tokens.isEmpty else { return [] }

        var hits: [(entry: CatalogFilm, score: Int)] = []
        for entry in entries {
            var score = 0
            for token in tokens where entry.searchKey.contains(token) {
                score += 1
            }
            guard score == tokens.count else { continue }
            hits.append((entry, score))
        }

        return hits
            .sorted { left, right in
                left.entry.name.localizedCaseInsensitiveCompare(right.entry.name) == .orderedAscending
            }
            .prefix(limit)
            .map(\.entry)
    }

    func matching(dx code: String, limit: Int = 40) -> [CatalogFilm] {
        let digits = code.filter(\.isNumber)
        guard digits.count >= 3 else { return [] }

        return entries
            .filter { entry in
                if let full = entry.dxFull, full == digits { return true }
                if let extract = entry.dxExtract, extract == digits { return true }
                return false
            }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: Identification

    /// Ranks the index against whatever a photo gave us: printed words, and any
    /// barcode payload that happened to be a DX number.
    func identify(texts: [String], barcodes: [String], limit: Int = 20) -> [CatalogFilm] {
        let combined = (texts + barcodes).joined(separator: " ")
        let normalized = Self.normalize(combined)
        guard !normalized.isEmpty else { return [] }

        let runs = Self.numericRuns(combined)
        let allDigits = combined.filter(\.isNumber)
        let tokenSet = Set(Self.tokens(combined))

        var scored: [(entry: CatalogFilm, score: Int)] = []

        for entry in entries {
            var score = 0
            var dxConfirmed = false

            if let full = entry.dxFull {
                if runs.contains(full) {
                    score += 500
                    dxConfirmed = true
                } else if full.count >= 4, allDigits.contains(full) {
                    score += 300
                    dxConfirmed = true
                }
            }
            if let extract = entry.dxExtract, runs.contains(extract) {
                score += 400
                dxConfirmed = true
            }

            let makerKey = Self.normalize(entry.manufacturer)
            if !makerKey.isEmpty, normalized.contains(makerKey) {
                score += 40
            }

            var matched = 0
            for token in entry.nameTokens where tokenSet.contains(token) {
                score += token.allSatisfy(\.isNumber) ? 15 : 30
                matched += 1
            }

            let tokenCount = max(entry.nameTokens.count, 1)
            let ratio = Double(matched) / Double(tokenCount)
            if matched >= 3, ratio >= 0.75 { score += 30 }

            let strong = dxConfirmed
                || (matched >= 3 && ratio >= 0.5)
                || (matched >= 2 && ratio >= 0.8)
            guard strong || score >= 90 else { continue }

            scored.append((entry, score))
        }

        return scored
            .sorted { left, right in
                if left.score != right.score { return left.score > right.score }
                return left.entry.name.localizedCaseInsensitiveCompare(right.entry.name) == .orderedAscending
            }
            .prefix(limit)
            .map(\.entry)
    }

    // MARK: Parsing

    static func parse(_ text: String) -> [CatalogFilm] {
        let rows = LibraryImporter.parseCSV(text, delimiter: ";")
        guard let headerRow = rows.first else { return [] }
        let columns = headerRow.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        func column(_ name: String) -> Int? {
            columns.firstIndex(of: name)
        }

        guard let nameIndex = column("name") else { return [] }
        let extractIndex = column("dx extract")
        let fullIndex = column("dx full")
        let manufacturerIndex = column("manufacturer")
        let notesIndex = column("original film or informations")
        let beginIndex = column("beginning year")
        let endIndex = column("end year")
        let countryIndex = column("country")
        let distributorIndex = column("distributor")

        func value(_ row: [String], _ index: Int?) -> String? {
            guard let index, index < row.count else { return nil }
            let trimmed = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        var seen = Set<String>()
        var result: [CatalogFilm] = []
        result.reserveCapacity(rows.count)

        for (offset, row) in rows.dropFirst().enumerated() {
            guard let name = value(row, nameIndex) else { continue }
            let manufacturer = value(row, manufacturerIndex) ?? ""
            let extract = value(row, extractIndex)?.filter(\.isNumber)
            let full = value(row, fullIndex)?.filter(\.isNumber)

            // The file lists a film once per box and packaging variant; for
            // identification one record per DX code is enough.
            let identifier = "catalog-\(full ?? "row-\(offset)")"
            guard !seen.contains(identifier) else { continue }
            seen.insert(identifier)

            result.append(
                CatalogFilm(
                    id: identifier,
                    dxExtract: extract,
                    dxFull: full,
                    name: name,
                    manufacturer: manufacturer,
                    notes: value(row, notesIndex),
                    beginYear: value(row, beginIndex),
                    endYear: value(row, endIndex),
                    country: value(row, countryIndex),
                    distributor: value(row, distributorIndex),
                    searchKey: normalize(name + " " + manufacturer),
                    nameTokens: tokens(name)
                )
            )
        }

        return result
    }

    private static func parseBundled() -> [CatalogFilm] {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: "dx_database", withExtension: "csv", subdirectory: "Library"),
            Bundle.main.url(forResource: "dx_database", withExtension: "csv")
        ]
        guard let url = candidates.compactMap({ $0 }).first else { return [] }

        let data = (try? Data(contentsOf: url)) ?? Data()
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
        guard !text.isEmpty else { return [] }
        return parse(text)
    }

    // MARK: Text helpers

    static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .reduce(into: "") { result, scalar in
                result.unicodeScalars.append(scalar)
            }
    }

    static func tokens(_ value: String) -> [String] {
        var seen = Set<String>()
        return value
            .lowercased()
            .split { character in
                !character.isLetter && !character.isNumber
            }
            .map(String.init)
            .filter { $0.count >= 2 }
            .filter { token in
                seen.insert(token).inserted
            }
    }

    static func numericRuns(_ value: String) -> [String] {
        var runs: [String] = []
        var current = ""
        for character in value {
            if character.isNumber {
                current.append(character)
            } else if !current.isEmpty {
                runs.append(current)
                current = ""
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }

    private func isDXQuery(_ value: String) -> Bool {
        let allowed = value.filter { !$0.isWhitespace && $0 != "-" && $0 != "." }
        return allowed.count >= 4 && allowed.allSatisfy(\.isNumber)
    }
}
