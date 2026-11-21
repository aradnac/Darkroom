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

    @Published private(set) var document: LibraryDocument {
        didSet { rebuildIndex() }
    }
    @Published private(set) var favourites: Set<String>
    @Published var lastImportReport: String?

    /// Everything the screens ask for that used to be recomputed on each call:
    /// key lookups, a film's times already filtered and sorted, a developer's
    /// film count, the search haystacks, and the verification queue. Built once
    /// per document change and read from then on.
    private var index = Index()

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
        rebuildIndex()
    }

    // MARK: Reading

    var films: [LibraryFilm] { document.films }

    var developers: [LibraryDeveloper] { document.developers }

    func film(key: String) -> LibraryFilm? {
        index.filmsByKey[key]
    }

    func developer(key: String) -> LibraryDeveloper? {
        index.developersByKey[key]
    }

    func source(key: String?) -> LibrarySource? {
        guard let key else { return nil }
        return index.sourcesByKey[key]
    }

    func times(forFilm key: String) -> [LibraryTimeEntry] {
        index.timesByFilm[key] ?? []
    }

    func times(forDeveloper key: String) -> [LibraryTimeEntry] {
        index.timesByDeveloper[key] ?? []
    }

    /// How many films have at least one documented time in this developer.
    func filmCount(forDeveloper key: String) -> Int {
        index.filmCountByDeveloper[key] ?? 0
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
        Units.shortTemperature(celsius)
    }

    // MARK: Filtering

    func films(
        matching query: String,
        process: FilmProcess?,
        status: FilmStatus?
    ) -> [LibraryFilm] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let dxKeys = dxMatchedFilmKeys(for: trimmed)
        let matches = document.films.filter { film in
            if let process, film.process != process { return false }
            if let status, film.status != status { return false }
            guard !trimmed.isEmpty else { return true }
            if dxKeys.contains(film.key) { return true }
            guard let haystack = index.filmSearchKey[film.key] else { return false }
            return haystack.localizedCaseInsensitiveContains(trimmed)
        }
        return matches.sorted(by: Self.browseOrder)
    }

    /// The catalogue reads as a shelf: current stock first, then by maker and
    /// name, so a library of a hundred films can be scanned without scrolling
    /// through the order they happened to be imported in.
    private static func browseOrder(_ left: LibraryFilm, _ right: LibraryFilm) -> Bool {
        if left.status != right.status {
            return left.status.browseRank < right.status.browseRank
        }
        if left.manufacturer != right.manufacturer {
            return left.manufacturer.localizedCaseInsensitiveCompare(right.manufacturer) == .orderedAscending
        }
        if left.name != right.name {
            return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        }
        return left.iso < right.iso
    }

    /// The index entry for a canister, matched to a film the development library
    /// actually has times for. Name, maker and — when the catalogue gives one —
    /// the ISO all have to line up, so Delta 100 is not mistaken for Delta 3200.
    func libraryFilm(for entry: CatalogFilm) -> LibraryFilm? {
        let entryKey = FilmCatalog.normalize(entry.manufacturer + " " + entry.name)
        let numbers = FilmCatalog.numericRuns(entry.name)

        // The names and makers were normalised once when the index was built, so
        // matching an index entry no longer re-normalises every film it looks at.
        for candidate in index.normalizedFilms {
            guard !candidate.nameKey.isEmpty,
                  entryKey.contains(candidate.nameKey),
                  entryKey.contains(candidate.makerKey) else { continue }
            if !numbers.isEmpty, !numbers.contains("\(candidate.film.iso)") { continue }
            return candidate.film
        }
        return nil
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
            guard let haystack = index.developerSearchKey[developer.key] else { return false }
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

    /// Built once per document — and again only if the temperature scale the
    /// subtitles are written in has changed since — rather than on every read.
    var verificationItems: [VerificationItem] {
        let scale = Preferences.shared.temperatureScale
        if index.verificationScale == scale {
            return index.verification
        }

        let items = buildVerificationItems()
        index.verification = items
        index.verificationScale = scale
        return items
    }

    private func buildVerificationItems() -> [VerificationItem] {
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

    // MARK: Derived index

    /// Everything the screens ask for repeatedly. Rebuilt once whenever the
    /// document changes, so a list row no longer filters and sorts the whole
    /// library to draw itself, and a keystroke no longer rebuilds a haystack per
    /// film.
    private struct Index {
        var filmsByKey: [String: LibraryFilm] = [:]
        var developersByKey: [String: LibraryDeveloper] = [:]
        var sourcesByKey: [String: LibrarySource] = [:]

        /// A film's times, already filtered and sorted by developer then
        /// dilution — the exact order `times(forFilm:)` used to produce.
        var timesByFilm: [String: [LibraryTimeEntry]] = [:]
        var timesByDeveloper: [String: [LibraryTimeEntry]] = [:]
        var filmCountByDeveloper: [String: Int] = [:]

        var filmSearchKey: [String: String] = [:]
        var developerSearchKey: [String: String] = [:]

        /// Names and makers normalised once, in document order, so the DX match
        /// keeps its first-match behaviour without re-normalising per candidate.
        var normalizedFilms: [(film: LibraryFilm, nameKey: String, makerKey: String)] = []

        var verification: [VerificationItem] = []
        var verificationScale: TemperatureScale?
    }

    private func rebuildIndex() {
        legacyFilmsCache = nil
        legacyDevelopersCache = nil
        var built = Index()

        // First entry wins, as the linear `first(where:)` lookups did.
        for film in document.films where built.filmsByKey[film.key] == nil {
            built.filmsByKey[film.key] = film
            built.filmSearchKey[film.key] = [
                film.manufacturer,
                film.name,
                String(film.iso),
                film.formatSummary,
                film.generationLabel,
                film.generation,
                film.origin?.stock,
                film.origin?.stockFilm
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            built.normalizedFilms.append((
                film: film,
                nameKey: FilmCatalog.normalize(film.name),
                makerKey: FilmCatalog.normalize(film.manufacturer)
            ))
        }

        for developer in document.developers where built.developersByKey[developer.key] == nil {
            built.developersByKey[developer.key] = developer
            built.developerSearchKey[developer.key] = [developer.manufacturer, developer.name, developer.dilutionSummary]
                .joined(separator: " ")
        }

        for source in document.sources where built.sourcesByKey[source.key] == nil {
            built.sourcesByKey[source.key] = source
        }

        for time in document.times {
            built.timesByFilm[time.film, default: []].append(time)
            built.timesByDeveloper[time.developer, default: []].append(time)
        }

        // The one sort a film's times need, done here rather than on every row.
        for (key, entries) in built.timesByFilm {
            built.timesByFilm[key] = entries.sorted { left, right in
                let leftName = built.developersByKey[left.developer]?.name ?? left.developer
                let rightName = built.developersByKey[right.developer]?.name ?? right.developer
                if leftName == rightName { return left.dilution < right.dilution }
                return leftName.localizedCaseInsensitiveCompare(rightName) == .orderedAscending
            }
        }

        for (key, entries) in built.timesByDeveloper {
            built.filmCountByDeveloper[key] = Set(entries.map(\.film)).count
        }

        index = built

        // The queue's subtitles carry a temperature in the user's scale, which is
        // the one input it takes from outside the document.
        index.verification = buildVerificationItems()
        index.verificationScale = Preferences.shared.temperatureScale
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
    ///
    /// Both lists are read from view initialisers, `ForEach`s and per-row
    /// lookups, so they are built once per document change and cached rather
    /// than re-mapped (hundreds of films) on every read.
    private var legacyFilmsCache: [Film]?
    private var legacyDevelopersCache: [Developer]?

    var legacyFilms: [Film] {
        if let cached = legacyFilmsCache { return cached }
        let built = document.films.map { film in
            Film(
                id: film.key,
                manufacturer: film.manufacturer,
                name: film.name,
                iso: film.iso,
                process: film.process,
                formats: film.formats
            )
        }
        legacyFilmsCache = built
        return built
    }

    var legacyDevelopers: [Developer] {
        if let cached = legacyDevelopersCache { return cached }
        let built = document.developers.map { developer in
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
        legacyDevelopersCache = built
        return built
    }

    func legacyFilm(key: String) -> Film? {
        legacyFilms.first { $0.id == key }
    }

    // MARK: Loading

    private static func loadBundled(bundle: Bundle) -> LibraryDocument {
        // The library is split across several documents so each one stays a
        // readable sheet rather than a single enormous file. Every document
        // named "library*.json" — in the folder or, with a project layout that
        // flattens resources, at the bundle root — is decoded and merged in a
        // stable order, with library.json first because it carries the sources.
        var urls: [URL] = []
        var seen: Set<String> = []

        for subdirectory in ["Library", "Resources/Library", nil] {
            let found = bundle.urls(forResourcesWithExtension: "json", subdirectory: subdirectory) ?? []
            for url in found {
                let name = url.lastPathComponent
                guard name.hasPrefix("library"),
                      seen.insert(url.standardizedFileURL.path).inserted else { continue }
                urls.append(url)
            }
        }

        urls.sort { left, right in
            if left.lastPathComponent == "library.json" { return true }
            if right.lastPathComponent == "library.json" { return false }
            return left.lastPathComponent.localizedStandardCompare(right.lastPathComponent) == .orderedAscending
        }

        var document = LibraryDocument.empty
        for url in urls {
            guard let part = decode(at: url) else { continue }
            document = document.merged(with: part)
        }
        return document
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
