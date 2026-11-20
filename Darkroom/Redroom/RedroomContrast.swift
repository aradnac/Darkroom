//
//  RedroomContrast.swift
//  Darkroom
//
//  Contrast, worked out from the tokens themselves rather than judged by eye.
//  The four safelight intensities scale glow, rims and specular pools only, so
//  the text colours and the panel bodies never move; the one thing that can
//  brighten under the lamp is the glass a label sits on, and that is what the
//  worst-case estimate here accounts for.
//
//  `RedroomContrast.audit` is what the debug lighting screen shows and what the
//  unit test asserts at every intensity.
//

import SwiftUI

enum RedroomContrast {
    /// WCAG AA for body text.
    static let minimumTextRatio: Double = 4.5
    /// WCAG AA for large text and for non-text UI boundaries.
    static let minimumLargeTextRatio: Double = 3.0

    // MARK: Colour maths

    static func components(_ hex: UInt32) -> (r: Double, g: Double, b: Double) {
        (
            Double((hex >> 16) & 0xFF) / 255,
            Double((hex >> 8) & 0xFF) / 255,
            Double(hex & 0xFF) / 255
        )
    }

    /// sRGB relative luminance, as WCAG defines it.
    static func luminance(r: Double, g: Double, b: Double) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045
                ? channel / 12.92
                : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    static func luminance(_ hex: UInt32) -> Double {
        let parts = components(hex)
        return luminance(r: parts.r, g: parts.g, b: parts.b)
    }

    static func ratio(_ first: Double, _ second: Double) -> Double {
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func ratio(foreground: UInt32, background: UInt32) -> Double {
        ratio(luminance(foreground), luminance(background))
    }

    /// The glass under a label, at the brightest the lamp can make it: the body's
    /// own dark fill, plus the red lit edge and the specular pool at full direct
    /// light, composited over the room's background.
    ///
    /// `direct` is clamped to 1 by `RedroomLightSample`, so this is an upper
    /// bound rather than an estimate that drifts with position.
    static func brightestGlassLuminance(intensity: RedroomIntensity) -> Double {
        let factor = intensity.lightFactor
        // Body fill at the illuminated end of the smoked variant.
        let body = components(0x0C0404)
        let red = components(0xFF1018)

        // The lit edge and the specular pool together, as one wash over the
        // body: 0.21 of red at NORMAL, scaled by the safelight and clamped at
        // the 0.42 a pane can hold before it stops reading as glass.
        let overlay = min(0.42, 0.21 * factor)
        let r = body.r + (red.r - body.r) * overlay
        let g = body.g + (red.g - body.g) * overlay
        let b = body.b + (red.b - body.b) * overlay
        return luminance(r: r, g: g, b: b)
    }

    // MARK: Audit

    struct Pair: Identifiable {
        let id: String
        let label: String
        let foreground: UInt32
        let background: UInt32
        let isLargeText: Bool
        let required: Double
        let ratio: Double

        var passes: Bool { ratio >= required }
    }

    struct Report: Identifiable {
        let id: String
        let intensity: RedroomIntensity
        let pairs: [Pair]

        var passes: Bool { pairs.allSatisfy(\.passes) }
        var lowest: Pair? { pairs.min { $0.ratio < $1.ratio } }
    }

    /// Every label the theme draws, against the darkest and the brightest
    /// surfaces it can be drawn on, at one intensity.
    static func audit(intensity: RedroomIntensity) -> Report {
        let glass = brightestGlassLuminance(intensity: intensity)
        let background = luminance(Redroom.backgroundHex)
        let surface = luminance(Redroom.surfaceHex)
        let elevated = luminance(Redroom.surfaceElevatedHex)

        func pair(
            _ id: String,
            _ label: String,
            _ foreground: UInt32,
            _ backgroundLuminance: Double,
            large: Bool = false
        ) -> Pair {
            let required = large ? minimumLargeTextRatio : minimumTextRatio
            return Pair(
                id: id,
                label: label,
                foreground: foreground,
                background: Redroom.backgroundHex,
                isLargeText: large,
                required: required,
                ratio: ratio(luminance(foreground), backgroundLuminance)
            )
        }

        let pairs: [Pair] = [
            pair("body-bg", "Body text on the room", Redroom.textHex, background),
            pair("body-surface", "Body text on a smoked panel", Redroom.textHex, surface),
            pair("body-elevated", "Body text on a raised panel", Redroom.textHex, elevated),
            pair("body-glass", "Body text on glass at full lamp", Redroom.textHex, glass),
            pair("muted-bg", "Secondary text on the room", Redroom.textMutedHex, background),
            pair("muted-surface", "Secondary text on a smoked panel", Redroom.textMutedHex, surface),
            pair("muted-glass", "Secondary text on glass at full lamp", Redroom.textMutedHex, glass),
            pair("display-glass", "Display figure on glass at full lamp", Redroom.textHex, glass, large: true),
            pair("safelight-bg", "The safelight as a control label", Redroom.safelightHex, background)
        ]

        return Report(id: intensity.rawValue, intensity: intensity, pairs: pairs)
    }

    static var allReports: [Report] {
        RedroomIntensity.allCases.map(audit(intensity:))
    }
}

// MARK: - Raw token values

extension Redroom {
    static let backgroundHex: UInt32 = 0x030202
    static let backgroundSecondaryHex: UInt32 = 0x080303
    static let surfaceHex: UInt32 = 0x100505
    static let surfaceElevatedHex: UInt32 = 0x180707
    static let safelightHex: UInt32 = 0xFF1018
    static let safelightSecondaryHex: UInt32 = 0xC90012
    static let deepRedHex: UInt32 = 0x65000A
    static let textHex: UInt32 = 0xF4EAEA
    static let textMutedHex: UInt32 = 0xC4B6B6
    static let textDisabledHex: UInt32 = 0x594747
}
