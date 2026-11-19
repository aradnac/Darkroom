//
//  Theme13Components.swift
//  Darkroom
//
//  The shared surfaces of THE 13TH THEME: paper plates with a hard misregistered
//  offset, the print backdrop, the unlock reveal and the specimen preview.
//

import SwiftUI

// MARK: - Paper surface

/// A flat paper plate with a hard offset duplicate behind it. No blur, no
/// gradient, no radius — the sign language of a two-ink print.
struct Theme13PaperSurface: ViewModifier {
    @ObservedObject private var store = Theme13SettingsStore.shared
    var marked = true
    var offset: CGFloat = 3

    @ViewBuilder
    func body(content: Content) -> some View {
        if store.isTheme13Active {
            let palette = store.palette
            let dark = store.isDarkAppearance
            content
                .background(alignment: .topLeading) {
                    Rectangle()
                        .fill(palette.stroke(isDark: dark).opacity(0.85))
                        .offset(x: offset, y: offset)
                }
                .background {
                    Rectangle().fill(palette.plate(isDark: dark))
                }
                .overlay {
                    Rectangle()
                        .stroke(palette.stroke(isDark: dark), lineWidth: 1.5)
                }
                .overlay(alignment: .topTrailing) {
                    if marked {
                        Theme13BurstMark(size: 14, color: palette.accent, seed: 4)
                            .offset(x: -7, y: 7)
                    }
                }
        } else {
            content.glassCard(radius: 20)
        }
    }
}

// MARK: - Section header

struct Theme13SectionHeader: View {
    let index: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(index)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.amber)
            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 20, height: 1)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Film strip divider

struct Theme13FilmStripDivider: View {
    let palette: Theme13Palette
    var isDark = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<9, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(palette.accent.opacity(0.85))
                    .frame(width: 8, height: 5)
            }
            Rectangle()
                .fill(palette.rule(isDark: isDark))
                .frame(height: 1)
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

// MARK: - Backdrop

/// The print field every screen sits on: a flat plane, film grain, dust, and one
/// palette-specific interruption.
struct Theme13Backdrop: View {
    @ObservedObject private var store = Theme13SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var paletteOverride: Theme13Palette? = nil
    var isDarkOverride: Bool? = nil

    var body: some View {
        let palette = paletteOverride ?? store.palette
        let isDark = isDarkOverride ?? (paletteOverride == nil ? store.isDarkAppearance : false)
        let animated = store.motionEnabled && !reduceMotion && paletteOverride == nil
        let fps = max(2, min(12, store.framesPerSecond))

        Group {
            if animated {
                TimelineView(.periodic(from: .now, by: 1.0 / fps)) { timeline in
                    plate(
                        palette: palette,
                        isDark: isDark,
                        frame: Int(timeline.date.timeIntervalSinceReferenceDate * fps),
                        wiggle: Int(timeline.date.timeIntervalSinceReferenceDate * Theme13Motion.wiggleFPS)
                    )
                }
            } else {
                plate(palette: palette, isDark: isDark, frame: 0, wiggle: 0)
            }
        }
        .background(palette.bg(isDark: isDark))
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func plate(palette: Theme13Palette, isDark: Bool, frame: Int, wiggle: Int) -> some View {
        Canvas { context, size in
            paint(context, size: size, palette: palette, isDark: isDark, frame: frame, wiggle: wiggle)
        }
    }

    private func paint(
        _ context: GraphicsContext,
        size: CGSize,
        palette: Theme13Palette,
        isDark: Bool,
        frame: Int,
        wiggle: Int
    ) {
        guard size.width > 20, size.height > 20 else { return }
        let ink = palette.ink(isDark: isDark)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.bg(isDark: isDark)))

        // Corner registration rule, present in every palette.
        var rule = Path()
        rule.move(to: CGPoint(x: size.width * 0.055, y: size.height * 0.058))
        rule.addLine(to: CGPoint(x: size.width * 0.20, y: size.height * 0.058))
        context.stroke(rule, with: .color(ink.opacity(0.30)), lineWidth: 1)

        decoration(context, size: size, palette: palette, isDark: isDark, wiggle: wiggle)

        // Film grain and dust, cycled at the theme's own frame rate.
        for index in 0..<230 {
            let seed = index &* 733 &+ frame &* 7_919
            let x = Theme13Noise.unit(seed) * size.width
            let y = Theme13Noise.unit(seed &+ 31) * size.height
            let side = 0.6 + Theme13Noise.unit(seed &+ 71) * 1.5
            let alpha = 0.05 + Double(Theme13Noise.unit(seed &+ 13)) * (isDark ? 0.14 : 0.10)
            context.fill(
                Path(CGRect(x: x, y: y, width: side, height: side)),
                with: .color(ink.opacity(alpha))
            )
        }
        for index in 0..<26 {
            let seed = index &* 991 &+ 17
            let x = Theme13Noise.unit(seed) * size.width
            let y = Theme13Noise.unit(seed &+ 53) * size.height
            let side = 0.8 + Theme13Noise.unit(seed &+ 97) * 1.6
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                with: .color(ink.opacity(0.16))
            )
        }
    }

    // MARK: Per-palette interruption

    private func decoration(
        _ context: GraphicsContext,
        size: CGSize,
        palette: Theme13Palette,
        isDark: Bool,
        wiggle: Int
    ) {
        let ink = palette.ink(isDark: isDark)

        switch palette.id {
        case .rangefinder:
            let side = min(150, size.width * 0.34)
            let burstRect = CGRect(x: size.width - side * 0.62, y: -side * 0.30, width: side, height: side)
            let angle = Theme13Motion.burstRotations[((wiggle % 4) + 4) % 4]
            context.drawLayer { layer in
                layer.translateBy(x: burstRect.midX, y: burstRect.midY)
                layer.rotate(by: .degrees(angle))
                layer.translateBy(x: -burstRect.midX, y: -burstRect.midY)
                layer.fill(
                    Theme13Burst(points: 9, seed: 2).path(in: burstRect),
                    with: .color(palette.accent.opacity(0.94))
                )
            }
            let hollow = min(96, size.width * 0.24)
            context.stroke(
                Theme13Burst(points: 8, innerRatio: 0.44, seed: 7).path(
                    in: CGRect(x: -hollow * 0.30, y: size.height * 0.68, width: hollow, height: hollow)
                ),
                with: .color(ink.opacity(0.34)),
                lineWidth: 1.4
            )
            for index in 0..<7 {
                let y = size.height * (0.16 + CGFloat(index) * 0.026)
                let dotSide = CGFloat(index.isMultiple(of: 3) ? 4 : 2.6)
                context.fill(
                    Path(ellipseIn: CGRect(x: size.width * 0.92, y: y, width: dotSide, height: dotSide)),
                    with: .color(ink.opacity(0.30))
                )
            }

        case .negativeGold:
            // Stipple sunburst: solid at the far edge, dots near the source.
            let origin = CGPoint(x: size.width * 0.12, y: size.height * 1.06)
            let span: CGFloat = 0.78
            let rays = 11
            let reach = size.height * 1.05

            for index in 0..<rays {
                let start = -CGFloat.pi / 2 - span + CGFloat(index) * (2 * span) / CGFloat(rays)
                let end = start + (2 * span) / CGFloat(rays)
                var wedge = Path()
                wedge.move(to: origin)
                var angle = start
                while angle <= end {
                    let px = origin.x + cos(angle) * reach
                    let py = origin.y + sin(angle) * reach
                    wedge.addLine(to: CGPoint(x: px, y: py))
                    angle += 0.06
                }
                wedge.closeSubpath()
                let colour = index.isMultiple(of: 2) ? palette.decoration[3] : palette.decoration[2]
                context.fill(wedge, with: .color(colour.opacity(0.13)))
            }

        case .bittersweet:
            for index in 0..<24 {
                let seed = index &* 137 &+ 5
                let x = Theme13Noise.unit(seed) * size.width
                let y = Theme13Noise.unit(seed &+ 41) * size.height
                let side = 3 + Theme13Noise.unit(seed &+ 71) * 9
                context.fill(
                    Theme13Star(points: 6).path(in: CGRect(x: x, y: y, width: side, height: side)),
                    with: .color(palette.accent.opacity(0.42))
                )
            }
            let side = min(120, size.width * 0.26)
            context.fill(
                Theme13Burst(points: 10, seed: 9).path(
                    in: CGRect(x: -side * 0.34, y: size.height * 0.72, width: side, height: side)
                ),
                with: .color(palette.accent.opacity(0.55))
            )

        case .bloom:
            let haze = size.width * 0.9
            context.fill(
                Path(ellipseIn: CGRect(x: -size.width * 0.34, y: -size.height * 0.06, width: haze, height: size.width * 0.82)),
                with: .color(palette.decoration[0].opacity(0.22))
            )
            context.stroke(
                Theme13Quatrefoil().path(
                    in: CGRect(x: size.width * 0.58, y: size.height * 0.70, width: size.width * 0.52, height: size.width * 0.52)
                ),
                with: .color(palette.decoration[1].opacity(0.26)),
                lineWidth: 1.2
            )

        case .sunspotLawn:
            let tornRect = CGRect(x: -2, y: -size.height * 0.03, width: size.width + 4, height: size.height * 0.17)
            context.fill(
                Theme13TornPlate(amplitude: 9, seed: 5).path(in: tornRect),
                with: .color(palette.surface.opacity(0.92))
            )
            let side = min(110, size.width * 0.26)
            context.fill(
                Theme13Burst(points: 9, seed: 12).path(
                    in: CGRect(x: size.width * 0.78, y: size.height * 0.66, width: side, height: side)
                ),
                with: .color(palette.accent2.opacity(0.50))
            )
            let grass = CGRect(x: 0, y: size.height * 0.93, width: size.width, height: size.height * 0.10)
            context.fill(
                Theme13TornPlate(amplitude: 6, seed: 9).path(in: grass),
                with: .color(palette.decoration[2].opacity(0.20))
            )

        case .fogMoss:
            let rect = CGRect(x: size.width * 0.02, y: size.height * 0.56, width: size.width * 0.96, height: size.height * 0.46)
            context.fill(
                Theme13PixelStairRiver(seed: 3, cell: 16).path(in: rect),
                with: .color(palette.decoration[0].opacity(0.55))
            )

        case .bokehCanopy:
            for index in 0..<7 {
                let seed = index &* 211 &+ 29
                let side = Theme13Noise.range(seed, 30, 130)
                let x = Theme13Noise.unit(seed &+ 7) * size.width - side * 0.3
                let y = Theme13Noise.unit(seed &+ 19) * size.height
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                    with: .color(palette.decoration[1].opacity(0.16))
                )
            }
            let glare = min(180, size.width * 0.40)
            context.fill(
                Path(ellipseIn: CGRect(x: -size.width * 0.22, y: size.height * 0.70, width: glare, height: glare)),
                with: .color(palette.decoration[2].opacity(0.10))
            )

        case .chromaDots:
            let pitch = size.width / 9
            for row in 0..<4 {
                let colour = palette.decoration[(row + row / 2) % palette.decoration.count]
                for column in 0..<8 {
                    let side = pitch * 0.52
                    let x = size.width * 0.08 + CGFloat(column) * pitch
                    let y = size.height * 0.10 + CGFloat(row) * pitch * 0.72
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                        with: .color(colour.opacity(0.32))
                    )
                }
            }

        case .riverRiso:
            let centre = CGPoint(x: size.width * 0.84, y: size.height * 0.80)
            var angle: CGFloat = 0
            var radius: CGFloat = 6
            let limit = min(size.width, size.height) * 0.30
            while radius < limit {
                let px = centre.x + cos(angle) * radius * 1.25
                let py = centre.y + sin(angle) * radius
                context.fill(
                    Path(ellipseIn: CGRect(x: px, y: py, width: 3.4, height: 3.4)),
                    with: .color(palette.accent.opacity(0.42))
                )
                angle += 0.44
                radius += 1.7
            }
        }
    }
}

// MARK: - Unlock reveal

/// One-time grit sweep that announces the hidden theme. Always drawn in the
/// Rangefinder palette so it reads as the theme itself, whichever palette is
/// currently selected.
struct Theme13UnlockReveal: View {
    var onDismiss: () -> Void

    private let palette = Theme13Palette.palette(.rangefinder)
    private let message = "A new print language is ready."

    @State private var startedAt = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: .now, by: reduceMotion ? 0.6 : 1.0 / 24.0)) { timeline in
                let elapsed = max(0, timeline.date.timeIntervalSince(startedAt))
                let progress = reduceMotion ? 1 : min(1, elapsed / 0.9)

                ZStack(alignment: .leading) {
                    wordmark(size: geometry.size)
                    grit(size: geometry.size, progress: progress)
                    if elapsed > 0.85 {
                        let typed = reduceMotion ? message.count : min(message.count, Int((elapsed - 0.85) * 30))
                        toast(characters: typed)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 54)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .background(palette.background)
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The 13th theme unlocked. A new print language is ready.")
        .onAppear { Haptics.success() }
        .task {
            let seconds = 0.85 + Double(message.count) / 30 + 0.9
            try? await Task.sleep(for: .seconds(seconds))
            onDismiss()
        }
    }

    private func wordmark(size: CGSize) -> some View {
        let width = min(size.width * 0.16, 62)
        return VStack(alignment: .leading, spacing: 0) {
            Text("THE 13TH")
                .foregroundStyle(palette.primaryText)
            Text("THEME")
                .foregroundStyle(palette.accent)
        }
        .font(.system(size: width, weight: .black).width(.expanded))
        .tracking(-2)
        .lineSpacing(-width * 0.22)
        .padding(.horizontal, 24)
        .accessibilityHidden(true)
    }

    private func grit(size: CGSize, progress: Double) -> some View {
        Canvas { context, canvasSize in
            let sweepX = canvasSize.width * progress
            for index in 0..<700 {
                let x = Theme13Noise.unit(index &* 7 &+ 11) * canvasSize.width
                let y = Theme13Noise.unit(index &* 11 &+ 43) * canvasSize.height
                let jitter = CGFloat((index % 9) - 4) * 8
                guard x <= sweepX + jitter else { continue }
                let side = CGFloat(index % 4 == 0 ? 2.2 : 1.1)
                context.fill(
                    Path(CGRect(x: x, y: y, width: side, height: side)),
                    with: .color(palette.primaryText.opacity(index % 5 == 0 ? 0.8 : 0.24))
                )
            }
            var front = Path()
            front.move(to: CGPoint(x: sweepX, y: 0))
            front.addLine(to: CGPoint(x: sweepX, y: canvasSize.height))
            context.stroke(front, with: .color(palette.accent), lineWidth: 5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .opacity(progress >= 1 ? 0 : 1)
        .animation(.linear(duration: 0.2), value: progress)
    }

    private func toast(characters: Int) -> some View {
        Text(String(message.prefix(characters)))
            .font(.system(size: 15, weight: .medium, design: .monospaced))
            .foregroundStyle(palette.surfaceText)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topLeading) {
                Rectangle().fill(palette.border).offset(x: 3, y: 3)
            }
            .background(palette.surface)
            .overlay(Rectangle().stroke(palette.border, lineWidth: 1.5))
            .rotationEffect(.degrees(-1.6))
    }
}

// MARK: - Specimen preview

/// A small, honest specimen of a palette: display type, one interruption, a film
/// strip, a primary action and numbered rows.
struct Theme13PreviewPlate: View {
    let palette: Theme13Palette
    var compact = false

    private var display: CGFloat { compact ? 34 : 46 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SPECIMEN — 01")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.8)
                Spacer()
                Text("27.06")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.4)
            }
            .foregroundStyle(palette.secondaryText)
            .padding(.bottom, 14)

            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DEVELOP")
                        .font(.system(size: display, weight: .black).width(.expanded))
                        .tracking(-1.6)
                        .foregroundStyle(palette.primaryText)
                    Text("A roll, end to end")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(palette.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 44)

                Theme13BurstMark(size: compact ? 34 : 46, color: palette.accent, seed: 6, wiggle: true)
                    .offset(x: 6, y: -6)
            }

            Theme13FilmStripDivider(palette: palette)
                .padding(.vertical, 14)

            HStack(spacing: 8) {
                Text("START")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(palette.accentInk)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(palette.accent)
                Text("SETUP")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(palette.primaryText)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .overlay(Rectangle().stroke(palette.border, lineWidth: 1.5))
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 6) {
                previewRow("01", "Pre-soak", "2 min")
                previewRow("02", "Developer", "9:30")
                previewRow("03", "Fix", "5:00")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topLeading) {
            Rectangle().fill(palette.border.opacity(0.85)).offset(x: 4, y: 4)
        }
        .background(palette.background)
        .overlay(Rectangle().stroke(palette.border, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(palette.name) palette preview")
    }

    private func previewRow(_ index: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(index)
                .foregroundStyle(palette.accentText)
            Text(title)
                .foregroundStyle(palette.primaryText)
            Spacer(minLength: 4)
            Text(value)
                .foregroundStyle(palette.secondaryText)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
    }
}
