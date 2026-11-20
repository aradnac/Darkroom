//
//  ChemistryMath.swift
//  Darkroom
//
//  The two sums a darkroom actually needs: how much stock and water make a working
//  solution, and how many sessions a bottle of stock will give.
//

import Foundation

/// A working dilution, expressed in parts.
struct MixRatio: Identifiable, Hashable {
    let id: String
    var stockParts: Double
    var waterParts: Double

    var label: String {
        if waterParts <= 0 { return "Stock" }
        return "\(MixRatio.number(stockParts))+\(MixRatio.number(waterParts))"
    }

    var summary: String {
        if waterParts <= 0 { return "Used undiluted." }
        return "\(MixRatio.number(stockParts)) parts stock to \(MixRatio.number(waterParts)) parts water."
    }

    static func number(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.01 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }

    static let presets: [MixRatio] = [
        MixRatio(id: "1+0", stockParts: 1, waterParts: 0),
        MixRatio(id: "1+1", stockParts: 1, waterParts: 1),
        MixRatio(id: "1+3", stockParts: 1, waterParts: 3),
        MixRatio(id: "1+4", stockParts: 1, waterParts: 4),
        MixRatio(id: "1+9", stockParts: 1, waterParts: 9),
        MixRatio(id: "1+19", stockParts: 1, waterParts: 19),
        MixRatio(id: "1+25", stockParts: 1, waterParts: 25),
        MixRatio(id: "1+31", stockParts: 1, waterParts: 31),
        MixRatio(id: "1+50", stockParts: 1, waterParts: 50),
        MixRatio(id: "1+100", stockParts: 1, waterParts: 100)
    ]
}

enum ChemistryMath {
    /// Splits a working volume into stock and water.
    static func split(totalMl: Double, ratio: MixRatio) -> (stockMl: Double, waterMl: Double) {
        let parts = ratio.stockParts + ratio.waterParts
        guard parts > 0, totalMl > 0 else { return (0, 0) }
        let stock = totalMl * ratio.stockParts / parts
        return (stock, totalMl - stock)
    }

    /// How many whole sessions one bottle of stock will make, and what is left over.
    static func sessions(
        bottleMl: Double,
        sessionMl: Double,
        ratio: MixRatio
    ) -> (count: Int, stockPerSession: Double, waterPerSession: Double, leftoverMl: Double) {
        let parts = split(totalMl: sessionMl, ratio: ratio)
        guard parts.stockMl > 0, bottleMl > 0 else {
            return (0, 0, parts.waterMl, bottleMl)
        }
        let count = Int(floor(bottleMl / parts.stockMl))
        return (count, parts.stockMl, parts.waterMl, bottleMl - parts.stockMl * Double(count))
    }
}

enum Amount {
    static func ml(_ value: Double) -> String {
        Units.volume(millilitres: value)
    }

    static func litres(_ value: Double) -> String {
        Units.litres(value)
    }
}
