//
//  RedroomCalculator.swift
//  Darkroom
//
//  The development time calculator, inside the tray. The arithmetic is the
//  app's own `DevelopmentTimeCalculator` — the same engine the session setup and
//  the Tools converter use — so this screen adds no maths of its own.
//
//  The liquid is drawn above the numbers and takes no input; every control here
//  is a normal SwiftUI control, fully accessible.
//

import SwiftUI

struct RedroomCalculatorView: View {
    @State private var sheetMinutes: Double = 10
    @State private var sheetCelsius: Double = 20
    @State private var waterCelsius: Double = 20
    @State private var continuousAgitation = false

    private var outcome: DevelopmentTimeCalculator.Outcome {
        DevelopmentTimeCalculator.calculate(
            nominalSeconds: sheetMinutes * 60,
            nominalCelsius: sheetCelsius,
            actualCelsius: waterCelsius,
            continuousAgitation: continuousAgitation
        )
    }

    var body: some View {
        DarkroomLiquidTray(depth: 1.0) {
            VStack(alignment: .leading, spacing: 16) {
                RedroomLabel("Development time")

                Text(Clock.mmss(outcome.seconds))
                    .font(Redroom.figure(46, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText(value: outcome.seconds))
                    .animation(.snappy(duration: 0.35), value: outcome.seconds)
                    .accessibilityLabel("Time to develop")
                    .accessibilityValue(Clock.mmss(outcome.seconds))

                stepper(
                    title: "Your sheet",
                    value: $sheetMinutes,
                    range: 1...60,
                    step: 0.5,
                    format: { Clock.mmss($0 * 60) }
                )

                stepper(
                    title: "Sheet at",
                    value: $sheetCelsius,
                    range: 15...30,
                    step: 0.5,
                    format: { Units.temperature($0) }
                )

                stepper(
                    title: "Your water",
                    value: $waterCelsius,
                    range: 18...24,
                    step: 0.5,
                    format: { Units.temperature($0) }
                )

                Toggle(isOn: $continuousAgitation) {
                    Text("Agitate the whole time")
                        .font(Redroom.body(14))
                        .foregroundStyle(Redroom.text)
                }
                .tint(Redroom.safelightSecondary)

                ForEach(Array(outcome.warnings.enumerated()), id: \.offset) { _, warning in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Redroom.safelight)
                        Text(warning.message(scale: Preferences.shared.temperatureScale))
                            .font(Redroom.body(12))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func stepper(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        Stepper(
            value: value,
            in: range,
            step: step
        ) {
            HStack {
                Text(title)
                    .font(Redroom.body(14))
                    .foregroundStyle(Redroom.textMuted)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(Redroom.figure(15, weight: .semibold))
                    .foregroundStyle(Redroom.text)
            }
        }
        .tint(Redroom.safelightSecondary)
        .accessibilityValue(format(value.wrappedValue))
    }
}
