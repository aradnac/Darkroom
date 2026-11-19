//
//  Theme13Graphics.swift
//  Darkroom
//
//  The signature marks of the language: bursts, stars, asterisks, thorns,
//  quatrefoils, sprocket strips, letter fields and the camera plate.
//  Everything is drawn from a seed so a layout never jumps between renders.
//

import SwiftUI

// MARK: - Shapes

struct Theme13Burst: Shape {
    var points = 9
    var innerRatio: CGFloat = 0.48
    var seed = 0
    var jitter: CGFloat = 0.20

    func path(in rect: CGRect) -> Path {
        let total = max(6, points) * 2
        let step = CGFloat.pi / CGFloat(max(3, points))
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()

        for index in 0..<total {
            let baseAngle = -CGFloat.pi / 2 + CGFloat(index) * step
            let wobble = Theme13Noise.signed(seed &+ index &* 13) * step * 0.18
            let isOuter = index.isMultiple(of: 2)
            let variance = 1 + Theme13Noise.signed(seed &+ index &* 7) * jitter * 0.5
            let radius = outer * (isOuter ? 1 : innerRatio) * variance
            let point = CGPoint(
                x: center.x + cos(baseAngle + wobble) * radius,
                y: center.y + sin(baseAngle + wobble) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct Theme13Star: Shape {
    var points = 6
    var innerRatio: CGFloat = 0.34

    func path(in rect: CGRect) -> Path {
        let total = max(3, points) * 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()

        for index in 0..<total {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * CGFloat.pi / CGFloat(max(3, points))
            let radius = outer * (index.isMultiple(of: 2) ? 1 : innerRatio)
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct Theme13Thorn: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control1: CGPoint(x: rect.width * 0.56, y: rect.height * 0.46),
            control2: CGPoint(x: rect.width * 0.28, y: rect.height * 0.06)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.60, y: rect.height * 0.76),
            control1: CGPoint(x: rect.width * 0.06, y: rect.height * 0.40),
            control2: CGPoint(x: rect.width * 0.22, y: rect.height * 0.70)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.84, y: rect.height * 0.80),
            control2: CGPoint(x: rect.width * 0.95, y: rect.height * 0.60)
        )
        path.closeSubpath()
        return path
    }
}

struct Theme13Quatrefoil: Shape {
    var lobes: Int = 4
    var depth: CGFloat = 0.24

    func path(in rect: CGRect) -> Path {
        let steps = 160
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        for index in 0..<steps {
            let angle = CGFloat(index) / CGFloat(steps) * .pi * 2
            let scale = 1 - depth * abs(sin(CGFloat(lobes) * angle / 2))
            let point = CGPoint(
                x: center.x + cos(angle) * (rect.width / 2) * scale,
                y: center.y + sin(angle) * (rect.height / 2) * scale
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct Theme13SpiralArrow: Shape {
    var turns: CGFloat = 1.5

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let steps = 80

        for index in 0...steps {
            let t = CGFloat(index) / CGFloat(steps)
            let angle = t * .pi * 2 * turns
            let r = radius * (0.20 + 0.80 * t)
            let point = CGPoint(
                x: center.x + cos(angle) * r * 1.35,
                y: center.y + sin(angle) * r
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

// MARK: - Marks as views

struct Theme13BurstMark: View {
    var size: CGFloat = 20
    var color: Color?
    var seed = 0
    var points = 9
    var hollow = false
    var wiggle = false

    @ViewBuilder
    var body: some View {
        if wiggle {
            mark.theme13Wiggle(seed: seed, isBurst: true)
        } else {
            mark
        }
    }

    private var mark: some View {
        Group {
            if hollow {
                Theme13Burst(points: points, seed: seed)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, lineJoin: .miter))
                    .foregroundStyle(color ?? Theme13SettingsStore.shared.palette.accent)
            } else {
                Theme13Burst(points: points, seed: seed)
                    .fill(color ?? Theme13SettingsStore.shared.palette.accent)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct Theme13Asterisk: View {
    var size: CGFloat = 24
    var color: Color
    var bars = 12
    var outlined = false
    var seed = 0

    var body: some View {
        ZStack {
            ForEach(0..<bars, id: \.self) { index in
                Rectangle()
                    .fill(outlined ? Color.clear : color)
                    .overlay {
                        if outlined {
                            Rectangle().strokeBorder(color, lineWidth: 1)
                        }
                    }
                    .frame(
                        width: size * 0.11,
                        height: size * (0.90 + Theme13Noise.unit(seed &+ index &* 3) * 0.16)
                    )
                    .rotationEffect(.degrees(Double(index) * 180 / Double(max(3, bars))))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct Theme13StarMark: View {
    var size: CGFloat = 12
    var color: Color
    var points = 6
    var outlined = false

    var body: some View {
        Group {
            if outlined {
                Theme13Star(points: points).stroke(color, lineWidth: 1)
            } else {
                Theme13Star(points: points).fill(color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Sprocket strip

struct Theme13SprocketRow: View {
    var color: Color
    var holeCount = 12
    var holeWidth: CGFloat = 8
    var holeHeight: CGFloat = 5
    var spacing: CGFloat = 4

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max(1, holeCount), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                    .fill(color)
                    .frame(width: holeWidth, height: holeHeight)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: holeHeight)
        .accessibilityHidden(true)
    }
}

// MARK: - Mono letter field

/// A plate where character density carries tone: dense in shadow, sparse in
/// highlight, uppercase A–Z only.
struct Theme13MonoLetterField: View {
    var ink: Color
    var paper: Color
    var cell: CGFloat = 11
    var coverage: (CGPoint, CGSize) -> CGFloat

    private let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(paper))
            let step = max(7, cell)
            var y: CGFloat = step / 2
            var row = 0

            while y < size.height {
                var x: CGFloat = step / 2
                var column = 0
                while x < size.width {
                    let tone = min(1, max(0, coverage(CGPoint(x: x, y: y), size)))
                    let value = row &* 131 &+ column &* 19
                    if Theme13Noise.unit(value) < tone {
                        let index = ((value &* 7) & 0x7FFF_FFFF) % letters.count
                        let text = Text(String(letters[index]))
                            .font(.system(size: step * 0.86, weight: .bold, design: .monospaced))
                            .foregroundStyle(ink)
                        context.draw(text, at: CGPoint(x: x, y: y), anchor: .center)
                    }
                    x += step
                    column += 1
                }
                y += step
                row += 1
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Camera plate

/// The theme's signature plate: a hand on a tilting rangefinder, screened in
/// coarse halftone, interrupted by one flat burst. Drawn from scratch, so no
/// reference artwork is reproduced.
struct Theme13CameraPlate: View {
    var palette: Theme13Palette
    var isDark = false
    var showsBurst = true

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            guard width > 40, height > 40 else { return }

            let ink = palette.ink(isDark: isDark)
            let paper = palette.plate(isDark: isDark)

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(paper))

            // Coarse 45° halftone, densest over the camera.
            let pitch: CGFloat = 5
            let focus = CGPoint(x: width * 0.42, y: height * 0.42)
            let reach = min(width, height) * 0.72
            var y: CGFloat = 0
            while y < height {
                var x: CGFloat = 0
                while x < width {
                    let distance = sqrt((x - focus.x) * (x - focus.x) + (y - focus.y) * (y - focus.y))
                    let falloff = max(0, 1 - distance / reach)
                    let tone = min(1, 0.10 + falloff * 0.72)
                    let radius = pitch * 0.58 * tone.squareRoot()
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(ink.opacity(0.92))
                    )
                    x += pitch
                }
                y += pitch
            }

            // Hand: four fingers and a wrist entering bottom-right.
            for index in 0..<4 {
                let fingerWidth = width * 0.082
                let fingerHeight = height * (index == 1 ? 0.30 : (index == 2 ? 0.27 : 0.33))
                let rect = CGRect(
                    x: width * (0.30 + CGFloat(index) * 0.098),
                    y: height * 0.56 - fingerHeight * 0.12,
                    width: fingerWidth,
                    height: fingerHeight
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: fingerWidth * 0.5),
                    with: .color(paper)
                )
                context.stroke(
                    Path(roundedRect: rect, cornerRadius: fingerWidth * 0.5),
                    with: .color(ink),
                    lineWidth: 1.4
                )
            }
            let wrist = CGRect(x: width * 0.36, y: height * 0.80, width: width * 0.40, height: height * 0.30)
            context.fill(Path(roundedRect: wrist, cornerRadius: width * 0.05), with: .color(paper))
            context.stroke(Path(roundedRect: wrist, cornerRadius: width * 0.05), with: .color(ink), lineWidth: 1.4)

            // Camera body, tilted.
            let bodyRect = CGRect(x: width * 0.14, y: height * 0.18, width: width * 0.52, height: height * 0.34)
            let bodyPath = Path(roundedRect: bodyRect, cornerRadius: width * 0.02)
            context.drawLayer { layer in
                layer.translateBy(x: width * 0.33, y: height * 0.35)
                layer.rotate(by: .degrees(-11))
                layer.translateBy(x: -width * 0.33, y: -height * 0.35)
                layer.fill(bodyPath, with: .color(paper))
                layer.stroke(bodyPath, with: .color(ink), lineWidth: 2.2)

                // Top plate.
                let plate = CGRect(
                    x: bodyRect.minX,
                    y: bodyRect.minY,
                    width: bodyRect.width,
                    height: bodyRect.height * 0.20
                )
                layer.fill(Path(roundedRect: plate, cornerRadius: width * 0.015), with: .color(ink))

                // Lens.
                let lensSide = width * 0.24
                let lens = CGRect(
                    x: bodyRect.midX - lensSide / 2,
                    y: bodyRect.midY - lensSide / 2 + height * 0.012,
                    width: lensSide,
                    height: lensSide
                )
                layer.fill(Path(ellipseIn: lens), with: .color(paper))
                layer.stroke(Path(ellipseIn: lens), with: .color(ink), lineWidth: 3)
                layer.fill(
                    Path(ellipseIn: lens.insetBy(dx: lensSide * 0.24, dy: lensSide * 0.24)),
                    with: .color(ink)
                )

                // Viewfinder and wind lever.
                layer.stroke(
                    Path(CGRect(
                        x: bodyRect.minX + width * 0.035,
                        y: bodyRect.minY + height * 0.055,
                        width: width * 0.09,
                        height: height * 0.045
                    )),
                    with: .color(paper),
                    lineWidth: 2.4
                )
                layer.stroke(
                    Path(CGRect(
                        x: bodyRect.maxX - width * 0.11,
                        y: bodyRect.minY - height * 0.012,
                        width: width * 0.10,
                        height: height * 0.022
                    )),
                    with: .color(ink),
                    lineWidth: 3
                )
            }

            if showsBurst {
                let burstSide = width * 0.42
                let burstRect = CGRect(x: width * 0.30, y: height * 0.02, width: burstSide, height: burstSide)
                context.fill(
                    Theme13Burst(points: 9, seed: 4).path(in: burstRect),
                    with: .color(palette.accent)
                )
                let hollowSide = width * 0.20
                context.stroke(
                    Theme13Burst(points: 8, innerRatio: 0.44, seed: 11).path(
                        in: CGRect(x: width * 0.74, y: height * 0.66, width: hollowSide, height: hollowSide)
                    ),
                    with: .color(ink),
                    lineWidth: 1.6
                )
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Riso offset

/// A misregistered duplicate laid behind a shape.
struct Theme13OffsetShape<S: Shape>: View {
    var shape: S
    var color: Color
    var offset: CGSize = CGSize(width: 3, height: 3)
    var opacity: Double = 0.85

    var body: some View {
        shape
            .fill(color)
            .offset(x: offset.width, y: offset.height)
            .opacity(opacity)
            .accessibilityHidden(true)
    }
}
