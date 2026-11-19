//
//  AgitationLiquid.swift
//  Darkroom
//
//  The moving liquid indicator: a small vessel whose surface moves with the prompt —
//  sloshing hard for an inversion, bubbling for the tap on the bench, settling flat
//  for the rest.
//

import SwiftUI

struct AgitationLiquid: View {
    let kind: AgitationKind?
    var width: CGFloat = 56
    var height: CGFloat = 76

    private struct Motion {
        let level: Double
        let wave: Double
        let speed: Double
        let rising: Bool
    }

    private var motion: Motion {
        switch kind {
        case .initial, .invert:
            return Motion(level: 0.62, wave: 0.10, speed: 2.4, rising: false)
        case .tap:
            return Motion(level: 0.48, wave: 0.05, speed: 1.1, rising: true)
        case .rest:
            return Motion(level: 0.30, wave: 0.022, speed: 0.5, rising: false)
        case .continuous:
            return Motion(level: 0.58, wave: 0.11, speed: 2.0, rising: false)
        case .none:
            return Motion(level: 0.20, wave: 0.014, speed: 0.35, rising: false)
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                draw(context: context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .frame(width: width, height: height)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut(duration: 0.45), value: kind)
        .allowsHitTesting(false)
    }

    private func draw(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let motion = self.motion
        let inset: CGFloat = 7
        let innerWidth = size.width - inset * 2
        let innerHeight = size.height - inset * 2
        let surfaceY = inset + innerHeight * (1 - motion.level)
        let amplitude = innerHeight * motion.wave
        let wavelength = max(innerWidth * 0.7, 20)

        func surface(_ x: Double) -> Double {
            let phase = x / Double(wavelength) * Double.pi * 2 + time * motion.speed
            let ripple = sin(phase) * Double(amplitude)
            let swell = sin(phase * 0.5 + time * motion.speed * 0.6) * Double(amplitude) * 0.5
            return Double(surfaceY) + ripple + swell
        }

        var liquid = Path()
        var x = 0.0
        liquid.move(to: CGPoint(x: x, y: surface(x)))
        while x <= Double(innerWidth) {
            liquid.addLine(to: CGPoint(x: x, y: surface(x)))
            x += 3
        }
        liquid.addLine(to: CGPoint(x: Double(innerWidth), y: Double(size.height)))
        liquid.addLine(to: CGPoint(x: 0, y: Double(size.height)))
        liquid.closeSubpath()

        context.fill(
            liquid,
            with: .linearGradient(
                Gradient(colors: [Theme.amber.opacity(0.9), Theme.amber.opacity(0.35)]),
                startPoint: CGPoint(x: 0, y: surfaceY),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        var crest = Path()
        var crestX = 0.0
        crest.move(to: CGPoint(x: crestX, y: surface(crestX)))
        while crestX <= Double(innerWidth) {
            crest.addLine(to: CGPoint(x: crestX, y: surface(crestX)))
            crestX += 3
        }
        context.stroke(crest, with: .color(.white.opacity(0.45)), lineWidth: 1.2)

        guard motion.rising else { return }

        for index in 0..<5 {
            let lane = 8.0 + Double(index) * Double(innerWidth) / 5.0
            guard lane < Double(innerWidth) - 2 else { continue }
            let period = 1.6 + Double(index) * 0.27
            let progress = (time / period + Double(index) * 0.31).truncatingRemainder(dividingBy: 1)
            let span = Double(size.height) - Double(surfaceY) - Double(inset)
            guard span > 2 else { continue }
            let bubbleY = Double(size.height) - Double(inset) - progress * span
            let radius = 1.4 + Double(index % 2) * 0.8
            let rect = CGRect(x: lane - radius, y: bubbleY - radius, width: radius * 2, height: radius * 2)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(.white.opacity(0.45 * (1 - progress)))
            )
        }
    }
}
