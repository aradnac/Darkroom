//
//  RedroomTransitions.swift
//  Darkroom
//
//  The room's four movements. Everything that arrives in REDROOM arrives one of
//  four ways, and nothing arrives with a system cross-fade:
//
//    • Safelight Fade   — a surface warming up under the lamp, out of the dark.
//    • Chemical Immersion — the screen rising out of the sump, through the
//      surface of the chemistry.
//    • Film Strip       — a strip drawn through the gate, gate bars either side.
//    • Enlarger Shutter — the print appearing as the blades open.
//
//  Each is a real effect with a resting state: with Reduce Motion on, the
//  element is placed, opaque and in position, and only a plain, short fade
//  remains. No transition moves further than 30 pt or scales past 4%.
//

import SwiftUI

// MARK: - Kinds

enum RedroomTransitionKind: String, CaseIterable, Identifiable {
    case safelightFade
    case immersion
    case filmStrip
    case shutter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safelightFade: return "Safelight fade"
        case .immersion: return "Chemical immersion"
        case .filmStrip: return "Film strip"
        case .shutter: return "Enlarger shutter"
        }
    }
}

// MARK: - Safelight fade

private struct RedroomSafelightFade: ViewModifier {
    /// 0 at rest, 1 fully hidden.
    let progress: Double

    func body(content: Content) -> some View {
        content
            .opacity(1 - progress)
            .scaleEffect(1 - 0.02 * progress)
            .blur(radius: 7 * progress)
    }
}

// MARK: - Chemical immersion

/// The surface line the screen rises through: the content is masked so its
/// bottom edge is a wet line, and it lifts 26 pt into place.
private struct RedroomImmersion: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        content
            .offset(y: 26 * progress)
            .opacity(1 - progress * 0.9)
            .mask {
                GeometryReader { proxy in
                    Rectangle()
                        .frame(height: max(0, proxy.size.height * (1 - progress * 0.35)))
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
    }
}

// MARK: - Film strip

/// A strip being drawn through a gate: it comes in from the right with the
/// gate's dark bars closing over its top and bottom edges.
private struct RedroomFilmStrip: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        content
            .offset(x: 30 * progress)
            .opacity(1 - progress * 0.8)
            .mask {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 10 + 26 * progress)
                    Rectangle().fill(Color.black)
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 10 + 26 * progress)
                }
            }
    }
}

// MARK: - Enlarger shutter

/// The print coming up as the blades open: a shallow tip away from the reader,
/// then square, with the corners still dark.
private struct RedroomShutter: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(1 - 0.035 * progress)
            .opacity(1 - progress)
            .rotation3DEffect(
                .degrees(6 * progress),
                axis: (x: 1, y: 0, z: 0),
                anchor: .top,
                perspective: 0.35
            )
            .mask {
                RoundedRectangle(cornerRadius: 26 * progress, style: .continuous)
            }
    }
}

// MARK: - Transitions

extension AnyTransition {
    /// A surface warming under the lamp.
    static var redroomSafelightFade: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: RedroomSafelightFade(progress: 1),
                identity: RedroomSafelightFade(progress: 0)
            ),
            removal: .opacity
        )
    }

    /// A screen rising through the chemistry.
    static var redroomImmersion: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: RedroomImmersion(progress: 1),
                identity: RedroomImmersion(progress: 0)
            ),
            removal: .modifier(
                active: RedroomImmersion(progress: 1),
                identity: RedroomImmersion(progress: 0)
            )
        )
    }

    /// A strip drawn through the gate.
    static var redroomFilmStrip: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: RedroomFilmStrip(progress: 1),
                identity: RedroomFilmStrip(progress: 0)
            ),
            removal: .opacity
        )
    }

    /// The print appearing as the blades open.
    static var redroomShutter: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: RedroomShutter(progress: 1),
                identity: RedroomShutter(progress: 0)
            ),
            removal: .opacity
        )
    }
}

// MARK: - Reveal on arrival

/// Plays one of the room's four movements as a view arrives. This is how a
/// pushed screen, a sheet's content and the running session make their entrance:
/// the push itself is the system's, the arrival is the room's.
struct RedroomReveal: ViewModifier {
    var kind: RedroomTransitionKind = .shutter
    var delay: Double = 0
    var distance: CGFloat = 18

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    private var isIn: Bool { arrived || reduceMotion }

    func body(content: Content) -> some View {
        content
            .opacity(isIn ? 1 : 0)
            .offset(y: isIn || kind == .filmStrip ? 0 : distance)
            .offset(x: isIn || kind != .filmStrip ? 0 : distance)
            .scaleEffect(scale)
            .blur(radius: isIn ? 0 : blur)
            .animation(animation, value: arrived)
            .onAppear {
                guard !arrived else { return }
                if reduceMotion {
                    arrived = true
                } else {
                    withAnimation(animation.delay(delay)) {
                        arrived = true
                    }
                }
            }
    }

    private var scale: CGFloat {
        guard !isIn else { return 1 }
        switch kind {
        case .shutter: return 0.975
        case .safelightFade: return 0.99
        default: return 1
        }
    }

    private var blur: CGFloat {
        guard !isIn else { return 0 }
        switch kind {
        case .safelightFade: return 5
        case .shutter: return 2
        default: return 0
        }
    }

    private var animation: Animation {
        reduceMotion ? .easeOut(duration: 0.16) : .spring(response: 0.48, dampingFraction: 0.9)
    }
}

extension View {
    func redroomReveal(
        _ kind: RedroomTransitionKind = .shutter,
        delay: Double = 0
    ) -> some View {
        modifier(RedroomReveal(kind: kind, delay: delay))
    }
}

// MARK: - Sheets

/// The room's sheet: the safelight's own dark surface, a heavy radius, and a
/// grabber that reads as a machined bar rather than a pill. The content still
/// arrives on the enlarger's shutter.
private struct RedroomSheetChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationBackground {
                ZStack {
                    Redroom.background
                    Redroom.backgroundSecondary.opacity(0.9)
                }
            }
            .presentationCornerRadius(30)
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
    }
}

extension View {
    /// Every sheet in REDROOM is presented inside the room.
    func redroomSheet() -> some View {
        modifier(RedroomSheetChrome())
    }
}

/// A sheet's own header: the sheet's name, why it is open, and the way out.
struct RedroomSheetHeader: View {
    let kicker: String
    let title: String
    var detail: String?
    var confirmTitle: String?
    var onConfirm: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    RedroomLabel(kicker)

                    Text(title.uppercased())
                        .font(Redroom.display(20, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Redroom.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                if let confirmTitle, let onConfirm {
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(Redroom.body(14, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                            .padding(.horizontal, 16)
                            .frame(height: 42)
                            .background {
                                Color.clear.redroomGlass(variant: .transparent, cornerRadius: 13)
                            }
                    }
                    .buttonStyle(HapticButtonStyle())
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                            .frame(width: 42, height: 42)
                            .background {
                                Color.clear.redroomGlass(variant: .transparent, cornerRadius: 13)
                            }
                    }
                    .buttonStyle(HapticButtonStyle())
                    .accessibilityLabel("Close")
                }
            }

            if let detail {
                Text(detail)
                    .font(Redroom.body(13))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            RedroomLitRule()
        }
        .padding(.horizontal, RedroomMetrics.screenPadding)
        .padding(.top, 18)
    }
}
