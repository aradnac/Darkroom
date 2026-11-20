//
//  CardMorph.swift
//  Darkroom
//
//  A card that changes in place should move, not blink. These two modifiers are
//  the whole vocabulary: text rolls over word by word, figures roll digit by
//  digit, and everything inside the card animates as one movement.
//
//  What drives the animation matters. Each one takes the value that means "this
//  card is now a different card" — a stage index, a phase — and animates only
//  when that changes. A live countdown inside the card keeps its own cadence, so
//  the step change morphs while the seconds tick as they always did.
//

import SwiftUI

extension View {
    /// Content across a card morphs when `value` changes: labels slide and
    /// cross-fade, the whole change animating together.
    func cardMorph<Value: Equatable>(_ value: Value) -> some View {
        contentTransition(.interpolate)
            .animation(.snappy(duration: 0.38, extraBounce: 0.05), value: value)
    }

    /// A figure that rolls vertically, one digit at a time, with the blur the
    /// numeric transition gives it.
    func numericMorph<Value: Equatable & BinaryInteger>(_ value: Value) -> some View {
        contentTransition(.numericText(value: Double(value)))
            .monospacedDigit()
            .animation(.snappy(duration: 0.42, extraBounce: 0.04), value: value)
    }
}
