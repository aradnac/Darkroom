//
//  LibraryStore.swift
//  Darkroom
//
//  Loads the bundled reference library, keeps imported records merged into it,
//  and answers every question the screens ask: what films exist, what is
//  documented for one of them, and what the library still owes a source.
//

import Combine
import Foundation

// MARK: - Verification

/// One record the library has not earned yet.
struct VerificationItem: Identifiable, Hashable {
    enum Kind: String {
        case time
        case capacity
        case reuse
        case film

        var label: String {
            switch self {
            case .time: return "Time"
            case .capacity: return "Capacity"
            case .reuse: return "Reuse"
            case .film: return "Film"
            }
        }
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let filmKey: String?
    let developerKey: String?
}

// MARK: - Store

final class LibraryStore: ObservableObject {
    static let shared = LibraryStore()

    @Published private(set) var document: LibraryDocument
    @Published private(set) var favourites: Set<String>
    @Published var lastImportReport: String?

    private static let favouritesKey = "library.favourites"
    private static let persistedFileName = "imported-library.json"

    init(document: LibraryDocument? = nil, bundle: Bundle = .main) {
        if let document {
            self.document = document
        } else {
            let bundled = Self.loadBundled(bundle: bundle)
            let imported = Self.loadPersisted()
            self.document = bundled.merged(with: imported)
        }
        favourites = Set(UserDefaults.standard.stringArray(forKey: Self.favouritesKey) ?? [])
    }

    // MARK: Reading

    var films: [LibraryFilm] { document.films }

    var developers: [LibraryDeveloper] { document.developers }

    func film(key: String) -> LibraryFilm? {
        document.films.first { $0.key == key }
    }

    func developer(key: String) -> LibraryDeveloper? {
        document.developers.first { $0.key == key }
    }

    func source(key: String?) -> LibrarySource? {
        guard let key else { return nil }
        return document.sources.first { $0.key == key }
    }

    func times(forFilm key: String) -> [LibraryTimeEntry] {
        document.times
            .filter { $0.film == key }
            .sorted { left, right in
                let leftName = developer(key: left.developer)?.name ?? left.developer
                let rightName = developer(key: right.developer)?.name ?? right.developer
                if leftName == rightName { return left.dilution < right.dilution }
                return leftName.localizedCaseInsensitiveCompare(rightName) == .orderedAscending
            }
    }

    func times(forDeveloper key: String) -> [LibraryTimeEntry] {
        document.times.filter { $0.developer == key }
    }

    func crossProcess(forFilm key: String) -> [LibraryCrossProcess] {
        document.crossProcess.filter { $0.film == key }
    }

    func dilutionLabel(developerKey: String, dilution id: String) -> String {
        developer(key: developerKey)?.dilution(id: id)?.label ?? id
    }

    /// Every source a film's own records lean on, once each.
    func sources(forFilm key: String) -> [LibrarySource] {
        var keys: [String] = []
        if let film = film(key: key) {
            for fact in [film.latitude, film.grain, film.contrast, film.reciprocity] {
                if let source = fact?.provenance.source, !keys.contains(source) {
                    keys.append(source)
                }
            }
        }
        for time in times(forFilm: key) {
            if let source = time.provenance.source, !keys.contains(source) {
                keys.append(source)
            }
        }
        for entry in crossProcess(forFilm: key) {
            if let source = entry.provenance.source, !keys.contains(source) {
                keys.append(source)
            }
        }
        return keys.compactMap { source(key: $0) }
    }

    func sourceCount(forFilm key: String) -> Int {
        sources(forFilm: key).count
    }

    /// The temperature most of a film's times share, for the section heading.
    func primaryTemperature(forFilm key: String) -> Double? {
        let times = times(forFilm: key)
        guard !times.isEmpty else { return nil }
        var counts: [Double: Int] = [:]
        for time in times { counts[time.celsius, default: 0] += 1 }
        return counts.max { left, right in
            if left.value == right.value { return left.key > right.key }
            return left.value < right.value
        }?.key
    }

    func temperatureLabel(_ celsius: Double) -> String {
        if abs(celsius - celsius.rounded()) < 0.05 {
            return String(format: "%.0f °C", celsius)
        }
        return String(format: "%.1f °C", celsius)
    }

    // MARK: Filtering

    func films(
        matching query: String,
        process: FilmProcess?,
        status: FilmStatus?
    ) -> [LibraryFilm] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let dxKeys = dxMatchedFilmKeys(for: trimmed)
        return document.films.filter { film in
            if let process, film.process != process { return false }
            if let status, film.status != status { return false }
            guard !trimmed.isEmpty else { return true }
            if dxKeys.contains(film.key) { return true }
            let haystack = [film.manufacturer, film.name, String(film.iso), film.formatSummary]
                .joined(separator: " ")
            return haystack.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// The index entry for a canister, matched to a film the development library
    /// actually has times for. Name, maker and — when the catalogue gives one —
    /// the ISO all have to line up, so Delta 100 is not mistaken for Delta 3200.
    func libraryFilm(for entry: CatalogFilm) -> LibraryFilm? {
        let entryKey = FilmCatalog.normalize(entry.manufacturer + " " + entry.name)
        let numbers = FilmCatalog.numericRuns(entry.name)

        return document.films.first { film in
            let nameKey = FilmCatalog.normalize(film.name)
            let makerKey = FilmCatalog.normalize(film.manufacturer)
            guard !nameKey.isEmpty,
                  entryKey.contains(nameKey),
                  entryKey.contains(makerKey) else { return false }
            if !numbers.isEmpty, !numbers.contains("\(film.iso)") { return false }
            return true
        }
    }

    private func dxMatchedFilmKeys(for query: String) -> Set<String> {
        let digits = query.filter(\.isNumber)
        let bare = query.filter { !$0.isWhitespace && $0 != "-" }
        guard digits.count >= 3, digits.count == bare.count else { return [] }

        let entries = FilmCatalog.shared.matching(dx: digits)
        guard !entries.isEmpty else { return [] }

        var keys: Set<String> = []
        for entry in entries {
            if let film = libraryFilm(for: entry) {
                keys.insert(film.key)
            }
        }
        return keys
    }

    func developers(matching query: String) -> [LibraryDeveloper] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return document.developers }
        return document.developers.filter { developer in
            let haystack = [developer.manufacturer, developer.name, developer.dilutionSummary]
                .joined(separator: " ")
            return haystack.localizedCaseInsensitiveContains(trimmed)
        }
    }

    // MARK: Favourites

    func isFavourite(_ filmKey: String) -> Bool {
        favourites.contains(filmKey)
    }

    func toggleFavourite(_ filmKey: String) {
        if favourites.contains(filmKey) {
            favourites.remove(filmKey)
        } else {
            favourites.insert(filmKey)
        }
        UserDefaults.standard.set(Array(favourites).sorted(), forKey: Self.favouritesKey)
    }

    // MARK: Verification queue

    var verificationItems: [VerificationItem] {
        var items: [VerificationItem] = []

        for time in document.times {
            let filmName = film(key: time.film)?.fullName ?? time.film
            let developerName = developer(key: time.developer)?.name ?? time.developer
            let dilution = dilutionLabel(developerKey: time.developer, dilution: time.dilution)
            let title = "\(filmName) in \(developerName) \(dilution)"
            let temperature = temperatureLabel(time.celsius)
            if time.seconds == nil {
                items.append(
                    VerificationItem(
                        id: "time-\(time.id)",
                        kind: .time,
                        title: title,
                        subtitle: "Time at \(temperature) is not documented",
                        filmKey: time.film,
                        developerKey: time.developer
                    )
                )
            } else if time.provenance.kind == .unverified {
                items.append(
                    VerificationItem(
                        id: "time-\(time.id)",
                        kind: .time,
                        title: title,
                        subtitle: "Time at \(temperature) has no source yet",
                        filmKey: time.film,
                        developerKey: time.developer
                    )
                )
            }
        }

        for film in document.films {
            let facts: [(String, LibraryFact?)] = [
                ("Latitude", film.latitude),
                ("Grain", film.grain),
                ("Contrast", film.contrast),
                ("Reciprocity", film.reciprocity)
            ]
            for (label, fact) in facts where fact == nil || fact?.provenance.kind == .unverified {
                items.append(
                    VerificationItem(
                        id: "fact-\(film.key)-\(label)",
                        kind: .film,
                        title: "\(film.fullName) · \(label)",
                        subtitle: fact == nil ? "Not documented" : "Not yet sourced",
                        filmKey: film.key,
                        developerKey: nil
                    )
                )
            }
        }

        for developer in document.developers {
            if developer.capacity == nil || developer.capacity?.provenance.kind == .unverified {
                items.append(
                    VerificationItem(
                        id: "capacity-\(developer.key)",
                        kind: .capacity,
                        title: developer.name,
                        subtitle: developer.capacity == nil ? "Capacity not documented" : "Capacity not yet sourced",
                        filmKey: nil,
                        developerKey: developer.key
                    )
                )
            }
            if developer.reuse == nil || developer.reuse?.provenance.kind == .unverified {
                items.append(
                    VerificationItem(
                        id: "reuse-\(developer.key)",
                        kind: .reuse,
                        title: developer.name,
                        subtitle: developer.reuse == nil ? "Reuse guidance not documented" : "Reuse guidance not yet sourced",
                        filmKey: nil,
                        developerKey: developer.key
                    )
                )
            }
        }

        return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: Import

    /// Imports a JSON or CSV file and merges it into the library.
    func importFile(at url: URL) -> String {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let incoming = try LibraryImporter.document(from: data, filename: url.lastPathComponent)
            guard !incoming.isEmpty else {
                return "\(url.lastPathComponent) contained no records."
            }
            document = document.merged(with: incoming)
            Self.persist(document)
            let report = LibraryImporter.summary(of: incoming)
            lastImportReport = report
            return report
        } catch {
            let report = error.localizedDescription
            lastImportReport = report
            return report
        }
    }

    // MARK: Legacy bridge

    /// The session setup still speaks in the app's original `Film` and
    /// `Developer` values; this is the one place the two vocabularies meet.
    var legacyFilms: [Film] {
        document.films.map { film in
            Film(
                id: film.key,
                manufacturer: film.manufacturer,
                name: film.name,
                iso: film.iso,
                process: film.process,
                formats: film.formats
            )
        }
    }

    var legacyDevelopers: [Developer] {
        document.developers.map { developer in
            Developer(
                id: developer.key,
                manufacturer: developer.manufacturer,
                name: developer.name,
                dilutions: developer.dilutions.map { dilution in
                    Dilution(
                        id: dilution.id,
                        label: dilution.label,
                        stockParts: dilution.stockParts,
                        waterParts: dilution.waterParts
                    )
                }
            )
        }
    }

    func legacyFilm(key: String) -> Film? {
        legacyFilms.first { $0.id == key }
    }

    // MARK: Loading

    private static func loadBundled(bundle: Bundle) -> LibraryDocument {
        let candidates: [URL?] = [
            bundle.url(forResource: "library", withExtension: "json", subdirectory: "Library"),
            bundle.url(forResource: "library", withExtension: "json"),
            bundle.url(forResource: "library", withExtension: "json", subdirectory: "Resources/Library")
        ]
        for case let url? in candidates {
            if let document = decode(at: url) {
                return document
            }
        }
        return .empty
    }

    private static func decode(at url: URL) -> LibraryDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(LibraryDocument.self, from: data)
    }

    private static func loadPersisted() -> LibraryDocument {
        guard let url = persistedURL, FileManager.default.fileExists(atPath: url.path) else {
            return .empty
        }
        return decode(at: url) ?? .empty
    }

    private static func persist(_ document: LibraryDocument) {
        guard let url = persistedURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(document)
            try data.write(to: url, options: .atomic)
        } catch {
            // A failed write only costs the import its persistence; the merge is
            // still live for this launch.
        }
    }

    private static var persistedURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent(persistedFileName)
    }
}
