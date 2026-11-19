//
//  Theme13Screens.swift
//  Darkroom
//
//  Screen-level compositions for THE 13TH THEME. These are presentation-only
//  archetypes: the poster cover, the cutout hero and the specimen-index rows.
//  No behaviour lives here.
//

import SwiftUI

// MARK: - Poster cover

/// The home archetype: micro credit, a display title over one interruption, a
/// cutout hero, a film-strip rule and an editorial caption.
struct Theme13PosterCover: View {
    let index: String
    let kicker: String
    let title: String
    let line: String
    let caption: String

    @ObservedObject private var store = Theme13SettingsStore.shared

    var body: some View {
        let palette = store.palette
        let dark = store.isDarkAppearance
        let ink = palette.ink(isDark: dark)
        let quiet = palette.inkAlt(isDark: dark)

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SPECIMEN — \(index)")
                Spacer(minLength: 8)
                Text(Self.dateLabel)
            }
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(1.7)
            .foregroundStyle(quiet)
            .padding(.bottom, 12)

            Text(kicker.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.9)
                .foregroundStyle(palette.accentText)
                .padding(.bottom, 6)

            ZStack(alignment: .topTrailing) {
                Text(title.uppercased())
                    .font(.system(size: 50, weight: .black).width(.expanded))
                    .tracking(-2)
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 34)

                Theme13BurstMark(size: 38, color: palette.accent, seed: 8)
                    .offset(x: 5, y: -9)
            }
            .padding(.bottom, 12)

            Theme13CutoutHero(palette: palette, isDark: dark)
                .frame(height: 148)
                .padding(.bottom, 12)

            Theme13FilmStripDivider(palette: palette, isDark: dark)
                .padding(.bottom, 10)

            Text(line)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(ink)

            Text(caption)
                .font(.system(size: 13))
                .foregroundStyle(quiet)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topLeading) {
            Rectangle()
                .fill(palette.stroke(isDark: dark).opacity(0.80))
                .offset(x: 4, y: 4)
        }
        .background(palette.plate(isDark: dark))
        .overlay {
            Rectangle().stroke(palette.stroke(isDark: dark), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }

    private static var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter.string(from: Date())
    }
}

// MARK: - Cutout hero

/// A window cut in paper that reveals the theme's signature plate.
struct Theme13CutoutHero: View {
    let palette: Theme13Palette
    let isDark: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Rectangle().fill(palette.bgAlt(isDark: isDark))

                Theme13CameraPlate(palette: palette, isDark: isDark)
                    .frame(width: size.width, height: size.height)

                Theme13TornPlate(amplitude: 8, seed: 4)
                    .fill(palette.plate(isDark: isDark))
                    .overlay(alignment: .center) {
                        Text("CAMERA HAND")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(palette.inkAlt(isDark: isDark))
                    }
                    .frame(width: size.width * 0.44, height: size.height * 0.40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .clipped()
            .overlay {
                Rectangle().stroke(palette.stroke(isDark: isDark), lineWidth: 1.2)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Specimen index

/// The list archetype: numbered rows separated by sprocket rules.
struct Theme13StageList: View {
    let index: String
    let heading: String
    let steps: [(title: String, detail: String)]

    @ObservedObject private var store = Theme13SettingsStore.shared

    var body: some View {
        let palette = store.palette
        let dark = store.isDarkAppearance
        let ink = palette.ink(isDark: dark)
        let quiet = palette.inkAlt(isDark: dark)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(index)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.accentText)
                Rectangle()
                    .fill(palette.rule(isDark: dark))
                    .frame(width: 18, height: 1)
                Text(heading.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.7)
                    .foregroundStyle(quiet)
                Spacer(minLength: 0)
            }
            .padding(.bottom, 8)

            ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", offset + 1))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.accentText)
                        .frame(width: 22, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ink)
                        Text(step.detail)
                            .font(.system(size: 13))
                            .foregroundStyle(quiet)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 9)
                .overlay(alignment: .bottom) {
                    Theme13SprocketRow(
                        color: palette.rule(isDark: dark),
                        holeCount: 14,
                        holeWidth: 6,
                        holeHeight: 4
                    )
                    .opacity(0.55)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topLeading) {
            Rectangle()
                .fill(palette.stroke(isDark: dark).opacity(0.80))
                .offset(x: 4, y: 4)
        }
        .background(palette.plate(isDark: dark))
        .overlay {
            Rectangle().stroke(palette.stroke(isDark: dark), lineWidth: 1.5)
        }
    }
}


// MARK: - Empty state

/// The empty/placeholder archetype: a burst cut in paper, filled with a
/// mono-letter tone field, over a typewriter message and numbered notes.
struct Theme13EmptyState: View {
    let index: String
    let headline: String
    let detail: String
    let bullets: [String]

    @ObservedObject private var store = Theme13SettingsStore.shared

    var body: some View {
        let palette = store.palette
        let dark = store.isDarkAppearance
        let ink = palette.ink(isDark: dark)
        let quiet = palette.inkAlt(isDark: dark)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PLATE — \(index)")
                Spacer(minLength: 8)
                Text("PLANNED NEXT")
            }
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(1.7)
            .foregroundStyle(quiet)
            .padding(.bottom, 14)

            Theme13MonoLetterField(
                ink: palette.accent,
                paper: palette.plate(isDark: dark),
                cell: 12
            ) { point, size in
                let centre = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
                let dx = point.x - centre.x
                let dy = (point.y - centre.y) * 1.25
                let distance = sqrt(dx * dx + dy * dy)
                let radius = min(size.width, size.height) * 0.46
                return distance < radius ? 0.90 : 0.12
            }
            .frame(height: 180)
            .mask { Theme13Burst(points: 10, seed: 6) }
            .padding(.bottom, 16)

            Text(headline)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(ink)

            Text(detail)
                .font(.system(size: 14))
                .foregroundStyle(quiet)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { offset, bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Text(String(format: "%02d", offset + 1))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(palette.accentText)
                        Text(bullet)
                            .font(.system(size: 13))
                            .foregroundStyle(ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 14)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topLeading) {
            Rectangle()
                .fill(palette.stroke(isDark: dark).opacity(0.80))
                .offset(x: 4, y: 4)
        }
        .background(palette.plate(isDark: dark))
        .overlay {
            Rectangle().stroke(palette.stroke(isDark: dark), lineWidth: 1.5)
        }
    }
}


// MARK: - Receipt plate

/// The detail archetype: a plate and its caption. Used for a finished session,
/// where every value is functional text set in mono on paper.
struct Theme13ReceiptPlate: View {
    let index: String
    let title: String
    let subtitle: String
    let rows: [(label: String, value: String)]

    @ObservedObject private var store = Theme13SettingsStore.shared

    var body: some View {
        let palette = store.palette
        let dark = store.isDarkAppearance
        let ink = palette.ink(isDark: dark)
        let quiet = palette.inkAlt(isDark: dark)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SPECIMEN — \(index)")
                Spacer(minLength: 8)
                Text("\(rows.count) FIELDS")
            }
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(1.7)
            .foregroundStyle(quiet)

            ZStack(alignment: .topTrailing) {
                Text(title.uppercased())
                    .font(.system(size: 38, weight: .black).width(.expanded))
                    .tracking(-1.4)
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 30)

                Theme13BurstMark(size: 30, color: palette.accent, seed: 11)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(palette.accentInk)
                    }
            }
            .padding(.top, 10)

            Text(subtitle)
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(quiet)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            Theme13FilmStripDivider(palette: palette, isDark: dark)
                .padding(.vertical, 12)

            ForEach(Array(rows.enumerated()), id: \.offset) { offset, row in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%02d", offset + 1))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.accentText)
                        .frame(width: 18, alignment: .leading)

                    Text(row.label)
                        .font(.system(size: 14))
                        .foregroundStyle(quiet)

                    Spacer(minLength: 8)

                    Text(row.value)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 7)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(palette.rule(isDark: dark).opacity(0.55))
                        .frame(height: 1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topLeading) {
            Rectangle()
                .fill(palette.stroke(isDark: dark).opacity(0.80))
                .offset(x: 4, y: 4)
        }
        .background(palette.plate(isDark: dark))
        .overlay {
            Rectangle().stroke(palette.stroke(isDark: dark), lineWidth: 1.5)
        }
    }
}
