//
//  StarterLibrary.swift
//  Darkroom
//
//  The session setup's film and developer lists now come from the reference
//  library. A built-in pair remains as a floor, so the setup screen still opens
//  if the bundled library is ever missing or empty.
//

import Foundation

enum StarterLibrary {
    static var films: [Film] {
        let library = LibraryStore.shared.legacyFilms
        return library.isEmpty ? fallbackFilms : library
    }

    static var developers: [Developer] {
        let library = LibraryStore.shared.legacyDevelopers
        return library.isEmpty ? fallbackDevelopers : library
    }

    // MARK: Floor

    private static let fallbackFilms: [Film] = [
        Film(
            id: "ilford-hp5-plus",
            manufacturer: "Ilford",
            name: "HP5 Plus",
            iso: 400,
            process: .blackAndWhite,
            formats: [.size135, .size120]
        )
    ]

    private static let fallbackDevelopers: [Developer] = [
        Developer(
            id: "ilford-id-11",
            manufacturer: "Ilford",
            name: "ID-11",
            dilutions: [
                Dilution(id: "stock", label: "Stock", stockParts: 1, waterParts: 0),
                Dilution(id: "1+1", label: "1+1", stockParts: 1, waterParts: 1)
            ]
        )
    ]
}
