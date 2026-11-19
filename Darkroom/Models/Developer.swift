//
//  Developer.swift
//  Darkroom
//

import Foundation

struct Dilution: Identifiable, Hashable {
    let id: String
    let label: String
    let stockParts: Double?
    let waterParts: Double?

    var isStock: Bool { (waterParts ?? 0) == 0 }

    /// "1+1" when the parts are known, otherwise nil.
    var ratio: String? {
        guard let stock = stockParts, let water = waterParts else { return nil }
        if water == 0 { return "Stock" }
        return "\(Self.number(stock))+\(Self.number(water))"
    }

    static func number(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.01 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
}

struct Developer: Identifiable, Hashable {
    let id: String
    let manufacturer: String
    let name: String
    let dilutions: [Dilution]

    var displayName: String { name }

    var manufacturerLine: String { manufacturer }

    func dilution(id: String) -> Dilution? {
        dilutions.first { $0.id == id }
    }
}
