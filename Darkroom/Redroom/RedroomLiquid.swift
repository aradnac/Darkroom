//
//  RedroomLiquid.swift
//  Darkroom
//
//  `DarkroomLiquidTray` — the signature surface. A black photographic tray whose
//  interior holds a shallow, dark red chemical, with the interface's content
//  sitting *beneath* it.
//
//  The liquid is drawn in one clipped Canvas inside the tray. It never takes
//  part in hit testing: a separate simultaneous gesture feeds the ripples, so
//  steppers, fields and buttons inside the tray keep working exactly as they do
//  anywhere else. It is a stylised surface, not a fluid simulation, and the
//  resting state is a single static frame.
//

import SwiftUI

// MARK: - Ripple

private struct RedroomRipple: Identifiable {
    let id = UUID()
    var location: CGPoint
    var strength: Double
    var start: Date
}

// MARK: - Tray

struct DarkroomLiquidTray<Content: View>: View {
    /// How deep the chemistry reads, 0.6...1.4. Deeper liquid is more opaque.
    var depth: Double = 1.0
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var ripples: [RedroomRipple] = []
    @State private var lastRipple = Date.distantPast

    private var isLive: Bool {
        !reduceMotion && !ripples.isEmpty
    }

    var body: some View {
        content()
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { trayBody }
            .overlay { liquidLayer }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        addRipple(at: value.location, strength: 0.6)
                    }
                    .onEnded { value in
                        addRipple(at: value.location, strength: 1.2)
                    }
            )
    }

    // MARK: Tray

    private var trayBody: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Redroom.color(0x0A0404),
                        Redroom.color(0x050202)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Redroom.safelight.opacity(0.35),
                                Redroom.deepRed.opacity(0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            }
            .overlay {
                // The tray's thick inner rim.
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.55), lineWidth: 6)
                    .padding(8)
            }
            .shadow(color: .black.opacity(0.55), radius: 18, y: 12)
    }

    // MARK: Liquid

    private var liquidLayer: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isLive)) { timeline in
            Canvas { context, size in
                let now = timeline.date
                let inset: CGFloat = 10
                let rect = CGRect(
                    x: inset,
                    y: size.height * 0.30,
                    width: size.width - inset * 2,
                    height: size.height * 0.62
                )
                let surfaceY = rect.minY

                let wave = surfacePath(
                    width: size.width,
                    surfaceY: surfaceY,
                    at: now,
                    ripples: ripples
                )

                var body = wave
                body.addLine(to: CGPoint(x: size.width, y: rect.maxY))
                body.addLine(to: CGPoint(x: 0, y: rect.maxY))
                body.closeSubpath()

                context.fill(
                    body,
                    with: .linearGradient(
                        Gradient(colors: [
                            Redroom.deepRed.opacity(0.55 * depth),
                            Redroom.safelightSecondary.opacity(0.18 * depth),
                            Redroom.color(0x120203).opacity(0.9)
                        ]),
                        startPoint: CGPoint(x: 0, y: surfaceY),
                        endPoint: CGPoint(x: 0, y: rect.maxY)
                    )
                )

                // The lamp caught on the surface.
                context.stroke(
                    wave,
                    with: .color(Redroom.safelight.opacity(0.45)),
                    lineWidth: 1.2
                )
                context.stroke(
                    wave,
                    with: .color(Color.white.opacity(0.18)),
                    lineWidth: 0.6
                )

                // Ripples: expanding rings, fading as they go.
                for ripple in ripples {
                    let age = max(0, now.timeIntervalSince(ripple.start))
                    guard age < 1.2 else { continue }
                    let radius = age * 150 * ripple.strength
                    let fade = max(0, 1 - age / 1.2)
                    let ring = Path(
                        ellipseIn: CGRect(
                            x: ripple.location.x - radius,
                            y: surfaceY - radius * 0.32,
                            width: radius * 2,
                            height: radius * 0.64
                        )
                    )
                    context.stroke(
                        ring,
                        with: .color(Redroom.safelight.opacity(0.30 * fade)),
                        lineWidth: 1
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous).inset(by: 9))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func surfacePath(
        width: CGFloat,
        surfaceY: CGFloat,
        at now: Date,
        ripples: [RedroomRipple]
    ) -> Path {
        var path = Path()
        var x: CGFloat = 0
        while x <= width + 4 {
            var y = surfaceY + sin(x / width * .pi * 3) * 2.0
            for ripple in ripples {
                let age = now.timeIntervalSince(ripple.start)
                guard age < 1.2 else { continue }
                let distance = abs(x - ripple.location.x)
                let spread = max(1, age * 150)
                guard distance < spread else { continue }
                let envelope = 1 - distance / spread
                let decay = max(0, 1 - age / 1.2)
                y += sin(distance / 16 - age * 9) * envelope * decay * 7 * ripple.strength
            }
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += 3
        }
        return path
    }

    // MARK: Ripples

    private func addRipple(at location: CGPoint, strength: Double) {
        guard !reduceMotion else { return }
        let now = Date()
        guard now.timeIntervalSince(lastRipple) > 0.06 else { return }
        lastRipple = now

        let point = CGPoint(x: location.x, y: location.y)
        ripples.removeAll { now.timeIntervalSince($0.start) > 1.2 }
        ripples.append(RedroomRipple(location: point, strength: strength, start: now))
        if ripples.count > 12 {
            ripples.removeFirst(ripples.count - 12)
        }
    }
}
