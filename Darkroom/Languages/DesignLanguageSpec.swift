//
//  DesignLanguageSpec.swift
//  Darkroom
//
//  What makes each language a different design team rather than a different
//  colour: a palette for each brightness, a type ramp, the geometry its panels
//  and controls are cut to, the navigation paradigm it navigates with, the
//  layout it lays a screen out in, and its motion.
//
//  Nothing here knows about the app's data. The screens above ask the spec for
//  a shape and draw it.
//

import SwiftUI

extension Color {
    /// A hex colour for the palettes below. Named rather than `hex` so it can
    /// never collide with another helper in the app.
    init(dlHex: UInt32) {
        self.init(
            .sRGB,
            red: Double((dlHex >> 16) & 0xFF) / 255,
            green: Double((dlHex >> 8) & 0xFF) / 255,
            blue: Double(dlHex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Palette

struct DLPalette {
    /// The page the screen sits on.
    var field: Color
    /// A second field, for languages that stripe or tint their page.
    var fieldAlt: Color
    /// The panel a group of values is mounted on.
    var surface: Color
    var surfaceAlt: Color

    var ink: Color
    var inkSoft: Color
    var inkFaint: Color

    /// Rules and hairlines.
    var line: Color
    /// The heavy rule a language uses when it means it.
    var lineStrong: Color

    var accent: Color
    /// Ink that sits on the accent block.
    var accentInk: Color
    /// A second light, used for glows and decorations.
    var glow: Color
    var glowTwo: Color

    /// Anything that must never be mistaken for ordinary ink.
    var danger: Color

    init(
        field: UInt32,
        fieldAlt: UInt32,
        surface: UInt32,
        surfaceAlt: UInt32,
        ink: UInt32,
        inkSoft: UInt32,
        inkFaint: UInt32,
        line: UInt32,
        lineStrong: UInt32,
        accent: UInt32,
        accentInk: UInt32,
        glow: UInt32,
        glowTwo: UInt32,
        danger: UInt32,
        surfaceAlpha: Double = 1,
        surfaceAltAlpha: Double = 1,
        lineAlpha: Double = 1,
        lineStrongAlpha: Double = 1
    ) {
        self.field = Color(dlHex: field)
        self.fieldAlt = Color(dlHex: fieldAlt)
        self.surface = Color(dlHex: surface).opacity(surfaceAlpha)
        self.surfaceAlt = Color(dlHex: surfaceAlt).opacity(surfaceAltAlpha)
        self.ink = Color(dlHex: ink)
        self.inkSoft = Color(dlHex: inkSoft)
        self.inkFaint = Color(dlHex: inkFaint)
        self.line = Color(dlHex: line).opacity(lineAlpha)
        self.lineStrong = Color(dlHex: lineStrong).opacity(lineStrongAlpha)
        self.accent = Color(dlHex: accent)
        self.accentInk = Color(dlHex: accentInk)
        self.glow = Color(dlHex: glow)
        self.glowTwo = Color(dlHex: glowTwo)
        self.danger = Color(dlHex: danger)
    }

    /// The same palette built from resolved colours, for a theme whose field is
    /// the reader's palette rather than a fixed colour.
    init(
        field: Color,
        fieldAlt: Color,
        surface: Color,
        surfaceAlt: Color,
        ink: Color,
        inkSoft: Color,
        inkFaint: Color,
        line: Color,
        lineStrong: Color,
        accent: Color,
        accentInk: Color,
        glow: Color,
        glowTwo: Color,
        danger: Color
    ) {
        self.field = field
        self.fieldAlt = fieldAlt
        self.surface = surface
        self.surfaceAlt = surfaceAlt
        self.ink = ink
        self.inkSoft = inkSoft
        self.inkFaint = inkFaint
        self.line = line
        self.lineStrong = lineStrong
        self.accent = accent
        self.accentInk = accentInk
        self.glow = glow
        self.glowTwo = glowTwo
        self.danger = danger
    }

    func withAccent(_ accent: Color, ink: Color, glow: Color) -> DLPalette {
        var copy = self
        copy.accent = accent
        copy.accentInk = ink
        copy.glow = glow
        copy.glowTwo = accent
        return copy
    }
}

// MARK: - Type

struct DLTypeSpec {
    var displayDesign: Font.Design = .default
    var bodyDesign: Font.Design = .default
    var numericDesign: Font.Design = .monospaced

    var displaySize: CGFloat = 30
    var displayWeight: Font.Weight = .bold
    var displayTracking: CGFloat = -0.4
    var displayUppercase: Bool = false

    var titleSize: CGFloat = 20
    var titleWeight: Font.Weight = .semibold
    var titleTracking: CGFloat = 0

    var bodySize: CGFloat = 15
    var smallSize: CGFloat = 13

    var labelSize: CGFloat = 10
    var labelWeight: Font.Weight = .semibold
    var labelTracking: CGFloat = 1.8
    var labelUppercase: Bool = true

    var lineSpacing: CGFloat = 3

    func display(scale: CGFloat) -> Font {
        .system(size: displaySize * scale, weight: displayWeight, design: displayDesign)
    }

    func title(scale: CGFloat, size: CGFloat? = nil) -> Font {
        .system(size: (size ?? titleSize) * scale, weight: titleWeight, design: displayDesign)
    }

    func body(scale: CGFloat, size: CGFloat? = nil, weight: Font.Weight = .regular) -> Font {
        .system(size: (size ?? bodySize) * scale, weight: weight, design: bodyDesign)
    }

    func label(scale: CGFloat) -> Font {
        .system(size: labelSize * scale, weight: labelWeight, design: bodyDesign)
    }

    /// Figures are tabular so a column of times never jumps while counting.
    func figure(scale: CGFloat, size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size * scale, weight: weight, design: numericDesign)
            .monospacedDigit()
    }
}

// MARK: - Geometry

enum DLShadow: String {
    case none
    case soft
    case hard
    case glow
    case inset
    case deep
}

enum DLSurfaceStyle: String {
    case glass
    case clean
    case acrylic
    case tonal
    case paper
    case block
    case extruded
    case hud
    case metal
    case terminal
    case outlined
    /// A flat colour tile: no border, no shadow, one shade of the field.
    case flat
}

enum DLButtonShape: String {
    case capsule
    case rounded
    case roundedSmall
    case pill
    case rectangle
    case sharpBlock
    case extruded
    case clipped
    case underline
    case metal
    case terminal
    /// A black block: the deck's one action.
    case deck
}

/// How a language gets from one place to another.
enum DLNavigation: String {
    case floatingDock
    case minimalBar
    case fluentPivot
    case materialBar
    case swissRail
    case brutalBlocks
    case softTray
    case hudRail
    case filmStrip
    case masthead
    case switchboard
    case promptBar
    /// A strip of labels on the field, the current one a black chip.
    case flatBar
}

/// How a language arranges a screen's blocks.
enum DLLayout: String {
    case glassStack
    case cleanStack
    case pivotCards
    case tonalCards
    case swissGrid
    case brutalBlocks
    case softGrid
    case hudPanels
    case editorialColumns
    case metalPanel
    case terminalPanels
    case filmStrip
    /// A deck: the title, the gauge, the time and the knobs, one under another.
    case flatDeck
}

enum DLBackground: String {
    case liquid
    case clean
    case mica
    case tonal
    case grid
    case concrete
    case clay
    case neon
    case safelight
    case paper
    case metal
    case crt
    /// The field and nothing else: one flat colour from edge to edge.
    case flat
}

struct DLGeometry {
    var cardRadius: CGFloat = 26
    var controlRadius: CGFloat = 14
    var chipRadius: CGFloat = 8
    var borderWidth: CGFloat = 1
    var shadow: DLShadow = .soft
    var shadowOffset: CGFloat = 0

    var pagePadding: CGFloat = 20
    var sectionSpacing: CGFloat = 18
    var rowSpacing: CGFloat = 12
    var blockSpacing: CGFloat = 14

    var controlHeight: CGFloat = 52
    var gridColumns: Int = 2
    var headerHeight: CGFloat = 52
    var navHeight: CGFloat = 64

    /// A language that draws every panel with a corner this tight is a language
    /// whose shapes are meant to be seen, so the components ask rather than guess.
    var isSquare: Bool { cardRadius <= 2 }
}

// MARK: - Spec

struct DLSpec {
    let language: ThemeLanguage
    var light: DLPalette?
    var dark: DLPalette?
    var type: DLTypeSpec
    var geometry: DLGeometry
    var nav: DLNavigation
    var layout: DLLayout
    var surface: DLSurfaceStyle
    var button: DLButtonShape
    var background: DLBackground
    var motion: DLMotion

    init(
        language: ThemeLanguage,
        light: DLPalette? = nil,
        dark: DLPalette? = nil,
        type: DLTypeSpec = DLTypeSpec(),
        geometry: DLGeometry = DLGeometry(),
        nav: DLNavigation = .floatingDock,
        layout: DLLayout = .glassStack,
        surface: DLSurfaceStyle = .glass,
        button: DLButtonShape = .capsule,
        background: DLBackground = .liquid,
        motion: DLMotion = DLMotion()
    ) {
        self.language = language
        self.light = light
        self.dark = dark
        self.type = type
        self.geometry = geometry
        self.nav = nav
        self.layout = layout
        self.surface = surface
        self.button = button
        self.background = background
        self.motion = motion
    }

    func palette(isDark: Bool, accent: AccentChoice? = nil) -> DLPalette {
        // The recorder is lit by the palette itself: its field is the chosen lamp
        // and everything on the field is black, at either brightness.
        if language == .recorder {
            return DLSpec.recorderPalette(accent)
        }

        var resolved: DLPalette
        if let dark, let light {
            resolved = isDark ? dark : light
        } else if let dark {
            resolved = dark
        } else {
            resolved = light ?? DLSpec.fallbackPalette
        }

        // Every theme is lit by the palette the reader chose. On a light field the
        // deeper shade of the lamp keeps its rules and labels legible.
        if let accent {
            resolved = resolved.withAccent(
                isDark ? accent.base : accent.deep,
                ink: accent.ink,
                glow: accent.bloom
            )
        }
        return resolved
    }

    static let fallbackPalette = DLPalette(
        field: 0x0B0C0E,
        fieldAlt: 0x12141A,
        surface: 0x1A1D24,
        surfaceAlt: 0x22262E,
        ink: 0xF2F3F6,
        inkSoft: 0xA8AEB9,
        inkFaint: 0x6C7280,
        line: 0x2C313A,
        lineStrong: 0x4A505C,
        accent: 0xF9AA32,
        accentInk: 0x1A1305,
        glow: 0xF25C1A,
        glowTwo: 0xFFC46B,
        danger: 0xFF5A4D
    )

    // MARK: Registry

    static func spec(for language: ThemeLanguage) -> DLSpec {
        switch language {
        case .darkroom: return .darkroom
        case .softLight: return .softLight
        case .appleClean: return .appleClean
        case .fluent: return .fluent
        case .material3: return .material3
        case .swiss: return .swiss
        case .brutalist: return .brutalist
        case .neumorphic: return .neumorphic
        case .cyberpunk: return .cyberpunk
        case .retroAnalog: return .retroAnalog
        case .editorial: return .editorial
        case .skeuomorphic: return .skeuomorphic
        case .terminal: return .terminal
        case .recorder: return .recorder
        }
    }

    // MARK: 01 — Apple Liquid Glass

    private static let liquidGlassLight = DLPalette(
        field: 0xF1F2F6,
        fieldAlt: 0xE7E9F0,
        surface: 0xFFFFFF,
        surfaceAlt: 0xFFFFFF,
        ink: 0x101216,
        inkSoft: 0x545A66,
        inkFaint: 0x8A909C,
        line: 0x0F1115,
        lineStrong: 0x0F1115,
        accent: 0x0A84FF,
        accentInk: 0xFFFFFF,
        glow: 0x64D2FF,
        glowTwo: 0xBF5AF2,
        danger: 0xD70015,
        surfaceAlpha: 0.80,
        surfaceAltAlpha: 0.94,
        lineAlpha: 0.10,
        lineStrongAlpha: 0.26
    )

    private static let liquidGlassDark = DLPalette(
        field: 0x0A0B0D,
        fieldAlt: 0x111318,
        surface: 0xFFFFFF,
        surfaceAlt: 0xFFFFFF,
        ink: 0xF4F5F8,
        inkSoft: 0xA9AFBB,
        inkFaint: 0x717784,
        line: 0xFFFFFF,
        lineStrong: 0xFFFFFF,
        accent: 0xF9AA32,
        accentInk: 0x1A1305,
        glow: 0xF25C1A,
        glowTwo: 0xFFC46B,
        danger: 0xFF6B5E,
        surfaceAlpha: 0.10,
        surfaceAltAlpha: 0.16,
        lineAlpha: 0.12,
        lineStrongAlpha: 0.30
    )

    static let darkroom = DLSpec(
        language: .darkroom,
        light: liquidGlassLight,
        dark: liquidGlassDark,
        type: DLTypeSpec(
            displayDesign: .default,
            numericDesign: .rounded,
            displaySize: 30,
            displayWeight: .bold,
            displayTracking: -0.6,
            titleSize: 20,
            bodySize: 15,
            labelSize: 10,
            labelTracking: 2.0
        ),
        geometry: DLGeometry(
            cardRadius: 28,
            controlRadius: 22,
            chipRadius: 10,
            shadow: .soft,
            pagePadding: 20,
            sectionSpacing: 18,
            rowSpacing: 12,
            blockSpacing: 14,
            controlHeight: 54,
            headerHeight: 54,
            navHeight: 68
        ),
        nav: .floatingDock,
        layout: .glassStack,
        surface: .glass,
        button: .capsule,
        background: .liquid,
        motion: DLMotion(response: 0.46, damping: 0.80, stagger: 0.05, quick: 0.18, style: .spring)
    )

    // MARK: Soft Light — the second native interface, drawn here only for its tile and preview

    private static let softLightDark = DLPalette(
        field: 0x050506,
        fieldAlt: 0x0B0B0D,
        surface: 0xFFFFFF,
        surfaceAlt: 0xFFFFFF,
        ink: 0xF7F7F8,
        inkSoft: 0xA0A0A3,
        inkFaint: 0x5E5E62,
        line: 0xFFFFFF,
        lineStrong: 0xFFFFFF,
        accent: 0xF9AA32,
        accentInk: 0x000000,
        glow: 0xF25C1A,
        glowTwo: 0xFFC46B,
        danger: 0xFF6B5E,
        surfaceAlpha: 0.05,
        surfaceAltAlpha: 0.09,
        lineAlpha: 0.08,
        lineStrongAlpha: 0.14
    )

    static let softLight = DLSpec(
        language: .softLight,
        dark: softLightDark,
        type: DLTypeSpec(
            displayDesign: .default,
            numericDesign: .rounded,
            displaySize: 32,
            displayWeight: .semibold,
            displayTracking: -0.6,
            titleSize: 20,
            bodySize: 15,
            labelSize: 10,
            labelTracking: 1.6
        ),
        geometry: DLGeometry(
            cardRadius: 32,
            controlRadius: 26,
            chipRadius: 12,
            shadow: .soft,
            pagePadding: 20,
            sectionSpacing: 18,
            rowSpacing: 12,
            blockSpacing: 14,
            controlHeight: 56,
            headerHeight: 52,
            navHeight: 68
        ),
        nav: .floatingDock,
        layout: .glassStack,
        surface: .glass,
        button: .capsule,
        background: .liquid,
        motion: DLMotion(response: 0.46, damping: 0.80, stagger: 0.05, quick: 0.18, style: .spring)
    )

    // MARK: 02 — Apple Clean

    private static let cleanLight = DLPalette(
        field: 0xFFFFFF,
        fieldAlt: 0xFAFAFC,
        surface: 0xFFFFFF,
        surfaceAlt: 0xF5F5F7,
        ink: 0x0A0A0B,
        inkSoft: 0x6E6E73,
        inkFaint: 0xA1A1A6,
        line: 0x0A0A0B,
        lineStrong: 0x0A0A0B,
        accent: 0x0A84FF,
        accentInk: 0xFFFFFF,
        glow: 0x30D158,
        glowTwo: 0xFF9F0A,
        danger: 0xD70015,
        lineAlpha: 0.12,
        lineStrongAlpha: 0.55
    )

    private static let cleanDark = DLPalette(
        field: 0x000000,
        fieldAlt: 0x0C0C0E,
        surface: 0x0C0C0E,
        surfaceAlt: 0x1C1C1E,
        ink: 0xFAFAFC,
        inkSoft: 0xA1A1A6,
        inkFaint: 0x6E6E73,
        line: 0xFFFFFF,
        lineStrong: 0xFFFFFF,
        accent: 0x0A84FF,
        accentInk: 0xFFFFFF,
        glow: 0x30D158,
        glowTwo: 0xFF9F0A,
        danger: 0xFF453A,
        lineAlpha: 0.14,
        lineStrongAlpha: 0.60
    )

    static let appleClean = DLSpec(
        language: .appleClean,
        light: cleanLight,
        dark: cleanDark,
        type: DLTypeSpec(
            numericDesign: .default,
            displaySize: 34,
            displayWeight: .semibold,
            displayTracking: -1.1,
            titleSize: 22,
            titleTracking: -0.4,
            bodySize: 16,
            smallSize: 14,
            labelSize: 11,
            labelWeight: .regular,
            labelTracking: 0,
            labelUppercase: false,
            lineSpacing: 4
        ),
        geometry: DLGeometry(
            cardRadius: 18,
            controlRadius: 14,
            borderWidth: 1,
            shadow: .none,
            pagePadding: 26,
            sectionSpacing: 26,
            rowSpacing: 18,
            blockSpacing: 20,
            controlHeight: 54,
            headerHeight: 56,
            navHeight: 56
        ),
        nav: .minimalBar,
        layout: .cleanStack,
        surface: .clean,
        button: .rounded,
        background: .clean,
        motion: DLMotion(response: 0.40, damping: 0.90, stagger: 0.03, quick: 0.20, style: .ease)
    )

    // MARK: 03 — Microsoft Fluent 2

    private static let fluentLight = DLPalette(
        field: 0xF3F3F3,
        fieldAlt: 0xEAEAEA,
        surface: 0xFFFFFF,
        surfaceAlt: 0xFFFFFF,
        ink: 0x1B1B1F,
        inkSoft: 0x5C5C66,
        inkFaint: 0x8B8B95,
        line: 0x1B1B1F,
        lineStrong: 0x1B1B1F,
        accent: 0x0067C0,
        accentInk: 0xFFFFFF,
        glow: 0x4CC2FF,
        glowTwo: 0x8764B8,
        danger: 0xC42B1C,
        surfaceAlpha: 0.80,
        surfaceAltAlpha: 0.94,
        lineAlpha: 0.14,
        lineStrongAlpha: 0.45
    )

    private static let fluentDark = DLPalette(
        field: 0x202020,
        fieldAlt: 0x272727,
        surface: 0x2C2C2C,
        surfaceAlt: 0x333333,
        ink: 0xFFFFFF,
        inkSoft: 0xC8C8CE,
        inkFaint: 0x9A9AA2,
        line: 0xFFFFFF,
        lineStrong: 0xFFFFFF,
        accent: 0x4CC2FF,
        accentInk: 0x00243D,
        glow: 0x60CDFF,
        glowTwo: 0xC2A4F5,
        danger: 0xFF99A4,
        surfaceAlpha: 0.90,
        lineAlpha: 0.14,
        lineStrongAlpha: 0.42
    )

    static let fluent = DLSpec(
        language: .fluent,
        light: fluentLight,
        dark: fluentDark,
        type: DLTypeSpec(
            numericDesign: .default,
            displaySize: 26,
            displayWeight: .semibold,
            displayTracking: -0.3,
            titleSize: 18,
            bodySize: 14,
            smallSize: 12,
            labelSize: 11,
            labelTracking: 0.2,
            labelUppercase: false,
            lineSpacing: 2
        ),
        geometry: DLGeometry(
            cardRadius: 8,
            controlRadius: 4,
            chipRadius: 4,
            shadow: .deep,
            pagePadding: 18,
            sectionSpacing: 14,
            rowSpacing: 10,
            blockSpacing: 12,
            controlHeight: 40,
            headerHeight: 46,
            navHeight: 56
        ),
        nav: .fluentPivot,
        layout: .pivotCards,
        surface: .acrylic,
        button: .roundedSmall,
        background: .mica,
        motion: DLMotion(response: 0.34, damping: 0.86, stagger: 0.03, quick: 0.15, style: .ease)
    )

    // MARK: 04 — Material 3

    private static let materialLight = DLPalette(
        field: 0xFEF7FF,
        fieldAlt: 0xF7F2FA,
        surface: 0xF3EDF7,
        surfaceAlt: 0xEADDFF,
        ink: 0x1D1B20,
        inkSoft: 0x49454F,
        inkFaint: 0x79747E,
        line: 0x79747E,
        lineStrong: 0x49454F,
        accent: 0x6750A4,
        accentInk: 0xFFFFFF,
        glow: 0x7D5260,
        glowTwo: 0x386A20,
        danger: 0xB3261E,
        lineAlpha: 0.32
    )

    private static let materialDark = DLPalette(
        field: 0x141218,
        fieldAlt: 0x1D1B20,
        surface: 0x211F26,
        surfaceAlt: 0x2B2930,
        ink: 0xE6E0E9,
        inkSoft: 0xCAC4D0,
        inkFaint: 0x938F99,
        line: 0x938F99,
        lineStrong: 0xCAC4D0,
        accent: 0xD0BCFF,
        accentInk: 0x381E72,
        glow: 0xEFB8C8,
        glowTwo: 0xB1D18B,
        danger: 0xF2B8B5,
        lineAlpha: 0.34
    )

    static let material3 = DLSpec(
        language: .material3,
        light: materialLight,
        dark: materialDark,
        type: DLTypeSpec(
            displayDesign: .rounded,
            numericDesign: .rounded,
            displaySize: 30,
            displayWeight: .regular,
            displayTracking: -0.2,
            titleSize: 21,
            titleWeight: .medium,
            bodySize: 15,
            smallSize: 13,
            labelSize: 11,
            labelWeight: .medium,
            labelTracking: 0.5,
            labelUppercase: false,
            lineSpacing: 4
        ),
        geometry: DLGeometry(
            cardRadius: 26,
            controlRadius: 24,
            borderWidth: 0,
            pagePadding: 20,
            sectionSpacing: 16,
            rowSpacing: 12,
            blockSpacing: 14,
            controlHeight: 52,
            headerHeight: 56,
            navHeight: 80
        ),
        nav: .materialBar,
        layout: .tonalCards,
        surface: .tonal,
        button: .pill,
        background: .tonal,
        motion: DLMotion(response: 0.44, damping: 0.78, stagger: 0.05, quick: 0.17, style: .spring)
    )

    // MARK: 05 — Swiss International Style

    private static let swissLight = DLPalette(
        field: 0xFFFFFF,
        fieldAlt: 0xF2F2F2,
        surface: 0xFFFFFF,
        surfaceAlt: 0xF2F2F2,
        ink: 0x0D0D0D,
        inkSoft: 0x4A4A4A,
        inkFaint: 0x8A8A8A,
        line: 0x0D0D0D,
        lineStrong: 0x0D0D0D,
        accent: 0xE2231A,
        accentInk: 0xFFFFFF,
        glow: 0x0D0D0D,
        glowTwo: 0xE2231A,
        danger: 0xE2231A,
        lineAlpha: 0.22
    )

    private static let swissDark = DLPalette(
        field: 0x0D0D0D,
        fieldAlt: 0x191919,
        surface: 0x0D0D0D,
        surfaceAlt: 0x191919,
        ink: 0xF7F7F7,
        inkSoft: 0xB4B4B4,
        inkFaint: 0x7A7A7A,
        line: 0xF7F7F7,
        lineStrong: 0xF7F7F7,
        accent: 0xFF3B30,
        accentInk: 0x0D0D0D,
        glow: 0xF7F7F7,
        glowTwo: 0xFF3B30,
        danger: 0xFF3B30,
        lineAlpha: 0.20
    )

    static let swiss = DLSpec(
        language: .swiss,
        light: swissLight,
        dark: swissDark,
        type: DLTypeSpec(
            numericDesign: .default,
            displaySize: 40,
            displayWeight: .bold,
            displayTracking: -1.8,
            titleSize: 20,
            titleWeight: .bold,
            titleTracking: -0.5,
            bodySize: 13,
            smallSize: 12,
            labelSize: 9,
            labelTracking: 1.2,
            lineSpacing: 2
        ),
        geometry: DLGeometry(
            cardRadius: 0,
            controlRadius: 0,
            chipRadius: 0,
            pagePadding: 20,
            sectionSpacing: 20,
            rowSpacing: 8,
            blockSpacing: 12,
            controlHeight: 46,
            gridColumns: 3,
            headerHeight: 44,
            navHeight: 60
        ),
        nav: .swissRail,
        layout: .swissGrid,
        surface: .paper,
        button: .rectangle,
        background: .grid,
        motion: DLMotion(response: 0.30, damping: 0.94, stagger: 0.02, quick: 0.12, style: .ease)
    )

    // MARK: 06 — Brutalist

    private static let brutalLight = DLPalette(
        field: 0xEDEAE4,
        fieldAlt: 0xF7F4EE,
        surface: 0xFFFFFF,
        surfaceAlt: 0xFFF9DB,
        ink: 0x000000,
        inkSoft: 0x2B2B2B,
        inkFaint: 0x5A5A5A,
        line: 0x000000,
        lineStrong: 0x000000,
        accent: 0xFF3B00,
        accentInk: 0x000000,
        glow: 0x1900FF,
        glowTwo: 0xFF3B00,
        danger: 0xC40000
    )

    private static let brutalDark = DLPalette(
        field: 0x101010,
        fieldAlt: 0x1A1A1A,
        surface: 0x000000,
        surfaceAlt: 0x1F1F1F,
        ink: 0xFFFFFF,
        inkSoft: 0xD6D6D6,
        inkFaint: 0x9A9A9A,
        line: 0xFFFFFF,
        lineStrong: 0xFFFFFF,
        accent: 0xFF3B00,
        accentInk: 0x000000,
        glow: 0x00E1FF,
        glowTwo: 0xFF3B00,
        danger: 0xFF6B6B
    )

    static let brutalist = DLSpec(
        language: .brutalist,
        light: brutalLight,
        dark: brutalDark,
        type: DLTypeSpec(
            bodyDesign: .monospaced,
            displaySize: 34,
            displayWeight: .black,
            displayTracking: -1.0,
            displayUppercase: true,
            titleSize: 19,
            titleWeight: .heavy,
            titleTracking: -0.2,
            bodySize: 13,
            smallSize: 12,
            labelSize: 10,
            labelWeight: .black,
            labelTracking: 1.0,
            lineSpacing: 2
        ),
        geometry: DLGeometry(
            cardRadius: 0,
            controlRadius: 0,
            chipRadius: 0,
            borderWidth: 3,
            shadow: .hard,
            shadowOffset: 7,
            pagePadding: 16,
            sectionSpacing: 16,
            rowSpacing: 10,
            blockSpacing: 14,
            controlHeight: 54,
            headerHeight: 46,
            navHeight: 62
        ),
        nav: .brutalBlocks,
        layout: .brutalBlocks,
        surface: .block,
        button: .sharpBlock,
        background: .concrete,
        motion: DLMotion(response: 0.20, damping: 1.0, stagger: 0.02, quick: 0.10, style: .snap)
    )

    // MARK: 07 — Neumorphic

    private static let neuLight = DLPalette(
        field: 0xE8EBF1,
        fieldAlt: 0xE2E6EE,
        surface: 0xE8EBF1,
        surfaceAlt: 0xEDF0F5,
        ink: 0x2A2F3A,
        inkSoft: 0x596170,
        inkFaint: 0x828B9C,
        line: 0x8E96A6,
        lineStrong: 0x5C6472,
        accent: 0x2F6BE0,
        accentInk: 0xFFFFFF,
        glow: 0x63B3ED,
        glowTwo: 0xA78BFA,
        danger: 0xC0392B,
        lineAlpha: 0.30
    )

    private static let neuDark = DLPalette(
        field: 0x23262C,
        fieldAlt: 0x1E2126,
        surface: 0x23262C,
        surfaceAlt: 0x282B32,
        ink: 0xE7EAF0,
        inkSoft: 0xA9B0BE,
        inkFaint: 0x7B8290,
        line: 0x0B0C0E,
        lineStrong: 0x585F6B,
        accent: 0x6FA8FF,
        accentInk: 0x101720,
        glow: 0x8FD1FF,
        glowTwo: 0xBBA6FF,
        danger: 0xFF8A7A,
        lineAlpha: 0.55
    )

    static let neumorphic = DLSpec(
        language: .neumorphic,
        light: neuLight,
        dark: neuDark,
        type: DLTypeSpec(
            displayDesign: .rounded,
            bodyDesign: .rounded,
            numericDesign: .rounded,
            displaySize: 28,
            displayWeight: .semibold,
            displayTracking: -0.3,
            titleSize: 19,
            bodySize: 15,
            smallSize: 13,
            labelSize: 10,
            labelTracking: 1.4
        ),
        geometry: DLGeometry(
            cardRadius: 24,
            controlRadius: 18,
            chipRadius: 12,
            borderWidth: 0,
            shadow: .inset,
            pagePadding: 22,
            sectionSpacing: 22,
            rowSpacing: 16,
            blockSpacing: 16,
            controlHeight: 56,
            navHeight: 74
        ),
        nav: .softTray,
        layout: .softGrid,
        surface: .extruded,
        button: .extruded,
        background: .clay,
        motion: DLMotion(response: 0.52, damping: 0.72, stagger: 0.05, quick: 0.24, style: .spring)
    )

    // MARK: 08 — Cyberpunk

    private static let cyberPalette = DLPalette(
        field: 0x05070A,
        fieldAlt: 0x080D13,
        surface: 0x0B131B,
        surfaceAlt: 0x101B26,
        ink: 0xE6FBFF,
        inkSoft: 0x86A9B4,
        inkFaint: 0x56707A,
        line: 0x00E5FF,
        lineStrong: 0x00E5FF,
        accent: 0x00E5FF,
        accentInk: 0x001318,
        glow: 0xFF2E97,
        glowTwo: 0x9BFF00,
        danger: 0xFF3864,
        lineAlpha: 0.30
    )

    static let cyberpunk = DLSpec(
        language: .cyberpunk,
        dark: cyberPalette,
        type: DLTypeSpec(
            displayDesign: .monospaced,
            bodyDesign: .monospaced,
            displaySize: 26,
            displayWeight: .bold,
            displayTracking: 1.0,
            displayUppercase: true,
            titleSize: 17,
            titleWeight: .bold,
            titleTracking: 0.8,
            bodySize: 12,
            smallSize: 11,
            labelSize: 9,
            labelTracking: 2.0,
            lineSpacing: 2
        ),
        geometry: DLGeometry(
            cardRadius: 2,
            controlRadius: 2,
            chipRadius: 2,
            shadow: .glow,
            pagePadding: 16,
            sectionSpacing: 14,
            rowSpacing: 9,
            blockSpacing: 12,
            controlHeight: 46,
            headerHeight: 40,
            navHeight: 58
        ),
        nav: .hudRail,
        layout: .hudPanels,
        surface: .hud,
        button: .clipped,
        background: .neon,
        motion: DLMotion(response: 0.24, damping: 1.0, stagger: 0.02, quick: 0.11, style: .linear)
    )

    // MARK: 09 — Retro Analog

    private static let retroPalette = DLPalette(
        field: 0x0B0505,
        fieldAlt: 0x140808,
        surface: 0x1A0C0A,
        surfaceAlt: 0x22100E,
        ink: 0xF3E4D8,
        inkSoft: 0xBDA192,
        inkFaint: 0x8A6E62,
        line: 0xE4572E,
        lineStrong: 0xE4572E,
        accent: 0xFF5A3C,
        accentInk: 0x1A0705,
        glow: 0xE4572E,
        glowTwo: 0xFFB38A,
        danger: 0xFF6B4A,
        lineAlpha: 0.34
    )

    static let retroAnalog = DLSpec(
        language: .retroAnalog,
        dark: retroPalette,
        type: DLTypeSpec(
            displayDesign: .monospaced,
            displaySize: 24,
            displayWeight: .bold,
            displayTracking: 2.2,
            displayUppercase: true,
            titleSize: 17,
            titleWeight: .bold,
            bodySize: 13,
            smallSize: 12,
            labelSize: 9,
            labelTracking: 1.8,
            lineSpacing: 2
        ),
        geometry: DLGeometry(
            cardRadius: 16,
            controlRadius: 12,
            chipRadius: 10,
            pagePadding: 18,
            sectionSpacing: 16,
            rowSpacing: 12,
            blockSpacing: 14,
            controlHeight: 50,
            headerHeight: 46,
            navHeight: 66
        ),
        nav: .filmStrip,
        layout: .filmStrip,
        surface: .glass,
        button: .rounded,
        background: .safelight,
        motion: DLMotion(response: 0.36, damping: 0.84, stagger: 0.04, quick: 0.16, style: .ease)
    )

    // MARK: 10 — Editorial

    private static let editorialLight = DLPalette(
        field: 0xF6F1E8,
        fieldAlt: 0xEFE8DB,
        surface: 0xFFFCF6,
        surfaceAlt: 0xF1EADC,
        ink: 0x171512,
        inkSoft: 0x574F45,
        inkFaint: 0x8C8377,
        line: 0x171512,
        lineStrong: 0x171512,
        accent: 0x7B1E22,
        accentInk: 0xFFFCF6,
        glow: 0xB08A45,
        glowTwo: 0x7B1E22,
        danger: 0x9B1B1B,
        lineAlpha: 0.22
    )

    private static let editorialDark = DLPalette(
        field: 0x14120F,
        fieldAlt: 0x1B1814,
        surface: 0x1F1B16,
        surfaceAlt: 0x272219,
        ink: 0xF3EBDD,
        inkSoft: 0xBFB3A0,
        inkFaint: 0x8C8172,
        line: 0xF3EBDD,
        lineStrong: 0xF3EBDD,
        accent: 0xE0A05A,
        accentInk: 0x1B1510,
        glow: 0xC98C4B,
        glowTwo: 0xE0A05A,
        danger: 0xFF8E7A,
        lineAlpha: 0.22
    )

    static let editorial = DLSpec(
        language: .editorial,
        light: editorialLight,
        dark: editorialDark,
        type: DLTypeSpec(
            displayDesign: .serif,
            bodyDesign: .serif,
            numericDesign: .serif,
            displaySize: 38,
            displayWeight: .regular,
            displayTracking: -0.8,
            titleSize: 21,
            bodySize: 15,
            smallSize: 13,
            labelSize: 9,
            labelTracking: 2.4,
            lineSpacing: 5
        ),
        geometry: DLGeometry(
            cardRadius: 0,
            controlRadius: 0,
            chipRadius: 0,
            shadow: .none,
            pagePadding: 24,
            sectionSpacing: 24,
            rowSpacing: 12,
            blockSpacing: 18,
            controlHeight: 48,
            headerHeight: 50,
            navHeight: 52
        ),
        nav: .masthead,
        layout: .editorialColumns,
        surface: .paper,
        button: .underline,
        background: .paper,
        motion: DLMotion(response: 0.46, damping: 0.92, stagger: 0.06, quick: 0.22, style: .ease)
    )

    // MARK: 11 — Skeuomorphic

    private static let skelLight = DLPalette(
        field: 0xD8D2C6,
        fieldAlt: 0xCEC7B9,
        surface: 0xE9E4D9,
        surfaceAlt: 0xDCD5C7,
        ink: 0x241F18,
        inkSoft: 0x564D40,
        inkFaint: 0x7C7263,
        line: 0x3A3228,
        lineStrong: 0x3A3228,
        accent: 0x9C4A17,
        accentInk: 0xFFF6E6,
        glow: 0xB87333,
        glowTwo: 0x6B7C4A,
        danger: 0x8E1B12,
        lineAlpha: 0.35
    )

    private static let skelDark = DLPalette(
        field: 0x191614,
        fieldAlt: 0x211D19,
        surface: 0x2B2620,
        surfaceAlt: 0x342E27,
        ink: 0xF1E9D9,
        inkSoft: 0xBFB29C,
        inkFaint: 0x8D8171,
        line: 0x000000,
        lineStrong: 0xE3D6BD,
        accent: 0xD98A4A,
        accentInk: 0x201510,
        glow: 0xE8B273,
        glowTwo: 0x9CB06A,
        danger: 0xFF8F7A,
        lineAlpha: 0.55,
        lineStrongAlpha: 0.50
    )

    static let skeuomorphic = DLSpec(
        language: .skeuomorphic,
        light: skelLight,
        dark: skelDark,
        type: DLTypeSpec(
            displayDesign: .rounded,
            numericDesign: .monospaced,
            displaySize: 26,
            displayWeight: .heavy,
            displayTracking: 0.2,
            titleSize: 18,
            titleWeight: .bold,
            bodySize: 14,
            smallSize: 12,
            labelSize: 9,
            labelWeight: .bold,
            labelTracking: 1.6,
            lineSpacing: 3
        ),
        geometry: DLGeometry(
            cardRadius: 14,
            controlRadius: 10,
            chipRadius: 6,
            shadow: .deep,
            shadowOffset: 3,
            pagePadding: 18,
            sectionSpacing: 18,
            rowSpacing: 12,
            blockSpacing: 14,
            controlHeight: 54,
            headerHeight: 52,
            navHeight: 76
        ),
        nav: .switchboard,
        layout: .metalPanel,
        surface: .metal,
        button: .metal,
        background: .metal,
        motion: DLMotion(response: 0.30, damping: 0.66, stagger: 0.03, quick: 0.14, style: .spring)
    )

    // MARK: 12 — Minimal Terminal

    private static let terminalLight = DLPalette(
        field: 0xF4F4EF,
        fieldAlt: 0xEAEAE3,
        surface: 0xFFFFFF,
        surfaceAlt: 0xF1F1EA,
        ink: 0x10140F,
        inkSoft: 0x4C534C,
        inkFaint: 0x7C847C,
        line: 0x10140F,
        lineStrong: 0x10140F,
        accent: 0x0F7A43,
        accentInk: 0xFFFFFF,
        glow: 0x0F7A43,
        glowTwo: 0x10140F,
        danger: 0xA3201A,
        lineAlpha: 0.25
    )

    private static let terminalDark = DLPalette(
        field: 0x070B08,
        fieldAlt: 0x0A0F0B,
        surface: 0x0B120D,
        surfaceAlt: 0x0E1710,
        ink: 0xCCFFD2,
        inkSoft: 0x74B37F,
        inkFaint: 0x4C7654,
        line: 0x3BF07A,
        lineStrong: 0x3BF07A,
        accent: 0x3BF07A,
        accentInk: 0x04160A,
        glow: 0x3BF07A,
        glowTwo: 0x9BFFB0,
        danger: 0xFF6B5E,
        lineAlpha: 0.26
    )

    static let terminal = DLSpec(
        language: .terminal,
        light: terminalLight,
        dark: terminalDark,
        type: DLTypeSpec(
            displayDesign: .monospaced,
            bodyDesign: .monospaced,
            displaySize: 22,
            displayTracking: 0,
            titleSize: 16,
            titleWeight: .bold,
            bodySize: 12,
            smallSize: 11,
            labelSize: 10,
            labelWeight: .regular,
            labelTracking: 0.4,
            lineSpacing: 1
        ),
        geometry: DLGeometry(
            cardRadius: 0,
            controlRadius: 0,
            chipRadius: 0,
            shadow: .none,
            pagePadding: 14,
            sectionSpacing: 10,
            rowSpacing: 4,
            blockSpacing: 10,
            controlHeight: 40,
            headerHeight: 34,
            navHeight: 46
        ),
        nav: .promptBar,
        layout: .terminalPanels,
        surface: .terminal,
        button: .terminal,
        background: .crt,
        motion: DLMotion(response: 0.14, damping: 1.0, stagger: 0.0, quick: 0.08, style: .linear)
    )

    // MARK: 13 — Recorder

    /// The deck's palette is the reader's palette: the chosen lamp is the field
    /// itself, and every mark on it is black. The one fixed colour is the knob's
    /// signal dot — a machine's indicator is not a theme colour.
    static func recorderPalette(_ accent: AccentChoice?) -> DLPalette {
        let lamp = accent ?? .safelight

        return DLPalette(
            field: lamp.base,
            fieldAlt: lamp.deep,
            surface: Color.black.opacity(0.10),
            surfaceAlt: Color.black.opacity(0.18),
            ink: Color(red: 0.055, green: 0.055, blue: 0.050),
            inkSoft: Color.black.opacity(0.62),
            inkFaint: Color.black.opacity(0.42),
            line: Color.black.opacity(0.16),
            lineStrong: Color.black.opacity(0.86),
            accent: Color(red: 0.055, green: 0.055, blue: 0.050),
            accentInk: lamp.soft,
            glow: Color(red: 0.878, green: 0.945, blue: 0.275),
            glowTwo: lamp.deep,
            danger: Color(red: 0.52, green: 0.05, blue: 0.03)
        )
    }

    private static let recorderBase = recorderPalette(.safelight)

    static let recorder = DLSpec(
        language: .recorder,
        light: recorderBase,
        dark: recorderBase,
        type: DLTypeSpec(
            numericDesign: .default,
            displaySize: 36,
            displayWeight: .bold,
            displayTracking: -1.4,
            titleSize: 19,
            titleWeight: .bold,
            titleTracking: -0.4,
            bodySize: 14,
            smallSize: 12,
            labelSize: 11,
            labelWeight: .semibold,
            labelTracking: 0.2,
            labelUppercase: false,
            lineSpacing: 3
        ),
        geometry: DLGeometry(
            cardRadius: 6,
            controlRadius: 8,
            chipRadius: 4,
            borderWidth: 0,
            shadow: .none,
            pagePadding: 18,
            sectionSpacing: 20,
            rowSpacing: 10,
            blockSpacing: 12,
            controlHeight: 54,
            navHeight: 62
        ),
        nav: .flatBar,
        layout: .flatDeck,
        surface: .flat,
        button: .deck,
        background: .flat,
        motion: DLMotion(response: 0.30, damping: 0.92, stagger: 0.03, quick: 0.14, style: .ease)
    )
}
