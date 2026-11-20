//
//  ContentView.swift
//  Darkroom
//
//  The five main tabs. Each tab's own screen lives in its feature folder.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared
    @Environment(\.colorScheme) private var colorScheme

    /// Held here, outside the re-identified tab stack, so switching the visual
    /// language never throws the reader back to the first tab.
    @State private var selection = 0

    private var preferredScheme: ColorScheme? {
        guard themeStore.isTheme13Active else { return .dark }
        return themeStore.isDarkAppearance ? .dark : .light
    }

    private var settingsBinding: Binding<Bool> {
        Binding(
            get: { themeStore.isShowingSettings },
            set: { themeStore.isShowingSettings = $0 }
        )
    }

    /// How far above the dock the fade keeps easing. Kept short so the ramp is
    /// nearly complete by the top of the capsule — the same shape the header
    /// fade has, where almost all of the blur lands at the edge of the display
    /// and the fade is already gentle over content.
    private static let dockFeather: CGFloat = 24

    /// The dock's edge fade: real variable blur plus a scrim, running from the
    /// physical bottom of the display up past the capsule and easing to
    /// nothing. It sits in the dock's full-width layer, bottom-aligned, and is
    /// offset down by the home-indicator inset so it starts at the true edge of
    /// the display — spanning the whole screen, not just the capsule.
    private var dockBand: some View {
        let bottom = ScreenInsets.bottom
        let height = bottom + SoftGlassTabBar.height + Self.dockFeather

        return ZStack {
            ProgressiveBlur(edge: .bottom, height: height, maxBlurRadius: 15)
            LinearGradient(
                stops: [
                    .init(color: SoftGlassTheme.background.opacity(0.55), location: 0),
                    .init(color: SoftGlassTheme.background.opacity(0.36), location: 0.30),
                    .init(color: SoftGlassTheme.background.opacity(0.15), location: 0.60),
                    .init(color: SoftGlassTheme.background.opacity(0.05), location: 0.82),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .offset(y: bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    var body: some View {
        Group {
            if themeStore.isRedroomActive {
                RedroomRootView()
            } else {
                ZStack {
                    TabView(selection: $selection) {
                        Tab("Develop", systemImage: "timer", value: 0) {
                            DevelopHomeView()
                                .appHidesSystemTabBar()
                        }

                        Tab("Recipes", systemImage: "books.vertical", value: 1) {
                            RecipesView()
                                .appHidesSystemTabBar()
                        }

                        Tab("Chemistry", systemImage: "flask", value: 2) {
                            ChemistryView()
                                .appHidesSystemTabBar()
                        }

                        Tab("Journal", systemImage: "book.closed", value: 3) {
                            JournalView()
                                .appHidesSystemTabBar()
                        }

                        Tab("Tools", systemImage: "wrench.and.screwdriver", value: 4) {
                            ToolsView()
                                .appHidesSystemTabBar()
                        }
                    }
                    .tint(Theme.amber)
                    .environment(\.controlSize, themeStore.compactControls ? .small : .regular)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if themeStore.isTheme13Active {
                            Theme13TabBar(selection: $selection)
                        } else if themeStore.isSoftGlassActive {
                            // The fade and the capsule share one full-width layer. A
                            // background on the capsule alone would inherit the
                            // capsule's own width and leave the edges of the screen
                            // uncovered — the bug this replaced.
                            ZStack(alignment: .bottom) {
                                dockBand
                                SoftGlassTabBar(selection: $selection)
                            }
                            .frame(height: SoftGlassTabBar.height)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .id(themeStore.revision)
                }
                .buttonStyle(HapticButtonStyle())
                .preferredColorScheme(preferredScheme)
            }
        }
        .sheet(isPresented: settingsBinding) {
            if themeStore.isRedroomActive {
                RedroomSettingsView()
            } else {
                Theme13SettingsView()
            }
        }
        .onAppear {
            themeStore.updateSystemAppearance(isDark: colorScheme == .dark)
            Theme13Chrome.apply(themeStore)
        }
        .onChange(of: colorScheme) { _, scheme in
            themeStore.updateSystemAppearance(isDark: scheme == .dark)
            Theme13Chrome.apply(themeStore)
        }
        .onChange(of: themeStore.revision) { _, _ in
            Theme13Chrome.apply(themeStore)
        }
    }
}

#Preview {
    ContentView()
}
