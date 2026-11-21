//
//  DesignLanguageGraphics.swift
//  Darkroom
//
//  The field a language sits on, and the few decorative marks it uses to
//  introduce itself. Each background is drawn for its own language: a lit
//  liquid field for Liquid Glass, mica for Fluent, paper for Editorial, a
//  pressing grid for Swiss, scanlines for Terminal.
//
//  Only the two languages that animate do so, and both stop when the reader has
//  asked for reduced motion or when the screen is not visible.
//

import SwiftUI

// MARK: - Field

struct DLBackgroundView: View {
    let spec: DLSpec
    let palette: DLPalette
    var intensity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var isStill: Bool {
        reduceMotion || scenePhase != .active
    }

    var body: some View {
        ZStack {
            palette.field

            switch spec.background {
            case .liquid: liquidField
            case .clean: cleanField
            case .mica: micaField
            case .tonal: tonalField
            case .grid: gridField
            case .concrete: concreteField
            case .clay: clayField
            case .neon: neonField
            case .safelight: safelightField
            case .paper: paperField
            case .metal: metalField
            case .crt: crtField
            case .flat: Color.clear
            }

            LinearGradient(
                colors: [palette.field.opacity(0.34), .clear, palette.field.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: 01 Liquid Glass

    private var liquidField: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: isStill)) { timeline in
                let t = isStill ? 0 : timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    let w = size.width
                    let h = size.height
                    let first = CGPoint(
                        x: w * (0.74 + 0.05 * sin(t * 0.18)),
                        y: h * (0.24 + 0.03 * cos(t * 0.14))
                    )
                    let second = CGPoint(
                        x: w * (0.22 + 0.04 * cos(t * 0.12)),
                        y: h * (0.68 + 0.04 * sin(t * 0.16))
                    )

                    for (centre, colour, radius) in [
                        (first, palette.accent, w * 0.72),
                        (second, palette.glow, w * 0.66),
                        (CGPoint(x: w * 0.5, y: h * 0.98), palette.glowTwo, w * 0.8)
                    ] {
                        var layer = context
                        layer.addFilter(.blur(radius: radius * 0.20))
                        layer.fill(
                            Path(ellipseIn: CGRect(
                                x: centre.x - radius / 2,
                                y: centre.y - radius / 2,
                                width: radius,
                                height: radius
                            )),
                            with: .radialGradient(
                                Gradient(colors: [
                                    colour.opacity(0.30 * intensity),
                                    colour.opacity(0.08 * intensity),
                                    .clear
                                ]),
                                center: centre,
                                startRadius: 0,
                                endRadius: radius / 2
                            )
                        )
                    }
                }
            }

            DLGrainField(colour: .white, opacity: 0.045)
        }
    }

    // MARK: 02 Apple Clean

    private var cleanField: some View {
        LinearGradient(
            colors: [palette.field, palette.fieldAlt],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: 03 Fluent

    private var micaField: some View {
        ZStack {
            LinearGradient(
                colors: [palette.field, palette.fieldAlt],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            blooms([
                (palette.accent.opacity(0.16), CGPoint(x: 0.16, y: 0.20), 0.62),
                (palette.glowTwo.opacity(0.13), CGPoint(x: 0.86, y: 0.42), 0.58),
                (palette.glow.opacity(0.10), CGPoint(x: 0.40, y: 0.94), 0.70)
            ])

            DLGrainField(colour: .white, opacity: 0.035)
        }
    }

    // MARK: 04 Material 3

    private var tonalField: some View {
        ZStack {
            palette.field
            blooms([
                (palette.surfaceAlt.opacity(0.85), CGPoint(x: 0.80, y: 0.02), 0.95),
                (palette.accent.opacity(0.10), CGPoint(x: 0.10, y: 0.30), 0.80)
            ])
        }
    }

    // MARK: 05 Swiss

    private var gridField: some View {
        ZStack {
            palette.field

            Canvas { context, size in
                let columns = 12
                let columnWidth = size.width / CGFloat(columns)
                var path = Path()
                for column in 0...columns {
                    let x = CGFloat(column) * columnWidth
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(palette.line.opacity(0.35)), lineWidth: 0.5)

                var baseline = Path()
                var y: CGFloat = 0
                while y < size.height {
                    baseline.move(to: CGPoint(x: 0, y: y))
                    baseline.addLine(to: CGPoint(x: size.width, y: y))
                    y += 64
                }
                context.stroke(baseline, with: .color(palette.line.opacity(0.18)), lineWidth: 0.5)
            }
        }
    }

    // MARK: 06 Brutalist

    private var concreteField: some View {
        ZStack {
            palette.field

            Canvas { context, size in
                var path = Path()
                var offset: CGFloat = -size.height
                while offset < size.width {
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                    offset += 14
                }
                context.stroke(path, with: .color(palette.ink.opacity(0.045)), lineWidth: 2)
            }

            DLGrainField(colour: palette.ink, opacity: 0.05)
        }
    }

    // MARK: 07 Neumorphic

    private var clayField: some View {
        ZStack {
            LinearGradient(
                colors: [palette.surfaceAlt, palette.field, palette.fieldAlt],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            blooms([
                (palette.surface.opacity(0.9), CGPoint(x: 0.24, y: 0.16), 0.9),
                (palette.accent.opacity(0.07), CGPoint(x: 0.86, y: 0.84), 0.9)
            ])
        }
    }

    // MARK: 08 Cyberpunk

    private var neonField: some View {
        ZStack {
            LinearGradient(
                colors: [palette.field, palette.fieldAlt, palette.field],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            blooms([
                (palette.accent.opacity(0.16), CGPoint(x: 0.10, y: 0.10), 0.7),
                (palette.glow.opacity(0.18), CGPoint(x: 0.92, y: 0.72), 0.7)
            ])

            Canvas { context, size in
                let horizon = size.height * 0.62
                var path = Path()
                var step: CGFloat = 0
                while step <= size.width {
                    path.move(to: CGPoint(x: size.width / 2, y: horizon))
                    path.addLine(to: CGPoint(x: step, y: size.height))
                    step += 28
                }
                var row: CGFloat = horizon
                var gap: CGFloat = 6
                while row < size.height {
                    path.move(to: CGPoint(x: 0, y: row))
                    path.addLine(to: CGPoint(x: size.width, y: row))
                    row += gap
                    gap *= 1.35
                }
                context.stroke(path, with: .color(palette.accent.opacity(0.14)), lineWidth: 0.8)
            }

            DLScanlines(spacing: 3, opacity: 0.16, colour: palette.field)
        }
    }

    // MARK: 09 Retro Analog

    private var safelightField: some View {
        ZStack {
            palette.field
            blooms([
                (palette.accent.opacity(0.34), CGPoint(x: 0.28, y: 0.12), 0.95),
                (palette.glow.opacity(0.20), CGPoint(x: 0.80, y: 0.86), 0.9)
            ])
            DLScanlines(spacing: 4, opacity: 0.10, colour: .black)
        }
    }

    // MARK: 10 Editorial

    private var paperField: some View {
        ZStack {
            palette.field

            Canvas { context, size in
                let margin = size.width * 0.055
                var path = Path()
                path.move(to: CGPoint(x: margin, y: 0))
                path.addLine(to: CGPoint(x: margin, y: size.height))
                path.move(to: CGPoint(x: size.width - margin, y: 0))
                path.addLine(to: CGPoint(x: size.width - margin, y: size.height))
                context.stroke(path, with: .color(palette.line.opacity(0.22)), lineWidth: 0.75)
            }

            DLGrainField(colour: palette.ink, opacity: 0.035)
        }
    }

    // MARK: 11 Skeuomorphic

    private var metalField: some View {
        ZStack {
            LinearGradient(
                colors: [palette.fieldAlt, palette.field, palette.fieldAlt],
                startPoint: .top,
                endPoint: .bottom
            )

            Canvas { context, size in
                var path = Path()
                var y: CGFloat = 0
                var index = 0
                while y < size.height {
                    let alpha = 0.03 + 0.05 * hash(index)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y + 0.6))
                    context.stroke(path, with: .color(.white.opacity(alpha)), lineWidth: 1)
                    path = Path()
                    y += 3
                    index += 1
                }
            }

            DLGrainField(colour: .black, opacity: 0.05)
        }
    }

    // MARK: 12 Terminal

    private var crtField: some View {
        ZStack {
            palette.field

            blooms([
                (palette.accent.opacity(0.12), CGPoint(x: 0.5, y: 0.02), 1.0)
            ])

            DLScanlines(spacing: 3, opacity: 0.22, colour: .black)
        }
    }

    // MARK: Shared

    private func blooms(_ stops: [(Color, CGPoint, CGFloat)]) -> some View {
        Canvas { context, size in
            for (colour, point, radius) in stops {
                let centre = CGPoint(x: size.width * point.x, y: size.height * point.y)
                let width = size.width * radius
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: centre.x - width / 2,
                        y: centre.y - width / 2,
                        width: width,
                        height: width
                    )),
                    with: .radialGradient(
                        Gradient(colors: [colour, colour.opacity(0.35), .clear]),
                        center: centre,
                        startRadius: 0,
                        endRadius: width / 2
                    )
                )
            }
        }
        .blur(radius: 40)
    }

    private func hash(_ index: Int) -> Double {
        let value = sin(Double(index) * 12.9898) * 43758.5453
        return value - floor(value)
    }
}

// MARK: - Textures

/// A fine, deterministic grain. One Canvas pass: no timeline, no randomness that
/// changes between frames, so it costs nothing after the first draw.
struct DLGrainField: View {
    var colour: Color = .white
    var opacity: Double = 0.05

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 4
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var column = 0
                while x < size.width {
                    let value = grain(row * 977 &+ column * 131)
                    if value > 0.62 {
                        let dot = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                        context.fill(Path(ellipseIn: dot), with: .color(colour.opacity(opacity * value)))
                    }
                    x += step
                    column += 1
                }
                y += step
                row += 1
            }
        }
    }

    private func grain(_ index: Int) -> Double {
        let value = sin(Double(index) * 78.233) * 43758.5453
        return abs(value - floor(value))
    }
}

/// Horizontal scanlines, used by the two languages that want a screen in front
/// of them.
struct DLScanlines: View {
    var spacing: CGFloat = 3
    var opacity: Double = 0.2
    var colour: Color = .black

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                    with: .color(colour.opacity(opacity))
                )
                y += spacing
            }
        }
    }
}

// MARK: - Signature marks

/// The small mark each language puts beside its own name so a screen's language
/// is legible before a single word is read.
struct DLSignatureMark: View {
    let spec: DLSpec
    let palette: DLPalette
    var size: CGFloat = 18

    var body: some View {
        Group {
            switch spec.language {
            case .darkroom:
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [palette.accent, palette.glow, palette.glowTwo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 0.8)
                    }
            case .softLight:
                Circle()
                    .fill(palette.accent)
                    .overlay { Circle().strokeBorder(palette.ink.opacity(0.9), lineWidth: 1.2) }
            case .appleClean:
                Circle().strokeBorder(palette.ink, lineWidth: 1.2)
            case .fluent:
                HStack(spacing: size * 0.10) {
                    Rectangle().fill(palette.accent)
                    Rectangle().fill(palette.ink.opacity(0.45))
                }
            case .material3:
                Capsule().fill(palette.accent)
            case .swiss:
                ZStack {
                    Rectangle().fill(palette.accent).frame(width: size, height: size * 0.34)
                    Rectangle().fill(palette.ink).frame(width: size * 0.34, height: size)
                }
            case .brutalist:
                Rectangle()
                    .fill(palette.accent)
                    .overlay { Rectangle().stroke(palette.ink, lineWidth: 2) }
            case .neumorphic:
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(palette.surface)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 1.5, y: 1.5)
                    .shadow(color: .white.opacity(0.55), radius: 2, x: -1.5, y: -1.5)
            case .cyberpunk:
                DLClippedShape(cut: size * 0.3)
                    .stroke(palette.accent, lineWidth: 1.4)
            case .retroAnalog:
                Circle().fill(palette.accent)
                    .overlay { Circle().strokeBorder(palette.field, lineWidth: 2) }
            case .editorial:
                Rectangle().fill(palette.accent).frame(width: size * 0.5, height: size)
            case .skeuomorphic:
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [palette.surfaceAlt, palette.field],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size
                        )
                    )
                    .overlay { Circle().strokeBorder(palette.line, lineWidth: 1) }
            case .terminal:
                Text(">")
                    .font(.system(size: size * 1.1, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.accent)
            case .recorder:
                Circle()
                    .fill(palette.ink)
                    .overlay {
                        Circle()
                            .fill(palette.glow)
                            .frame(width: size * 0.30, height: size * 0.30)
                            .offset(x: size * 0.16, y: size * 0.16)
                    }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Shapes

/// The cyberpunk panel: a rectangle with one corner cut away.
struct DLClippedShape: Shape {
    var cut: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        path.closeSubpath()
        return path
    }
}

/// Four brackets at the corners of a panel, the way a targeting reticle frames
/// its subject.
struct DLCornerBrackets: View {
    var colour: Color
    var length: CGFloat = 10
    var thickness: CGFloat = 1.5

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            Path { path in
                // top leading
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
                // top trailing
                path.move(to: CGPoint(x: w - length, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: length))
                // bottom trailing
                path.move(to: CGPoint(x: w, y: h - length))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w - length, y: h))
                // bottom leading
                path.move(to: CGPoint(x: length, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: 0, y: h - length))
            }
            .stroke(colour, lineWidth: thickness)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
