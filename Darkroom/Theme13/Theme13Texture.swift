//
//  Theme13Texture.swift
//  Darkroom
//
//  Procedural print surfaces. Halftone, dither, stipple, grain, dust, creases
//  and torn edges are structural material in this theme, not decoration, so each
//  one is generated from a stable seed and drawn into a Canvas.
//

import SwiftUI

// MARK: - Deterministic noise

enum Theme13Noise {
    static func unit(_ seed: Int) -> CGFloat {
        var x = UInt64(bitPattern: Int64(seed)) &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        x = x ^ (x >> 31)
        return CGFloat(x % 100_000) / 100_000
    }

    static func signed(_ seed: Int) -> CGFloat {
        unit(seed) * 2 - 1
    }

    static func range(_ seed: Int, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        lower + (upper - lower) * unit(seed)
    }
}

// MARK: - Halftone

/// A dot screen whose dot radius follows a coverage function.
struct Theme13HalftoneField: View {
    var pitch: CGFloat = 6
    var angle: CGFloat = .pi / 4
    var ink: Color
    var paper: Color?
    var maximumDots = 14_000
    var coverage: (CGPoint, CGSize) -> CGFloat

    var body: some View {
        Canvas { context, size in
            if let paper {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(paper))
            }
            var step = max(3, pitch)
            let diagonal = (size.width * size.width + size.height * size.height).squareRoot()
            guard diagonal > 0 else { return }

            let estimated = (diagonal / step) * (diagonal / step)
            if estimated > CGFloat(maximumDots) {
                step *= (estimated / CGFloat(maximumDots)).squareRoot()
            }

            let count = Int(diagonal / step) + 3
            let cosine = cos(angle)
            let sine = sin(angle)
            let originX = size.width / 2 - diagonal / 2
            let originY = size.height / 2 - diagonal / 2

            for row in 0..<count {
                for column in 0..<count {
                    let localX = CGFloat(column) * step
                    let localY = CGFloat(row) * step
                    let x = originX + localX * cosine - localY * sine
                    let y = originY + localX * sine + localY * cosine
                    guard x > -step, x < size.width + step, y > -step, y < size.height + step else { continue }
                    let tone = min(1, max(0, coverage(CGPoint(x: x, y: y), size)))
                    guard tone > 0.02 else { continue }
                    let radius = step * 0.62 * tone.squareRoot()
                    let dot = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: dot), with: .color(ink))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Dither

/// Ordered Bayer squares for flat graphic regions.
struct Theme13DitherField: View {
    var cell: CGFloat = 3
    var ink: Color
    var paper: Color?
    var coverage: (CGPoint, CGSize) -> CGFloat

    private static let bayer: [[CGFloat]] = [
        [0, 8, 2, 10],
        [12, 4, 14, 6],
        [3, 11, 1, 9],
        [15, 7, 13, 5]
    ]

    var body: some View {
        Canvas { context, size in
            if let paper {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(paper))
            }
            let step = max(2, cell)
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var column = 0
                while x < size.width {
                    let threshold = (Theme13DitherField.bayer[row % 4][column % 4] + 0.5) / 16
                    let tone = min(1, max(0, coverage(CGPoint(x: x, y: y), size)))
                    if tone > threshold {
                        context.fill(
                            Path(CGRect(x: x, y: y, width: step, height: step)),
                            with: .color(ink)
                        )
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

// MARK: - Grain, dust, creases

/// Luminance grain, cycled at a deliberately low frame rate.
struct Theme13GrainOverlay: View {
    var ink: Color
    var amount: Double = 0.10
    @ObservedObject private var store = Theme13SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let animate = store.motionEnabled && !reduceMotion
        let fps = max(2, min(12, store.framesPerSecond))

        TimelineView(.periodic(from: .now, by: animate ? 1.0 / fps : 600)) { timeline in
            let frame = animate ? Int(timeline.date.timeIntervalSinceReferenceDate * fps) : 0
            Canvas { context, size in
                for index in 0..<340 {
                    let seed = index &* 977 &+ frame &* 7_919
                    let x = Theme13Noise.unit(seed) * size.width
                    let y = Theme13Noise.unit(seed &+ 31) * size.height
                    let side = 0.7 + Theme13Noise.unit(seed &+ 71) * 1.4
                    let alpha = Double(0.18 + Theme13Noise.unit(seed &+ 13) * 0.82) * amount
                    context.fill(
                        Path(CGRect(x: x, y: y, width: side, height: side)),
                        with: .color(ink.opacity(alpha))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Dust specks and hair scratches, per the film-cue pillar.
struct Theme13DustOverlay: View {
    var ink: Color
    var withScratches = true
    var seed = 0

    var body: some View {
        Canvas { context, size in
            for index in 0..<70 {
                let value = index &* 613 &+ seed &* 47
                let x = Theme13Noise.unit(value) * size.width
                let y = Theme13Noise.unit(value &+ 29) * size.height
                let side = 0.6 + Theme13Noise.unit(value &+ 83) * 2.0
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                    with: .color(ink.opacity(0.42))
                )
            }
            guard withScratches else { return }
            for index in 0..<4 {
                let value = index &* 431 &+ seed &* 19
                let startX = Theme13Noise.unit(value) * size.width
                let startY = Theme13Noise.unit(value &+ 7) * size.height
                let dx = Theme13Noise.range(value &+ 11, -70, 70)
                let dy = Theme13Noise.range(value &+ 17, 60, 250)
                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: startX + dx, y: startY + dy))
                context.stroke(path, with: .color(ink.opacity(0.26)), lineWidth: 0.8)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Fold and crease lines: a 1px white line with a 1px dark neighbour.
struct Theme13CreaseOverlay: View {
    var ink: Color

    var body: some View {
        Canvas { context, size in
            for index in 0..<4 {
                let value = index &* 733 &+ 41
                let degrees = Theme13Noise.unit(value) > 0.5 ? 12.0 : 80.0
                let radians = CGFloat(degrees) * .pi / 180
                let x = Theme13Noise.unit(value &+ 3) * size.width
                let y = Theme13Noise.unit(value &+ 9) * size.height
                let length = max(size.width, size.height) * 1.6
                let dx = cos(radians) * length
                let dy = sin(radians) * length

                var shadow = Path()
                shadow.move(to: CGPoint(x: x + 1, y: y + 1))
                shadow.addLine(to: CGPoint(x: x + dx + 1, y: y + dy + 1))
                context.stroke(shadow, with: .color(ink.opacity(0.08)), lineWidth: 1)

                var line = Path()
                line.move(to: CGPoint(x: x, y: y))
                line.addLine(to: CGPoint(x: x + dx, y: y + dy))
                context.stroke(line, with: .color(.white.opacity(0.14)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Dot plates and stipple

/// Rows of discs with per-row blur, grain re-applied after the blur.
struct Theme13BlurDotPlate: View {
    var paper: Color
    var colors: [Color]
    var columns = 16
    var rows = 17

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(paper))
            guard !colors.isEmpty, size.width > 0, size.height > 0 else { return }

            let pitch = min(size.width / CGFloat(columns), size.height / CGFloat(rows))
            let diameter = pitch * 0.74

            for row in 0..<rows {
                let blur = Theme13Noise.unit(row &* 37) * 7
                context.drawLayer { layer in
                    if blur > 0.4 {
                        layer.addFilter(.blur(radius: blur))
                    }
                    for column in 0..<columns {
                        let value = row &* 137 &+ column &* 17
                        let colourIndex = min(colors.count - 1, Int(Theme13Noise.unit(value) * CGFloat(colors.count)))
                        let jitter = Theme13Noise.signed(value &+ 5) * pitch * 0.08
                        let x = CGFloat(column) * pitch + (pitch - diameter) / 2 + jitter
                        let y = CGFloat(row) * pitch + (pitch - diameter) / 2
                        layer.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                            with: .color(colors[colourIndex])
                        )
                    }
                }
            }

            for index in 0..<240 {
                let value = index &* 811
                let x = Theme13Noise.unit(value) * size.width
                let y = Theme13Noise.unit(value &+ 23) * size.height
                context.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.black.opacity(0.14))
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A tone transition built from dots — the theme never uses a smooth ramp.
struct Theme13StipplePlate: View {
    var colors: [Color]
    var spacing: CGFloat = 6

    var body: some View {
        Canvas { context, size in
            guard !colors.isEmpty else { return }
            let step = max(4, spacing)
            var y: CGFloat = 0
            while y < size.height {
                let position = size.height > 0 ? y / size.height : 0
                let colour = Theme13Color.blend(colors, at: position)
                var x: CGFloat = 0
                while x < size.width {
                    let value = Int(x) &* 31 &+ Int(y) &* 17
                    let noise = Theme13Noise.unit(value)
                    if noise > 0.28 {
                        let radius = 1.1 + noise * 2.0
                        context.fill(
                            Path(ellipseIn: CGRect(x: x + noise * 2, y: y + noise, width: radius, height: radius)),
                            with: .color(colour.opacity(0.55 + noise * 0.45))
                        )
                    }
                    x += step
                }
                y += step
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Hand-hatched interior used inside bursts.
struct Theme13HatchOverlay: View {
    var ink: Color
    var angles: [Double] = [18, 74, -24]

    var body: some View {
        Canvas { context, size in
            let diagonal = (size.width * size.width + size.height * size.height).squareRoot()
            for (index, degrees) in angles.enumerated() {
                let radians = CGFloat(degrees) * .pi / 180
                let dx = cos(radians)
                let dy = sin(radians)
                let nx = -dy
                let ny = dx
                let spacing: CGFloat = 4 + CGFloat(index) * 1.5
                var offset = -diagonal
                while offset <= diagonal {
                    var line = Path()
                    line.move(to: CGPoint(
                        x: size.width / 2 + nx * offset - dx * diagonal,
                        y: size.height / 2 + ny * offset - dy * diagonal
                    ))
                    line.addLine(to: CGPoint(
                        x: size.width / 2 + nx * offset + dx * diagonal,
                        y: size.height / 2 + ny * offset + dy * diagonal
                    ))
                    context.stroke(line, with: .color(ink.opacity(0.55)), lineWidth: 1.1)
                    offset += spacing * 2
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Torn and stepped edges

/// A paper plate with a torn lower edge.
struct Theme13TornPlate: Shape {
    var amplitude: CGFloat = 7
    var seed = 1

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        let steps = max(10, Int(rect.width / 7))
        let stepWidth = rect.width / CGFloat(steps)
        var x = rect.maxX
        var index = 0
        while x > rect.minX {
            x -= stepWidth
            let noise = Theme13Noise.unit(seed &+ index &* 13)
            let y = rect.maxY - amplitude * noise
            path.addLine(to: CGPoint(x: max(rect.minX, x), y: y))
            index += 1
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

/// A meandering river cut in square steps, orthogonal edges only.
struct Theme13PixelStairRiver: Shape {
    var seed = 3
    var cell: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        let rows = max(3, Int(rect.height / max(6, cell)))
        let rowHeight = rect.height / CGFloat(rows)
        var centres: [CGFloat] = []
        var widths: [CGFloat] = []
        var centre: CGFloat = 0.5

        for row in 0...rows {
            let noise = Theme13Noise.unit(seed &+ row &* 7) - 0.5
            centre = min(0.80, max(0.20, centre + noise * 0.24))
            centres.append(centre)
            widths.append(0.09 + 0.07 * Theme13Noise.unit(seed &+ row &* 11))
        }

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * (centres[0] - widths[0]), y: rect.minY))
        for row in 1...rows {
            let y = rect.minY + CGFloat(row) * rowHeight
            path.addLine(to: CGPoint(x: rect.minX + rect.width * (centres[row - 1] - widths[row - 1]), y: y))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * (centres[row] - widths[row]), y: y))
        }
        for row in stride(from: rows, through: 0, by: -1) {
            let y = rect.minY + CGFloat(row) * rowHeight
            path.addLine(to: CGPoint(x: rect.minX + rect.width * (centres[row] + widths[row]), y: y))
            if row > 0 {
                let upperY = rect.minY + CGFloat(row - 1) * rowHeight
                path.addLine(to: CGPoint(x: rect.minX + rect.width * (centres[row] + widths[row]), y: upperY))
            }
        }
        path.closeSubpath()
        return path
    }
}
