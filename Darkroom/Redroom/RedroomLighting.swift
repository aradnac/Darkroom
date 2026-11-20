//
//  RedroomLighting.swift
//  Darkroom
//
//  One light for the whole theme. `SafelightEnvironment` lives here: the lamp's
//  position at the top centre of the display, the four intensity levels, and a
//  helper that turns any view's global frame into a direction and a strength.
//
//  Components never invent a highlight: they read `sample.direct`,
//  `sample.bounce`, `sample.start` and `sample.end` from this file. That is what
//  makes a button near the lamp brighter than one at the foot of the screen, and
//  keeps every reflection pointing at the same light.
//

import SwiftUI
import UIKit

// MARK: - Parameters

struct RedroomLightParameters: Equatable {
    /// The lamp, in unit space. Top centre, just under the Dynamic Island.
    var position: UnitPoint = UnitPoint(x: 0.5, y: 0.055)
    var intensity: RedroomIntensity = .normal
}

private struct RedroomLightKey: EnvironmentKey {
    static let defaultValue = RedroomLightParameters()
}

extension EnvironmentValues {
    var redroomLight: RedroomLightParameters {
        get { self[RedroomLightKey.self] }
        set { self[RedroomLightKey.self] = newValue }
    }
}

// MARK: - Screen metrics

enum RedroomScreenMetrics {
    /// The key window's size, used to place the lamp in the same place the
    /// Dynamic Island sits.
    static var size: CGSize {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        return window?.bounds.size ?? CGSize(width: 390, height: 844)
    }
}

// MARK: - A view's light

/// What one element sees of the lamp: which way to face, how strongly, and how
/// much of that is direct light rather than bounce from the bench.
struct RedroomLightSample: Equatable {
    /// Gradient start, pointing at the lamp (unit space, 0...1).
    var start: UnitPoint = UnitPoint(x: 0.5, y: 0)
    /// Gradient end, pointing away from the lamp.
    var end: UnitPoint = UnitPoint(x: 0.5, y: 1)
    /// Full strength at this element, 0...1.
    var strength: Double = 0
    /// Where the specular pool lands on the surface.
    var glowCenter: UnitPoint = UnitPoint(x: 0.5, y: 0)
    /// Direct light on the lamp-facing edge.
    var direct: Double = 0
    /// The faint bounce on the opposite edge — never zero, never bright.
    var bounce: Double = 0

    static func make(
        frame: CGRect,
        light: RedroomLightParameters,
        screen: CGSize = RedroomScreenMetrics.size
    ) -> RedroomLightSample {
        guard screen.width > 0, screen.height > 0, frame != .zero else {
            return RedroomLightSample()
        }

        let lamp = CGPoint(
            x: screen.width * light.position.x,
            y: screen.height * light.position.y
        )
        let centre = CGPoint(x: frame.midX, y: frame.midY)

        let dx = lamp.x - centre.x
        let dy = lamp.y - centre.y
        let length = max(hypot(dx, dy), 1)
        let ux = dx / length
        let uy = dy / length

        // Falloff down the display: the top of the screen is lit, the foot is not.
        let normalisedY = max(0, min(1, centre.y / screen.height))
        let falloff = max(0, 1 - normalisedY * 1.18)
        let factor = light.intensity.lightFactor
        let strength = min(1, (0.20 + 0.80 * falloff) * factor)

        // The lamp is above everything, so `-uy` is how much the element faces
        // it. A surface at the foot of the screen still faces it, but weakly.
        let facing = max(0, -uy)
        let direct = strength * (0.55 + 0.45 * facing)
        let bounce = strength * 0.18 * max(0, uy)

        return RedroomLightSample(
            start: UnitPoint(x: 0.5 + ux * 0.5, y: 0.5 + uy * 0.5),
            end: UnitPoint(x: 0.5 - ux * 0.5, y: 0.5 - uy * 0.5),
            strength: strength,
            glowCenter: UnitPoint(x: 0.5 + ux * 0.5, y: 0.5 + uy * 0.5),
            direct: direct,
            bounce: bounce
        )
    }
}

// MARK: - Measuring an element's frame

private struct RedroomFrameKey: PreferenceKey {
    static var defaultValue: CGRect { .zero }
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// Dresses a view in the theme's glass and keeps its lighting current as it
/// moves or scrolls: the frame is measured in global space and re-sampled on
/// every change, with no per-frame work.
struct RedroomLit: ViewModifier {
    var cornerRadius: CGFloat = RedroomMetrics.cardRadius
    var variant: RedroomGlassVariant = .smoked
    var lit: Bool = true

    @Environment(\.redroomLight) private var light
    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        let sample = RedroomLightSample.make(frame: frame, light: light)

        content
            .background {
                RedroomGlassBody(
                    variant: variant,
                    cornerRadius: cornerRadius,
                    sample: lit ? sample : RedroomLightSample()
                )
            }
            .overlay {
                RedroomGlassRim(
                    cornerRadius: cornerRadius,
                    sample: lit ? sample : RedroomLightSample()
                )
            }
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: RedroomFrameKey.self,
                        value: proxy.frame(in: .global)
                    )
                }
            }
            .onPreferenceChange(RedroomFrameKey.self) { value in
                frame = value
            }
    }
}

extension View {
    func redroomGlass(
        variant: RedroomGlassVariant = .smoked,
        cornerRadius: CGFloat = RedroomMetrics.cardRadius,
        lit: Bool = true
    ) -> some View {
        modifier(RedroomLit(cornerRadius: cornerRadius, variant: variant, lit: lit))
    }
}

// MARK: - The safelight itself

/// The room: near-black, with one lamp above and its glow falling away down the
/// screen. Static gradients plus a slow breath on opacity — no per-frame canvas.
struct RedroomSafelight: View {
    @Environment(\.redroomLight) private var light
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        let factor = light.intensity.lightFactor

        GeometryReader { proxy in
            ZStack {
                Redroom.background

                RadialGradient(
                    colors: [
                        Redroom.safelight.opacity(0.40 * factor),
                        Redroom.safelightSecondary.opacity(0.16 * factor),
                        Color.clear
                    ],
                    center: light.position,
                    startRadius: 0,
                    endRadius: max(proxy.size.height * 0.62, 240)
                )
                .opacity(breathing ? 1 : 0.90)

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.55 * factor),
                        Redroom.safelight.opacity(0.85 * factor),
                        Color.clear
                    ],
                    center: light.position,
                    startRadius: 0,
                    endRadius: 130
                )
                .blendMode(.screen)
                .blur(radius: 18)
                .opacity(breathing ? 1 : 0.94)

                // Atmospheric falloff at the foot of the room.
                LinearGradient(
                    colors: [Color.clear, Redroom.background.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Small shared pieces

/// A tracked uppercase caption, engraved rather than printed.
struct RedroomLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(Redroom.label())
            .tracking(1.6)
            .foregroundStyle(Redroom.textMuted)
    }
}

/// A section heading with the room's quiet rule under it.
struct RedroomSectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RedroomLabel(title)
            Rectangle()
                .fill(Redroom.deepRed.opacity(0.7))
                .frame(height: 1)
        }
    }
}

/// A soft red indicator light, the kind on the front of an enlarger.
struct RedroomIndicator: View {
    var on: Bool = true
    var size: CGFloat = 7

    var body: some View {
        Circle()
            .fill(on ? Redroom.safelight : Redroom.deepRed)
            .frame(width: size, height: size)
            .overlay {
                if on {
                    Circle()
                        .fill(Redroom.safelight.opacity(0.45))
                        .frame(width: size * 2.2, height: size * 2.2)
                        .blur(radius: 4)
                }
            }
            .accessibilityHidden(true)
    }
}
