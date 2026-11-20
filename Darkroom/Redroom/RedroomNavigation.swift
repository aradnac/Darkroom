//
//  RedroomNavigation.swift
//  Darkroom
//
//  The third design language's navigation layer. The app's five places are five
//  developing trays on a black bench: a pressed-steel rail at the foot of the
//  room, each tray with its own lamp, the lit one standing a little proud of the
//  bench. Above them, a room header — engraved caption, tracked room name and a
//  hairline whose brightness falls off from the safelight.
//
//  Nothing here draws system chrome: no navigation bar, no tab bar, no glass.
//

import SwiftUI

// MARK: - Tabs

enum RedroomTab: Int, CaseIterable, Identifiable {
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

    /// Stamped into the bench beside the lamp.
    var plate: String {
        String(format: "%02d", rawValue + 1)
    }
}

// MARK: - Tab bar

/// The bench rail: five trays, each with a pilot lamp, the active one lit and
/// raised. The rail itself is glass, so its rim answers the safelight like every
/// other surface in the room.
struct RedroomTabBar: View {
    @Binding var selection: RedroomTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(RedroomTab.allCases) { tab in
                RedroomTabTray(
                    tab: tab,
                    selected: selection == tab,
                    action: {
                        guard selection != tab else { return }
                        Haptics.impact(.light)
                        withAnimation(.snappy(duration: 0.32, extraBounce: 0.05)) {
                            selection = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 3)
        .background {
            Color.clear
                .redroomGlass(variant: .frosted, cornerRadius: 0)
                .ignoresSafeArea(edges: .bottom)
        }
        .accessibilityElement(children: .contain)
    }
}

/// One tray: the pilot lamp, the tool's mark, its name stamped into the metal.
private struct RedroomTabTray: View {
    let tab: RedroomTab
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                RedroomIndicator(on: selected, size: 5)

                Image(systemName: tab.symbol)
                    .font(.system(size: selected ? 18 : 16, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Redroom.text : Redroom.textMuted)
                    .frame(height: 21)

                Text(tab.title.uppercased())
                    .font(Redroom.label(8))
                    .tracking(0.9)
                    .foregroundStyle(selected ? Redroom.text : Redroom.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.clear)
                        .redroomGlass(variant: .optical, cornerRadius: 14)
                } else {
                    Color.clear
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Headers

/// A room header: the engraved caption above the room's name, with the hairline
/// under it that the safelight lights from its own end.
struct RedroomScreenHeader: View {
    let kicker: String
    let title: String
    var actionSymbol: String?
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    RedroomLabel(kicker)

                    Text(title.uppercased())
                        .font(Redroom.display(24, weight: .bold))
                        .tracking(2.4)
                        .foregroundStyle(Redroom.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                if let actionSymbol, let action {
                    Button(action: action) {
                        Image(systemName: actionSymbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                            .frame(width: 44, height: 44)
                            .background {
                                Color.clear.redroomGlass(variant: .transparent, cornerRadius: 14)
                            }
                    }
                    .buttonStyle(HapticButtonStyle())
                    .accessibilityLabel(actionLabel ?? title)
                }
            }

            RedroomLitRule()
        }
    }
}

/// A detail screen's header. It carries the way back, because the room hides
/// the system bar, and the plate the screen came from.
struct RedroomDetailHeader: View {
    let kicker: String
    let title: String
    var actionSymbol: String?
    var actionLabel: String?
    var action: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                        .frame(width: 44, height: 44)
                        .background {
                            Color.clear.redroomGlass(variant: .transparent, cornerRadius: 14)
                        }
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 3) {
                    RedroomLabel(kicker)

                    Text(title.uppercased())
                        .font(Redroom.display(19, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(Redroom.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                if let actionSymbol, let action {
                    Button(action: action) {
                        Image(systemName: actionSymbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                            .frame(width: 44, height: 44)
                            .background {
                                Color.clear.redroomGlass(variant: .transparent, cornerRadius: 14)
                            }
                    }
                    .buttonStyle(HapticButtonStyle())
                    .accessibilityLabel(actionLabel ?? title)
                }
            }

            RedroomLitRule()
        }
        .padding(.horizontal, RedroomMetrics.screenPadding)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

// MARK: - The room a screen is built in

/// The body of every screen: the room behind it, the scroll, and the padding
/// the theme uses. The safelight lives at the root; this is the bench.
struct RedroomScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(.horizontal, RedroomMetrics.screenPadding)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - A rule the safelight lights

/// A hairline that reads the room: bright under the lamp, deep red at the foot.
struct RedroomLitRule: View {
    var thickness: CGFloat = 1

    @Environment(\.redroomLight) private var light
    @State private var frame: CGRect = .zero

    var body: some View {
        let sample = RedroomLightSample.make(frame: frame, light: light)

        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Redroom.safelight.opacity(0.42 * sample.direct + 0.05),
                        Redroom.deepRed.opacity(0.45),
                        Redroom.deepRed.opacity(0.18)
                    ],
                    startPoint: sample.start,
                    endPoint: sample.end
                )
            )
            .frame(height: thickness)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { value in
                frame = value
            }
            .accessibilityHidden(true)
    }
}
