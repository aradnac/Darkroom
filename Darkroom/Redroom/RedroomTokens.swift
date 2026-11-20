//
//  RedroomTokens.swift
//  Darkroom
//
//  THE THIRD DESIGN LANGUAGE — REDROOM.
//
//  A photographic darkroom at 2 AM: near-black everywhere, one intense red
//  safelight above, and every surface lit by that same lamp. These are the
//  tokens: the colours, the four safelight intensities, and the type.
//
//  Red is illumination, not decoration. Text stays the same near-white at every
//  intensity, so contrast never depends on how bright the room is.
//

import SwiftUI

// MARK: - Safelight intensity

enum RedroomIntensity: String, CaseIterable, Identifiable {
    case dim
    case normal
    case bright
    case extreme

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dim: return "Dim"
        case .normal: return "Normal"
        case .bright: return "Bright"
        case .extreme: return "Extreme"
        }
    }

    /// Scales glow, reflections and highlights only. Type colour never reads
    /// this, which is what keeps body text at the same contrast in every room.
    var lightFactor: Double {
        switch self {
        case .dim: return 0.55
        case .normal: return 1.0
        case .bright: return 1.45
        case .extreme: return 2.0
        }
    }
}

// MARK: - Palette

enum Redroom {
    /// The theme identifier in the store.
    static let themeIdentifier = "redroom"
    /// The persisted flag that makes REDROOM selectable. Set once every screen
    /// has a REDROOM presentation.
    static let availabilityKey = "redroom.available"

    /// `#030202`
    static let background = color(0x030202)
    /// `#080303`
    static let backgroundSecondary = color(0x080303)
    /// `#100505`
    static let surface = color(0x100505)
    /// `#180707`
    static let surfaceElevated = color(0x180707)

    /// `#FF1018`
    static let safelight = color(0xFF1018)
    /// `#C90012`
    static let safelightSecondary = color(0xC90012)
    /// `#65000A`
    static let deepRed = color(0x65000A)

    /// `#A99A9A` → `#C4B6B6`. Lifted so the room's quiet text still clears 4.5:1
    /// on glass at the extreme safelight, which is the brightest a label is ever
    /// asked to sit on.
    static let textMuted = color(0xC4B6B6)
    /// `#F4EAEA`
    static let text = color(0xF4EAEA)
    /// `#594747`
    static let textDisabled = color(0x594747)

    /// A hairline that reads on any glass without glowing.
    static let hairline = Color.white.opacity(0.08)

    static func color(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    // MARK: Type
    //
    // Photographic equipment is engraved, not typeset: a rounded grotesque for
    // reading, monospaced figures for every number, tracked caps for labels.

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func figure(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    static func label(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .semibold)
    }
}

// MARK: - Metrics

enum RedroomMetrics {
    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 16
    static let screenPadding: CGFloat = 20
}
