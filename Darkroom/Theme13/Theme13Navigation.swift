//
//  Theme13Navigation.swift
//  Darkroom
//
//  THE 13TH THEME's own navigation layer: a numbered specimen strip where the
//  system navigation bar would be, and a film-strip tab bar where the system tab
//  bar would be. Both are drawn by the app, so the theme never shows a glass
//  control. The darkroom keeps the system's Liquid Glass untouched — nothing here
//  renders unless the print theme is active.
//

import SwiftUI
import UIKit

// MARK: - Tabs

/// One tab of the app, numbered the way a specimen sheet numbers its plates.
struct Theme13Tab: Identifiable, Hashable {
    let number: String
    let title: String

    var id: String { number }

    static let all: [Theme13Tab] = [
        Theme13Tab(number: "01", title: "Develop"),
        Theme13Tab(number: "02", title: "Recipes"),
        Theme13Tab(number: "03", title: "Chemistry"),
        Theme13Tab(number: "04", title: "Journal"),
        Theme13Tab(number: "05", title: "Tools")
    ]
}

// MARK: - Tab bar

/// The navigation strip at the foot of the app: tracked uppercase labels with
/// their numbers, a film-strip indicator and a burst on the active plate. Flat
/// paper, a 1.5pt ink hairline above it, and a 44pt target for every tab.
struct Theme13TabBar: View {
    @Binding var selection: Int

    @ObservedObject private var store = Theme13SettingsStore.shared

    var body: some View {
        let palette = store.palette
        let dark = store.isDarkAppearance
        let ink = palette.ink(isDark: dark)
        let quiet = palette.inkAlt(isDark: dark)

        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(Theme13Tab.all.enumerated()), id: \.offset) { offset, tab in
                let selected = selection == offset

                Button {
                    guard selection != offset else { return }
                    selection = offset
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            Text(tab.number)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .tracking(1.0)

                            if selected {
                                Theme13BurstMark(size: 7, color: palette.accent, seed: offset &+ 3)
                            }
                        }
                        .foregroundStyle(selected ? palette.accentText : quiet)
                        .frame(height: 9)

                        Text(tab.title.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.9)
                            .foregroundStyle(selected ? ink : quiet)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)

                        Theme13SprocketRow(
                            color: selected ? palette.accent : palette.rule(isDark: dark).opacity(0.55),
                            holeCount: 4,
                            holeWidth: 4,
                            holeHeight: 3,
                            spacing: 2
                        )
                        .frame(width: 24)
                        .opacity(selected ? 1 : 0.6)
                    }
                    .padding(.top, 7)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityLabel("\(tab.title), plate \(tab.number)")
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 2)
        .background(alignment: .top) {
            Rectangle()
                .fill(palette.plate(isDark: dark))
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(palette.stroke(isDark: dark))
                .frame(height: 1.5)
        }
        .overlay(alignment: .topLeading) {
            Rectangle()
                .fill(palette.accent)
                .frame(width: 46, height: 3)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Specimen bar

/// The strip that stands in for the system navigation bar: plate number, rule,
/// the screen's name with one interruption, the date as a corner micro-label, and
/// whatever action the screen needs. Flat paper, one hairline, no blur.
struct Theme13SpecimenBar<Accessory: View>: View {
    let index: String
    let title: String
    let accessory: Accessory

    @ObservedObject private var store = Theme13SettingsStore.shared

    var body: some View {
        let palette = store.palette
        let dark = store.isDarkAppearance
        let ink = palette.ink(isDark: dark)
        let quiet = palette.inkAlt(isDark: dark)

        HStack(spacing: 10) {
            Text(index)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(palette.accentText)
                .frame(width: 16, alignment: .leading)

            Rectangle()
                .fill(palette.rule(isDark: dark))
                .frame(width: 1, height: 15)

            HStack(spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .tracking(2.1)
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Theme13BurstMark(size: 9, color: palette.accent, seed: 6)
            }

            Spacer(minLength: 6)

            Text(Self.dateLabel)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(quiet)

            accessory
        }
        .padding(.horizontal, 20)
        .frame(height: 46)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Rectangle()
                .fill(palette.plate(isDark: dark))
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.stroke(isDark: dark))
                .frame(height: 1.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }

    private static var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: Date())
    }
}

// MARK: - Bar action

/// A square inked plate for an action inside the specimen strip. The mark is
/// small, the target is 44 × 44.
struct Theme13BarButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    @ObservedObject private var store = Theme13SettingsStore.shared

    var body: some View {
        let palette = store.palette
        let dark = store.isDarkAppearance

        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(palette.plateRaised(isDark: dark))
                Rectangle()
                    .strokeBorder(palette.stroke(isDark: dark), lineWidth: 1.5)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(palette.ink(isDark: dark))
            }
            .frame(width: 38, height: 30)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - Chrome

/// Swaps a screen's system navigation bar for the theme's specimen strip while
/// the print theme is active, and leaves the system bar and title alone otherwise.
struct Theme13NavigationChrome<Accessory: View>: ViewModifier {
    let index: String
    let title: String
    let accessory: Accessory

    @ObservedObject private var store = Theme13SettingsStore.shared

    @ViewBuilder
    func body(content: Content) -> some View {
        if store.isTheme13Active {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Theme13SpecimenBar(index: index, title: title, accessory: accessory)
                }
        } else {
            content.navigationTitle(title)
        }
    }
}

/// Stops the system tab bar drawing underneath the theme's own strip. Inert in
/// the darkroom, which keeps the glass tab bar.
struct Theme13HidesSystemTabBar: ViewModifier {
    @ObservedObject private var store = Theme13SettingsStore.shared

    @ViewBuilder
    func body(content: Content) -> some View {
        if store.isTheme13Active {
            content.toolbar(.hidden, for: .tabBar)
        } else {
            content
        }
    }
}

extension View {
    /// The print theme's navigation chrome for a screen with no strip action.
    func theme13NavigationChrome(index: String, title: String) -> some View {
        modifier(Theme13NavigationChrome(index: index, title: title, accessory: EmptyView()))
    }

    /// The same chrome, carrying the screen's own action in the strip.
    func theme13NavigationChrome<Accessory: View>(
        index: String,
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        modifier(Theme13NavigationChrome(index: index, title: title, accessory: accessory()))
    }

    func theme13HidesSystemTabBar() -> some View {
        modifier(Theme13HidesSystemTabBar())
    }
}
