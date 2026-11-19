//
//  LibraryImporter.swift
//  Darkroom
//
//  One reusable pipeline for growing the library: JSON documents and CSV rows
//  are decoded into the same merged document, keyed so a stock is never
//  duplicated and an emulsion generation is never collapsed into its parent.
//

import Foundation

enum LibraryImporter {
    enum ImportError: LocalizedError {
        case unreadable
        case empty

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "That file is not a library JSON document or a library CSV."
            case .empty:
                return "That file contained no records."
            }
        }
    }

    // MARK: Entry point

    static func document(from data: Data, filename: String) throws -> LibraryDocument {
        let isCSV = filename.lowercased().hasSuffix(".csv")
            || (filename.lowercased().hasSuffix(".txt"))
        if isCSV {
            guard let text = String(data: data, encoding: .utf8) else { throw ImportError.unreadable }
            return try document(fromCSV: text)
        }

        if let document = try? JSONDecoder().decode(LibraryDocument.self, from: data) {
            return document
        }
        // A bare array of time records is a valid, small import.
        if let times = try? JSONDecoder().decode([LibraryTimeEntry].self, from: data) {
            return LibraryDocument(times: times)
        }
        throw ImportError.unreadable
    }

    static func summary(of document: LibraryDocument) -> String {
        var parts: [String] = []
        if !document.films.isEmpty { parts.append("\(document.films.count) film\(document.films.count == 1 ? "" : "s")") }
        if !document.developers.isEmpty { parts.append("\(document.developers.count) developer\(document.developers.count == 1 ? "" : "s")") }
        if !document.times.isEmpty { parts.append("\(document.times.count) time record\(document.times.count == 1 ? "" : "s")") }
        if !document.sources.isEmpty { parts.append("\(document.sources.count) source\(document.sources.count == 1 ? "" : "s")") }
        if !document.crossProcess.isEmpty { parts.append("\(document.crossProcess.count) cross-process record\(document.crossProcess.count == 1 ? "" : "s")") }
        guard !parts.isEmpty else { return "Nothing to import." }
        return "Imported " + parts.joined(separator: ", ") + "."
    }

    // MARK: CSV

    /// The CSV carries a `kind` column so one file can add films, developers and
    /// times alike. Blank facts stay blank: nothing is inferred.
    static func document(fromCSV text: String) throws -> LibraryDocument {
        let rows = parseCSV(text)
        guard let headerRow = rows.first else { throw ImportError.empty }

        let header = headerRow.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        func column(_ row: [String], _ name: String) -> String? {
            guard let index = header.firstIndex(of: name), index < row.count else { return nil }
            let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }

        var films: [LibraryFilm] = []
        var developers: [LibraryDeveloper] = []
        var times: [LibraryTimeEntry] = []
        var sources: [String: LibrarySource] = [:]

        for row in rows.dropFirst() {
            guard row.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { continue }
            let kind = column(row, "kind")?.lowercased() ?? "time"
            let provenanceKind = LibraryProvenanceKind(rawValue: column(row, "provenance")?.lowercased() ?? "") ?? .unverified
            let sourceKey = column(row, "source")
            let provenance = LibraryProvenance(
                kind: provenanceKind,
                source: sourceKey,
                note: column(row, "note")
            )

            if let sourceKey {
                sources[sourceKey] = LibrarySource(
                    key: sourceKey,
                    title: column(row, "sourcetitle") ?? sourceKey,
                    publisher: column(row, "sourcepublisher") ?? "Imported",
                    url: column(row, "sourceurl") ?? "",
                    retrieved: column(row, "sourceretrieved") ?? ""
                )
            }

            switch kind {
            case "film":
                guard let key = column(row, "key"),
                      let name = column(row, "name"),
                      let manufacturer = column(row, "manufacturer") else { continue }
                let iso = Int(column(row, "iso") ?? "") ?? 0
                let process = FilmProcess(rawValue: column(row, "process") ?? "") ?? .blackAndWhite
                let formats = (column(row, "formats") ?? "")
                    .split(separator: "|")
                    .compactMap { FilmFormat(rawValue: String($0).trimmingCharacters(in: .whitespaces)) }
                let status = FilmStatus(rawValue: column(row, "status")?.lowercased() ?? "") ?? .current
                films.append(
                    LibraryFilm(
                        key: key,
                        manufacturer: manufacturer,
                        name: name,
                        iso: iso,
                        process: process,
                        formats: formats,
                        status: status,
                        generation: column(row, "generation"),
                        generationLabel: nil,
                        latitude: nil,
                        grain: nil,
                        contrast: nil,
                        reciprocity: nil,
                        notes: column(row, "note")
                    )
                )

            case "developer":
                guard let key = column(row, "key"),
                      let name = column(row, "name"),
                      let manufacturer = column(row, "manufacturer") else { continue }
                var dilutions: [LibraryDilution] = []
                if let raw = column(row, "dilution") {
                    dilutions.append(
                        LibraryDilution(
                            id: slug(raw),
                            label: raw,
                            stockParts: nil,
                            waterParts: nil,
                            provenance: provenance
                        )
                    )
                }
                developers.append(
                    LibraryDeveloper(
                        key: key,
                        manufacturer: manufacturer,
                        name: name,
                        type: column(row, "type"),
                        dilutions: dilutions,
                        capacity: column(row, "capacity").map {
                            LibraryFact(value: $0, unit: nil, provenance: provenance)
                        },
                        reuse: column(row, "reuse").map {
                            LibraryFact(value: $0, unit: nil, provenance: provenance)
                        }
                    )
                )

            default:
                guard let film = column(row, "film"),
                      let developer = column(row, "developer"),
                      let dilution = column(row, "dilution"),
                      let celsius = Double(column(row, "celsius") ?? "") else { continue }
                let seconds = Int(column(row, "seconds") ?? "")
                times.append(
                    LibraryTimeEntry(
                        film: film,
                        developer: developer,
                        dilution: dilution,
                        celsius: celsius,
                        seconds: seconds,
                        provenance: provenance
                    )
                )
            }
        }

        let document = LibraryDocument(
            sources: Array(sources.values),
            films: films,
            developers: developers,
            times: times
        )
        guard !document.isEmpty else { throw ImportError.empty }
        return document
    }

    private static func slug(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let cleaned = text.lowercased().unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(String(scalar)) : Character("-")
        }
        return String(cleaned)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
    }

    /// Minimal RFC 4180 reader: quoted fields, doubled quotes, and the delimiter
    /// or newline inside quotes. The DX index uses semicolons, so the separator
    /// is a parameter.
    static func parseCSV(_ text: String, delimiter: Character = ",") -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if inQuotes {
                if character == "\"" {
                    let next = text.index(after: index)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    inQuotes = true
                case delimiter:
                    row.append(field)
                    field = ""
                case "\r":
                    break
                case "\n":
                    row.append(field)
                    field = ""
                    rows.append(row)
                    row = []
                default:
                    field.append(character)
                }
            }
            index = text.index(after: index)
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}
