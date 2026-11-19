//
//  LiquidBackdrop.swift
//  Darkroom
//
//  The default bench-light backdrop, with a procedural print surface in THE 13TH THEME.
//

import SwiftUI

struct LiquidBackdrop: View {
    var tint: Color = Theme.amber
    var intensity: Double = 1.0
    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    var body: some View {
        Group {
            if themeStore.isTheme13Active {
                Theme13Backdrop()
            } else if themeStore.isSoftGlassActive {
                SoftGlassTheme.backdrop(intensity: intensity)
            } else {
                darkroomBackdrop
            }
        }
        // The backdrop must always take the size it is offered, never report
        // its own. The blooms are fixed-size layers that overflow this frame on
        // purpose; without it the soft-glass backdrop reports the union of those
        // frames (~940 × 1330 pt) as its own size, and any screen that hosts it
        // as a child instead of a background lays its content out on that
        // canvas — cut off on every edge of the phone.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private var darkroomBackdrop: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let width = Double(size.width)
                let height = Double(size.height)

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(DarkroomThemeDefaults.base)
                )

                let horizon = height * 0.96
                let glowRect = CGRect(
                    x: -width * 0.35,
                    y: horizon - height * 0.34,
                    width: width * 1.7,
                    height: height * 0.68
                )
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            tint.opacity(0.40 * intensity),
                            tint.opacity(0.14 * intensity),
                            tint.opacity(0.0)
                        ]),
                        center: CGPoint(x: width * 0.5, y: horizon),
                        startRadius: 0,
                        endRadius: width * 0.95
                    )
                )

                for band in 0..<3 {
                    let progress = Double(band)
                    let baseY = height * (0.87 + 0.045 * progress)
                    let amplitude = height * (0.016 + 0.006 * progress)
                    let wavelength = width * (0.92 - 0.16 * progress)
                    let speed = 0.16 + 0.07 * progress

                    var path = Path()
                    var x = 0.0
                    var first = true
                    while x <= width + 8 {
                        let y = baseY + sin((x / wavelength) * Double.pi * 2 + time * speed + progress) * amplitude
                        if first {
                            path.move(to: CGPoint(x: x, y: y))
                            first = false
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        x += 6
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()

                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: 24 + 10 * progress))
                        layer.fill(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [
                                    tint.opacity(max(0, 0.20 * intensity - 0.045 * progress)),
                                    tint.opacity(0.04 * intensity)
                                ]),
                                startPoint: CGPoint(x: 0, y: baseY - amplitude),
                                endPoint: CGPoint(x: 0, y: height)
                            )
                        )
                    }
                }
            }
        }
        .background(DarkroomThemeDefaults.base)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
