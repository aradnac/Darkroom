//
//  Theme13SettingsView.swift
//  Darkroom
//
//  Settings, and the hidden nine-tap path that reveals THE 13TH THEME.
//

import SwiftUI

private struct ThemesRowFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

struct Theme13SettingsView: View {
    @ObservedObject private var store = Theme13SettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingUnlockReveal = false
    @State private var showingPreview = false
    @State private var previewPalette: Theme13PaletteID = .rangefinder
    @State private var themesRowFrame: CGRect = .zero

    private var preferredScheme: ColorScheme {
        guard store.isTheme13Active else { return .dark }
        return store.isDarkAppearance ? .dark : .light
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    themesRow
                    designLanguageSection
                    if store.isTheme13Active {
                        paletteSection
                        appearanceSection
                        motionSection
                    }
                    notesSection

                    #if DEBUG
                    if store.isUnlocked {
                        debugReset
                    }
                    #endif
                }
                .padding(20)
                .padding(.bottom, 28)
            }
            .coordinateSpace(name: "settings")
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    guard themesRowFrame != .zero else { return }
                    if !themesRowFrame.contains(value.location) {
                        store.resetUnlockSequence()
                    }
                }
            )
            .background { LiquidBackdrop() }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if showingUnlockReveal {
                    Theme13UnlockReveal { showingUnlockReveal = false }
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .sheet(isPresented: $showingPreview) { previewSheet }
            .onAppear {
                previewPalette = store.paletteID
                store.updateSystemAppearance(isDark: colorScheme == .dark)
            }
            .onDisappear { store.resetUnlockSequence() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { store.resetUnlockSequence() }
            }
            .onChange(of: colorScheme) { _, scheme in
                store.updateSystemAppearance(isDark: scheme == .dark)
            }
        }
        .tint(Theme.amber)
        .preferredColorScheme(preferredScheme)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            OverlineText(text: "Bench preferences", color: Theme.amber)
            Text("Settings")
                .font(Theme13Type.headline(30))
                .foregroundStyle(Theme.ink)
            Text("How the bench reads, moves and remembers.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    // MARK: The nine-tap row

    private var currentLanguageLabel: String {
        if store.isTheme13Active { return "The 13th Theme" }
        if store.isSoftGlassActive { return "Soft Glass" }
        return "Darkroom"
    }

    private var themesRow: some View {
        Button {
            if store.tapThemes(at: Date()) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showingUnlockReveal = true
                }
            }
        } label: {
            HStack(spacing: 14) {
                Text("01")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.amber)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Themes")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(currentLanguageLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .modifier(Theme13PaperSurface(marked: false))
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Themes")
        .accessibilityHint("Current visual language: \(currentLanguageLabel)")
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ThemesRowFrameKey.self,
                    value: proxy.frame(in: .named("settings"))
                )
            }
        }
        .onPreferenceChange(ThemesRowFrameKey.self) { frame in
            themesRowFrame = frame
        }
    }

    // MARK: Design language

    private var designLanguageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Theme13SectionHeader(index: "02", title: "Design language")

            themeRow(
                identifier: "darkroom",
                title: "Darkroom",
                detail: "Liquid glass, safelight amber",
                systemImage: "moon.stars.fill"
            )

            themeRow(
                identifier: "softglass",
                title: "Soft Glass",
                detail: "White capsules, dot-matrix figures, colour tiles",
                systemImage: "circle.grid.2x2.fill"
            )

            if store.isUnlocked {
                theme13Card
            }
        }
    }

    private func themeRow(identifier: String, title: String, detail: String, systemImage: String) -> some View {
        let selected = store.selectedThemeIdentifier == identifier
        return Button {
            store.selectTheme(identifier)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.amber)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                selectionMark(selected)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .modifier(Theme13PaperSurface(marked: false))
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var theme13Card: some View {
        let selected = store.selectedThemeIdentifier == "theme13"
        let palette = Theme13Palette.palette(previewPalette)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Theme13BurstMark(size: 22, color: palette.accent, seed: 5)
                VStack(alignment: .leading, spacing: 4) {
                    Text("THE 13TH THEME")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(Theme.ink)
                    Text("Analog–digital print collage")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                selectionMark(selected)
            }

            Theme13PreviewPlate(palette: palette, compact: true)

            HStack(spacing: 10) {
                Button("Preview") { showingPreview = true }
                    .buttonStyle(GlassCapsuleStyle(height: 44))

                Button {
                    store.selectTheme("theme13")
                } label: {
                    Text(selected ? "Applied" : "Use theme")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AmberCapsuleStyle(height: 44))
                .disabled(selected)
                .opacity(selected ? 0.55 : 1)
            }
        }
        .padding(16)
        .modifier(Theme13PaperSurface())
    }

    private func selectionMark(_ selected: Bool) -> some View {
        Group {
            if selected {
                Theme13BurstMark(size: 16, color: Theme.amber, seed: 3)
            } else {
                Circle()
                    .strokeBorder(Theme.inkFaint, lineWidth: 1.2)
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Palettes

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Theme13SectionHeader(index: "03", title: "Print palettes")
            Text("Nine fields. One interruption each.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(Theme13Palette.all) { palette in
                    paletteChip(palette)
                }
            }
        }
    }

    private func paletteChip(_ palette: Theme13Palette) -> some View {
        let selected = palette.id == store.paletteID
        return Button {
            store.selectPalette(palette.id)
            previewPalette = palette.id
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 3) {
                    swatch(palette.background)
                    swatch(palette.accent)
                    swatch(palette.primaryText)
                    swatch(palette.decoration.count > 2 ? palette.decoration[2] : palette.accent2)
                }
                .frame(height: 16)

                Text(palette.name)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Rectangle()
                    .fill(selected ? palette.accent : palette.border.opacity(0.25))
                    .frame(height: selected ? 3 : 1)
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topLeading) {
                if selected {
                    Rectangle().fill(palette.border).offset(x: 3, y: 3)
                }
            }
            .background(palette.surface)
            .overlay(Rectangle().stroke(palette.border, lineWidth: selected ? 1.5 : 0.9))
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(palette.name) palette")
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func swatch(_ color: Color) -> some View {
        Rectangle()
            .fill(color)
            .overlay(Rectangle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Theme13SectionHeader(index: "04", title: "Appearance")

            VStack(alignment: .leading, spacing: 14) {
                Text("Brightness")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Picker("Brightness", selection: Binding(
                    get: { store.appearanceMode },
                    set: { store.selectAppearance($0) }
                )) {
                    ForEach(Theme13AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("Text size")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Picker("Text size", selection: Binding(
                    get: { store.textSize },
                    set: { store.setTextSize($0) }
                )) {
                    ForEach(Theme13TextSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: Binding(
                    get: { store.compactControls },
                    set: { store.setCompactControls($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compact controls")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Tighter rows and shorter buttons.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .tint(Theme.amber)
            }
            .padding(16)
            .modifier(Theme13PaperSurface(marked: false))
        }
    }

    // MARK: Motion

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Theme13SectionHeader(index: "05", title: "Motion")

            VStack(alignment: .leading, spacing: 14) {
                Picker("Animation intensity", selection: Binding(
                    get: { store.motion },
                    set: { store.setMotion($0) }
                )) {
                    ForEach(Theme13MotionIntensity.allCases) { intensity in
                        Text(intensity.title).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: Binding(
                    get: { store.stillMode },
                    set: { store.setStillMode($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Still mode")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Freezes grain, wiggle and the print field.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .tint(Theme.amber)

                Text("Reduce Motion is always honoured, whatever is chosen here.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .modifier(Theme13PaperSurface(marked: false))
        }
    }

    // MARK: Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Theme13SectionHeader(index: "06", title: "Notes")
            Text("Display type, tracked labels and mono figures all scale with the text size above. Your choices are remembered on this device.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Preview sheet

    private var previewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Theme13PreviewPlate(palette: Theme13Palette.palette(previewPalette))

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(Theme13Palette.all) { palette in
                            Button {
                                previewPalette = palette.id
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 2) {
                                        swatch(palette.background)
                                        swatch(palette.accent)
                                    }
                                    .frame(height: 14)
                                    Text(palette.name)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(palette.primaryText)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(palette.surface)
                                .overlay(
                                    Rectangle().stroke(
                                        palette.border,
                                        lineWidth: previewPalette == palette.id ? 1.8 : 0.8
                                    )
                                )
                            }
                            .buttonStyle(HapticButtonStyle())
                        }
                    }

                    Text("Nothing is applied until you use it.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)

                    Button {
                        store.selectPalette(previewPalette)
                        store.selectTheme("theme13")
                        showingPreview = false
                    } label: {
                        Text("Use this palette")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AmberCapsuleStyle())
                }
                .padding(20)
            }
            .background { LiquidBackdrop() }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showingPreview = false }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(preferredScheme)
    }

    // MARK: QA

    #if DEBUG
    private var debugReset: some View {
        Button(role: .destructive) {
            store.resetUnlockForQA()
        } label: {
            Label("Reset hidden-theme unlock (QA)", systemImage: "arrow.counterclockwise")
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(HapticButtonStyle())
        .foregroundStyle(Theme.inkSoft)
        .padding(15)
        .modifier(Theme13PaperSurface(marked: false))
    }
    #endif
}
