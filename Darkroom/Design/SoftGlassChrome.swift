//
//  SoftGlassChrome.swift
//  Darkroom
//
//  The soft-glass navigation: a floating capsule dock at the foot of the app and
//  a quiet translucent header at the top of each tab. Both exist only while the
//  soft-glass language is active; the darkroom keeps the system chrome.
//

import SwiftUI

// MARK: - Tabs

struct SoftGlassTab: Identifiable {
    let id: Int
    let title: String
    let symbol: String

    static let all: [SoftGlassTab] = [
        SoftGlassTab(id: 0, title: "Develop", symbol: "timer"),
        SoftGlassTab(id: 1, title: "Recipes", symbol: "books.vertical"),
        SoftGlassTab(id: 2, title: "Chemistry", symbol: "flask"),
        SoftGlassTab(id: 3, title: "Journal", symbol: "book.closed"),
        SoftGlassTab(id: 4, title: "Tools", symbol: "wrench.and.screwdriver")
    ]
}

/// A floating capsule dock: five circular targets on frosted glass, the active
/// one a solid white disc with black ink.
struct SoftGlassTabBar: View {
    @Binding var selection: Int

    /// The dock's full height — icon row, its own vertical padding and the
    /// small lift above the home indicator. The edge fade behind it is sized
    /// from this, so keep the two in step if the layout changes.
    static let height: CGFloat = 64

    /// One disc for the whole dock, so it slides between tabs instead of
    /// blinking off in one place and on in another.
    @Namespace private var disc

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SoftGlassTab.all) { tab in
                let selected = selection == tab.id

                Button {
                    guard selection != tab.id else { return }
                    withAnimation(.spring(response: 0.40, dampingFraction: 0.76)) {
                        selection = tab.id
                    }
                } label: {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(selected ? Color.black : Color.white.opacity(0.55))
                        .frame(width: 48, height: 48)
                        .background {
                            if selected {
                                Circle()
                                    .fill(.white)
                                    .matchedGeometryEffect(id: "disc", in: disc)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            Capsule().fill(.ultraThinMaterial)
            Capsule().fill(Color.white.opacity(0.06))
        }
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 14, x: 0, y: 8)
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Header

/// Metrics the chrome's edge fades size themselves from. Kept out of the generic
/// bar types, which cannot hold static stored properties.
enum SoftGlassBarMetrics {
    static let topBarHeight: CGFloat = 52
}

/// The quiet header at the top of a soft-glass screen: an optional outlined
/// circle at the leading edge, a centred small title, an optional action.
struct SoftGlassTopBar<Accessory: View>: View {
    let title: String
    let accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(1)

            Spacer(minLength: 0)

            accessory
        }
        .padding(.horizontal, 20)
        .frame(height: SoftGlassBarMetrics.topBarHeight)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            TopEdgeFade()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// The fade behind the header: real variable blur plus a scrim, running from
/// the physical top of the display down past the bar, easing to nothing. It is
/// anchored top-aligned to the bar and offset up by the status inset on
/// purpose — a plain `.background` would centre the taller backdrop on the bar
/// and leave the band straddling the screen, and any offset without the
/// alignment makes that worse.
private struct TopEdgeFade: View {
    /// How far past the bar the fade keeps easing. Small on purpose: at rest
    /// the top of the content sits inside this zone, so the blur and scrim
    /// must already be near zero here to stay invisible until something
    /// actually scrolls under the bar.
    static let feather: CGFloat = 40

    var body: some View {
        let top = ScreenInsets.top
        let height = top + SoftGlassBarMetrics.topBarHeight + Self.feather

        return ZStack {
            ProgressiveBlur(edge: .top, height: height, maxBlurRadius: 18)
            LinearGradient(
                stops: [
                    .init(color: SoftGlassTheme.background.opacity(0.60), location: 0),
                    .init(color: SoftGlassTheme.background.opacity(0.45), location: 0.30),
                    .init(color: SoftGlassTheme.background.opacity(0.26), location: 0.55),
                    .init(color: SoftGlassTheme.background.opacity(0.10), location: 0.78),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .offset(y: -top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Chrome

struct SoftGlassNavigationChrome<Accessory: View>: ViewModifier {
    let title: String
    let accessory: Accessory

    @ObservedObject private var appearance = AppearanceStore.shared

    @ViewBuilder
    func body(content: Content) -> some View {
        if appearance.isSoftGlassActive {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top, spacing: 0) {
                    SoftGlassTopBar(title: title, accessory: accessory)
                }
        } else {
            content.navigationTitle(title)
        }
    }
}

/// Chooses the right chrome for the active language: the soft-glass header, or
/// the system navigation title.
struct AppNavigationChrome<Accessory: View>: ViewModifier {
    let title: String
    let accessory: Accessory

    @ObservedObject private var appearance = AppearanceStore.shared

    /// How far the content's bottom sits above the physical bottom of the
    /// display. The bottom fade has to start from the edge of the glass, not
    /// from the edge of the safe area, or the home-indicator strip below it
    /// stays sharp.
    @State private var bottomInset: CGFloat = 0

    @ViewBuilder
    func body(content: Content) -> some View {
        if appearance.isSoftGlassActive {
            content.softGlassNavigationChrome(title: title) { accessory }
        } else {
            content
                .navigationTitle(title)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { bottomInset = proxy.safeAreaInsets.bottom }
                            .onChange(of: proxy.safeAreaInsets.bottom) { _, inset in
                                bottomInset = inset
                            }
                    }
                }
                .overlay(alignment: .top) {
                    ScreenEdgeFade(
                        edge: .top,
                        color: Theme.base,
                        height: ScreenInsets.top + 96
                    )
                    .ignoresSafeArea(edges: .top)
                }
                // Bottom-aligned inside the safe area, the band's extra height
                // grew upward: its opaque end sat at the safe-area edge, above
                // the home indicator, leaving an unfaded strip under it. Shifting
                // it down by that inset puts the opaque end on the glass, and the
                // height is measured from there so the fade reads as long as it
                // did before.
                .overlay(alignment: .bottom) {
                    ScreenEdgeFade(
                        edge: .bottom,
                        color: Theme.base,
                        height: bottomInset + 120
                    )
                    .offset(y: bottomInset)
                    .ignoresSafeArea(edges: .bottom)
                }
        }
    }
}

// MARK: - Screen action

/// The action a screen puts in its own header, drawn in whatever language is
/// active. The darkroom leaves it to the system toolbar, so this draws nothing.
struct AppBarButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    @ObservedObject private var appearance = AppearanceStore.shared

    @ViewBuilder
    var body: some View {
        if appearance.isSoftGlassActive {
            SoftGlassIconButton(systemImage: symbol, size: 38, action: action)
                .accessibilityLabel(label)
        }
    }
}

// MARK: - System chrome

/// Stops the system tab bar drawing underneath the soft-glass dock. Inert in
/// the darkroom, which keeps the glass tab bar.
struct AppHidesSystemTabBar: ViewModifier {
    @ObservedObject private var appearance = AppearanceStore.shared

    @ViewBuilder
    func body(content: Content) -> some View {
        if appearance.isSoftGlassActive {
            content.toolbar(.hidden, for: .tabBar)
        } else {
            content
        }
    }
}

extension View {
    func softGlassNavigationChrome(title: String) -> some View {
        modifier(SoftGlassNavigationChrome(title: title, accessory: EmptyView()))
    }

    func softGlassNavigationChrome<Accessory: View>(
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        modifier(SoftGlassNavigationChrome(title: title, accessory: accessory()))
    }

    func appNavigationChrome(title: String) -> some View {
        modifier(AppNavigationChrome(title: title, accessory: EmptyView()))
    }

    func appNavigationChrome<Accessory: View>(
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        modifier(AppNavigationChrome(title: title, accessory: accessory()))
    }

    func appHidesSystemTabBar() -> some View {
        modifier(AppHidesSystemTabBar())
    }
}
