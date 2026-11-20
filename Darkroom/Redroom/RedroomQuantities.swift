//
//  RedroomQuantities.swift
//  Darkroom
//
//  The one quantity the room turns into a shape: how full a bottle is drawn.
//  Kept as a pure function so the mapping from the batch's real numbers to the
//  liquid's height can be checked without a screen.
//

import Foundation

enum RedroomQuantities {
    /// The level a bottle is drawn at: what is left of its capacity, clamped.
    /// A bottle with no capacity set reads empty rather than invented full.
    static func bottleLevel(remaining: Int, capacity: Int) -> Double {
        guard capacity > 0 else { return 0 }
        return min(max(Double(remaining) / Double(capacity), 0), 1)
    }

    /// The figure the bottle's card prints beside it.
    static func bottlePercent(remaining: Int, capacity: Int) -> Int {
        Int((bottleLevel(remaining: remaining, capacity: capacity) * 100).rounded())
    }
}
