//
//  TimeTemperatureToolView.swift
//  Darkroom
//
//  The time / temperature converter, both ways round: the time to use at the
//  water you have, or the water that gives the time you want.
//

import SwiftUI

struct TimeTemperatureCalculatorView: View {
    @State private var sheetSeconds = 10 * 60
    @State private var sheetCelsius: Double = 20
    @State private var waterCelsius: Double = 22
    @State private var wantedSeconds = 7 * 60
    @State private var continuousAgitation = false
    @State private var direction: DevelopmentDirection = .findTime
    @State private var editingSheetTime = false
    @State private var editingWantedTime = false
    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    // MARK: - The arithmetic

    /// The temperature the wanted time asks for, before the bath's range.
    private var requiredCelsius: Double {
        DevelopmentTimeCalculator.temperature(
            forSeconds: TimeInterval(wantedSeconds),
            nominalSeconds: TimeInterval(sheetSeconds),
            nominalCelsius: sheetCelsius,
            continuousAgitation: continuousAgitation
        )
    }

    private var workingCelsius: Double {
        direction == .findTemperature ? min(35, max(15, requiredCelsius)) : waterCelsius
    }

    private var outcome: DevelopmentTimeCalculator.Outcome {
        DevelopmentTimeCalculator.calculate(
            nominalSeconds: TimeInterval(sheetSeconds),
            nominalCelsius: sheetCelsius,
            actualCelsius: workingCelsius,
            continuousAgitation: continuousAgitation
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                introduction
                sheetCard
                directionCard
                resultCard
                nearbyCard
                formulaNote
                ToolSourceLink(
                    title: "Massive Dev Chart · Time/Temp Converter",
                    detail: "The converter this tool reproduces, written for Digitaltruth by Matthew Roughan.",
                    url: "https://www.digitaltruth.com/devchart.php?doc=timetemp"
                )
                ToolSourceLink(
                    title: "Film Developing Time Calculator",
                    detail: "Roughan's own page: the formula, the 10% for continuous agitation, and the warnings.",
                    url: "https://roughan.info/math/developing_time_calculator/"
                )
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background {
            LiquidBackdrop()
        }
        .navigationTitle("Times & temperature")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editingSheetTime) {
            DurationSheet(title: "Time from your sheet", seconds: $sheetSeconds)
        }
        .sheet(isPresented: $editingWantedTime) {
            DurationSheet(title: "Time you want", seconds: $wantedSeconds)
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            OverlineText(text: "Time / temperature", color: Theme.amber)
            Text("Warmer water develops faster.")
                .font(
                    themeStore.isTheme13Active
                        ? Theme13Type.headline(27)
                        : .system(size: 27, weight: .semibold, design: .rounded)
                )
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Put in the time your sheet gives and the temperature it is for. Then either set the water you have and read the time, or set the time you want and read the water.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - What the sheet says

    private var sheetCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                editingSheetTime = true
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("Your sheet says")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.ink)

                    Spacer(minLength: 8)

                    Text(Clock.mmss(TimeInterval(sheetSeconds)))
                        .font(.figures(30, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(HapticButtonStyle())

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            temperatureRow(title: "For water at", celsius: $sheetCelsius)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Which way round

    private var directionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SegmentedPill(
                options: DevelopmentDirection.allCases,
                selection: $direction,
                title: { $0.title }
            )

            if direction == .findTime {
                temperatureRow(title: "Your water is", celsius: $waterCelsius)
            } else {
                HStack(spacing: 10) {
                    Text("You want to develop for")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkSoft)

                    Spacer(minLength: 8)

                    Button {
                        editingWantedTime = true
                    } label: {
                        Text(Clock.mmss(TimeInterval(wantedSeconds)))
                            .font(.figures(22, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassCard(radius: 99, tint: Theme.amber)
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            Toggle(isOn: $continuousAgitation) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Agitate the whole time")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Text("Times are written for agitation at intervals. If the tank keeps moving, take 10% off.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.switchTint)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private func temperatureRow(title: String, celsius: Binding<Double>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 8)
                Text(Units.temperature(celsius.wrappedValue))
                    .font(.figures(15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .glassCard(radius: 99, tint: Theme.amber)
            }

            Slider(value: celsius, in: 15...35, step: 0.5)
                .tint(Theme.amber)
                .accessibilityLabel(title)
                .accessibilityValue(Units.temperature(celsius.wrappedValue))

            HStack {
                Text(Units.shortTemperature(15))
                Spacer()
                Text(Units.shortTemperature(35))
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkFaint)
        }
    }

    // MARK: - Result

    private var resultCard: some View {
        let outcome = self.outcome
        return VStack(alignment: .leading, spacing: 12) {
            OverlineText(
                text: direction == .findTime ? "Develop for" : "Use water at",
                color: Theme.amber
            )

            Text(direction == .findTime
                 ? Clock.mmss(outcome.seconds)
                 : Units.temperature(workingCelsius))
                .font(.figures(52, weight: .semibold))
                .foregroundStyle(Theme.amber)
                .contentTransition(.numericText())
                .accessibilityLabel(
                    direction == .findTime
                        ? "Develop for \(Clock.mmss(outcome.seconds))"
                        : "Use water at \(Units.temperature(workingCelsius))"
                )

            Text(summary(outcome))
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(outcome.warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 1)
                    Text(warning.message(scale: Preferences.shared.temperatureScale))
                        .font(.system(size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.42))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26, tint: Theme.amber)
    }

    private func summary(_ outcome: DevelopmentTimeCalculator.Outcome) -> String {
        if direction == .findTime {
            return "\(Clock.mmss(outcome.nominalSeconds)) at \(Units.temperature(outcome.nominalCelsius)) becomes \(Clock.mmss(outcome.seconds)) at \(Units.temperature(outcome.actualCelsius))."
        }
        if abs(requiredCelsius - workingCelsius) > 0.05 {
            return "That time needs water at \(Units.temperature(requiredCelsius)). The slider stops at \(Units.temperature(workingCelsius)), which gives \(Clock.mmss(outcome.seconds))."
        }
        return "Water at \(Units.temperature(workingCelsius)) gives \(Clock.mmss(outcome.seconds))."
    }

    // MARK: - The table the calculator also shows

    private var nearbyRows: [(id: Double, seconds: TimeInterval)] {
        (0...6).map { step in
            let celsius = sheetCelsius - 2 + Double(step)
            let seconds = DevelopmentTimeCalculator.calculate(
                nominalSeconds: TimeInterval(sheetSeconds),
                nominalCelsius: sheetCelsius,
                actualCelsius: celsius,
                continuousAgitation: continuousAgitation
            ).seconds
            return (celsius, seconds)
        }
    }

    private var nearbyCard: some View {
        let rows = nearbyRows
        let last = rows.last?.id ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            OverlineText(text: "Nearby temperatures", color: Theme.inkSoft)

            ForEach(rows, id: \.id) { row in
                HStack {
                    Text(Units.temperature(row.id))
                        .font(.figures(15))
                        .foregroundStyle(abs(row.id - workingCelsius) < 0.25 ? Theme.amber : Theme.ink)
                    Spacer()
                    Text(Clock.mmss(row.seconds))
                        .font(.figures(15, weight: .semibold))
                        .foregroundStyle(abs(row.id - workingCelsius) < 0.25 ? Theme.amber : Theme.inkSoft)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Units.temperature(row.id)): \(Clock.mmss(row.seconds))")

                if row.id < last {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - What the number is

    private var formulaNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Each degree cooler adds about 10%; each degree warmer takes about 10% away.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("The converter's own arithmetic is t = t₀ × e^(0.1 × (T₀ − T)), worked in Celsius. It is an estimate, not a published figure: test a combination before important work.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }
}
