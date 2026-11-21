//
//  DesignLanguageComponents.swift
//  Darkroom
//
//  The component system every design language shares. One API — panel, button,
//  label, row, figure, chip, section header, segmented control, dial — and
//  eleven drawings of it, chosen by the active language. A screen asks for a
//  panel; the language decides whether that panel is frosted glass, a white
//  hairline card, an acrylic sheet, an extruded tile, a hard-edged block or a
//  phosphor box.
//
//  The components never touch the app's data. They are given strings and views.
//

import SwiftUI

// MARK: - Style

/// Everything a component needs, resolved once: the language's spec, its palette
/// for the current brightness, and the reader's density and text scale.
struct DLStyle {
    let language: ThemeLanguage
    let spec: DLSpec
    let palette: DLPalette
    let isDark: Bool
    let scale: CGFloat
    let density: DLDensity

    init(
        language: ThemeLanguage,
        isDark: Bool,
        accent: AccentChoice?,
        scale: CGFloat,
        density: DLDensity
    ) {
        self.language = language
        self.spec = language.spec
        self.isDark = isDark
        self.palette = language.spec.palette(isDark: isDark, accent: accent)
        self.scale = scale
        self.density = density
    }

    init(store: ThemeLanguageStore) {
        self.init(
            language: store.selected,
            isDark: store.isDark,
            accent: Preferences.shared.accent,
            scale: store.textScale,
            density: store.density
        )
    }

    static let fallback = DLStyle(
        language: .darkroom,
        isDark: true,
        accent: nil,
        scale: 1,
        density: .regular
    )

    var geometry: DLGeometry {
        var geometry = spec.geometry
        let k = density.scale
        geometry.pagePadding *= k
        geometry.sectionSpacing *= k
        geometry.rowSpacing *= k
        geometry.blockSpacing *= k
        return geometry
    }

    var motion: DLMotion { spec.motion }

    var labelCase: Text.Case? {
        spec.type.labelUppercase ? .uppercase : nil
    }

    // MARK: Type

    func display(_ size: CGFloat? = nil) -> Font {
        var type = spec.type
        if let size { type.displaySize = size }
        return type.display(scale: scale)
    }

    func title(_ size: CGFloat? = nil) -> Font {
        spec.type.title(scale: scale, size: size)
    }

    func body(_ size: CGFloat? = nil, weight: Font.Weight = .regular) -> Font {
        spec.type.body(scale: scale, size: size, weight: weight)
    }

    func label() -> Font {
        spec.type.label(scale: scale)
    }

    func figure(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        spec.type.figure(scale: scale, size: size, weight: weight)
    }

    var lineSpacing: CGFloat { spec.type.lineSpacing }
}

private struct DLStyleKey: EnvironmentKey {
    static let defaultValue = DLStyle.fallback
}

extension EnvironmentValues {
    var dlStyle: DLStyle {
        get { self[DLStyleKey.self] }
        set { self[DLStyleKey.self] = newValue }
    }
}

extension View {
    /// Injects a design language's resolved style into a subtree.
    func designLanguage(_ style: DLStyle) -> some View {
        environment(\.dlStyle, style)
    }
}

// MARK: - Roles

enum DLRole: String {
    case primary
    case secondary
    case quiet
}

// MARK: - Panel

struct DLSurfaceModifier: ViewModifier {
    @Environment(\.dlStyle) private var style

    var radius: CGFloat?
    var role: DLRole = .secondary
    var tint: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        let p = style.palette
        let g = style.geometry
        let r = radius ?? g.cardRadius

        switch style.spec.surface {
        case .glass:
            content
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .fill(role == .primary ? p.surfaceAlt : p.surface)
                        if let tint {
                            RoundedRectangle(cornerRadius: r, style: .continuous)
                                .fill(tint.opacity(0.14))
                        }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(style.isDark ? 0.30 : 0.85),
                                    p.line,
                                    p.line.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: g.borderWidth
                        )
                }
                .shadow(color: .black.opacity(style.isDark ? 0.38 : 0.10), radius: 18, x: 0, y: 10)

        case .clean:
            content
                .background {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .fill(p.surface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(p.line, lineWidth: g.borderWidth)
                }

        case .acrylic:
            content
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .fill(p.surface)
                        if let tint {
                            RoundedRectangle(cornerRadius: r, style: .continuous)
                                .fill(tint.opacity(0.10))
                        }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(p.line, lineWidth: g.borderWidth)
                }
                .shadow(color: .black.opacity(style.isDark ? 0.28 : 0.08), radius: 10, x: 0, y: 4)

        case .tonal:
            content
                .background {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .fill(role == .primary ? p.surfaceAlt : p.surface)
                }
                .overlay {
                    if let tint {
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .strokeBorder(tint.opacity(0.35), lineWidth: 1)
                    }
                }
                .shadow(color: p.ink.opacity(style.isDark ? 0.35 : 0.08), radius: 8, x: 0, y: 3)

        case .paper:
            content
                .background {
                    Rectangle().fill(p.surface)
                }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(p.lineStrong)
                        .frame(height: g.borderWidth)
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(p.line)
                        .frame(height: g.borderWidth)
                }

        case .block:
            content
                .background(alignment: .topLeading) {
                    Rectangle()
                        .fill(p.lineStrong)
                        .offset(x: g.shadowOffset, y: g.shadowOffset)
                }
                .background {
                    Rectangle().fill(p.surface)
                }
                .overlay {
                    Rectangle().strokeBorder(p.lineStrong, lineWidth: g.borderWidth)
                }

        case .extruded:
            content
                .background {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .fill(p.surface)
                }
                .shadow(
                    color: (style.isDark ? Color.black : p.lineStrong).opacity(style.isDark ? 0.55 : 0.18),
                    radius: 7,
                    x: 5,
                    y: 5
                )
                .shadow(
                    color: (style.isDark ? Color.white.opacity(0.06) : Color.white).opacity(style.isDark ? 1 : 0.85),
                    radius: 7,
                    x: -5,
                    y: -5
                )

        case .hud:
            content
                .background {
                    DLClippedShape(cut: 12)
                        .fill(p.surface.opacity(0.92))
                }
                .overlay {
                    DLClippedShape(cut: 12)
                        .stroke(p.lineStrong.opacity(0.55), lineWidth: g.borderWidth)
                }
                .overlay {
                    DLCornerBrackets(colour: p.accent, length: 9, thickness: 1.2)
                }
                .shadow(color: p.accent.opacity(style.isDark ? 0.20 : 0.10), radius: 10, x: 0, y: 0)

        case .metal:
            content
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [p.surfaceAlt, p.surface, p.fieldAlt],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(style.isDark ? 0.10 : 0.55), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(p.lineStrong.opacity(0.55), lineWidth: g.borderWidth)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.black.opacity(0.35), .clear, Color.white.opacity(0.30)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 7)

        case .terminal:
            content
                .background {
                    Rectangle().fill(p.surface)
                }
                .overlay {
                    Rectangle().strokeBorder(p.line, lineWidth: g.borderWidth)
                }

        case .outlined:
            content
                .overlay {
                    Rectangle().strokeBorder(p.lineStrong, lineWidth: g.borderWidth)
                }

        case .flat:
            content
                .background {
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .fill(role == .primary ? p.surfaceAlt : p.surface)
                }
        }
    }
}

extension View {
    /// A group of values on a surface the active language drew.
    func dlPanel(radius: CGFloat? = nil, role: DLRole = .secondary, tint: Color? = nil) -> some View {
        modifier(DLSurfaceModifier(radius: radius, role: role, tint: tint))
    }
}

// MARK: - Buttons

struct DLButtonStyle: ButtonStyle {
    var role: DLRole = .primary
    var height: CGFloat?
    var expands: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        DLButtonBody(
            configuration: configuration,
            role: role,
            height: height,
            expands: expands
        )
    }
}

private struct DLButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let role: DLRole
    let height: CGFloat?
    let expands: Bool

    @Environment(\.dlStyle) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var labelInk: Color {
        switch role {
        case .primary:
            switch style.spec.button {
            case .rectangle, .sharpBlock:
                return style.spec.button == .rectangle ? style.palette.surface : style.palette.accentInk
            default:
                return style.palette.accentInk
            }
        case .secondary, .quiet:
            return style.palette.ink
        }
    }

    private var box: CGFloat {
        height ?? (role == .primary ? style.geometry.controlHeight : style.geometry.controlHeight * 0.84)
    }

    var body: some View {
        let p = style.palette
        let g = style.geometry
        let label = styledLabel

        Group {
            switch style.spec.button {
            case .capsule:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        Capsule().fill(
                            role == .primary
                                ? LinearGradient(
                                    colors: [p.accent, p.glow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(colors: [p.surface, p.surface], startPoint: .top, endPoint: .bottom)
                        )
                    }
                    .overlay {
                        Capsule().strokeBorder(
                            role == .primary ? Color.white.opacity(0.30) : p.line,
                            lineWidth: 1
                        )
                    }
                    .shadow(color: p.accent.opacity(role == .primary ? 0.32 : 0), radius: 16, x: 0, y: 8)
                    .scaleEffect(configuration.isPressed ? 0.97 : 1)

            case .rounded:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                            .fill(role == .primary ? p.accent : p.surface)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                            .strokeBorder(role == .primary ? Color.clear : p.line, lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.8 : 1)

            case .roundedSmall:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(role == .primary ? p.accent : p.surface)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(role == .primary ? Color.clear : p.line, lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.72 : 1)

            case .pill:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        Capsule().fill(role == .primary ? p.accent : p.surfaceAlt)
                    }
                    .shadow(color: p.ink.opacity(0.16), radius: 6, x: 0, y: 2)
                    .opacity(configuration.isPressed ? 0.85 : 1)

            case .rectangle:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        Rectangle().fill(role == .primary ? p.ink : p.surface)
                    }
                    .overlay {
                        Rectangle().strokeBorder(p.lineStrong, lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.7 : 1)

            case .sharpBlock:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background(alignment: .topLeading) {
                        Rectangle()
                            .fill(p.lineStrong)
                            .offset(x: configuration.isPressed ? 0 : g.shadowOffset * 0.7,
                                    y: configuration.isPressed ? 0 : g.shadowOffset * 0.7)
                    }
                    .background {
                        Rectangle().fill(role == .primary ? p.accent : p.surface)
                    }
                    .overlay {
                        Rectangle().strokeBorder(p.lineStrong, lineWidth: 3)
                    }
                    .offset(
                        x: configuration.isPressed ? g.shadowOffset * 0.7 : 0,
                        y: configuration.isPressed ? g.shadowOffset * 0.7 : 0
                    )

            case .extruded:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                            .fill(p.surface)
                    }
                    .shadow(
                        color: (style.isDark ? Color.black : p.lineStrong).opacity(configuration.isPressed ? 0.10 : 0.30),
                        radius: configuration.isPressed ? 2 : 7,
                        x: configuration.isPressed ? 1 : 5,
                        y: configuration.isPressed ? 1 : 5
                    )
                    .shadow(
                        color: (style.isDark ? Color.white.opacity(0.06) : Color.white).opacity(configuration.isPressed ? 0.2 : 0.9),
                        radius: configuration.isPressed ? 2 : 7,
                        x: configuration.isPressed ? -1 : -5,
                        y: configuration.isPressed ? -1 : -5
                    )

            case .clipped:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        DLClippedShape(cut: 10)
                            .fill(role == .primary ? p.accent.opacity(0.16) : p.surface)
                    }
                    .overlay {
                        DLClippedShape(cut: 10)
                            .stroke(p.accent, lineWidth: 1.2)
                    }
                    .shadow(color: p.accent.opacity(configuration.isPressed ? 0.5 : 0.28), radius: 10, x: 0, y: 0)
                    .opacity(configuration.isPressed ? 0.85 : 1)

            case .underline:
                VStack(spacing: 6) {
                    label
                    Rectangle()
                        .fill(p.accent)
                        .frame(height: 2)
                }
                .frame(maxWidth: expands ? .infinity : nil)
                .opacity(configuration.isPressed ? 0.6 : 1)

            case .metal:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: role == .primary
                                        ? [p.accent, p.glow]
                                        : [p.surfaceAlt, p.surface, p.fieldAlt],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                            .strokeBorder(p.lineStrong.opacity(0.6), lineWidth: 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.55), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.18 : 0.32), radius: configuration.isPressed ? 3 : 8, x: 0, y: configuration.isPressed ? 2 : 5)

            case .terminal:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        Rectangle().fill(role == .primary ? p.accent.opacity(0.14) : p.surface)
                    }
                    .overlay {
                        Rectangle().strokeBorder(p.lineStrong, lineWidth: 1)
                    }
                    .opacity(configuration.isPressed ? 0.7 : 1)

            case .deck:
                label
                    .frame(maxWidth: expands ? .infinity : nil)
                    .frame(height: box)
                    .background {
                        RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                            .fill(role == .primary ? p.accent : p.surface)
                    }
                    .opacity(configuration.isPressed ? 0.82 : 1)
            }
        }
        .animation(
            style.spec.motion.animation(
                intensity: ThemeLanguageStore.shared.motion,
                reduced: reduceMotion || ThemeLanguageStore.shared.reducesMotion
            ),
            value: configuration.isPressed
        )
        .contentShape(Rectangle())
    }

    private var styledLabel: some View {
        configuration.label
            .font(style.body(16, weight: .semibold))
            .tracking(style.spec.type.labelUppercase ? style.spec.type.labelTracking * 0.6 : 0)
            .textCase(style.spec.type.labelUppercase ? .uppercase : nil)
            .foregroundStyle(labelInk)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 16)
    }
}

// MARK: - Label

struct DLLabel: View {
    let text: String
    var color: Color?

    @Environment(\.dlStyle) private var style

    var body: some View {
        Text(text)
            .font(style.label())
            .tracking(style.spec.type.labelTracking)
            .textCase(style.labelCase)
            .foregroundStyle(color ?? style.palette.inkFaint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// A small plate with a value on it: a status, a count, a provenance.
struct DLChip: View {
    let text: String
    var emphasized: Bool = false

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette
        Text(text)
            .font(style.label())
            .tracking(style.spec.type.labelTracking * 0.6)
            .textCase(style.labelCase)
            .foregroundStyle(emphasized ? p.accentInk : p.inkSoft)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                chipShape
                    .fill(emphasized ? p.accent : p.surfaceAlt)
            }
            .overlay {
                if !emphasized {
                    chipShape.stroke(p.line, lineWidth: 1)
                }
            }
            .accessibilityLabel(text)
    }

    private var chipShape: AnyShape {
        if style.geometry.isSquare {
            return AnyShape(Rectangle())
        }
        return AnyShape(RoundedRectangle(cornerRadius: style.geometry.chipRadius, style: .continuous))
    }
}

// MARK: - Section header

/// The heading a group of values hangs from. Every language sets it differently:
/// a rule and an index for Swiss, an inked block for Brutalist, a serif line for
/// Editorial, a bracketed tag for Cyberpunk, a prompt for Terminal.
struct DLSectionHeader: View {
    let title: String
    var index: String? = nil
    var note: String? = nil

    @Environment(\.dlStyle) private var style

    @ViewBuilder
    var body: some View {
        let p = style.palette

        switch style.language {
        case .swiss, .editorial:
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(style.language == .editorial ? style.title(18) : style.title(15))
                        .tracking(style.language == .editorial ? 0 : -0.4)
                        .foregroundStyle(p.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    if let index {
                        Text(index)
                            .font(style.figure(11, weight: .bold))
                            .foregroundStyle(p.accent)
                    }
                }
                Rectangle()
                    .fill(p.lineStrong)
                    .frame(height: style.language == .swiss ? 2.5 : 1)
            }

        case .brutalist:
            HStack(spacing: 0) {
                Rectangle()
                    .fill(p.accent)
                    .frame(width: 6)
                Text(title.uppercased())
                    .font(style.title(15))
                    .tracking(0.6)
                    .foregroundStyle(p.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                Spacer(minLength: 0)
                if let index {
                    Text(index)
                        .font(style.figure(11, weight: .black))
                        .foregroundStyle(p.ink)
                        .padding(.horizontal, 10)
                }
            }
            .background(Rectangle().fill(p.surface))
            .overlay(Rectangle().strokeBorder(p.lineStrong, lineWidth: 2))

        case .terminal:
            HStack(spacing: 6) {
                Text("##")
                    .font(style.label())
                    .foregroundStyle(p.accent)
                Text(title.lowercased())
                    .font(style.title(14))
                    .foregroundStyle(p.ink)
                Rectangle()
                    .fill(p.line)
                    .frame(height: 1)
                if let index {
                    Text(index)
                        .font(style.label())
                        .foregroundStyle(p.inkFaint)
                }
            }

        case .cyberpunk:
            HStack(spacing: 6) {
                Rectangle()
                    .fill(p.accent)
                    .frame(width: 3, height: 13)
                Text(title.uppercased())
                    .font(style.title(14))
                    .tracking(1.4)
                    .foregroundStyle(p.ink)
                Spacer(minLength: 4)
                if let index {
                    Text("[\(index)]")
                        .font(style.label())
                        .foregroundStyle(p.accent)
                }
            }

        case .fluent:
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(style.title(15))
                        .foregroundStyle(p.ink)
                    Spacer(minLength: 4)
                    if let index {
                        Text(index)
                            .font(style.label())
                            .foregroundStyle(p.inkFaint)
                    }
                }
                RoundedRectangle(cornerRadius: 1)
                    .fill(p.accent)
                    .frame(width: 22, height: 3)
            }

        case .recorder:
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(style.label())
                        .foregroundStyle(p.ink)
                    Spacer(minLength: 4)
                    if let index {
                        Text(index)
                            .font(style.label())
                            .foregroundStyle(p.inkSoft)
                    }
                }
                Rectangle()
                    .fill(p.lineStrong)
                    .frame(height: 1)
            }

        default:
            HStack(spacing: 8) {
                DLLabel(text: title)
                Rectangle()
                    .fill(p.line)
                    .frame(height: 1)
                if let index {
                    Text(index)
                        .font(style.label())
                        .foregroundStyle(p.accent)
                }
            }
        }

        if let note {
            Text(note)
                .font(style.body(12))
                .foregroundStyle(p.inkSoft)
                .lineSpacing(style.lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Screen header

/// The title block at the top of a language's screen.
struct DLHeader: View {
    let kicker: String
    let title: String
    var detail: String? = nil
    var trailing: AnyView? = nil

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(alignment: .leading, spacing: 8) {
            switch style.language {
            case .editorial:
                VStack(alignment: .leading, spacing: 6) {
                    Text(kicker.uppercased())
                        .font(style.label())
                        .tracking(style.spec.type.labelTracking)
                        .foregroundStyle(p.accent)
                    Text(title)
                        .font(style.display())
                        .foregroundStyle(p.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Rectangle()
                        .fill(p.lineStrong)
                        .frame(height: 2)
                }

            case .brutalist:
                Text(title.uppercased())
                    .font(style.display())
                    .foregroundStyle(p.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(p.accent).frame(height: 8).offset(y: 8)
                    }

            case .terminal:
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(">")
                        .font(style.display())
                        .foregroundStyle(p.accent)
                    Text(title)
                        .font(style.display())
                        .foregroundStyle(p.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

            case .recorder:
                // The deck's masthead: the title alone, set as large as it needs
                // and broken across lines the way a printed label is.
                Text(title)
                    .font(style.display())
                    .foregroundStyle(p.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(-2)

            default:
                VStack(alignment: .leading, spacing: 6) {
                    DLLabel(text: kicker, color: p.accent)
                    Text(title)
                        .font(style.display())
                        .foregroundStyle(p.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let detail {
                Text(detail)
                    .font(style.body(14))
                    .foregroundStyle(p.inkSoft)
                    .lineSpacing(style.lineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let trailing {
                trailing
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Figure

/// The large number a screen is built around.
struct DLFigure: View {
    let value: String
    var unit: String? = nil
    var caption: String? = nil
    var size: CGFloat = 42

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(style.figure(size, weight: .semibold))
                    .foregroundStyle(style.language == .cyberpunk ? p.accent : p.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .contentTransition(.numericText())

                if let unit {
                    Text(unit)
                        .font(style.body(13))
                        .foregroundStyle(p.inkSoft)
                }
            }

            if let caption {
                Text(caption)
                    .font(style.body(12))
                    .foregroundStyle(p.inkSoft)
                    .lineSpacing(style.lineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Row

/// A row: a name, a line under it, and a value at the end of it. The rule, the
/// chevron and the casing are the language's.
struct DLRow: View {
    let title: String
    var detail: String? = nil
    var value: String? = nil
    var badge: String? = nil
    var symbol: String? = nil
    var showsChevron: Bool = false

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(alignment: .center, spacing: 11) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(p.accent)
                    .frame(width: 24, alignment: .leading)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(style.body(14, weight: .semibold))
                    .foregroundStyle(p.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let detail {
                    Text(detail)
                        .font(style.body(12))
                        .foregroundStyle(p.inkSoft)
                        .lineSpacing(style.lineSpacing - 1)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 6)

            if let badge {
                DLChip(text: badge)
            }

            if let value {
                Text(value)
                    .font(style.figure(14, weight: .semibold))
                    .foregroundStyle(style.language == .cyberpunk ? p.accent : p.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if showsChevron {
                Image(systemName: style.geometry.isSquare ? "arrow.right" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(p.inkFaint)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, style.geometry.rowSpacing * 0.35)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .overlay(alignment: .bottom) {
            if style.language == .swiss || style.language == .editorial || style.language == .terminal {
                Rectangle()
                    .fill(p.line)
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Stat

struct DLStatTile: View {
    let label: String
    let value: String
    var unit: String? = nil

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(alignment: .leading, spacing: 6) {
            DLLabel(text: label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(style.figure(20, weight: .semibold))
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    Text(unit)
                        .font(style.body(11))
                        .foregroundStyle(p.inkSoft)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, style.geometry.blockSpacing)
        .padding(.vertical, style.geometry.blockSpacing * 0.8)
        .dlPanel(role: .secondary)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Note

struct DLNote: View {
    let text: String
    var symbol: String = "info.circle"
    var emphasized: Bool = false

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(emphasized ? p.danger : p.inkFaint)
                .padding(.top, 2)

            Text(text)
                .font(style.body(12))
                .foregroundStyle(emphasized ? p.ink : p.inkSoft)
                .lineSpacing(style.lineSpacing - 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Rule

struct DLRule: View {
    var heavy: Bool = false

    @Environment(\.dlStyle) private var style

    var body: some View {
        Rectangle()
            .fill(heavy ? style.palette.lineStrong : style.palette.line)
            .frame(height: heavy ? 2 : 1)
            .accessibilityHidden(true)
    }
}

// MARK: - Segmented

/// The language's segmented control. Swiss and Brutalist use hard blocks,
/// Material and Terminal use their own idioms, the softer languages a capsule.
struct DLSegmented<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let title: (Item) -> String

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette
        let g = style.geometry

        HStack(spacing: style.geometry.isSquare ? 0 : 3) {
            ForEach(items, id: \.self) { item in
                let isOn = item == selection

                Button {
                    guard selection != item else { return }
                    withAnimation(
                        style.spec.motion.animation(
                            intensity: ThemeLanguageStore.shared.motion,
                            reduced: ThemeLanguageStore.shared.reducesMotion
                        )
                    ) {
                        selection = item
                    }
                    Haptics.impact(.light)
                } label: {
                    Text(title(item))
                        .font(style.body(13, weight: isOn ? .semibold : .regular))
                        .textCase(style.labelCase)
                        .tracking(style.spec.type.labelUppercase ? 0.6 : 0)
                        .foregroundStyle(isOn ? onInk : p.inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(34, g.controlHeight * 0.66))
                        .background {
                            if isOn {
                                segmentBackground
                            }
                        }
                        .overlay(alignment: .leading) {
                            if style.geometry.isSquare && !isOn {
                                Rectangle().fill(p.line).frame(width: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(style.geometry.isSquare ? 0 : 3)
        .background {
            switch style.language {
            case .swiss, .brutalist, .editorial, .terminal:
                Rectangle().fill(p.surface)
            default:
                RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                    .fill(p.surface.opacity(0.7))
            }
        }
        .overlay {
            switch style.language {
            case .swiss, .editorial, .terminal:
                Rectangle().strokeBorder(p.line, lineWidth: 1)
            case .brutalist:
                Rectangle().strokeBorder(p.lineStrong, lineWidth: 2)
            default:
                RoundedRectangle(cornerRadius: g.controlRadius, style: .continuous)
                    .strokeBorder(p.line, lineWidth: 1)
            }
        }
    }

    private var onInk: Color {
        switch style.spec.surface {
        case .block, .metal:
            return style.palette.accentInk
        case .terminal:
            return style.palette.accentInk
        default:
            return style.palette.accentInk
        }
    }

    @ViewBuilder
    private var segmentBackground: some View {
        let p = style.palette
        switch style.language {
        case .swiss:
            Rectangle().fill(p.ink)
        case .brutalist:
            Rectangle().fill(p.accent)
        case .terminal:
            Rectangle().fill(p.accent.opacity(0.18))
        case .editorial:
            Rectangle().fill(p.accent)
        default:
            Capsule().fill(p.accent)
        }
    }
}

// MARK: - Switch

/// A switch drawn by the language: a physical toggle for the two that are
/// physical, a pill everywhere else.
struct DLSwitch: View {
    @Binding var isOn: Bool
    var label: String? = nil

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette
        let g = style.geometry

        HStack(spacing: 10) {
            if let label {
                Text(label)
                    .font(style.body(14))
                    .foregroundStyle(p.ink)
                Spacer(minLength: 6)
            }

            Button {
                withAnimation(
                    style.spec.motion.animation(
                        intensity: ThemeLanguageStore.shared.motion,
                        reduced: ThemeLanguageStore.shared.reducesMotion
                    )
                ) {
                    isOn.toggle()
                }
                Haptics.impact(.light)
            } label: {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? p.accent : p.surfaceAlt)
                        .frame(width: 48, height: 28)
                        .overlay {
                            Capsule().strokeBorder(
                                style.language == .brutalist ? p.lineStrong : p.line,
                                lineWidth: style.language == .brutalist ? 2 : 1
                            )
                        }

                    Circle()
                        .fill(
                            style.language == .skeuomorphic || style.language == .neumorphic
                                ? LinearGradient(
                                    colors: [p.surface, p.fieldAlt],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [Color.white, Color.white],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .frame(width: 22, height: 22)
                        .padding(3)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                }
                .frame(width: 48, height: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label ?? "Switch")
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        }
    }
}

// MARK: - Dial

/// A rotary dial. Used where a language wants a knob rather than a slider, and
/// where a session's temperature or a setting wants a physical gesture.
struct DLDial: View {
    let label: String
    let value: String
    var fraction: Double
    var tint: Color?

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette
        let colour = tint ?? p.accent

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [p.surfaceAlt, p.surface, p.fieldAlt],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 40
                        )
                    )
                    .overlay {
                        Circle().strokeBorder(p.lineStrong.opacity(0.5), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.32), radius: 6, x: 0, y: 3)

                ForEach(0..<24, id: \.self) { tick in
                    Rectangle()
                        .fill(tick % 6 == 0 ? p.ink.opacity(0.6) : p.inkFaint.opacity(0.4))
                        .frame(width: 1, height: tick % 6 == 0 ? 6 : 3)
                        .offset(y: -26)
                        .rotationEffect(.degrees(Double(tick) / 24 * 360))
                }

                Rectangle()
                    .fill(colour)
                    .frame(width: 2, height: 18)
                    .offset(y: -10)
                    .rotationEffect(.degrees(fraction.clamped(to: 0...1) * 270 - 135))
                    .animation(
                        style.spec.motion.animation(
                            intensity: ThemeLanguageStore.shared.motion,
                            reduced: ThemeLanguageStore.shared.reducesMotion
                        ),
                        value: fraction
                    )

                Circle()
                    .fill(p.fieldAlt)
                    .frame(width: 8, height: 8)
                    .overlay { Circle().strokeBorder(p.line, lineWidth: 1) }
            }
            .frame(width: 64, height: 64)

            Text(value)
                .font(style.figure(13, weight: .semibold))
                .foregroundStyle(p.ink)

            DLLabel(text: label)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

// MARK: - Meter

/// An analog meter: a half circle with a needle and a scale printed under it.
struct DLMeter: View {
    let caption: String
    var fraction: Double

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette
        let clamped = fraction.clamped(to: 0...1)

        VStack(spacing: 4) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                ZStack(alignment: .bottomLeading) {
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: width / 2, y: height),
                            radius: min(width, height * 2) * 0.46,
                            startAngle: .degrees(180),
                            endAngle: .degrees(360),
                            clockwise: false
                        )
                    }
                    .stroke(p.line, lineWidth: 1)

                    Path { path in
                        path.addArc(
                            center: CGPoint(x: width / 2, y: height),
                            radius: min(width, height * 2) * 0.46,
                            startAngle: .degrees(180),
                            endAngle: .degrees(180 + 180 * clamped),
                            clockwise: false
                        )
                    }
                    .stroke(p.accent, lineWidth: 2.5)

                    Rectangle()
                        .fill(p.ink)
                        .frame(width: 1.5, height: min(width, height * 2) * 0.40)
                        .rotationEffect(.degrees(-90 + 180 * clamped), anchor: .bottom)
                        .offset(x: width / 2, y: 0)
                }
            }
            .frame(height: 44)

            DLLabel(text: caption)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption)
    }
}

// MARK: - Helpers

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}


// MARK: - Action surfaces for the app's own buttons

extension DLStyle {
    /// The drawing an action takes in this language. The app's own button styles
    /// use it so a screen the module did not write still presses in the language.
    @ViewBuilder
    func actionBackground(role: DLRole, isPressed: Bool) -> some View {
        switch spec.button {
        case .capsule:
            Capsule().fill(
                LinearGradient(
                    colors: role == .primary
                        ? [palette.accent, palette.glow]
                        : [palette.surface, palette.surfaceAlt],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        case .rounded:
            RoundedRectangle(cornerRadius: geometry.controlRadius, style: .continuous)
                .fill(fill(role))

        case .roundedSmall:
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(fill(role))

        case .pill:
            Capsule().fill(fill(role))

        case .rectangle:
            Rectangle().fill(role == .primary ? palette.ink : palette.surface)

        case .sharpBlock:
            Rectangle().fill(role == .primary ? palette.accent : palette.surface)

        case .extruded:
            RoundedRectangle(cornerRadius: geometry.controlRadius, style: .continuous)
                .fill(palette.surface)

        case .clipped:
            DLClippedShape(cut: 10)
                .fill(role == .primary ? palette.accent.opacity(0.16) : palette.surface)

        case .underline:
            Color.clear

        case .metal:
            RoundedRectangle(cornerRadius: geometry.controlRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: role == .primary
                            ? [palette.accent, palette.glow]
                            : [palette.surfaceAlt, palette.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

        case .terminal:
            Rectangle().fill(role == .primary ? palette.accent.opacity(0.14) : palette.surface)

        case .deck:
            RoundedRectangle(cornerRadius: geometry.controlRadius, style: .continuous)
                .fill(role == .primary ? palette.accent : palette.surface)
        }
    }

    func fill(_ role: DLRole) -> Color {
        role == .primary ? palette.accent : palette.surface
    }

    /// The corner an action is cut to.
    var actionRadius: CGFloat {
        switch spec.button {
        case .capsule, .pill:
            return 999
        case .roundedSmall, .rectangle, .sharpBlock, .terminal:
            return spec.button == .roundedSmall ? 4 : 0
        case .clipped:
            return 2
        default:
            return geometry.controlRadius
        }
    }
}

// MARK: - Recorder furniture

/// The deck's gauge: a disc made of square dots in horizontal bands, lit top
/// down to the fraction. It is the one large mark on a Recorder screen, the way
/// a dial is on a machine.
struct DLDotDisc: View {
    var fraction: Double
    var size: CGFloat = 176
    /// How much of the field shows through an unlit dot.
    var unlitOpacity: Double = 0.16

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette
        let clamped = fraction.clamped(to: 0...1)

        Canvas { context, canvas in
            let side = min(canvas.width, canvas.height)
            let radius = side / 2
            let pitch = side / 15
            let cell = pitch * 0.62
            let centre = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
            let rows = max(Int(radius / pitch), 1)

            for row in -rows...rows {
                let dy = CGFloat(row) * pitch
                let chord = (radius * radius - dy * dy)
                guard chord > 0 else { continue }
                let columns = Int(chord.squareRoot() / pitch)

                for column in -columns...columns {
                    let x = centre.x + CGFloat(column) * pitch
                    let y = centre.y + dy
                    let rect = CGRect(x: x - cell / 2, y: y - cell / 2, width: cell, height: cell)

                    // Top down: the rows above the progress are the lit ones.
                    let position = Double(row + rows) / Double(rows * 2)
                    context.fill(
                        Path(rect),
                        with: .color(position <= clamped ? p.ink : p.ink.opacity(unlitOpacity))
                    )
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A black knob with a small signal dot on its rim, the way a machine shows where
/// its control is set.
struct DLKnob: View {
    var fraction: Double
    var size: CGFloat = 88

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette
        let clamped = fraction.clamped(to: 0...1)

        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.13), Color(white: 0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.28), radius: 7, x: 0, y: 4)

            Circle()
                .fill(p.glow)
                .frame(width: 7, height: 7)
                .offset(y: -size * 0.30)
                .rotationEffect(.degrees(clamped * 300 - 150))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Hosted header

/// Reserved for a screen that needs a header of its own inside a language; the
/// hosted tabs keep the system bar so a pushed screen always has its way back.
struct DLHostedHeader<Accessory: View>: View {
    let title: String
    let accessory: Accessory

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                DLSignatureMark(spec: style.spec, palette: p, size: 13)

                Text(title)
                    .font(style.title(style.language == .editorial ? 19 : 15))
                    .textCase(style.language == .editorial ? nil : style.labelCase)
                    .tracking(style.language == .editorial ? 0 : 1.2)
                    .foregroundStyle(p.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 6)

                accessory
            }
            .padding(.horizontal, style.geometry.pagePadding)
            .frame(height: 46)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(p.field)

            Rectangle()
                .fill(style.language == .brutalist ? p.lineStrong : p.line)
                .frame(height: style.language == .brutalist ? 2 : 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}
