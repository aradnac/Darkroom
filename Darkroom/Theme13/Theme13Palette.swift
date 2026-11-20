//
//  Theme13Palette.swift
//  Darkroom
//
//  THE 13TH THEME — the nine print palettes, the colour maths the whole theme is
//  built on, and the preference store behind the hidden nine-tap unlock.
//

import SwiftUI
import UIKit

// MARK: - Colour maths

enum Theme13Color {
    /// Straight RGB interpolation. Used for dark variants and plate tints; a
    /// stipple or dither plate is used wherever the theme needs a visible ramp.
    static func mix(_ first: Color, _ second: Color, _ amount: CGFloat) -> Color {
        let t = min(1, max(0, amount))
        let a = components(first)
        let b = components(second)
        return Color(
            .sRGB,
            red: Double(a.r + (b.r - a.r) * t),
            green: Double(a.g + (b.g - a.g) * t),
            blue: Double(a.b + (b.b - a.b) * t),
            opacity: Double(a.a + (b.a - a.a) * t)
        )
    }

    static func components(_ color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let resolved = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1
        if resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        }
        var white: CGFloat = 0
        if resolved.getWhite(&white, alpha: &alpha) {
            return (white, white, white, alpha)
        }
        return (0, 0, 0, alpha)
    }

    /// Picks a colour out of a multi-stop list at a position from 0 to 1.
    static func blend(_ colors: [Color], at position: CGFloat) -> Color {
        guard let first = colors.first else { return Color.clear }
        guard colors.count > 1 else { return first }
        let clamped = min(0.9999, max(0, position))
        let scaled = clamped * CGFloat(colors.count - 1)
        let index = Int(scaled)
        let next = min(colors.count - 1, index + 1)
        return mix(colors[index], colors[next], scaled - CGFloat(index))
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Palette

struct Theme13Palette: Identifiable {
    let id: Theme13PaletteID
    let name: String
    let note: String

    let background: Color
    let secondaryBackground: Color
    let surface: Color
    let secondarySurface: Color
    let inverse: Color

    let primaryText: Color
    let secondaryText: Color
    let textOnInverse: Color

    let accent: Color
    let accentText: Color
    let accentInk: Color
    let accent2: Color
    let accent3: Color

    let border: Color
    let divider: Color

    /// Decorative inks, in a fixed order the backdrop and preview plate rely on.
    let decoration: [Color]

    let surfaceText: Color
    let surfaceSecondaryText: Color

    init(
        id: Theme13PaletteID,
        name: String,
        note: String,
        background: Color,
        secondaryBackground: Color,
        surface: Color,
        secondarySurface: Color,
        inverse: Color,
        primaryText: Color,
        secondaryText: Color,
        textOnInverse: Color,
        accent: Color,
        accentText: Color,
        accentInk: Color,
        accent2: Color,
        accent3: Color,
        border: Color,
        divider: Color,
        decoration: [Color],
        surfaceText: Color? = nil,
        surfaceSecondaryText: Color? = nil
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.background = background
        self.secondaryBackground = secondaryBackground
        self.surface = surface
        self.secondarySurface = secondarySurface
        self.inverse = inverse
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.textOnInverse = textOnInverse
        self.accent = accent
        self.accentText = accentText
        self.accentInk = accentInk
        self.accent2 = accent2
        self.accent3 = accent3
        self.border = border
        self.divider = divider
        self.decoration = decoration
        self.surfaceText = surfaceText ?? primaryText
        self.surfaceSecondaryText = surfaceSecondaryText ?? secondaryText
    }

    // MARK: Resolved appearances
    //
    // Names are deliberately distinct from the stored colours so a palette can
    // expose both the light plate and its dark swap without ambiguity.

    func bg(isDark: Bool) -> Color {
        isDark ? Theme13Color.mix(inverse, .white, 0.05) : background
    }

    func bgAlt(isDark: Bool) -> Color {
        isDark ? Theme13Color.mix(inverse, .white, 0.09) : secondaryBackground
    }

    func plate(isDark: Bool) -> Color {
        isDark ? Theme13Color.mix(inverse, .white, 0.12) : surface
    }

    func plateRaised(isDark: Bool) -> Color {
        isDark ? Theme13Color.mix(inverse, .white, 0.19) : secondarySurface
    }

    func ink(isDark: Bool) -> Color {
        isDark ? textOnInverse : primaryText
    }

    func inkAlt(isDark: Bool) -> Color {
        isDark ? textOnInverse.opacity(0.78) : secondaryText
    }

    /// Ink for text sitting on a paper plate rather than the field.
    func inkOnPlate(isDark: Bool) -> Color {
        isDark ? textOnInverse : surfaceText
    }

    func inkAltOnPlate(isDark: Bool) -> Color {
        isDark ? textOnInverse.opacity(0.72) : surfaceSecondaryText
    }

    func stroke(isDark: Bool) -> Color {
        isDark ? textOnInverse.opacity(0.45) : border
    }

    func rule(isDark: Bool) -> Color {
        isDark ? textOnInverse.opacity(0.22) : divider
    }

    // MARK: Registry

    static func palette(_ id: Theme13PaletteID) -> Theme13Palette {
        all.first { $0.id == id } ?? all[0]
    }

    static let all: [Theme13Palette] = [
        Theme13Palette(
            id: .rangefinder,
            name: "Rangefinder",
            note: "Black and white, one red interruption",
            background: Color(hex: 0xF5F3EE),
            secondaryBackground: Color(hex: 0xE7E4DD),
            surface: Color(hex: 0xFFFFFF),
            secondarySurface: Color(hex: 0xECE9E2),
            inverse: Color(hex: 0x0D0D0D),
            primaryText: Color(hex: 0x0D0D0D),
            secondaryText: Color(hex: 0x4A4845),
            textOnInverse: Color(hex: 0xF5F3EE),
            accent: Color(hex: 0xE5392B),
            accentText: Color(hex: 0xC4271B),
            accentInk: Color(hex: 0x0D0D0D),
            accent2: Color(hex: 0xA81E14),
            accent3: Color(hex: 0xFFFFFF),
            border: Color(hex: 0x0D0D0D),
            divider: Color(hex: 0xBDB9B0),
            decoration: [Color(hex: 0x0D0D0D), Color(hex: 0xA81E14), Color(hex: 0xFFFFFF), Color(hex: 0xC4271B)]
        ),
        Theme13Palette(
            id: .negativeGold,
            name: "Negative Gold",
            note: "Golden screen-print, crimson negative",
            background: Color(hex: 0xF2CE63),
            secondaryBackground: Color(hex: 0xF7DE8E),
            surface: Color(hex: 0xFBEBB5),
            secondarySurface: Color(hex: 0xE9B947),
            inverse: Color(hex: 0x2B0610),
            primaryText: Color(hex: 0x3B0A10),
            secondaryText: Color(hex: 0x6B1A22),
            textOnInverse: Color(hex: 0xFFF3D6),
            accent: Color(hex: 0xD01F2F),
            accentText: Color(hex: 0x8E0F1E),
            accentInk: Color(hex: 0xFFF3D6),
            accent2: Color(hex: 0xF58A1E),
            accent3: Color(hex: 0xA61448),
            border: Color(hex: 0x3B0A10),
            divider: Color(hex: 0xC49D4E),
            decoration: [Color(hex: 0xFFF6DC), Color(hex: 0x4A0710), Color(hex: 0xFFD56B), Color(hex: 0xF0454F)]
        ),
        Theme13Palette(
            id: .bittersweet,
            name: "Bittersweet",
            note: "Lemon field, red ink only",
            background: Color(hex: 0xF9EC20),
            secondaryBackground: Color(hex: 0xFFF6A0),
            surface: Color(hex: 0xFFFBD2),
            secondarySurface: Color(hex: 0xEAD400),
            inverse: Color(hex: 0x0B0A09),
            primaryText: Color(hex: 0x121008),
            secondaryText: Color(hex: 0x4A4308),
            textOnInverse: Color(hex: 0xFFF6A0),
            accent: Color(hex: 0xE8201C),
            accentText: Color(hex: 0xB3140F),
            accentInk: Color(hex: 0xFFFBD2),
            accent2: Color(hex: 0xF0606A),
            accent3: Color(hex: 0xE4BE2B),
            border: Color(hex: 0x121008),
            divider: Color(hex: 0xC9B800),
            decoration: [Color(hex: 0x121008), Color(hex: 0xF0606A), Color(hex: 0xE4BE2B), Color(hex: 0xE8201C)]
        ),
        Theme13Palette(
            id: .bloom,
            name: "Bloom",
            note: "Plum field, cream paper cutouts",
            background: Color(hex: 0x6F2160),
            secondaryBackground: Color(hex: 0x8E2F77),
            surface: Color(hex: 0x3A0F33),
            secondarySurface: Color(hex: 0x4A1B42),
            inverse: Color(hex: 0x3A0F33),
            primaryText: Color(hex: 0xF6F0E0),
            secondaryText: Color(hex: 0xE8C9DD),
            textOnInverse: Color(hex: 0xF6F0E0),
            accent: Color(hex: 0xD24A30),
            accentText: Color(hex: 0xB83A22),
            accentInk: Color(hex: 0x2A1026),
            accent2: Color(hex: 0xF0DC3C),
            accent3: Color(hex: 0x3A4FA3),
            border: Color(hex: 0xF6F0E0),
            divider: Color(hex: 0xB89BB0),
            decoration: [Color(hex: 0xE9C6DA), Color(hex: 0xB8C4E6), Color(hex: 0xF0DC3C), Color(hex: 0xB2573D)]
        ),
        Theme13Palette(
            id: .sunspotLawn,
            name: "Sunspot Lawn",
            note: "Torn paper over sunlit grass",
            background: Color(hex: 0xEFEDE4),
            secondaryBackground: Color(hex: 0xDDE6C8),
            surface: Color(hex: 0xF8F6EE),
            secondarySurface: Color(hex: 0xD5DFBC),
            inverse: Color(hex: 0x1F2B12),
            primaryText: Color(hex: 0x14180C),
            secondaryText: Color(hex: 0x4B5238),
            textOnInverse: Color(hex: 0xF8F6EE),
            accent: Color(hex: 0xB23A4A),
            accentText: Color(hex: 0xB23A4A),
            accentInk: Color(hex: 0xFFFFFF),
            accent2: Color(hex: 0xEE6350),
            accent3: Color(hex: 0xA9CFE0),
            border: Color(hex: 0x14180C),
            divider: Color(hex: 0xC9CFB6),
            decoration: [Color(hex: 0x14180C), Color(hex: 0xFFE9A8), Color(hex: 0x5F8B2D), Color(hex: 0xEE6350)]
        ),
        Theme13Palette(
            id: .fogMoss,
            name: "Fog Moss",
            note: "Fog, moss, a blue pixel river",
            background: Color(hex: 0xE6E8E3),
            secondaryBackground: Color(hex: 0xCFDDC3),
            surface: Color(hex: 0xF3F4F0),
            secondarySurface: Color(hex: 0xD9E3CD),
            inverse: Color(hex: 0x26352E),
            primaryText: Color(hex: 0x1E2A22),
            secondaryText: Color(hex: 0x4E5E4F),
            textOnInverse: Color(hex: 0xF3F4F0),
            accent: Color(hex: 0x9EC4E6),
            accentText: Color(hex: 0x566424),
            accentInk: Color(hex: 0x1E2A22),
            accent2: Color(hex: 0x8A9B3A),
            accent3: Color(hex: 0xC8202A),
            border: Color(hex: 0x1E2A22),
            divider: Color(hex: 0xC3CCC0),
            decoration: [Color(hex: 0xB9D6EE), Color(hex: 0x8A9B3A), Color(hex: 0xA9BFA0), Color(hex: 0xC8202A)]
        ),
        Theme13Palette(
            id: .bokehCanopy,
            name: "Bokeh Canopy",
            note: "Forest blur, amber light",
            background: Color(hex: 0x1B2814),
            secondaryBackground: Color(hex: 0x2E3E1C),
            surface: Color(hex: 0x26351A),
            secondarySurface: Color(hex: 0x3A4A24),
            inverse: Color(hex: 0xF5E6C8),
            primaryText: Color(hex: 0xF5E6C8),
            secondaryText: Color(hex: 0xCFC8A4),
            textOnInverse: Color(hex: 0x1B2814),
            accent: Color(hex: 0xE39A32),
            accentText: Color(hex: 0xE39A32),
            accentInk: Color(hex: 0x1B2814),
            accent2: Color(hex: 0xC6F000),
            accent3: Color(hex: 0xD9622E),
            border: Color(hex: 0x8A8C70),
            divider: Color(hex: 0x596447),
            decoration: [Color(hex: 0xF7E8CC), Color(hex: 0xC9822A), Color(hex: 0xFFF7E0), Color(hex: 0x1E2A19)]
        ),
        Theme13Palette(
            id: .chromaDots,
            name: "Chroma Dots",
            note: "Cream plate, blurred colour dots",
            background: Color(hex: 0xF6F1E4),
            secondaryBackground: Color(hex: 0xEDE5D0),
            surface: Color(hex: 0xFFFBF0),
            secondarySurface: Color(hex: 0xF3E0CB),
            inverse: Color(hex: 0x1A1512),
            primaryText: Color(hex: 0x1A1512),
            secondaryText: Color(hex: 0x5A4A40),
            textOnInverse: Color(hex: 0xF6F1E4),
            accent: Color(hex: 0xE8621A),
            accentText: Color(hex: 0xC8202A),
            accentInk: Color(hex: 0x1A1512),
            accent2: Color(hex: 0xB8408A),
            accent3: Color(hex: 0x2D4543),
            border: Color(hex: 0x1A1512),
            divider: Color(hex: 0xD9CDB3),
            decoration: [Color(hex: 0xEBC6D6), Color(hex: 0xC9D2D8), Color(hex: 0xFF5A12), Color(hex: 0x8A6A3C)]
        ),
        Theme13Palette(
            id: .riverRiso,
            name: "River Riso",
            note: "Riso blue, stipple dunes",
            background: Color(hex: 0xF5F4F0),
            secondaryBackground: Color(hex: 0xD9D6CF),
            surface: Color(hex: 0xFFFFFF),
            secondarySurface: Color(hex: 0xE8E6E0),
            inverse: Color(hex: 0x2A2A22),
            primaryText: Color(hex: 0x20211A),
            secondaryText: Color(hex: 0x4F5560),
            textOnInverse: Color(hex: 0xF5F4F0),
            accent: Color(hex: 0x4A9AD9),
            accentText: Color(hex: 0x1F5F9E),
            accentInk: Color(hex: 0x20211A),
            accent2: Color(hex: 0x5B5CD6),
            accent3: Color(hex: 0xC9A24B),
            border: Color(hex: 0x20211A),
            divider: Color(hex: 0xC9C7BF),
            decoration: [Color(hex: 0x3F8FD2), Color(hex: 0xAEB8C0), Color(hex: 0xC9A24B), Color(hex: 0x3A3A2C)]
        )
    ]
}

enum Theme13PaletteID: String, CaseIterable, Identifiable {
    case rangefinder
    case negativeGold
    case bittersweet
    case bloom
    case sunspotLawn
    case fogMoss
    case bokehCanopy
    case chromaDots
    case riverRiso

    var id: String { rawValue }
    var palette: Theme13Palette { Theme13Palette.palette(self) }
}

// MARK: - Preferences

enum Theme13AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum Theme13TextSize: String, CaseIterable, Identifiable {
    case small
    case standard
    case large
    case larger

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: return "S"
        case .standard: return "M"
        case .large: return "L"
        case .larger: return "XL"
        }
    }

    var scale: CGFloat {
        switch self {
        case .small: return 0.90
        case .standard: return 1.0
        case .large: return 1.12
        case .larger: return 1.24
        }
    }
}

enum Theme13MotionIntensity: String, CaseIterable, Identifiable {
    case calm
    case standard
    case lively

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .standard: return "Standard"
        case .lively: return "Lively"
        }
    }

    var framesPerSecond: Double {
        switch self {
        case .calm: return 4
        case .standard: return 8
        case .lively: return 12
        }
    }
}

/// The hidden theme's single source of truth. Every write persists immediately;
/// `revision` is what the app root watches to re-dress itself.
final class Theme13SettingsStore: ObservableObject {
    static let shared = Theme13SettingsStore()

    private enum Keys {
        static let unlocked = "theme13.unlocked"
        static let theme = "theme13.theme"
        static let legacyTheme = "theme.identifier"
        static let palette = "theme13.palette"
        static let appearance = "theme13.appearance"
        static let still = "theme13.stillMode"
        static let density = "theme13.density"
        static let textSize = "theme13.textSize"
        static let motion = "theme13.motion"
    }

    private let defaults = UserDefaults.standard

    @Published private(set) var isUnlocked: Bool
    @Published private(set) var selectedThemeIdentifier: String
    @Published private(set) var paletteID: Theme13PaletteID
    @Published private(set) var appearanceMode: Theme13AppearanceMode
    @Published private(set) var stillMode: Bool
    @Published private(set) var compactControls: Bool
    @Published private(set) var textSize: Theme13TextSize
    @Published private(set) var motion: Theme13MotionIntensity
    @Published private(set) var systemIsDark: Bool
    @Published private(set) var revision: Int

    /// Set by the Tools hub; the app root presents Settings as a sheet so the
    /// tabs behind it can be rebuilt without tearing down the screen.
    @Published var isShowingSettings = false {
        didSet {
            guard oldValue != isShowingSettings else { return }
            resetUnlockSequence()
            if !isShowingSettings {
                revision &+= 1
                Theme13Chrome.apply(self)
            }
        }
    }

    private var tapCount = 0
    private var lastTap: Date?

    private init() {
        let unlocked = defaults.bool(forKey: Keys.unlocked)
        let storedTheme = defaults.string(forKey: Keys.theme)
            ?? defaults.string(forKey: Keys.legacyTheme)
            ?? "darkroom"

        isUnlocked = unlocked
        var initialTheme = storedTheme
        if storedTheme == "theme13" && !unlocked {
            initialTheme = "darkroom"
        }
        if storedTheme == Redroom.themeIdentifier,
           !defaults.bool(forKey: Redroom.availabilityKey) {
            initialTheme = "darkroom"
        }
        selectedThemeIdentifier = initialTheme
        paletteID = Theme13PaletteID(rawValue: defaults.string(forKey: Keys.palette) ?? "") ?? .rangefinder
        appearanceMode = Theme13AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        stillMode = defaults.bool(forKey: Keys.still)
        compactControls = defaults.bool(forKey: Keys.density)
        textSize = Theme13TextSize(rawValue: defaults.string(forKey: Keys.textSize) ?? "") ?? .standard
        motion = Theme13MotionIntensity(rawValue: defaults.string(forKey: Keys.motion) ?? "") ?? .standard
        systemIsDark = false
        revision = 0

        if selectedThemeIdentifier != storedTheme {
            defaults.set(selectedThemeIdentifier, forKey: Keys.theme)
        }

        Theme13Chrome.apply(self)
    }

    // MARK: Derived

    var isTheme13Active: Bool { isUnlocked && selectedThemeIdentifier == "theme13" }
    var isSoftGlassActive: Bool { selectedThemeIdentifier == "softglass" }
    var palette: Theme13Palette { Theme13Palette.palette(paletteID) }
    var fontScale: CGFloat { textSize.scale }
    var motionEnabled: Bool { !stillMode }
    var framesPerSecond: Double { motion.framesPerSecond }

    var isDarkAppearance: Bool {
        switch appearanceMode {
        case .system: return systemIsDark
        case .light: return false
        case .dark: return true
        }
    }

    // MARK: Hidden activation

    /// Registers one tap on the Themes row. Returns true only on the ninth
    /// consecutive tap within the two-second window.
    @discardableResult
    func tapThemes(at date: Date) -> Bool {
        guard !isUnlocked else { return false }
        if let lastTap, date.timeIntervalSince(lastTap) >= 2 {
            tapCount = 0
        }
        tapCount += 1
        lastTap = date
        guard tapCount >= 9 else { return false }

        tapCount = 0
        lastTap = nil
        isUnlocked = true
        defaults.set(true, forKey: Keys.unlocked)
        return true
    }

    func resetUnlockSequence() {
        tapCount = 0
        lastTap = nil
    }

    // MARK: Selection

    func selectTheme(_ identifier: String) {
        resetUnlockSequence()
        var resolved = identifier
        if identifier == "theme13" && !isUnlocked {
            resolved = "darkroom"
        }
        // REDROOM stays unreachable until every screen has its own presentation.
        if identifier == Redroom.themeIdentifier && !isRedroomAvailable {
            resolved = "darkroom"
        }
        guard resolved != selectedThemeIdentifier else { return }
        selectedThemeIdentifier = resolved
        defaults.set(resolved, forKey: Keys.theme)
    }

    func selectPalette(_ id: Theme13PaletteID) {
        resetUnlockSequence()
        paletteID = id
        defaults.set(id.rawValue, forKey: Keys.palette)
    }

    func selectAppearance(_ mode: Theme13AppearanceMode) {
        resetUnlockSequence()
        appearanceMode = mode
        defaults.set(mode.rawValue, forKey: Keys.appearance)
    }

    func setStillMode(_ value: Bool) {
        resetUnlockSequence()
        stillMode = value
        defaults.set(value, forKey: Keys.still)
    }

    func setCompactControls(_ value: Bool) {
        resetUnlockSequence()
        compactControls = value
        defaults.set(value, forKey: Keys.density)
    }

    func setTextSize(_ size: Theme13TextSize) {
        resetUnlockSequence()
        textSize = size
        defaults.set(size.rawValue, forKey: Keys.textSize)
    }

    func setMotion(_ intensity: Theme13MotionIntensity) {
        resetUnlockSequence()
        motion = intensity
        defaults.set(intensity.rawValue, forKey: Keys.motion)
    }

    /// Re-dresses the app root without changing a preference of this store's
    /// own — used by the settings that live in `Preferences`.
    func bumpRevision() {
        revision &+= 1
        Theme13Chrome.apply(self)
    }

    /// Returns this store's preferences to their defaults. The hidden theme's
    /// unlock is not a preference and is deliberately kept.
    func resetPreferences() {
        for key in [
            Keys.theme, Keys.legacyTheme, Keys.palette, Keys.appearance,
            Keys.still, Keys.density, Keys.textSize, Keys.motion
        ] {
            defaults.removeObject(forKey: key)
        }

        selectedThemeIdentifier = "darkroom"
        paletteID = .rangefinder
        appearanceMode = .system
        stillMode = false
        compactControls = false
        textSize = .standard
        motion = .standard

        bumpRevision()
    }

    func updateSystemAppearance(isDark: Bool) {
        guard systemIsDark != isDark else { return }
        systemIsDark = isDark
        if isTheme13Active && appearanceMode == .system && !isShowingSettings {
            revision &+= 1
            Theme13Chrome.apply(self)
        }
    }

    #if DEBUG
    /// QA only. Never compiled into a release build.
    func resetUnlockForQA() {
        isUnlocked = false
        defaults.set(false, forKey: Keys.unlocked)
        if selectedThemeIdentifier == "theme13" {
            selectedThemeIdentifier = "darkroom"
            defaults.set("darkroom", forKey: Keys.theme)
        }
        resetUnlockSequence()
        revision &+= 1
    }
    #endif
}

// MARK: - REDROOM

extension Theme13SettingsStore {
    /// True while the third design language owns the interface.
    var isRedroomActive: Bool {
        selectedThemeIdentifier == Redroom.themeIdentifier
    }

    /// REDROOM is offered in the selector now that every screen has its own
    /// presentation. The key is kept so a build under test can take it away
    /// again by writing false; with nothing written, it is on.
    var isRedroomAvailable: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Redroom.availabilityKey) != nil else { return true }
        return defaults.bool(forKey: Redroom.availabilityKey)
    }

    #if DEBUG
    /// Preview hook for building the theme. Never compiled into a release build.
    func previewRedroom() {
        UserDefaults.standard.set(true, forKey: Redroom.availabilityKey)
        selectTheme(Redroom.themeIdentifier)
    }
    #endif
}
