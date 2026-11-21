//
//  DesignLanguageAppearanceView.swift
//  Darkroom
//
//  The one Appearance section: the theme, the palette every theme is lit with,
//  the brightness a theme can be read in, the text size, how much it moves, how
//  much room it takes, and a preview of a theme before it is used.
//
//  Everything here changes how the app is drawn. Nothing here changes what it
//  does.
//

import SwiftUI

struct ThemeLanguageAppearanceView: View {
    @ObservedObject private var store = ThemeLanguageStore.shared
    @ObservedObject private var preferences = Preferences.shared

    @Environment(\.dismiss) private var dismiss

    @State private var preview: ThemeLanguage?

    private var style: DLStyle { DLStyle(store: store) }

    var body: some View {
        let style = self.style

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    themeSection
                    paletteSection
                    brightnessSection
                    typeSection
                    motionSection
                    densitySection
                    resetSection
                    notesSection
                }
                .padding(.horizontal, style.geometry.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background {
                DLBackgroundView(spec: style.spec, palette: style.palette)
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .tint(style.palette.accent)
                }
            }
        }
        .designLanguage(style)
        .preferredColorScheme(store.preferredScheme)
        .sheet(item: $preview) { language in
            ThemeLanguagePreviewSheet(language: language)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            DLHeader(
                kicker: "One setting",
                title: "Appearance",
                detail: "The theme draws the whole app. The palette you choose lights every theme."
            )

            HStack(spacing: 8) {
                DLLabel(text: "Now showing")
                DLChip(text: store.selected.name, emphasized: true)
                DLChip(text: store.selected.family)
            }
            .padding(.top, 2)
        }
    }

    // MARK: Theme

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(
                title: "Theme",
                index: "01",
                note: "Tap one to preview it first. Nothing changes until you use it."
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(ThemeLanguage.allCases) { language in
                    themeTile(language)
                }
            }
        }
    }

    private func themeTile(_ language: ThemeLanguage) -> some View {
        let selected = store.selected == language
        let lamp = preferences.accent
        let isDark = language.isDark(resolvedDark: store.isDark)
        let spec = language.spec
        let sample = spec.palette(isDark: isDark, accent: lamp)
        let tileStyle = DLStyle(
            language: language,
            isDark: isDark,
            accent: lamp,
            scale: 1,
            density: .compact
        )

        return Button {
            preview = language
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 6) {
                    DLSignatureMark(spec: spec, palette: sample, size: 14)
                    Text(language.number)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(sample.inkFaint)
                    Spacer(minLength: 4)
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(sample.accent)
                    }
                }

                Text(language.name)
                    .font(tileStyle.title(15))
                    .textCase(tileStyle.labelCase)
                    .foregroundStyle(sample.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(language.tagline)
                    .font(tileStyle.body(11))
                    .foregroundStyle(sample.inkSoft)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                SwatchStrip(palette: sample, square: tileStyle.geometry.isSquare)
                    .frame(height: 8)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 106, alignment: .topLeading)
            .background {
                // The tile carries the theme's own field under its surface, so a
                // theme whose field is the palette reads as itself here rather
                // than as a transparent patch on this screen's field.
                ZStack {
                    RoundedRectangle(
                        cornerRadius: tileStyle.geometry.isSquare ? 0 : 12,
                        style: .continuous
                    )
                    .fill(sample.field)

                    RoundedRectangle(
                        cornerRadius: tileStyle.geometry.isSquare ? 0 : 12,
                        style: .continuous
                    )
                    .fill(sample.surface)
                }
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: tileStyle.geometry.isSquare ? 0 : 12,
                    style: .continuous
                )
                .strokeBorder(selected ? sample.accent : sample.line, lineWidth: selected ? 2 : 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(language.name), \(language.family)")
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityHint("Opens a preview")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Palette

    /// The lamp every theme is lit with. One choice, for all thirteen themes.
    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(
                title: "Palette",
                index: "02",
                note: "The lamp every theme is lit with. It applies to every theme."
            )

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 10
            ) {
                ForEach(AccentChoice.allCases) { choice in
                    accentChip(choice)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dlPanel()
    }

    private func accentChip(_ choice: AccentChoice) -> some View {
        let p = style.palette
        let selected = preferences.accent == choice

        return Button {
            preferences.setAccent(choice)
            Haptics.impact(.light)
        } label: {
            VStack(spacing: 5) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [choice.soft, choice.base, choice.deep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                    .overlay {
                        Circle().strokeBorder(
                            selected ? p.ink : p.line,
                            lineWidth: selected ? 2 : 1
                        )
                    }
                    .overlay {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(choice.ink)
                        }
                    }

                Text(choice.title)
                    .font(style.body(10))
                    .foregroundStyle(p.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("\(choice.title) palette")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Brightness

    private var brightnessSection: some View {
        let mode = store.selected.brightnessMode

        return VStack(alignment: .leading, spacing: 10) {
            DLSectionHeader(
                title: "Brightness",
                index: "03",
                note: brightnessNote
            )

            DLSegmented(
                items: DLAppearance.allCases,
                selection: Binding(
                    get: { store.appearance },
                    set: { store.setAppearance($0) }
                )
            ) { $0.title }
            .disabled(mode != .followsSetting)
            .opacity(mode == .followsSetting ? 1 : 0.55)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dlPanel()
    }

    private var brightnessNote: String {
        switch store.selected.brightnessMode {
        case .followsSetting:
            return "The theme follows this, and every panel, rule and ink in it."
        case .alwaysDark:
            return "\(store.selected.name) is drawn dark by its own design. Choose another theme for a light field."
        case .alwaysLight:
            return "\(store.selected.name) is drawn light by its own design: black type on the field is the whole look."
        }
    }

    // MARK: Type

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DLSectionHeader(
                title: "Text size",
                index: "04",
                note: "Scales the type ramp of every theme."
            )

            DLSegmented(
                items: DLTextSize.allCases,
                selection: Binding(
                    get: { store.textSize },
                    set: { store.setTextSize($0) }
                )
            ) { $0.title }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("09:30")
                    .font(style.figure(24, weight: .semibold))
                    .foregroundStyle(style.palette.ink)
                Text("a published time at this size")
                    .font(style.body(12))
                    .foregroundStyle(style.palette.inkSoft)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dlPanel()
    }

    // MARK: Motion

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(
                title: "Motion",
                index: "05",
                note: "How much each theme is allowed to move when it changes."
            )

            DLSegmented(
                items: DLMotionIntensity.allCases,
                selection: Binding(
                    get: { store.motion },
                    set: { store.setMotion($0) }
                )
            ) { $0.title }

            DLSwitch(
                isOn: Binding(
                    get: { store.reducesMotion },
                    set: { store.setReducesMotion($0) }
                ),
                label: "Reduce motion"
            )

            DLNote(text: "The system's Reduce Motion setting is always honoured, whatever is chosen here.")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dlPanel()
    }

    // MARK: Density

    private var densitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DLSectionHeader(
                title: "Interface density",
                index: "06",
                note: "How much room every row, panel and gap takes. Compact also tightens the native controls."
            )

            DLSegmented(
                items: DLDensity.allCases,
                selection: Binding(
                    get: { store.density },
                    set: { store.setDensity($0) }
                )
            ) { $0.title }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dlPanel()
    }

    // MARK: Reset

    private var resetSection: some View {
        Button {
            store.reset()
            preferences.setAccent(.safelight)
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                Text("Reset appearance")
                    .font(style.body(14, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(style.palette.ink)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel()
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Reset appearance")
        .accessibilityHint("Returns to Darkroom, system brightness, the safelight palette and regular density")
    }

    private var notesSection: some View {
        DLNote(
            text: "The theme, palette and density are remembered on this device and used by the next launch, every session and every calculation. A theme never changes what the app does, only how it is presented.",
            symbol: "paintbrush.pointed"
        )
    }
}

// MARK: - Swatches

private struct SwatchStrip: View {
    let palette: DLPalette
    var square: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            swatch(palette.field)
            swatch(palette.surface)
            swatch(palette.accent)
            swatch(palette.ink)
        }
    }

    private func swatch(_ colour: Color) -> some View {
        Group {
            if square {
                Rectangle().fill(colour)
            } else {
                RoundedRectangle(cornerRadius: 2, style: .continuous).fill(colour)
            }
        }
        .overlay {
            Rectangle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
        }
    }
}

// MARK: - Preview

/// A theme shown live: the Develop front door as that theme lays it out, held
/// still so it can be looked at, with the decision underneath it. The palette is
/// the one the reader has chosen.
struct ThemeLanguagePreviewSheet: View {
    let language: ThemeLanguage

    @ObservedObject private var store = ThemeLanguageStore.shared
    @ObservedObject private var preferences = Preferences.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSize

    private var style: DLStyle {
        DLStyle(
            language: language,
            isDark: language.isDark(resolvedDark: store.isDark),
            accent: preferences.accent,
            scale: store.textScale,
            density: store.density
        )
    }

    var body: some View {
        let style = self.style

        ZStack {
            DLBackgroundView(spec: style.spec, palette: style.palette)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(style: style)
                    specimen(style: style)
                    notes(style: style)
                    actions(style: style)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .designLanguage(style)
        .preferredColorScheme(
            language.isDark(resolvedDark: store.isDark) ? .dark : .light
        )
    }

    private func header(style: DLStyle) -> some View {
        HStack(alignment: .top, spacing: 10) {
            DLSignatureMark(spec: style.spec, palette: style.palette, size: 22)

            VStack(alignment: .leading, spacing: 4) {
                DLLabel(text: "Preview")
                Text(language.name)
                    .font(style.display(26))
                    .textCase(style.labelCase)
                    .foregroundStyle(style.palette.ink)
                Text("\(language.family) · \(language.tagline)")
                    .font(style.body(12))
                    .foregroundStyle(style.palette.inkSoft)
            }

            Spacer(minLength: 4)
        }
    }

    private func specimen(style: DLStyle) -> some View {
        DLDevelopScreen()
            .environment(
                \.colorScheme,
                language.isDark(resolvedDark: store.isDark) ? .dark : .light
            )
            .designLanguage(style)
            .frame(width: 393, height: 700)
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(style.palette.line, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
            .frame(maxWidth: .infinity)
            .scaleEffect(horizontalSize == .regular ? 0.86 : 0.80)
            .frame(height: 580)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("A preview of the Develop screen in \(language.name)")
    }

    private func notes(style: DLStyle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(language.detail)
                .font(style.body(13))
                .foregroundStyle(style.palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            DLNote(
                text: "\(language.name) brings its own navigation, layout, type ramp, controls, borders and motion. The app's data and behaviour are unchanged.",
                symbol: "square.3.layers.3d"
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dlPanel()
    }

    private func actions(style: DLStyle) -> some View {
        VStack(spacing: 10) {
            Button {
                store.apply(language)
                dismiss()
            } label: {
                Text(store.selected == language ? "Already in use" : "Use \(language.name)")
            }
            .buttonStyle(DLButtonStyle(role: .primary))
            .disabled(store.selected == language)
            .opacity(store.selected == language ? 0.55 : 1)

            Button {
                dismiss()
            } label: {
                Text("Not now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DLButtonStyle(role: .secondary))
        }
    }
}

#if DEBUG
#Preview {
    ThemeLanguageAppearanceView()
}
#endif
