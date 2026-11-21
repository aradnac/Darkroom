//
//  LibraryModel.swift
//  Darkroom
//
//  The reference library's data model. Every fact that matters carries where it
//  came from; a fact nobody has sourced is either absent or explicitly marked
//  unverified, never filled in with a plausible guess.
//

import Foundation

// MARK: - Provenance

/// Where a documented fact came from.
enum LibraryProvenanceKind: String, Codable, CaseIterable, Identifiable {
    case datasheet
    case community
    case unverified

    var id: String { rawValue }

    var label: String {
        switch self {
        case .datasheet: return "Datasheet"
        case .community: return "Community"
        case .unverified: return "Verify"
        }
    }

    var detail: String {
        switch self {
        case .datasheet: return "Manufacturer datasheet"
        case .community: return "Community chart"
        case .unverified: return "Not yet verified"
        }
    }

    /// Higher wins when two records for the same key are merged.
    var rank: Int {
        switch self {
        case .datasheet: return 3
        case .community: return 2
        case .unverified: return 1
        }
    }
}

struct LibraryProvenance: Codable, Hashable {
    var kind: LibraryProvenanceKind
    var source: String?
    var note: String?

    static let unverified = LibraryProvenance(kind: .unverified, source: nil, note: nil)
}

/// A document a fact can point at.
struct LibrarySource: Codable, Identifiable, Hashable {
    var key: String
    var title: String
    var publisher: String
    var url: String
    /// As printed by the source, so it is never re-formatted behind the reader's back.
    var retrieved: String

    var id: String { key }
}

/// One documented value with the provenance that earns it a place on screen.
struct LibraryFact: Codable, Hashable {
    var value: String
    var unit: String?
    var provenance: LibraryProvenance
}

/// One further named property of a stock — sharpness, base, push behaviour,
/// halation — so a profile can carry more than the four headline facts without
/// each new one becoming a schema change.
struct LibraryCharacteristic: Codable, Identifiable, Hashable {
    var label: String
    var value: String
    var provenance: LibraryProvenance

    var id: String { label }
}

// MARK: - Origin

/// Where a stock actually comes from. A good part of what is on a shelf is
/// another maker's emulsion, reprinted or respooled, and the library says so
/// rather than presenting the repackager as the manufacturer.
enum LibraryOriginKind: String, Codable, CaseIterable, Identifiable {
    /// The maker's own emulsion, sold under the maker's name.
    case original
    /// Cinema or bulk stock cut down and put into 35 mm cassettes.
    case respool
    /// An existing film sold under another brand's name.
    case rebrand
    /// A stock sold for a different process than the one it was designed for.
    case converted

    var id: String { rawValue }

    var label: String {
        switch self {
        case .original: return "Original"
        case .respool: return "Respool"
        case .rebrand: return "Rebrand"
        case .converted: return "Converted"
        }
    }

    var detail: String {
        switch self {
        case .original: return "The maker's own emulsion"
        case .respool: return "Bulk or cinema stock cut down into still-film cassettes"
        case .rebrand: return "Another maker's emulsion sold under a different name"
        case .converted: return "Repackaged for a different process than it was made for"
        }
    }
}

struct LibraryOrigin: Codable, Hashable {
    var kind: LibraryOriginKind
    /// The stock this is made from, as it is written in the trade, e.g.
    /// "Kodak Vision3 500T 5219".
    var stock: String?
    /// The library key of that stock when it has a profile of its own.
    var stockFilm: String?
    /// True only when the carbon backing has been removed before resale, which
    /// is what lets a cinema stock go through C-41.
    var remjetRemoved: Bool?
    var note: String?
    var provenance: LibraryProvenance?
}

// MARK: - Films

enum FilmStatus: String, Codable, CaseIterable, Identifiable {
    case current
    case discontinued
    case cinema
    case specialty

    var id: String { rawValue }

    var label: String {
        switch self {
        case .current: return "Current"
        case .discontinued: return "Discontinued"
        case .cinema: return "Cinema"
        case .specialty: return "Specialty"
        }
    }

    /// The order the catalogue reads in: what you can buy, then what needs a
    /// special process, then what is still made in small runs, then history.
    var browseRank: Int {
        switch self {
        case .current: return 0
        case .cinema: return 1
        case .specialty: return 2
        case .discontinued: return 3
        }
    }
}

struct LibraryFilm: Codable, Identifiable, Hashable {
    var key: String
    var manufacturer: String
    var name: String
    var iso: Int
    var process: FilmProcess
    var formats: [FilmFormat]
    var status: FilmStatus
    /// Stable identity of the emulsion itself, so two generations of one name stay apart.
    var generation: String?
    var generationLabel: String?
    var latitude: LibraryFact?
    var grain: LibraryFact?
    var contrast: LibraryFact?
    var reciprocity: LibraryFact?
    var notes: String?

    // Provenance and story. A respool is not worth listing without the stock it
    // came from, and a discontinued film is not worth listing without why it
    // went, so both live with the record rather than in a separate document.
    var origin: LibraryOrigin? = nil
    var history: String?
    var grainStructure: LibraryFact?
    var characteristics: [LibraryCharacteristic]? = nil

    var id: String { key }

    var displayName: String { "\(name) \(iso)" }

    var fullName: String { "\(manufacturer) \(name) \(iso)" }

    var formatSummary: String { formats.map(\.label).joined(separator: " · ") }

    /// Used by the importer to deduplicate the same emulsion loaded twice.
    var stableKey: String {
        let base = "\(manufacturer.lowercased())|\(name.lowercased())|\(iso)"
        guard let generation, !generation.isEmpty else { return base }
        return "\(base)|\(generation.lowercased())"
    }

    func merged(with other: LibraryFilm) -> LibraryFilm {
        var result = self
        result.latitude = Self.pick(latitude, other.latitude)
        result.grain = Self.pick(grain, other.grain)
        result.contrast = Self.pick(contrast, other.contrast)
        result.reciprocity = Self.pick(reciprocity, other.reciprocity)
        result.grainStructure = Self.pick(grainStructure, other.grainStructure)
        result.notes = other.notes ?? notes
        result.history = other.history ?? history
        result.origin = other.origin ?? origin
        result.characteristics = other.characteristics ?? characteristics
        if !other.formats.isEmpty { result.formats = other.formats }
        if other.generationLabel != nil { result.generationLabel = other.generationLabel }
        return result
    }

    private static func pick(_ mine: LibraryFact?, _ theirs: LibraryFact?) -> LibraryFact? {
        guard let theirs else { return mine }
        guard let mine else { return theirs }
        return theirs.provenance.kind.rank >= mine.provenance.kind.rank ? theirs : mine
    }
}

// MARK: - Developers

struct LibraryDilution: Codable, Identifiable, Hashable {
    var id: String
    var label: String
    var stockParts: Double?
    var waterParts: Double?
    var provenance: LibraryProvenance?

    var ratio: String? {
        guard let stock = stockParts, let water = waterParts else { return nil }
        if water == 0 { return "Stock" }
        return "\(Dilution.number(stock))+\(Dilution.number(water))"
    }
}

struct LibraryDeveloper: Codable, Identifiable, Hashable {
    var key: String
    var manufacturer: String
    var name: String
    var type: String?
    var dilutions: [LibraryDilution]
    var capacity: LibraryFact?
    var reuse: LibraryFact?

    var id: String { key }

    var displayName: String { name }

    var dilutionSummary: String { dilutions.map(\.label).joined(separator: " · ") }

    /// Same stock loaded twice is one record, whatever it was keyed as.
    var stableKey: String { "\(manufacturer.lowercased())|\(name.lowercased())" }

    func dilution(id: String) -> LibraryDilution? {
        dilutions.first { $0.id == id }
    }

    func merged(with other: LibraryDeveloper) -> LibraryDeveloper {
        var result = self
        result.type = other.type ?? type
        result.capacity = Self.pick(capacity, other.capacity)
        result.reuse = Self.pick(reuse, other.reuse)
        if !other.dilutions.isEmpty {
            var byID = Dictionary(uniqueKeysWithValues: dilutions.map { ($0.id, $0) })
            var order = dilutions.map(\.id)
            for dilution in other.dilutions {
                if let existing = byID[dilution.id] {
                    byID[dilution.id] = dilution.provenance == nil ? existing : dilution
                } else {
                    byID[dilution.id] = dilution
                    order.append(dilution.id)
                }
            }
            result.dilutions = order.compactMap { byID[$0] }
        }
        return result
    }

    private static func pick(_ mine: LibraryFact?, _ theirs: LibraryFact?) -> LibraryFact? {
        guard let theirs else { return mine }
        guard let mine else { return theirs }
        return theirs.provenance.kind.rank >= mine.provenance.kind.rank ? theirs : mine
    }
}

// MARK: - Times

/// One film/developer/dilution at one temperature. `seconds` is nil when the
/// pairing is known but no time has been sourced for it.
struct LibraryTimeEntry: Codable, Identifiable, Hashable {
    var film: String
    var developer: String
    var dilution: String
    var celsius: Double
    var seconds: Int?
    var provenance: LibraryProvenance

    var id: String { "\(film)|\(developer)|\(dilution)|\(celsius)" }

    var mergeKey: String { "\(film.lowercased())|\(developer.lowercased())|\(dilution.lowercased())|\(celsius)" }
}

// MARK: - Cross-processing

enum CrossProcessClass: String, Codable, CaseIterable, Identifiable {
    case documentedAndTested
    case communityTested
    case experimental
    case notRecommended
    case incompatible

    var id: String { rawValue }

    var label: String {
        switch self {
        case .documentedAndTested: return "Documented"
        case .communityTested: return "Community"
        case .experimental: return "Experimental"
        case .notRecommended: return "Not recommended"
        case .incompatible: return "Incompatible"
        }
    }

    /// Only one class says the combination must not be attempted at all.
    var isSafe: Bool { self != .incompatible }

    /// The wording the profile uses for this class. An incompatible entry is
    /// never described as experimental, however thin its documentation is.
    var safetyTitle: String {
        switch self {
        case .incompatible: return "Unsafe — chemically incompatible"
        case .documentedAndTested: return "Documented and tested"
        case .communityTested: return "Community-tested"
        case .experimental: return "Experimental"
        case .notRecommended: return "Not recommended"
        }
    }

    /// Documented first, experimentally thin later, and anything unsafe last.
    var rank: Int {
        switch self {
        case .documentedAndTested: return 0
        case .communityTested: return 1
        case .experimental: return 2
        case .notRecommended: return 3
        case .incompatible: return 4
        }
    }
}

struct LibraryCrossProcess: Codable, Identifiable, Hashable {
    var film: String
    var fromProcess: FilmProcess
    var toProcess: FilmProcess
    var classification: CrossProcessClass
    var summary: String
    var provenance: LibraryProvenance

    // The rest of the profile. Every field is optional: an entry says only what
    // its source actually documents.
    var colourShifts: String?
    var contrastChange: String?
    var grainChange: String?
    var exposureNotes: String?
    var expectedResult: String?
    var limitations: String?
    var examples: [String]?
    var references: [String]?

    var id: String { "\(film)|\(fromProcess.rawValue)|\(toProcess.rawValue)" }

    /// True only for the one class that must not be attempted.
    var isUnsafe: Bool { !classification.isSafe }

    /// The profile as labelled rows, in a fixed order, with the limitations row
    /// flagged whenever the combination is unsafe.
    var profileFields: [(label: String, value: String, isWarning: Bool)] {
        var rows: [(label: String, value: String, isWarning: Bool)] = []
        if let colourShifts, !colourShifts.isEmpty {
            rows.append(("Colour shifts", colourShifts, false))
        }
        if let contrastChange, !contrastChange.isEmpty {
            rows.append(("Contrast", contrastChange, false))
        }
        if let grainChange, !grainChange.isEmpty {
            rows.append(("Grain", grainChange, false))
        }
        if let exposureNotes, !exposureNotes.isEmpty {
            rows.append(("Exposure", exposureNotes, false))
        }
        if let expectedResult, !expectedResult.isEmpty {
            rows.append(("Expected result", expectedResult, false))
        }
        if let limitations, !limitations.isEmpty {
            rows.append(("Limitations", limitations, isUnsafe))
        }
        return rows
    }

    /// Profiles in the order the sheet shows them: safest first, unsafe last.
    static func sorted(_ entries: [LibraryCrossProcess]) -> [LibraryCrossProcess] {
        entries.sorted { left, right in
            if left.classification.rank != right.classification.rank {
                return left.classification.rank < right.classification.rank
            }
            if left.fromProcess.label != right.fromProcess.label {
                return left.fromProcess.label < right.fromProcess.label
            }
            return left.toProcess.label < right.toProcess.label
        }
    }
}

// MARK: - Document

/// The whole library as one importable, mergeable document.
struct LibraryDocument: Codable {
    var schema: Int
    var sources: [LibrarySource]
    var films: [LibraryFilm]
    var developers: [LibraryDeveloper]
    var times: [LibraryTimeEntry]
    var crossProcess: [LibraryCrossProcess]

    static let empty = LibraryDocument(
        schema: 1,
        sources: [],
        films: [],
        developers: [],
        times: [],
        crossProcess: []
    )

    init(
        schema: Int = 1,
        sources: [LibrarySource] = [],
        films: [LibraryFilm] = [],
        developers: [LibraryDeveloper] = [],
        times: [LibraryTimeEntry] = [],
        crossProcess: [LibraryCrossProcess] = []
    ) {
        self.schema = schema
        self.sources = sources
        self.films = films
        self.developers = developers
        self.times = times
        self.crossProcess = crossProcess
    }

    /// Every section is optional on the way in, so a partial import is a merge
    /// rather than a parse failure.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decodeIfPresent(Int.self, forKey: .schema) ?? 1
        sources = try container.decodeIfPresent([LibrarySource].self, forKey: .sources) ?? []
        films = try container.decodeIfPresent([LibraryFilm].self, forKey: .films) ?? []
        developers = try container.decodeIfPresent([LibraryDeveloper].self, forKey: .developers) ?? []
        times = try container.decodeIfPresent([LibraryTimeEntry].self, forKey: .times) ?? []
        crossProcess = try container.decodeIfPresent([LibraryCrossProcess].self, forKey: .crossProcess) ?? []
    }

    var isEmpty: Bool {
        films.isEmpty && developers.isEmpty && times.isEmpty && crossProcess.isEmpty
    }

    // MARK: Merge

    /// Incoming records win on provenance, and never wipe a documented value
    /// with an unsourced one.
    func merged(with incoming: LibraryDocument) -> LibraryDocument {
        var result = self

        result.sources = Self.merge(sources, incoming.sources, key: \.key) { $1 }

        result.films = Self.merge(films, incoming.films, key: \.stableKey) { existing, new in
            existing.merged(with: new)
        }

        result.developers = Self.merge(developers, incoming.developers, key: \.stableKey) { existing, new in
            existing.merged(with: new)
        }

        result.times = Self.merge(times, incoming.times, key: \.mergeKey) { existing, new in
            let existingRank = existing.provenance.kind.rank
            let newRank = new.provenance.kind.rank
            if existing.seconds == nil && new.seconds != nil { return new }
            if existing.seconds != nil && new.seconds == nil { return existing }
            return newRank >= existingRank ? new : existing
        }

        result.crossProcess = Self.merge(crossProcess, incoming.crossProcess, key: \.id) { existing, new in
            new.provenance.kind.rank >= existing.provenance.kind.rank ? new : existing
        }

        return result
    }

    private static func merge<T>(
        _ base: [T],
        _ incoming: [T],
        key: (T) -> String,
        combine: (T, T) -> T
    ) -> [T] {
        var order: [String] = []
        var map: [String: T] = [:]

        for item in base {
            let identifier = key(item)
            if map[identifier] == nil {
                order.append(identifier)
                map[identifier] = item
            } else if let existing = map[identifier] {
                map[identifier] = combine(existing, item)
            }
        }

        for item in incoming {
            let identifier = key(item)
            if let existing = map[identifier] {
                map[identifier] = combine(existing, item)
            } else {
                map[identifier] = item
                order.append(identifier)
            }
        }

        return order.compactMap { map[$0] }
    }
}
