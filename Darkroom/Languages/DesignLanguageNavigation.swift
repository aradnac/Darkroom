//
//  DesignLanguageNavigation.swift
//  Darkroom
//
//  Twelve ways of moving between the app's five places. The navigation is where
//  a language announces itself first: a floating glass dock, a hairline bar, a
//  Windows pivot, a Material navigation bar, a numbered Swiss rail, hard blocks,
//  a soft tray, a HUD rail, a film strip, a magazine masthead, a switchboard of
//  physical keys, or a terminal prompt.
//
//  Each one is placed where its language would put it: the masthead and the
//  pivot across the top, the Swiss rail down the leading edge, the rest at the
//  foot.
//

import SwiftUI
import UIKit

// MARK: - Tabs

enum DLTab: Int, CaseIterable, Identifiable {
    case develop
    case recipes
    case chemistry
    case journal
    case tools

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .develop: return "Develop"
        case .recipes: return "Recipes"
        case .chemistry: return "Chemistry"
        case .journal: return "Journal"
        case .tools: return "Tools"
        }
    }

    var symbol: String {
        switch self {
        case .develop: return "timer"
        case .recipes: return "books.vertical"
        case .chemistry: return "flask"
        case .journal: return "book.closed"
        case .tools: return "wrench.and.screwdriver"
        }
    }

    var index: String {
        String(format: "%02d", rawValue + 1)
    }

    /// What the terminal calls this place.
    var command: String {
        switch self {
        case .develop: return "dev"
        case .recipes: return "lib"
        case .chemistry: return "chem"
        case .journal: return "log"
        case .tools: return "tools"
        }
    }
}

enum DLNavPlacement: String {
    case top
    case bottom
    case leading
}

// MARK: - Dispatcher

struct DLNavigationBar: View {
    @Binding var selection: DLTab
    let placement: DLNavPlacement

    @Environment(\.dlStyle) private var style

    @ViewBuilder
    var body: some View {
        switch style.spec.nav {
        case .floatingDock:
            DLFloatingDock(selection: $selection)
        case .minimalBar:
            DLMinimalBar(selection: $selection)
        case .fluentPivot:
            DLFluentPivot(selection: $selection, isSidebar: placement == .leading)
        case .materialBar:
            DLMaterialBar(selection: $selection)
        case .swissRail:
            DLSwissRail(selection: $selection)
        case .brutalBlocks:
            DLBrutalBlocks(selection: $selection)
        case .softTray:
            DLSoftTray(selection: $selection)
        case .hudRail:
            DLHudRail(selection: $selection)
        case .filmStrip:
            DLFilmStrip(selection: $selection)
        case .masthead:
            DLMasthead(selection: $selection)
        case .switchboard:
            DLSwitchboard(selection: $selection)
        case .promptBar:
            DLPromptBar(selection: $selection)
        case .flatBar:
            DLFlatBar(selection: $selection)
        }
    }
}

// MARK: - Shared

private struct DLTabButton<Label: View>: View {
    let onSelect: () -> Void
    let label: Label

    init(onSelect: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.onSelect = onSelect
        self.label = label()
    }

    var body: some View {
        Button(action: onSelect) {
            label
                .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
    }
}

private func select(_ tab: DLTab, into selection: Binding<DLTab>, style: DLStyle) {
    guard selection.wrappedValue != tab else { return }
    withAnimation(
        style.spec.motion.animation(
            intensity: ThemeLanguageStore.shared.motion,
            reduced: ThemeLanguageStore.shared.reducesMotion || UIAccessibility.isReduceMotionEnabled
        )
    ) {
        selection.wrappedValue = tab
    }
    Haptics.impact(.light)
}

// MARK: - 01 Liquid Glass

private struct DLFloatingDock: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 2) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(height: 20)
                        Text(tab.title)
                            .font(style.label())
                            .tracking(0.6)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .foregroundStyle(selected ? p.accentInk : p.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        if selected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [p.accent, p.glow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: p.accent.opacity(0.45), radius: 12, x: 0, y: 5)
                        }
                    }
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(p.surface)
            }
        }
        .overlay {
            Capsule().strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(style.isDark ? 0.34 : 0.9), p.line],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        }
        .shadow(color: .black.opacity(style.isDark ? 0.45 : 0.16), radius: 22, x: 0, y: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

// MARK: - 02 Apple Clean

private struct DLMinimalBar: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 0) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 19, weight: selected ? .semibold : .regular))
                            .frame(height: 22)
                        Text(tab.title)
                            .font(.system(size: 10, weight: selected ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .foregroundStyle(selected ? p.ink : p.inkFaint)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 2)
        .background(p.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(p.line)
                .frame(height: style.geometry.borderWidth)
        }
    }
}

// MARK: - 03 Microsoft Fluent

private struct DLFluentPivot: View {
    @Binding var selection: DLTab
    let isSidebar: Bool
    @Namespace private var indicator

    @Environment(\.dlStyle) private var style

    var body: some View {
        if isSidebar {
            sidebar
        } else {
            pivot
        }
    }

    private var pivot: some View {
        let p = style.palette

        return HStack(spacing: 0) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 14, weight: .regular))
                        Text(tab.title)
                            .font(style.body(13, weight: selected ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .foregroundStyle(selected ? p.ink : p.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(p.surfaceAlt)
                                .matchedGeometryEffect(id: "pivot", in: indicator)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if selected {
                            Rectangle()
                                .fill(p.accent)
                                .frame(width: 18, height: 2)
                                .offset(y: 1)
                                .matchedGeometryEffect(id: "underline", in: indicator)
                        }
                    }
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(p.surface.opacity(0.65))
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(p.line).frame(height: 1)
        }
    }

    private var sidebar: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 4) {
            Text("DARKROOM")
                .font(style.label())
                .tracking(1.2)
                .foregroundStyle(p.inkFaint)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(selected ? p.accent : Color.clear)
                            .frame(width: 3)
                        Image(systemName: tab.symbol)
                            .font(.system(size: 14, weight: .regular))
                            .frame(width: 18)
                        Text(tab.title)
                            .font(style.body(13, weight: selected ? .semibold : .regular))
                        Spacer(minLength: 4)
                    }
                    .foregroundStyle(selected ? p.ink : p.inkSoft)
                    .frame(height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(selected ? p.surfaceAlt : Color.clear)
                    }
                    .padding(.horizontal, 6)
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 190)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(p.surface.opacity(0.72))
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(p.line).frame(width: 1)
        }
    }
}

// MARK: - 04 Material 3

private struct DLMaterialBar: View {
    @Binding var selection: DLTab
    @Namespace private var indicator
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 0) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected {
                                Capsule()
                                    .fill(p.surfaceAlt)
                                    .frame(width: 56, height: 30)
                                    .matchedGeometryEffect(id: "pill", in: indicator)
                            }
                            Image(systemName: tab.symbol)
                                .font(.system(size: 17, weight: selected ? .semibold : .regular))
                                .foregroundStyle(selected ? p.accent : p.inkSoft)
                        }
                        .frame(height: 30)

                        Text(tab.title)
                            .font(style.body(11, weight: selected ? .semibold : .medium))
                            .foregroundStyle(selected ? p.ink : p.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 2)
        .background(p.surface)
    }
}

// MARK: - 05 Swiss

private struct DLSwissRail: View {
    @Binding var selection: DLTab
    @Namespace private var indicator
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(spacing: 0) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 4) {
                        Text(tab.index)
                            .font(style.figure(11, weight: .bold))
                            .foregroundStyle(selected ? p.accentInk : p.accent)

                        Image(systemName: tab.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selected ? p.accentInk : p.ink)

                        Text(tab.title.uppercased())
                            .font(style.label())
                            .tracking(1.0)
                            .fixedSize()
                            .rotationEffect(.degrees(-90))
                            .frame(width: 16, height: 62)
                            .foregroundStyle(selected ? p.accentInk : p.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 108)
                    .background {
                        if selected {
                            Rectangle()
                                .fill(p.accent)
                                .matchedGeometryEffect(id: "cell", in: indicator)
                        }
                    }
                }
                .accessibilityLabel("\(tab.title), \(tab.index)")
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 64)
        .background(p.surface)
        .overlay(alignment: .trailing) {
            Rectangle().fill(p.lineStrong).frame(width: 1.5)
        }
    }
}

// MARK: - 06 Brutalist

private struct DLBrutalBlocks: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 0) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .black))
                        Text(tab.title.uppercased())
                            .font(style.label())
                            .tracking(0.4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .foregroundStyle(selected ? p.accentInk : p.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(selected ? p.accent : p.surface)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(p.lineStrong).frame(width: 2)
                    }
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .overlay(alignment: .top) {
            Rectangle().fill(p.lineStrong).frame(height: 3)
        }
        .background(p.surface)
    }
}

// MARK: - 07 Neumorphic

private struct DLSoftTray: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 8) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.title)
                            .font(style.label())
                            .tracking(0.4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .foregroundStyle(selected ? p.accent : p.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selected ? p.surfaceAlt : p.surface)
                    }
                    .shadow(
                        color: (style.isDark ? Color.black : p.lineStrong).opacity(selected ? 0.10 : 0.28),
                        radius: selected ? 2 : 6,
                        x: selected ? 1 : 4,
                        y: selected ? 1 : 4
                    )
                    .shadow(
                        color: (style.isDark ? Color.white : Color.white).opacity(selected ? 0.05 : 0.85),
                        radius: selected ? 2 : 6,
                        x: selected ? -1 : -4,
                        y: selected ? -1 : -4
                    )
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(style.palette.fieldAlt)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - 08 Cyberpunk

private struct DLHudRail: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 3) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 13, weight: .bold))
                            Text(tab.index)
                                .font(style.label())
                                .tracking(0.6)
                        }
                        Text(tab.title.uppercased())
                            .font(style.label())
                            .tracking(0.4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .foregroundStyle(selected ? p.accent : p.inkSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(selected ? p.accent.opacity(0.12) : Color.clear)
                    .overlay {
                        Rectangle()
                            .strokeBorder(selected ? p.accent : p.line.opacity(0.5), lineWidth: 1)
                    }
                    .shadow(color: selected ? p.accent.opacity(0.35) : .clear, radius: 8, x: 0, y: 0)
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(p.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(p.accent.opacity(0.55)).frame(height: 1)
        }
    }
}

// MARK: - 09 Retro Analog

private struct DLFilmStrip: View {
    @Binding var selection: DLTab
    @Namespace private var indicator
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(spacing: 0) {
            DLSprocketStrip(colour: p.accent.opacity(0.5), holes: 22)

            HStack(spacing: 0) {
                ForEach(DLTab.allCases) { tab in
                    let selected = selection == tab

                    DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                        VStack(spacing: 2) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 15, weight: .semibold))
                            Text(tab.title.uppercased())
                                .font(style.label())
                                .tracking(0.8)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                            Text(tab.index)
                                .font(style.figure(8, weight: .medium))
                                .opacity(0.7)
                        }
                        .foregroundStyle(selected ? p.accentInk : p.inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background {
                            if selected {
                                Rectangle()
                                    .fill(p.accent)
                                    .matchedGeometryEffect(id: "cell", in: indicator)
                            }
                        }
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(p.line.opacity(0.8))
                                .frame(width: 1)
                        }
                    }
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }

            DLSprocketStrip(colour: p.accent.opacity(0.5), holes: 22)
        }
        .background(p.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(p.lineStrong).frame(height: 1)
        }
    }
}

// MARK: - 10 Editorial

private struct DLMasthead: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("DARKROOM")
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .tracking(2.6)
                    .foregroundStyle(p.ink)

                Spacer(minLength: 6)

                Text("FILM · CHEMISTRY · NOTES")
                    .font(style.label())
                    .tracking(1.2)
                    .foregroundStyle(p.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            HStack(spacing: 18) {
                ForEach(DLTab.allCases) { tab in
                    let selected = selection == tab

                    DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                        VStack(spacing: 3) {
                            Text(tab.title)
                                .font(.system(size: 14, weight: selected ? .semibold : .regular, design: .serif))
                                .foregroundStyle(selected ? p.ink : p.inkSoft)
                            Rectangle()
                                .fill(selected ? p.accent : Color.clear)
                                .frame(height: 1.5)
                        }
                        .fixedSize()
                    }
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }

                Spacer(minLength: 0)
            }

            Rectangle().fill(p.lineStrong).frame(height: 2)
            Rectangle().fill(p.line).frame(height: 1)
        }
        .padding(.horizontal, style.geometry.pagePadding)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(p.field)
    }
}

// MARK: - 11 Skeuomorphic

private struct DLSwitchboard: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 6) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 15, weight: .bold))
                        Text(tab.title.uppercased())
                            .font(style.label())
                            .tracking(0.6)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .foregroundStyle(selected ? p.accentInk : p.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: selected
                                        ? [p.accent, p.accent.opacity(0.82)]
                                        : [p.surfaceAlt, p.surface, p.fieldAlt],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(p.lineStrong.opacity(0.55), lineWidth: 1)
                    }
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Color.white.opacity(selected ? 0.45 : 0.25), lineWidth: 1)
                            .padding(1)
                    }
                    .shadow(color: .black.opacity(selected ? 0.2 : 0.35), radius: selected ? 2 : 5, x: 0, y: selected ? 1 : 3)
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [p.fieldAlt, p.field],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(p.lineStrong.opacity(0.5), lineWidth: 1)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
    }
}

// MARK: - 12 Terminal

private struct DLPromptBar: View {
    @Binding var selection: DLTab
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(DLTab.allCases) { tab in
                    let selected = selection == tab

                    DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                        HStack(spacing: 3) {
                            Text(selected ? ">" : " ")
                                .font(style.label())
                            Text(tab.command)
                                .font(style.label())
                                .tracking(0.3)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .foregroundStyle(selected ? p.accent : p.inkSoft)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(selected ? p.accent.opacity(0.10) : Color.clear)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(p.line.opacity(0.6)).frame(width: 1)
                        }
                    }
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }

            HStack(spacing: 5) {
                Text(">")
                    .font(style.label())
                    .foregroundStyle(p.accent)
                Text(selection.title.lowercased())
                    .font(style.label())
                    .foregroundStyle(p.ink)
                Rectangle()
                    .fill(p.accent)
                    .frame(width: 6, height: 11)
                    .opacity(0.9)
                Spacer(minLength: 4)
                Text("\(selection.index)/05")
                    .font(style.label())
                    .foregroundStyle(p.inkFaint)
            }
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(p.surfaceAlt)
        }
        .background(p.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(p.lineStrong).frame(height: 1)
        }
    }
}

// MARK: - 13 Recorder

/// The deck's navigation: five labels straight on the field, the current one set
/// in a black chip. No rule, no dock, no tray — the field is the whole screen.
private struct DLFlatBar: View {
    @Binding var selection: DLTab
    @Namespace private var indicator

    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        HStack(spacing: 3) {
            ForEach(DLTab.allCases) { tab in
                let selected = selection == tab

                DLTabButton(onSelect: { select(tab, into: $selection, style: style) }) {
                    Text(tab.title)
                        .font(style.body(13, weight: selected ? .bold : .medium))
                        .foregroundStyle(selected ? p.accentInk : p.ink.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(p.accent)
                                    .matchedGeometryEffect(id: "chip", in: indicator)
                            }
                        }
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(p.field)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(p.line)
                .frame(height: 1)
        }
    }
}

// MARK: - Sprockets

/// The perforated edge of a strip of film, used by the retro language to frame
/// both its navigation and its panels.
struct DLSprocketStrip: View {
    var colour: Color
    var holes: Int = 12
    var height: CGFloat = 9

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<holes, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(colour)
                    .frame(width: 7, height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 3)
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
