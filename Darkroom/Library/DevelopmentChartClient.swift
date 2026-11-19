//
//  DevelopmentChartClient.swift
//  Darkroom
//
//  The live development chart: 35mm.org's public API, read on demand, with every
//  time keeping the source it came from. Anonymous requests are allowed at 60 a
//  minute; answers are cached by the session and by HTTP, so a film you have
//  already opened costs nothing to open again.
//
//  Attribution is part of the deal: the film's page on 35mm.org is returned with
//  the times and the screen links back to it.
//

import Foundation

// MARK: - Models

struct ChartManufacturer: Decodable, Hashable {
    let slug: String
    let name: String
}

struct ChartReference: Decodable, Hashable {
    let slug: String
    let name: String
    let url: String?
}

struct ChartDilution: Decodable, Hashable {
    let label: String
    let isStock: Bool

    private enum CodingKeys: String, CodingKey {
        case label
        case isStock = "is_stock"
    }
}

struct ChartSourceInfo: Decodable, Hashable {
    let type: String
    let title: String?
    let url: String?

    var typeLabel: String {
        switch type {
        case "manufacturer_datasheet": return "Datasheet"
        case "own_test": return "Own test"
        case "third_party": return "Third party"
        case "community": return "Community"
        default: return type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

/// One published development time.
struct ChartTime: Decodable, Identifiable, Hashable {
    let id: Int
    let developer: ChartReference
    let dilution: ChartDilution
    let format: String?
    let ei: Int?
    let temperatureC: Double
    let timeSeconds: Int
    let time: String
    let agitation: String?
    let confidence: String
    let notes: String?
    let source: ChartSourceInfo?
    let url: String?

    private enum CodingKeys: String, CodingKey {
        case id, developer, dilution, format, ei, time, agitation, confidence, notes, source, url
        case temperatureC = "temperature_c"
        case timeSeconds = "time_seconds"
    }

    /// How far the time has been checked against its source.
    var confidenceLabel: String {
        switch confidence {
        case "verified": return "Verified"
        case "community": return "Community"
        case "unverified": return "Unverified"
        case "disputed": return "Disputed"
        default: return confidence.capitalized
        }
    }
}

struct ChartFilmTimes {
    let slug: String
    let name: String
    let filmURL: URL?
    let times: [ChartTime]
    let attribution: String
}

// MARK: - Errors

enum ChartError: LocalizedError {
    case noMatch
    case busy
    case offline
    case badResponse

    var errorDescription: String? {
        switch self {
        case .noMatch:
            return "This film is not in the 35mm.org chart."
        case .busy:
            return "35mm.org is busy right now. Try again in a minute."
        case .offline:
            return "Could not reach 35mm.org. Check the connection and try again."
        case .badResponse:
            return "35mm.org answered in a way the app could not read."
        }
    }
}

// MARK: - Client

final class DevelopmentChartClient {
    static let shared = DevelopmentChartClient()

    private let baseURL = URL(string: "https://35mm.org/api/public/v1")!
    private let session: URLSession

    private var slugCache: [String: String?] = [:]
    private var timesCache: [String: ChartFilmTimes] = [:]

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.httpAdditionalHeaders = ["Accept": "application/json"]
        session = URLSession(configuration: configuration)
    }

    // MARK: Public

    func times(manufacturer: String, name: String, iso: Int) async throws -> ChartFilmTimes {
        let slug = try await resolveSlug(manufacturer: manufacturer, name: name, iso: iso)
        guard let slug else { throw ChartError.noMatch }
        return try await times(forSlug: slug)
    }

    // MARK: Slug resolution

    private func resolveSlug(manufacturer: String, name: String, iso: Int) async throws -> String? {
        let cacheKey = "\(manufacturer.lowercased())|\(name.lowercased())|\(iso)"
        if let cached = slugCache[cacheKey] { return cached }

        let query = "\(manufacturer) \(name)"
        let summaries = try await filmSummaries(matching: query)
        let resolved = Self.bestMatch(
            manufacturer: manufacturer,
            name: name,
            iso: iso,
            in: summaries
        )

        slugCache[cacheKey] = resolved
        return resolved
    }

    /// Picks the catalogue entry a library film means: maker, name and ISO all
    /// have to agree, so "Delta 100" cannot answer with "Delta 3200".
    static func bestMatch(
        manufacturer: String,
        name: String,
        iso: Int,
        in summaries: [ChartFilmSummary]
    ) -> String? {
        let wantedMaker = Self.canonical(manufacturer)
        let wantedName = Self.canonical(name)

        func baseName(of summary: ChartFilmSummary) -> String {
            var base = summary.fullName
            if base.lowercased().hasPrefix(summary.manufacturer.name.lowercased()) {
                base = String(base.dropFirst(summary.manufacturer.name.count))
            }
            return base
        }

        let sameMaker = summaries.filter { Self.canonical($0.manufacturer.name) == wantedMaker }
        let pool = sameMaker.isEmpty ? summaries : sameMaker

        if let exact = pool.first(where: { summary in
            Self.canonical(baseName(of: summary)) == wantedName && (summary.iso ?? iso) == iso
        }) {
            return exact.slug
        }

        if let prefixed = pool.first(where: { summary in
            let base = Self.canonical(baseName(of: summary))
            return base.hasPrefix(wantedName) && (summary.iso ?? iso) == iso
        }) {
            return prefixed.slug
        }

        if let byISO = pool.first(where: { ($0.iso ?? iso) == iso }) {
            return byISO.slug
        }

        return nil
    }

    private static func canonical(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "plus", with: "+")
            .filter { $0.isLetter || $0.isNumber || $0 == "+" }
    }

    private func filmSummaries(matching query: String) async throws -> [ChartFilmSummary] {
        var components = URLComponents(url: baseURL.appendingPathComponent("films"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: "20")
        ]
        guard let url = components?.url else { throw ChartError.badResponse }

        let data = try await get(url)
        let envelope = try? JSONDecoder().decode(FilmListEnvelope.self, from: data)
        return envelope?.data ?? []
    }

    // MARK: Film detail

    private func times(forSlug slug: String) async throws -> ChartFilmTimes {
        if let cached = timesCache[slug] { return cached }

        let url = baseURL
            .appendingPathComponent("films")
            .appendingPathComponent(slug)
        let data = try await get(url)
        let result = try Self.decode(filmDetail: data)
        timesCache[slug] = result
        return result
    }

    /// Split out so the wire format can be exercised against a saved answer.
    static func decode(filmDetail data: Data) throws -> ChartFilmTimes {
        let envelope = try? JSONDecoder().decode(FilmDetailEnvelope.self, from: data)
        guard let envelope else { throw ChartError.badResponse }

        return ChartFilmTimes(
            slug: envelope.data.slug,
            name: envelope.data.fullName,
            filmURL: envelope.data.url.flatMap(URL.init(string:)),
            times: envelope.data.developmentTimes,
            attribution: envelope.attribution?.text
                ?? "Data from 35mm.org — each time with its source."
        )
    }

    // MARK: Transport

    private func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Darkroom/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ChartError.offline
        }

        guard let http = response as? HTTPURLResponse else { throw ChartError.badResponse }
        switch http.statusCode {
        case 200:
            return data
        case 429:
            throw ChartError.busy
        case 404:
            throw ChartError.noMatch
        default:
            throw ChartError.badResponse
        }
    }

    // MARK: Wire format

    private struct FilmListEnvelope: Decodable {
        let data: [ChartFilmSummary]
    }

    struct ChartFilmSummary: Decodable {
        let slug: String
        let name: String
        let fullName: String
        let iso: Int?
        let manufacturer: ChartManufacturer

        private enum CodingKeys: String, CodingKey {
            case slug, name, iso, manufacturer
            case fullName = "full_name"
        }
    }

    private struct ChartAttribution: Decodable {
        let text: String
        let url: String?
    }

    private struct FilmDetailEnvelope: Decodable {
        let data: ChartFilmDetail
        let attribution: ChartAttribution?
    }

    private struct ChartFilmDetail: Decodable {
        let slug: String
        let name: String
        let fullName: String
        let url: String?
        let developmentTimes: [ChartTime]

        private enum CodingKeys: String, CodingKey {
            case slug, name, url
            case fullName = "full_name"
            case developmentTimes = "development_times"
        }
    }
}
