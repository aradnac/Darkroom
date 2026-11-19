//
//  LibraryComponents.swift
//  Darkroom
//
//  The small pieces the library screens share: the provenance badge that says
//  where a number came from, the fact chip, the tile that shows a documented
//  value or admits it is not documented, and a flow layout for wrapping rows of
//  chips.
//

import SwiftUI

// MARK: - Badge

struct LibraryBadge: View {
    let kind: LibraryProvenanceKind
    var text: String? = nil

    var body: some View {
        Text((text ?? kind.label).uppercased())
            .font(.system(size: 9, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(kind == .unverified ? Theme.amber : Theme.ink.opacity(0.82))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule().fill(kind == .unverified ? Theme.accentWash : Theme.surfaceRaised)
            }
            .overlay {
                Capsule().strokeBorder(
                    kind == .unverified ? Theme.amber.opacity(0.4) : Theme.border,
                    lineWidth: 1
                )
            }
            .accessibilityLabel(kind.detail)
    }
}

// MARK: - Chip

struct LibraryChip: View {
    let text: String
    var emphasised = false

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(emphasised ? Theme.amberInk : Theme.ink.opacity(0.85))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background {
                Capsule().fill(emphasised ? Theme.amber : Theme.surfaceRaised)
            }
            .overlay {
                if !emphasised {
                    Capsule().strokeBorder(Theme.border, lineWidth: 1)
                }
            }
    }
}

// MARK: - Fact tile

/// One documented property of a film. A missing fact reads "Not documented"
/// rather than borrowing a number from somewhere else.
struct LibraryFactTile: View {
    let symbol: String
    let label: String
    let fact: LibraryFact?

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(fact == nil ? Theme.inkFaint : Theme.ink.opacity(0.82))

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(fact == nil ? Theme.inkSoft : Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(fact?.unit ?? " ")
                .font(.system(size: 10))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .glassCard(radius: 18)
        .accessibilityElement(children: .combine)
    }

    private var value: String { fact?.value ?? "Not documented" }
}

// MARK: - Section heading

struct LibrarySectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Flow layout

/// Wraps chips onto as many lines as they need, centring each line.
struct LibraryFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = layoutRows(subviews, width: width)
        let height = rows.reduce(CGFloat.zero) { partial, row in
            partial + row.height
        } + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? widestRow(rows), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = layoutRows(subviews, width: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX + max(0, (bounds.width - row.width) / 2)
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func layoutRows(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].items.isEmpty ? size.width : size.width + spacing
            if !rows[rows.count - 1].items.isEmpty, rows[rows.count - 1].width + needed > width {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.items.append((index, size))
            row.width += row.items.count == 1 ? size.width : size.width + spacing
            row.height = max(row.height, size.height)
            rows[rows.count - 1] = row
        }
        return rows
    }

    private func widestRow(_ rows: [Row]) -> CGFloat {
        rows.map(\.width).max() ?? 0
    }
}
