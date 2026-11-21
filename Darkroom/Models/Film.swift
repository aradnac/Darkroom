//
//  Film.swift
//  Darkroom
//

import Foundation

enum FilmProcess: String, CaseIterable, Identifiable, Codable {
    case blackAndWhite
    case colourNegative
    case colourReversal
    case cinemaNegative

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blackAndWhite: return "B&W"
        case .colourNegative: return "C-41"
        case .colourReversal: return "E-6"
        case .cinemaNegative: return "ECN-2"
        }
    }
}

enum FilmFormat: String, CaseIterable, Identifiable, Codable {
    case size135
    case size120
    /// The Instamatic cartridge. Only historical films use it, but without the
    /// case a library document that lists it cannot be decoded at all.
    case size126
    case sheet4x5
    case sheet8x10
    case cinema

    var id: String { rawValue }

    var label: String {
        switch self {
        case .size135: return "35 mm"
        case .size120: return "120"
        case .size126: return "126"
        case .sheet4x5: return "4×5"
        case .sheet8x10: return "8×10"
        case .cinema: return "Cinema"
        }
    }
}

struct Film: Identifiable, Hashable {
    let id: String
    let manufacturer: String
    let name: String
    let iso: Int
    let process: FilmProcess
    let formats: [FilmFormat]

    /// "HP5 Plus 400"
    var displayName: String { "\(name) \(iso)" }

    /// "Ilford HP5 Plus 400"
    var fullName: String { "\(manufacturer) \(name) \(iso)" }

    var formatSummary: String {
        formats.map(\.label).joined(separator: " · ")
    }
}
