//
//  StageRing.swift
//  Darkroom
//
//  The dial. A bezel of fine ticks, one band segment per stage, and the current
//  stage filling with amber as its time runs down. No labels sit on the band —
//  the stage names live in the strip beneath it — so the ring reads as a clean
//  instrument instead of type colliding with its own segments.
//

import SwiftUI

struct StageRing: View {
    let stages: [SessionStage]
    let current: Int
    /// How much of the current stage has elapsed, 0 to 1.
    var progress: Double = 0
    var diameter: CGFloat = 240
    var lineWidth: CGFloat = 16

    private var count: Int { max(stages.count, 1) }
    private var index: Int { min(max(current, 0), count - 1) }
    private var step: Double { 1 / Double(count) }
    private var gap: Double { 0.010 }
    private var bandDiameter: CGFloat { max(diameter - 30, 40) }

    private enum Segment {
        case done
        case active
        case upcoming
    }

    var body: some View {
        ZStack {
            ticks

            ForEach(0..<count, id: \.self) { position in
                segment(position)
            }

            fill
            innerRule
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeOut(duration: 0.45), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: Bezel

    private var ticks: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2 - 2
            let majorEvery = max(1, 60 / count)

            for tick in 0..<60 {
                let angle = Double(tick) / 60 * 2 * Double.pi - Double.pi / 2
                let isMajor = tick % majorEvery == 0
                let length: CGFloat = isMajor ? 6 : 2.5
                let colour: Color
                if isMajor {
                    let boundary = min(tick / majorEvery, count)
                    if boundary < index {
                        colour = Theme.amber.opacity(0.45)
                    } else if boundary == index {
                        colour = Theme.amber.opacity(0.85)
                    } else {
                        colour = Color.white.opacity(0.18)
                    }
                } else {
                    colour = Color.white.opacity(0.08)
                }

                var path = Path()
                path.move(
                    to: CGPoint(
                        x: centre.x + CGFloat(cos(angle)) * outer,
                        y: centre.y + CGFloat(sin(angle)) * outer
                    )
                )
                path.addLine(
                    to: CGPoint(
                        x: centre.x + CGFloat(cos(angle)) * (outer - length),
                        y: centre.y + CGFloat(sin(angle)) * (outer - length)
                    )
                )
                context.stroke(path, with: .color(colour), lineWidth: isMajor ? 1.4 : 1)
            }
        }
        .frame(width: diameter, height: diameter)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Segments

    private func segment(_ position: Int) -> some View {
        Circle()
            .trim(from: startFraction(position) + gap, to: endFraction(position) - gap)
            .stroke(
                colour(for: state(position)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: bandDiameter, height: bandDiameter)
            .rotationEffect(.degrees(-90))
    }

    /// The part of the current stage that has already run.
    private var fill: some View {
        let fraction = min(1, max(0, progress))
        let start = startFraction(index)
        let span = max(0, step - gap * 2)

        return Circle()
            .trim(from: start + gap, to: start + gap + span * fraction)
            .stroke(Theme.amber, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: bandDiameter, height: bandDiameter)
            .rotationEffect(.degrees(-90))
            .shadow(color: Theme.amber.opacity(0.50), radius: 9)
            .shadow(color: Theme.amber.opacity(0.22), radius: 20)
            .opacity(fraction > 0.001 ? 1 : 0)
            .id(index)
            .animation(.linear(duration: 0.12), value: fraction)
    }

    private var innerRule: some View {
        Circle()
            .stroke(Color.white.opacity(0.05), lineWidth: 1)
            .frame(
                width: bandDiameter - lineWidth - 10,
                height: bandDiameter - lineWidth - 10
            )
    }

    // MARK: Geometry and colour

    private func startFraction(_ position: Int) -> Double {
        Double(position) * step
    }

    private func endFraction(_ position: Int) -> Double {
        Double(position + 1) * step
    }

    private func state(_ position: Int) -> Segment {
        if position < index { return .done }
        if position == index { return .active }
        return .upcoming
    }

    private func colour(for segment: Segment) -> Color {
        switch segment {
        case .done: return Theme.amber.opacity(0.52)
        case .active: return Theme.amber.opacity(0.20)
        case .upcoming: return Color.white.opacity(0.07)
        }
    }

    private var accessibilityText: String {
        guard stages.indices.contains(index) else { return "Stage timer" }
        return "\(stages[index].kind.title), stage \(index + 1) of \(count)"
    }
}
