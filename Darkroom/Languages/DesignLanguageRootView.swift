//
//  DesignLanguageRootView.swift
//  Darkroom
//
//  The root of a design language: the field behind it, the navigation its own
//  paradigm asks for, and the five places inside it. Changing theme cross-fades
//  the whole root. Moving between places plays the language's own page motion,
//  from the side the move came from.
//

import SwiftUI

struct ThemeLanguageRootView: View {
    @ObservedObject private var store = ThemeLanguageStore.shared
    /// Observed so a new palette re-lights this root.
    @ObservedObject private var preferences = Preferences.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @Environment(\.colorScheme) private var systemScheme

    @State private var tab: DLTab = .develop
    /// Which way the last move went, so a page enters from the side it came from.
    @State private var movingForward = true
    @State private var appeared = false

    private var style: DLStyle { DLStyle(store: store) }

    private var placement: DLNavPlacement {
        switch style.spec.nav {
        case .masthead:
            return .top
        case .fluentPivot:
            return horizontalSize == .regular ? .leading : .top
        case .swissRail:
            return .leading
        default:
            return .bottom
        }
    }

    /// The navigation writes through this binding, so the direction of a move is
    /// recorded in the same transaction as the move it belongs to.
    private var selection: Binding<DLTab> {
        Binding(
            get: { tab },
            set: { next in
                movingForward = next.rawValue > tab.rawValue
                tab = next
            }
        )
    }

    var body: some View {
        let style = self.style

        ZStack {
            DLBackgroundView(spec: style.spec, palette: style.palette)

            framed(pages, style: style)
                .opacity(appeared ? 1 : 0)
        }
        // A new theme is a new tree: the old one cross-fades out while the new one
        // fades in, instead of being swapped in place.
        .id(store.selected)
        .transition(.opacity)
        .designLanguage(style)
        .preferredColorScheme(store.preferredScheme)
        .sheet(isPresented: appearanceBinding) {
            ThemeLanguageAppearanceView()
        }
        .onAppear {
            store.updateSystemAppearance(isDark: systemScheme == .dark)
            guard !appeared else { return }
            withAnimation(
                store.animation(style.spec.motion, reducedBySystem: reduceMotion)
            ) {
                appeared = true
            }
        }
        .onChange(of: systemScheme) { _, value in
            store.updateSystemAppearance(isDark: value == .dark)
        }
    }

    private var appearanceBinding: Binding<Bool> {
        Binding(
            get: { store.isShowingAppearance },
            set: { store.isShowingAppearance = $0 }
        )
    }

    // MARK: Pages

    /// The current place, carried in on the theme's own page motion. Clipped so a
    /// sliding page never shows outside the screen.
    private var pages: some View {
        ZStack {
            content
                .id(tab)
                .transition(store.selected.pageMotion.transition(forward: movingForward))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .develop:
            DLDevelopScreen()
        case .recipes:
            RecipesView()
        case .chemistry:
            ChemistryView()
        case .journal:
            JournalView()
        case .tools:
            ToolsView()
        }
    }

    // MARK: Navigation placement

    @ViewBuilder
    private func framed<Content: View>(_ content: Content, style: DLStyle) -> some View {
        switch placement {
        case .top:
            content.safeAreaInset(edge: .top, spacing: 0) {
                DLNavigationBar(selection: selection, placement: .top)
            }
        case .bottom:
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                DLNavigationBar(selection: selection, placement: .bottom)
            }
        case .leading:
            content.safeAreaInset(edge: .leading, spacing: 0) {
                DLNavigationBar(selection: selection, placement: .leading)
            }
        }
    }
}

// MARK: - Page motion

/// How a theme moves between its five places. Each is the theme's own vocabulary:
/// Material's shared axis, a plain slide, a printed drift, a press-like lift, a
/// strip advancing, or a hard cut.
enum DLPageMotion {
    /// Material's shared-axis move: a clear slide with a fade.
    case sharedAxis
    /// A small slide with a fade, for the calmer languages.
    case slide
    /// A fade with a little drift, for the printed languages.
    case drift
    /// The page grows out of a press.
    case lift
    /// A hard edge: a strip advancing, a rail sliding, with no fade.
    case edge
    /// No motion: the new place replaces the old one at once.
    case cut

    func transition(forward: Bool) -> AnyTransition {
        let direction: CGFloat = forward ? 1 : -1
        switch self {
        case .sharedAxis:
            return .asymmetric(
                insertion: .offset(x: 56 * direction).combined(with: .opacity),
                removal: .offset(x: -56 * direction).combined(with: .opacity)
            )
        case .slide:
            return .asymmetric(
                insertion: .offset(x: 26 * direction).combined(with: .opacity),
                removal: .offset(x: -26 * direction).combined(with: .opacity)
            )
        case .drift:
            return .opacity.combined(with: .offset(y: 12))
        case .lift:
            return .scale(scale: 0.96).combined(with: .opacity)
        case .edge:
            return .asymmetric(
                insertion: .move(edge: forward ? .trailing : .leading),
                removal: .move(edge: forward ? .leading : .trailing)
            )
        case .cut:
            return .identity
        }
    }
}

extension ThemeLanguage {
    /// The motion a theme uses between its places.
    var pageMotion: DLPageMotion {
        switch self {
        case .darkroom, .softLight, .appleClean, .fluent: return .slide
        case .material3: return .sharedAxis
        case .swiss, .retroAnalog: return .edge
        case .brutalist, .cyberpunk, .terminal: return .cut
        case .neumorphic, .skeuomorphic: return .lift
        case .editorial: return .drift
        case .recorder: return .slide
        }
    }
}

#if DEBUG
#Preview {
    ThemeLanguageRootView()
}
#endif
