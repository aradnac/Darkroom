//
//  RedroomComponents.swift
//  Darkroom
//
//  The physical controls: a rotary dial, a mechanical switch, a counter, a
//  laboratory thermometer, a liquid progress vessel, a chemical bottle and a
//  film negative card, plus the button styles and the anodised panel.
//
//  Each control binds to the same value a conventional control would and keeps
//  its accessibility label, value and adjustable action. Highlight geometry is
//  never written here: the glass and the rims read the shared safelight.
//

import SwiftUI

// MARK: - Buttons

struct RedroomPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Redroom.body(15, weight: .semibold))
            .foregroundStyle(isEnabled ? Redroom.text : Redroom.textMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Redroom.safelightSecondary.opacity(configuration.isPressed ? 0.55 : 0.30),
                                Redroom.deepRed.opacity(0.70)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        Redroom.safelight.opacity(configuration.isPressed ? 0.85 : 0.45),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.22), value: configuration.isPressed)
            .hapticFeedbackOnPress(isPressed: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

struct RedroomSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Redroom.body(15, weight: .medium))
            .foregroundStyle(isEnabled ? Redroom.text : Redroom.textMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .redroomGlass(variant: .transparent, cornerRadius: 16)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.22), value: configuration.isPressed)
            .hapticFeedbackOnPress(isPressed: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

// MARK: - Rotary dial

/// A mechanical dial: drag to turn it, with a tick of haptics at each notch and
/// an adjustable action for VoiceOver.
struct RedroomRotaryDial: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var format: (Double) -> String
    var diameter: CGFloat = 132

    @Environment(\.redroomLight) private var light
    @State private var dragStart: Double?

    private var span: Double {
        max(range.upperBound - range.lowerBound, 0.0001)
    }

    private var fraction: Double {
        min(max((value - range.lowerBound) / span, 0), 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let sample = RedroomLightSample.make(
                    frame: proxy.frame(in: .global),
                    light: light
                )
                let size = min(proxy.size.width, proxy.size.height)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Redroom.color(0x1A0808),
                                    Redroom.color(0x060202)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Circle()
                        .strokeBorder(Redroom.safelight.opacity(0.30 * sample.direct + 0.06), lineWidth: 1)

                    Canvas { context, canvasSize in
                        let centre = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                        let radius = min(canvasSize.width, canvasSize.height) / 2 - 8
                        for tick in 0..<40 {
                            let angle = Double(tick) / 40 * 2 * .pi - .pi * 0.72
                            let isMajor = tick % 5 == 0
                            let inner = radius - (isMajor ? 12 : 6)
                            var path = Path()
                            path.move(to: CGPoint(x: centre.x + CGFloat(cos(angle)) * radius, y: centre.y + CGFloat(sin(angle)) * radius))
                            path.addLine(to: CGPoint(x: centre.x + CGFloat(cos(angle)) * inner, y: centre.y + CGFloat(sin(angle)) * inner))
                            context.stroke(
                                path,
                                with: .color(isMajor ? Redroom.textMuted.opacity(0.7) : Redroom.textMuted.opacity(0.28)),
                                lineWidth: isMajor ? 1.4 : 1
                            )
                        }
                    }

                    Capsule()
                        .fill(Redroom.safelight)
                        .frame(width: 2, height: 34)
                        .offset(y: -size * 0.26)
                        .rotationEffect(.degrees(-129 + 258 * fraction))
                        .shadow(color: Redroom.safelight.opacity(0.6), radius: 6)

                    Circle()
                        .fill(Redroom.color(0x0E0404))
                        .frame(width: size * 0.46, height: size * 0.46)
                        .overlay {
                            Circle().strokeBorder(Redroom.deepRed.opacity(0.6), lineWidth: 1)
                        }

                    VStack(spacing: 0) {
                        Text(format(value))
                            .font(Redroom.figure(19, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Text(title.uppercased())
                            .font(Redroom.label(8))
                            .tracking(1)
                            .foregroundStyle(Redroom.textMuted)
                    }
                }
                .frame(width: size, height: size)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if dragStart == nil { dragStart = value }
                            let start = dragStart ?? value
                            let travel = Double(-gesture.translation.height + gesture.translation.width)
                            let raw = start + travel / 220 * span
                            let stepped = (raw / step).rounded() * step
                            let clamped = min(max(range.lowerBound, stepped), range.upperBound)
                            if abs(clamped - value) > 0.0001 {
                                value = clamped
                                Haptics.impact(.light)
                            }
                        }
                        .onEnded { _ in dragStart = nil }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityValue(format(value))
                .accessibilityAdjustableAction { direction in
                    let delta = direction == .increment ? step : -step
                    let clamped = min(max(range.lowerBound, value + delta), range.upperBound)
                    value = clamped
                }
            }
            .frame(width: diameter, height: diameter)
        }
    }
}

// MARK: - Switch

struct RedroomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer(minLength: 8)

                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(
                            configuration.isOn
                                ? Redroom.deepRed.opacity(0.9)
                                : Redroom.color(0x120606)
                        )
                        .frame(width: 54, height: 30)
                        .overlay {
                            Capsule().strokeBorder(
                                configuration.isOn
                                    ? Redroom.safelight.opacity(0.7)
                                    : Redroom.textDisabled.opacity(0.6),
                                lineWidth: 1
                            )
                        }

                    Circle()
                        .fill(configuration.isOn ? Redroom.safelight : Redroom.textMuted.opacity(0.5))
                        .frame(width: 22, height: 22)
                        .padding(.horizontal, 4)
                        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                }
                .animation(.snappy(duration: 0.22), value: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(
                isOn: Binding(
                    get: { configuration.isOn },
                    set: { configuration.isOn = $0 }
                )
            ) {
                configuration.label
            }
        }
    }
}

// MARK: - Counter

/// A mechanical counter: engraved label, monospaced figure, edge glow.
struct RedroomCounter: View {
    let label: String
    let value: String
    var unit: String?
    var size: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RedroomLabel(label)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(Redroom.figure(size, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.35), value: value)
                if let unit {
                    Text(unit)
                        .font(Redroom.body(13))
                        .foregroundStyle(Redroom.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .redroomGlass(variant: .reflective, cornerRadius: 14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(unit.map { "\(value) \($0)" } ?? value)
    }
}

// MARK: - Thermometer

/// A laboratory thermometer: a glass tube with a rising red column.
struct RedroomThermometer: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 15...35
    var step: Double = 0.5
    var height: CGFloat = 190

    private var fraction: Double {
        let span = max(range.upperBound - range.lowerBound, 0.0001)
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            GeometryReader { proxy in
                let tubeWidth: CGFloat = 18
                let filled = proxy.size.height * fraction

                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Redroom.color(0x0C0404))
                        .frame(width: tubeWidth)
                        .overlay {
                            Capsule().strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
                        }

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Redroom.safelight, Redroom.safelightSecondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: tubeWidth - 6, height: max(10, filled))
                        .shadow(color: Redroom.safelight.opacity(0.5), radius: 6)

                    Circle()
                        .fill(Redroom.safelight)
                        .frame(width: tubeWidth + 12, height: tubeWidth + 12)
                        .offset(y: 10)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let ratio = 1 - min(max(gesture.location.y / proxy.size.height, 0), 1)
                            let raw = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
                            let stepped = (raw / step).rounded() * step
                            let clamped = min(max(range.lowerBound, stepped), range.upperBound)
                            if abs(clamped - value) > 0.0001 {
                                value = clamped
                                Haptics.impact(.light)
                            }
                        }
                )
            }
            .frame(width: 44, height: height)

            VStack(alignment: .leading, spacing: 6) {
                RedroomLabel(title)
                Text(Units.temperature(value))
                    .font(Redroom.figure(26, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                Text("Drag the column")
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Units.temperature(value))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? step : -step
            value = min(max(range.lowerBound, value + delta), range.upperBound)
        }
    }
}

// MARK: - Liquid progress

/// Progress drawn as chemistry rising in a horizontal vessel, always with the
/// figure beside it.
struct RedroomLiquidProgress: View {
    let title: String
    let fraction: Double
    let readout: String

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RedroomLabel(title)
                Spacer(minLength: 8)
                Text(readout)
                    .font(Redroom.figure(14, weight: .semibold))
                    .foregroundStyle(Redroom.text)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Redroom.color(0x0C0404))
                        .overlay {
                            Capsule().strokeBorder(Redroom.textDisabled.opacity(0.45), lineWidth: 1)
                        }

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Redroom.safelightSecondary.opacity(0.85), Redroom.deepRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, proxy.size.width * clamped))
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(Color.white.opacity(0.22))
                                .frame(height: 2)
                                .offset(y: 3)
                        }
                }
            }
            .frame(height: 18)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(readout)
    }
}

// MARK: - Bottle

/// A transparent chemical bottle. The level is the real remaining quantity.
struct ChemicalBottle: View {
    let name: String
    let detail: String
    /// 0...1, filled from the batch's remaining capacity.
    let level: Double
    var warning: Bool = false

    private var clamped: Double { min(max(level, 0), 1) }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let liquidHeight = max(4, height * 0.86 * clamped)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Redroom.color(0x0E0505).opacity(0.85))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Redroom.textDisabled.opacity(0.55), lineWidth: 1)
                        }

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Redroom.safelightSecondary.opacity(0.55),
                                    Redroom.deepRed.opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: liquidHeight)
                        .padding(.horizontal, 3)
                        .padding(.bottom, 3)
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(Redroom.safelight.opacity(0.75))
                                .frame(height: 2)
                                .padding(.horizontal, 6)
                                .offset(y: height - liquidHeight - 2)
                        }

                    // Neck
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Redroom.color(0x120606))
                        .frame(width: width * 0.34, height: height * 0.16)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
                        }
                        .offset(y: -height * 0.80)
                }
            }
            .frame(width: 62, height: 96)

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(Redroom.body(16, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                Text(detail)
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if warning {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Check this batch")
                            .font(Redroom.body(11, weight: .medium))
                    }
                    .foregroundStyle(Redroom.safelight)
                }
            }

            Spacer(minLength: 0)

            Text("\(Int((clamped * 100).rounded()))%")
                .font(Redroom.figure(15, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent remaining. \(detail)")
    }
}

// MARK: - Film negative card

/// A strip of film: sprocket holes, dark frames, a red backlight. Selected
/// frames illuminate.
struct FilmNegativeCard: View {
    let title: String
    let subtitle: String
    var selected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Canvas { context, size in
                let holeWidth: CGFloat = 7
                let holeHeight: CGFloat = 5
                let pitch = holeWidth * 2.4
                let stripTop: CGFloat = 0
                let stripBottom = size.height

                for x in stride(from: pitch / 2, to: size.width, by: pitch) {
                    let topHole = CGRect(x: x - holeWidth / 2, y: stripTop + 4, width: holeWidth, height: holeHeight)
                    let bottomHole = CGRect(x: x - holeWidth / 2, y: stripBottom - holeHeight - 4, width: holeWidth, height: holeHeight)
                    context.fill(Path(roundedRect: topHole, cornerRadius: 1.5), with: .color(Redroom.color(0x1C0B0B)))
                    context.fill(Path(roundedRect: bottomHole, cornerRadius: 1.5), with: .color(Redroom.color(0x1C0B0B)))
                }

                let frameRect = CGRect(x: 10, y: 14, width: size.width - 20, height: size.height - 28)
                context.fill(
                    Path(roundedRect: frameRect, cornerRadius: 4),
                    with: .color(selected ? Redroom.safelightSecondary.opacity(0.55) : Redroom.color(0x080303))
                )
            }
            .frame(height: 68)
            .background(Redroom.color(0x0B0404))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Redroom.textDisabled.opacity(0.4), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Redroom.body(15, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: selected ? .optical : .smoked, cornerRadius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Enlarger panel

/// Black anodised metal with engraved markings, used for parameter groups.
struct RedroomEnlargerPanel: ViewModifier {
    var marked: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Redroom.color(0x141010),
                                Redroom.color(0x070404)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Redroom.textDisabled.opacity(0.35), lineWidth: 1)
                    }
            }
            .overlay(alignment: .topLeading) {
                if marked {
                    Rectangle()
                        .fill(Redroom.deepRed.opacity(0.8))
                        .frame(width: 46, height: 2)
                        .padding(.leading, 16)
                        .padding(.top, 10)
                }
            }
    }
}

extension View {
    func enlargerPanel(marked: Bool = true) -> some View {
        modifier(RedroomEnlargerPanel(marked: marked))
    }
}
