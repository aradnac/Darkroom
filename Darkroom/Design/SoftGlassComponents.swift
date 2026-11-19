//
//  SoftGlassComponents.swift
//  Darkroom
//
//  The pieces that give the soft-glass language its character: saturated
//  gradient tiles for figures, the dot-matrix numerals, and the small white
//  capsule actions. Everything else is built from the shared glass panel.
//

import SwiftUI

// MARK: - Gradient tile

/// A saturated panel that carries one figure: a tiny tracked label, a large
/// rounded value and an optional caption, floating on the ambient field.
struct SoftGlassTile: View {
    let label: String
    let value: String
    var caption: String?
    var gradient: LinearGradient
    var tint: Color
    var height: CGFloat = 118

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 6)

            Text(value)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            if let caption {
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: SoftGlassTheme.tileRadius, style: .continuous)
                    .fill(gradient)
                RoundedRectangle(cornerRadius: SoftGlassTheme.tileRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .blendMode(.softLight)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: SoftGlassTheme.tileRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: tint.opacity(0.28), radius: 20, x: 0, y: 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Dot matrix numerals

/// A number set as a grid of round dots, the way the reference sets its hero
/// figure. Three columns by five rows per glyph, one column for a colon.
struct DotMatrixDigits: View {
    let text: String
    var dot: CGFloat = 6
    var spacing: CGFloat = 3
    var color: Color = .white

    private static let patterns: [Character: [String]] = [
        "0": ["111", "101", "101", "101", "111"],
        "1": ["010", "110", "010", "010", "111"],
        "2": ["111", "001", "111", "100", "111"],
        "3": ["111", "001", "111", "001", "111"],
        "4": ["101", "101", "111", "001", "001"],
        "5": ["111", "100", "111", "001", "111"],
        "6": ["111", "100", "111", "101", "111"],
        "7": ["111", "001", "001", "001", "001"],
        "8": ["111", "101", "111", "101", "111"],
        "9": ["111", "101", "111", "001", "111"],
        ":": ["0", "1", "0", "1", "0"],
        "-": ["000", "000", "111", "000", "000"]
    ]

    var body: some View {
        let characters = Array(text)
        HStack(alignment: .center, spacing: spacing * 2) {
            ForEach(0..<characters.count, id: \.self) { index in
                glyph(characters[index])
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func glyph(_ character: Character) -> some View {
        let rows = Self.patterns[character] ?? ["000", "000", "000", "000", "000"]
        return VStack(spacing: spacing) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                let cells = Array(rows[rowIndex])
                HStack(spacing: spacing) {
                    ForEach(0..<cells.count, id: \.self) { columnIndex in
                        Circle()
                            .fill(cells[columnIndex] == "1" ? color : Color.clear)
                            .frame(width: dot, height: dot)
                    }
                }
            }
        }
    }
}

// MARK: - Small circular action

/// The thin outlined circle the reference uses for back, close and secondary
/// actions.
struct SoftGlassIconButton: View {
    let systemImage: String
    var size: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .frame(width: size, height: size)
                .background {
                    Circle().fill(.ultraThinMaterial)
                    Circle().fill(Color.white.opacity(0.07))
                }
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(HapticButtonStyle())
    }
}

// MARK: - Caption

/// A tiny tracked caption, used above titles and inside cards.
struct SoftGlassCaption: View {
    let text: String
    var color: Color = SoftGlassTheme.inkSoft

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}


// MARK: - Primary capsule label

/// The white capsule action from the reference: the words at the leading edge
/// and a dark circular badge carrying the glyph at the trailing edge. Meant to
/// be used inside `AmberCapsuleStyle`, which supplies the white fill.
struct SoftGlassActionLabel: View {
    let title: String
    var symbol: String = "plus"

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            ZStack {
                Circle().fill(Color.black)
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
    }
}

// MARK: - Glass row

/// A quiet row on the panel surface: white figure in a small disc, a title, an
/// optional detail line and an optional trailing value.
struct SoftGlassRow: View {
    let title: String
    var detail: String?
    var index: Int?
    var trailing: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let index {
                Text("\(index)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .frame(width: 26, height: 26)
                    .background { Circle().fill(Color.white) }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SoftGlassTheme.ink)
                if let detail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(SoftGlassTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 6)

            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SoftGlassTheme.inkFaint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
