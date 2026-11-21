//
//  Theme.swift
//  Darkroom
//
//  The shared visual language. Every token resolves to the darkroom defaults, to
//  the soft-glass language's values, or — while one of the twelve design
//  languages is on — to that language's own palette and type.
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
    private static var store: AppearanceStore { .shared }

    /// True while the soft-glass language owns the interface.
    static var isSoft: Bool { store.isSoftGlassActive }

    /// The active design language's resolved style, when one is on.
    private static var language: DLStyle? { DLRuntime.activeStyle }

    // MARK: Fields

    static var base: Color {
        if let language { return language.palette.field }
        if isSoft { return SoftGlassTheme.background }
        return DarkroomThemeDefaults.base
    }

    static var baseLift: Color {
        if let language { return language.palette.fieldAlt }
        if isSoft { return SoftGlassTheme.backgroundLift }
        return DarkroomThemeDefaults.baseLift
    }

    static var surfaceRaised: Color {
        if let language { return language.palette.surfaceAlt }
        if isSoft { return SoftGlassTheme.surfaceRaised }
        return DarkroomThemeDefaults.raised
    }

    // MARK: Inks

    static var ink: Color {
        if let language { return language.palette.ink }
        if isSoft { return SoftGlassTheme.ink }
        return DarkroomThemeDefaults.ink
    }

    static var inkSoft: Color {
        if let language { return language.palette.inkSoft }
        if isSoft { return SoftGlassTheme.inkSoft }
        return DarkroomThemeDefaults.inkSoft
    }

    static var inkFaint: Color {
        if let language { return language.palette.inkFaint }
        if isSoft { return SoftGlassTheme.inkFaint }
        return DarkroomThemeDefaults.inkFaint
    }

    static var hairline: Color {
        if let language { return language.palette.line }
        if isSoft { return SoftGlassTheme.hairline }
        return DarkroomThemeDefaults.hairline
    }

    static var border: Color {
        if let language { return language.palette.lineStrong }
        if isSoft { return SoftGlassTheme.border }
        return DarkroomThemeDefaults.border
    }

    // MARK: Accents

    static var amber: Color {
        if let language { return language.palette.accent }
        if isSoft { return SoftGlassTheme.amber }
        return Preferences.shared.accent.base
    }

    static var amberSoft: Color {
        if let language { return language.palette.glow }
        if isSoft { return SoftGlassTheme.amberSoft }
        return Preferences.shared.accent.soft
    }

    static var amberDeep: Color {
        if let language { return language.palette.glowTwo }
        if isSoft { return SoftGlassTheme.amberDeep }
        return Preferences.shared.accent.deep
    }

    /// Ink that sits on top of the accent block.
    static var amberInk: Color {
        if let language { return language.palette.accentInk }
        if isSoft { return SoftGlassTheme.amberInk }
        return Preferences.shared.accent.ink
    }

    static var accentWash: Color {
        if let language { return language.palette.accent.opacity(0.14) }
        if isSoft { return SoftGlassTheme.amber.opacity(0.14) }
        return amber.opacity(0.13)
    }

    /// The track a switch takes when it is on. White is the soft-glass signal
    /// for *pressable*, not for *on*: a white track around a white knob reads
    /// as one blank pill, so the switch takes a quieter grey there.
    static var switchTint: Color {
        if let language { return language.palette.accent }
        if isSoft { return Color(white: 0.58) }
        return Preferences.shared.accent.base
    }

    /// Decorative blooms — only the softer languages use these.
    static var magenta: Color {
        if let language { return language.palette.glow }
        return isSoft ? Preferences.shared.accent.bloom : Preferences.shared.accent.deep
    }

    static var mint: Color {
        if let language { return language.palette.glowTwo }
        return Preferences.shared.accent.soft
    }

    // MARK: Fills

    static var amberGradient: LinearGradient {
        if let language {
            return LinearGradient(
                colors: [language.palette.accent, language.palette.glow],
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
        if let language {
            return LinearGradient(
                colors: [language.palette.surface, language.palette.surfaceAlt],
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
    /// A design language sets them in its own numeric face.
    static func figures(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        if let language = DLRuntime.activeStyle {
            return language.figure(size, weight: weight)
        }
        return .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}
