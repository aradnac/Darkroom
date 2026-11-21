//
//  DesignLanguage.swift
//  Darkroom
//
//  The thirteen themes. A theme is not a colour scheme: the design languages
//  carry their own navigation structure, layouts, type ramp, controls, surfaces,
//  borders, shadows, motion and background. Everything the app does is shared;
//  only the presentation is replaced.
//
//  Darkroom and Soft Light are the app's own two interfaces and are drawn by the
//  app's screens. The other eleven are drawn by this module. One store holds the
//  single theme choice for all of them, and the palette, which lives in
//  Preferences, lights every one of them.
//

import SwiftUI
import UIKit

// MARK: - The themes

/// Every theme the reader can choose, in the order Settings lists them. The first
/// is the default.
enum ThemeLanguage: String, CaseIterable, Identifiable {
    /// The app's own interface: frosted panels, a capsule dock and a lit bench.
    /// Its raw value is the one earlier builds stored for it, so it is kept.
    case darkroom = "liquidGlass"
    /// The app's second native interface: a black field, white capsules for
    /// anything you can press, and colour cards for the figures.
    case softLight = "softLight"
    case appleClean = "appleClean"
    case fluent = "fluent"
    case material3 = "material3"
    case swiss = "swiss"
    case brutalist = "brutalist"
    case neumorphic = "neumorphic"
    case cyberpunk = "cyberpunk"
    case retroAnalog = "retroAnalog"
    case editorial = "editorial"
    case skeuomorphic = "skeuomorphic"
    case terminal = "terminal"
    /// A flat, saturated deck: black type on the chosen colour, a dot-matrix
    /// gauge and a two-by-two of knobs.
    case recorder = "recorder"

    var id: String { rawValue }

    var index: Int {
        (ThemeLanguage.allCases.firstIndex(of: self) ?? 0) + 1
    }

    var number: String {
        String(format: "%02d", index)
    }

    var name: String {
        switch self {
        case .darkroom: return "Darkroom"
        case .softLight: return "Soft Light"
        case .appleClean: return "Clean"
        case .fluent: return "Fluent"
        case .material3: return "Material 3"
        case .swiss: return "Swiss"
        case .brutalist: return "Brutalist"
        case .neumorphic: return "Neumorphic"
        case .cyberpunk: return "Cyberpunk"
        case .retroAnalog: return "Retro Analog"
        case .editorial: return "Editorial"
        case .skeuomorphic: return "Skeuomorphic"
        case .terminal: return "Terminal"
        case .recorder: return "Recorder"
        }
    }

    var family: String {
        switch self {
        case .darkroom, .softLight: return "Native"
        case .appleClean: return "Apple"
        case .fluent: return "Microsoft"
        case .material3: return "Google"
        case .swiss: return "International Style"
        case .brutalist: return "Brutalist"
        case .neumorphic: return "Soft UI"
        case .cyberpunk: return "Futurist"
        case .retroAnalog: return "Analog"
        case .editorial: return "Editorial"
        case .skeuomorphic: return "Physical"
        case .terminal: return "Developer"
        case .recorder: return "Instrument"        }
    }

    var tagline: String {
        switch self {
        case .darkroom: return "Frosted glass, lit by your palette"
        case .softLight: return "White capsules, dot-matrix figures"
        case .appleClean: return "Whitespace first"
        case .fluent: return "Acrylic and light"
        case .material3: return "Tonal surfaces, adaptive"
        case .swiss: return "The grid decides"
        case .brutalist: return "Raw, loud, unhedged"
        case .neumorphic: return "Soft, extruded, tactile"
        case .cyberpunk: return "Neon on dark chrome"
        case .retroAnalog: return "Analog meters in the dark"
        case .editorial: return "Set like a magazine"
        case .skeuomorphic: return "Metal you can press"
        case .terminal: return "Command line, dense"
        case .recorder: return "Flat colour, black knobs"
        }
    }

    var detail: String {
        switch self {
        case .darkroom:
            return "The app's own interface: frosted panels, a capsule dock and a lit bench behind everything."
        case .softLight:
            return "A black field lit by your palette, white capsules for anything you can press, and colour cards for the figures."
        case .appleClean:
            return "Hairlines instead of cards, very generous space, one quiet dock at the foot."
        case .fluent:
            return "A pivot bar on the phone, a sidebar on the iPad, acrylic sheets and small corners."
        case .material3:
            return "Tonal containers, a pill indicator navigation bar and a floating action button."
        case .swiss:
            return "A numbered rail down the left edge and everything else on a strict column grid."
        case .brutalist:
            return "Three-pixel rules, hard offset shadows, block navigation, uppercase at volume."
        case .neumorphic:
            return "Surfaces pressed out of one soft field, with a raised tray for the tabs."
        case .cyberpunk:
            return "Angular panels, scanlines, bracketed headers and a HUD rail with telemetry."
        case .retroAnalog:
            return "Film frames, sprocket rails, mechanical meters and a warm safelight grain."
        case .editorial:
            return "A serif masthead across the top, numbered folios, ruled columns and a pull quote."
        case .skeuomorphic:
            return "Brushed metal panels, screwed bezels, a physical switchboard and a rotary dial."
        case .terminal:
            return "A phosphor prompt, monospaced panels and a command bar in place of a tab bar."
        case .recorder:
            return "One flat colour from edge to edge, black type on it, and a deck of black knobs with a signal dot."
        }
    }

    var glyph: String {
        switch self {
        case .darkroom: return "circle.hexagongrid.fill"
        case .softLight: return "circle.grid.2x2.fill"
        case .appleClean: return "square.dashed"
        case .fluent: return "square.split.2x1"
        case .material3: return "circle.circle.fill"
        case .swiss: return "grid"
        case .brutalist: return "square.fill"
        case .neumorphic: return "square.on.square.dashed"
        case .cyberpunk: return "bolt.horizontal.fill"
        case .retroAnalog: return "light.max"
        case .editorial: return "textformat.serif"
        case .skeuomorphic: return "dial.high.fill"
        case .terminal: return "terminal"
        case .recorder: return "record.circle"
        }
    }

    /// The two native interfaces are drawn by the app's own screens. Every other
    /// theme is drawn by this module.
    var isNativeToApp: Bool { self == .darkroom || self == .softLight }

    var isDrawnHere: Bool { !isNativeToApp }

    /// A theme that never leaves its own brightness.
    var isDarkOnly: Bool {
        self == .darkroom || self == .softLight || self == .cyberpunk || self == .retroAnalog
    }

    /// How the theme treats the brightness setting. Most follow it; a few are
    /// drawn at one brightness by their own design. Recorder is the one theme that
    /// is always light, because black type on a saturated field is the whole look.
    var brightnessMode: DLThemeBrightness {
        if self == .recorder { return .alwaysLight }
        return isDarkOnly ? .alwaysDark : .followsSetting
    }

    /// Whether this theme is drawn dark, given the reader's brightness choice.
    func isDark(resolvedDark: Bool) -> Bool {
        switch brightnessMode {
        case .alwaysDark: return true
        case .alwaysLight: return false
        case .followsSetting: return resolvedDark
        }
    }

    var spec: DLSpec {
        DLSpec.spec(for: self)
    }
}

// MARK: - Appearance of the field

enum DLScheme {
    case light
    case dark
}

/// Whether a theme follows the brightness setting or draws one of its own.
enum DLThemeBrightness {
    case followsSetting
    case alwaysDark
    case alwaysLight
}

enum DLAppearance: String, CaseIterable, Identifiable {
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

enum DLDensity: String, CaseIterable, Identifiable {
    case compact
    case regular
    case spacious

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .regular: return "Regular"
        case .spacious: return "Spacious"
        }
    }

    /// Multiplies every spacing token a language declares.
    var scale: CGFloat {
        switch self {
        case .compact: return 0.82
        case .regular: return 1
        case .spacious: return 1.20
        }
    }
}

enum DLTextSize: String, CaseIterable, Identifiable {
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

enum DLMotionIntensity: String, CaseIterable, Identifiable {
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
}

// MARK: - Motion

/// One language's animation recipe. Durations scale with the animation intensity
/// setting, and collapse to nothing when motion is reduced.
struct DLMotion {
    var response: Double = 0.42
    var damping: Double = 0.82
    var stagger: Double = 0.04
    var quick: Double = 0.16
    var style: DLMotionStyle = .spring

    enum DLMotionStyle {
        case spring
        case ease
        case linear
        case snap
    }

    func animation(intensity: DLMotionIntensity, reduced: Bool) -> Animation? {
        guard !reduced else { return nil }
        let multiplier: Double
        switch intensity {
        case .calm: multiplier = 1.45
        case .standard: multiplier = 1
        case .lively: multiplier = 0.66
        }
        switch style {
        case .spring:
            return .spring(response: response * multiplier, dampingFraction: damping)
        case .ease:
            return .easeOut(duration: quick * multiplier)
        case .linear:
            return .linear(duration: quick * multiplier)
        case .snap:
            return .snappy(duration: quick * multiplier, extraBounce: 0.02)
        }
    }
}

// MARK: - Preference store

/// The one theme choice and everything that adjusts how it is drawn. Every write
/// persists and publishes, so the root and the theme's own screens re-dress
/// together. The palette is not here: it lives in `Preferences` and lights every
/// theme alike.
final class ThemeLanguageStore: ObservableObject {
    static let shared = ThemeLanguageStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let language = "designLanguage.language"
        static let appearance = "designLanguage.appearance"
        static let density = "designLanguage.density"
        static let textSize = "designLanguage.textSize"
        static let motion = "designLanguage.motion"
        static let reducedMotion = "designLanguage.reducedMotion"
        /// Earlier builds kept Soft Glass in its own store. Read once, then removed.
        static let legacySoftGlass = "appearance.language"
        /// Earlier builds kept a second accent for the twelve. Removed on reset.
        static let retiredAccent = "designLanguage.accent"
        /// Earlier builds kept compact controls as a separate switch, which was
        /// folded into density. Read once for the migration, then removed.
        static let retiredCompact = "appearance.compactControls"
    }

    @Published private(set) var selected: ThemeLanguage
    @Published private(set) var appearance: DLAppearance
    @Published private(set) var density: DLDensity
    @Published private(set) var textSize: DLTextSize
    @Published private(set) var motion: DLMotionIntensity
    @Published private(set) var reducesMotion: Bool

    /// The system's own scheme, tracked by the app root.
    @Published private(set) var systemIsDark: Bool = true

    /// Set by the Appearance entry in Settings and by the Develop header; the root
    /// presents the Appearance sheet.
    @Published var isShowingAppearance = false

    /// The one way to open Appearance from a theme's own screens. Same rule as
    /// Settings: a tap can only happen with no sheet up, so a flag that is still
    /// true is stale and is cleared before it is raised again.
    func presentAppearance() {
        guard isShowingAppearance else {
            isShowingAppearance = true
            return
        }
        isShowingAppearance = false
        DispatchQueue.main.async { [weak self] in
            self?.isShowingAppearance = true
        }
    }

    private init() {
        let stored = defaults.string(forKey: Keys.language).flatMap(ThemeLanguage.init(rawValue:))
        if let stored {
            selected = stored
        } else if defaults.string(forKey: Keys.legacySoftGlass) == "softGlass" {
            // A Soft Glass choice made before the themes were merged carries over.
            selected = .softLight
            defaults.set(ThemeLanguage.softLight.rawValue, forKey: Keys.language)
        } else {
            selected = .darkroom
        }
        defaults.removeObject(forKey: Keys.legacySoftGlass)
        defaults.removeObject(forKey: Keys.retiredAccent)

        appearance = DLAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system

        if let storedDensity = DLDensity(rawValue: defaults.string(forKey: Keys.density) ?? "") {
            density = storedDensity
        } else {
            density = defaults.bool(forKey: Keys.retiredCompact) ? .compact : .regular
        }
        defaults.removeObject(forKey: Keys.retiredCompact)

        textSize = DLTextSize(rawValue: defaults.string(forKey: Keys.textSize) ?? "") ?? .standard
        motion = DLMotionIntensity(rawValue: defaults.string(forKey: Keys.motion) ?? "") ?? .standard
        reducesMotion = defaults.bool(forKey: Keys.reducedMotion)
    }

    // MARK: Derived

    /// True while one of this module's themes owns the interface.
    var isActive: Bool { selected.isDrawnHere }

    var isDark: Bool {
        switch selected.brightnessMode {
        case .alwaysDark:
            return true
        case .alwaysLight:
            return false
        case .followsSetting:
            switch appearance {
            case .system: return systemIsDark
            case .light: return false
            case .dark: return true
            }
        }
    }

    var preferredScheme: ColorScheme? {
        isDark ? .dark : .light
    }

    var spec: DLSpec { selected.spec }

    /// The palette the reader chose, applied to the selected theme.
    var palette: DLPalette {
        spec.palette(isDark: isDark, accent: Preferences.shared.accent)
    }

    var textScale: CGFloat { textSize.scale }

    var animations: Bool { !reducesMotion }

    // MARK: Selection

    func select(_ language: ThemeLanguage) {
        guard language != selected else { return }
        let previous = selected
        // The new theme arrives on the motion the theme itself asks for, and not
        // at all when motion is reduced.
        withAnimation(
            language.spec.motion.animation(
                intensity: motion,
                reduced: reducesMotion || UIAccessibility.isReduceMotionEnabled
            )
        ) {
            selected = language
        }
        // Only a move into or out of one of the two native interfaces rebuilds the
        // native tab stack. Moving between the eleven leaves it alone.
        if previous.isNativeToApp || language.isNativeToApp {
            AppearanceStore.shared.bumpRevision()
        }
        defaults.set(language.rawValue, forKey: Keys.language)
        Haptics.impact(.light)
    }

    /// Applies a theme after it has been previewed.
    func apply(_ language: ThemeLanguage) {
        select(language)
    }

    func returnToNative() {
        select(.darkroom)
    }

    // MARK: Appearance

    func setAppearance(_ value: DLAppearance) {
        guard value != appearance else { return }
        appearance = value
        defaults.set(value.rawValue, forKey: Keys.appearance)
    }

    func updateSystemAppearance(isDark: Bool) {
        guard systemIsDark != isDark else { return }
        systemIsDark = isDark
    }

    // MARK: Density and type

    func setDensity(_ value: DLDensity) {
        guard value != density else { return }
        density = value
        defaults.set(value.rawValue, forKey: Keys.density)
        // The native controls read density too, so their tab stack is re-dressed.
        AppearanceStore.shared.bumpRevision()
    }

    func setTextSize(_ value: DLTextSize) {
        guard value != textSize else { return }
        textSize = value
        defaults.set(value.rawValue, forKey: Keys.textSize)
    }

    // MARK: Motion

    func setMotion(_ value: DLMotionIntensity) {
        guard value != motion else { return }
        motion = value
        defaults.set(value.rawValue, forKey: Keys.motion)
    }

    func setReducesMotion(_ value: Bool) {
        guard value != reducesMotion else { return }
        reducesMotion = value
        defaults.set(value, forKey: Keys.reducedMotion)
    }

    /// The animation a theme's components should use right now.
    func animation(_ languageMotion: DLMotion, reducedBySystem: Bool) -> Animation? {
        languageMotion.animation(
            intensity: motion,
            reduced: reducesMotion || reducedBySystem
        )
    }

    func reset() {
        let keys = [
            Keys.language,
            Keys.appearance,
            Keys.density,
            Keys.textSize,
            Keys.motion,
            Keys.reducedMotion,
            Keys.legacySoftGlass,
            Keys.retiredAccent,
            Keys.retiredCompact
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }

        selected = .darkroom
        appearance = .system
        density = .regular
        textSize = .standard
        motion = .standard
        reducesMotion = false
        AppearanceStore.shared.bumpRevision()
    }
}

// MARK: - Reading the active theme

/// One place that answers "which theme is on", so the app's own screens can
/// dress themselves without each one learning a store's keys.
enum DLRuntime {
    static var active: ThemeLanguage { ThemeLanguageStore.shared.selected }

    /// The spec for the theme this module draws, and nil while one of the two
    /// native interfaces is on.
    static var activeSpec: DLSpec? {
        let store = ThemeLanguageStore.shared
        return store.selected.isDrawnHere ? store.spec : nil
    }

    /// A ready-made style for the app's own screens: palette, type and geometry
    /// resolved against the current brightness, density and text size.
    static var activeStyle: DLStyle? {
        guard activeSpec != nil else { return nil }
        return DLStyle.current(from: ThemeLanguageStore.shared)
    }
}
