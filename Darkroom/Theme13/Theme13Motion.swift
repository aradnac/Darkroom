//
//  Theme13Motion.swift
//  Darkroom
//
//  The theme's motion language: four hard-stepped poses at a deliberately low
//  frame rate. No springs, no easing, no smooth page transitions.
//

import SwiftUI

enum Theme13Motion {
    /// Burst poses: 0°, +3°, −2.5°, +1.5°.
    static let burstRotations: [Double] = [0, 3, -2.5, 1.5]
    /// Small element poses: 0°, +1.4°, −1.1°, +0.7°.
    static let smallRotations: [Double] = [0, 1.4, -1.1, 0.7]
    static let offsets: [CGSize] = [
        CGSize(width: 0, height: 0),
        CGSize(width: 1, height: -1),
        CGSize(width: -1, height: 1),
        CGSize(width: 1, height: 1)
    ]
    static let scales: [CGFloat] = [1, 1.02, 0.99, 1.015]

    static let wiggleFPS: Double = 6.4

    static func poseIndex(at date: Date, seed: Int) -> Int {
        let frame = Int(date.timeIntervalSinceReferenceDate * wiggleFPS)
        return ((frame &+ seed) % 4 + 4) % 4
    }

    static func burstAngle(at date: Date, seed: Int) -> Double {
        burstRotations[poseIndex(at: date, seed: seed)]
    }
}

/// Applies the four-pose wiggle. Frozen to pose 0 under Reduce Motion or while
/// the theme's Still mode is on.
struct Theme13Wiggle: ViewModifier {
    var seed: Int = 0
    var isBurst = false

    @ObservedObject private var store = Theme13SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if store.motionEnabled && !reduceMotion {
            TimelineView(.periodic(from: .now, by: 1.0 / Theme13Motion.wiggleFPS)) { timeline in
                let pose = Theme13Motion.poseIndex(at: timeline.date, seed: seed)
                content
                    .rotationEffect(.degrees(isBurst ? Theme13Motion.burstRotations[pose] : Theme13Motion.smallRotations[pose]))
                    .offset(Theme13Motion.offsets[pose])
                    .scaleEffect(Theme13Motion.scales[pose])
            }
        } else {
            content
        }
    }
}

extension View {
    /// Hard-stepped wiggle for a burst or a small decorative mark.
    func theme13Wiggle(seed: Int = 0, isBurst: Bool = false) -> some View {
        modifier(Theme13Wiggle(seed: seed, isBurst: isBurst))
    }
}
