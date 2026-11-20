//
//  Theme.swift
//  Darkroom
//
//  The shared visual language. Every token resolves to the darkroom defaults,
//  or to the hidden print theme's current palette when that theme is active.
//

import SwiftUI

enum DarkroomThemeDefaults {
    static let base = Color(red: 0.043, green: 0.047, blue: 0.055)
    static let baseLift = Color(red: 0.072, green: 0.078, blue: 0.088)

    static let amber = Color(red: 0.976, green: 0.667, blue: 0.196)
    static let amberSoft = Color(red: 1.0, green: 0.812, blue: 0.494)
    static let amberDeep = Color(red: 0.839, green: 0.463, blue: 0.098)
    static let amberInk = Color(red: 0.106, green: 0.075, blue: 0.020)

    static let ink = Color.white.opacity(0.94)
    static let inkSoft = Color.white.opacity(0.64)
    static let inkFaint = Color.white.opacity(0.38)
    static let hairline = Color.white.opacity(0.09)
    static let border = Color.white.opacity(0.12)
    static let raised = Color.white.opacity(0.06)
}

enum Theme {
    private static var store: Theme13SettingsStore { .shared }

    /// True while the hidden print theme owns the interface.
    static var isPaper: Bool { store.isTheme13Active }

    /// True while the soft-glass language owns the interface.
    static var isSoft: Bool { store.isSoftGlassActive }

    static var palette: Theme13Palette { store.palette }
    private static var paperIsDark: Bool { store.isDarkAppearance }

    // MARK: Fields

    static var base: Color {
        if isPaper { return palette.bg(isDark: paperIsDark) }
        if isSoft { return SoftGlassTheme.background }
        return DarkroomThemeDefaults.base
    }

    static var baseLift: Color {
        if isPaper { return palette.plate(isDark: paperIsDark) }
        if isSoft { return SoftGlassTheme.backgroundLift }
        return DarkroomThemeDefaults.baseLift
    }

    static var surfaceRaised: Color {
        if isPaper { return palette.plateRaised(isDark: paperIsDark) }
        if isSoft { return SoftGlassTheme.surfaceRaised }
        return DarkroomThemeDefaults.raised
    }

    // MARK: Inks

    static var ink: Color {
        if isPaper { return palette.ink(isDark: paperIsDark) }
        if isSoft { return SoftGlassTheme.ink }
        return DarkroomThemeDefaults.ink
    }

    static var inkSoft: Color {
        if isPaper { return palette.inkAlt(isDark: paperIsDark) }
        if isSoft { return SoftGlassTheme.inkSoft }
        return DarkroomThemeDefaults.inkSoft
    }

    static var inkFaint: Color {
        if isPaper { return palette.inkAlt(isDark: paperIsDark).opacity(0.72) }
        if isSoft { return SoftGlassTheme.inkFaint }
        return DarkroomThemeDefaults.inkFaint
    }

    static var hairline: Color {
        if isPaper { return palette.rule(isDark: paperIsDark) }
        if isSoft { return SoftGlassTheme.hairline }
        return DarkroomThemeDefaults.hairline
    }

    static var border: Color {
        if isPaper { return palette.stroke(isDark: paperIsDark) }
        if isSoft { return SoftGlassTheme.border }
        return DarkroomThemeDefaults.border
    }

    // MARK: Accents

    static var amber: Color {
        if isPaper { return palette.accent }
        if isSoft { return SoftGlassTheme.amber }
        return Preferences.shared.accent.base
    }

    static var amberSoft: Color {
        if isPaper { return palette.accent2 }
        if isSoft { return SoftGlassTheme.amberSoft }
        return Preferences.shared.accent.soft
    }

    static var amberDeep: Color {
        if isPaper { return palette.accentText }
        if isSoft { return SoftGlassTheme.amberDeep }
        return Preferences.shared.accent.deep
    }

    /// Ink that sits on top of the accent block.
    static var amberInk: Color {
        if isPaper { return palette.accentInk }
        if isSoft { return SoftGlassTheme.amberInk }
        return Preferences.shared.accent.ink
    }

    static var accentWash: Color {
        if isPaper { return palette.accent.opacity(0.14) }
        if isSoft { return SoftGlassTheme.amber.opacity(0.14) }
        return amber.opacity(0.13)
    }

    /// The track a switch takes when it is on. White is the soft-glass signal
    /// for *pressable*, not for *on*: a white track around a white knob reads
    /// as one blank pill, so the switch takes a quieter grey there.
    static var switchTint: Color {
        if isPaper { return palette.accent }
        if isSoft { return Color(white: 0.58) }
        return Preferences.shared.accent.base
    }

    /// Decorative blooms — only the soft-glass language uses these.
    static var magenta: Color {
        isSoft ? SoftGlassTheme.magenta : DarkroomThemeDefaults.amberDeep
    }

    static var mint: Color {
        isSoft ? SoftGlassTheme.mint : DarkroomThemeDefaults.amberSoft
    }

    // MARK: Fills

    /// The paper theme is flat by definition; the darkroom keeps its amber ramp.
    static var amberGradient: LinearGradient {
        if isPaper {
            return LinearGradient(
                colors: [palette.accent, palette.accent, palette.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        if isSoft { return SoftGlassTheme.amberGradient }
        let accent = Preferences.shared.accent
        return LinearGradient(
            colors: [accent.soft, accent.base, accent.deep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var panelGradient: LinearGradient {
        if isPaper {
            return LinearGradient(
                colors: [palette.plate(isDark: paperIsDark), palette.plate(isDark: paperIsDark), palette.plate(isDark: paperIsDark)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        if isSoft { return SoftGlassTheme.panelGradient }
        return LinearGradient(
            colors: [Color.white.opacity(0.10), Color.white.opacity(0.028), Color.black.opacity(0.24)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Font {
    /// Tabular figures — every number in the app uses this so digits never jump.
    /// The print theme sets them in mono; the darkroom and the soft-glass language
    /// in rounded.
    static func figures(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        if Theme13SettingsStore.shared.isTheme13Active {
            let scaled = size * Theme13SettingsStore.shared.fontScale
            return .system(size: scaled, weight: weight, design: .monospaced).monospacedDigit()
        }
        return .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}
