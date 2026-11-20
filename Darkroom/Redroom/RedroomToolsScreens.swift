//
//  RedroomToolsScreens.swift
//  Darkroom
//
//  The Tools bench in REDROOM: the sink-side utilities as instruments on the
//  room's own bench. Timers are dials and gauges, references are stamped plates,
//  and the tank visualizer is drawn as the tank it describes, lit by the one
//  safelight.
//
//  Every figure and every rule is the app's: the calculator, the interval logic,
//  the wash schedule, the troubleshooter's ranked causes and the reference
//  content are unchanged.
//

import SwiftUI

// MARK: - Tab

struct RedroomToolsTab: View {
    var body: some View {
        NavigationStack {
            RedroomToolsHub()
        }
    }
}

// MARK: - Hub

struct RedroomToolsHub: View {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    var body: some View {
        RedroomScreen {
            RedroomScreenHeader(kicker: "At the sink", title: "Tools")
                .redroomReveal(.safelightFade)

            VStack(alignment: .leading, spacing: 4) {
                Text("Small tools.\nSteady hands.")
                    .font(Redroom.display(24, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Quick conversions, dependable timing, and references for the work in front of you.")
                    .font(Redroom.body(13))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            toolGroup(title: "Instruments") {
                toolLink("Film troubleshooter", "What do your negatives show?", "exclamationmark.triangle") {
                    RedroomTroubleshooter()
                }
                toolLink("Times & temperature", "Move a development time to another temperature", "hourglass") {
                    RedroomTimeTemperature()
                }
                toolLink("Temperature", "Convert °C and °F", "thermometer.medium") {
                    RedroomTemperatureConverter()
                }
                toolLink("Stopwatch", "Elapsed time with lap splits", "stopwatch") {
                    RedroomStopwatch()
                }
                toolLink("Interval timer", "Set work, rest, and rounds", "repeat") {
                    RedroomIntervalTimer()
                }
                toolLink("Wash & final rinse", "Fill-and-dump guide and timers", "drop") {
                    RedroomWashRinse()
                }
                toolLink("Tank visualizer", "See how far a pour reaches", "cylinder") {
                    RedroomTankVisualizer()
                }
            }

            toolGroup(title: "Reference") {
                toolLink("Film leader retrieval", "A documented 35 mm retriever method", "film") {
                    RedroomFilmLeaderGuide()
                }
                toolLink("Tank capacities", "Film load and reference volumes", "cylinder.split.1x2") {
                    RedroomTankCapacityReference()
                }
                toolLink("Chemical safety", "Handling, ventilation, and disposal", "hand.raised") {
                    RedroomChemicalSafety()
                }
            }

            Button {
                themeStore.isShowingSettings = true
            } label: {
                RedroomNavRow(
                    title: "Settings",
                    detail: "Appearance, motion and the room",
                    symbol: "slider.horizontal.3"
                )
            }
            .buttonStyle(HapticButtonStyle())
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toolGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RedroomSectionHeader(title: title)
            content()
        }
    }

    private func toolLink<Destination: View>(
        _ title: String,
        _ detail: String,
        _ symbol: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            RedroomNavRow(title: title, detail: detail, symbol: symbol)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .redroomGlass(variant: .smoked, cornerRadius: 18)
        }
        .buttonStyle(HapticButtonStyle())
    }
}

// MARK: - Source link

struct RedroomToolSourceLink: View {
    let title: String
    let detail: String
    let url: String

    var body: some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Redroom.safelight)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(Redroom.body(12, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Text(detail)
                            .font(Redroom.body(10))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .redroomGlass(variant: .smoked, cornerRadius: 16)
            }
            .buttonStyle(HapticButtonStyle())
        }
    }
}

// MARK: - Temperature converter

struct RedroomTemperatureConverter: View {
    private enum Direction: String, CaseIterable, Identifiable {
        case celsiusToFahrenheit
        case fahrenheitToCelsius

        var id: String { rawValue }
        var title: String { self == .celsiusToFahrenheit ? "°C → °F" : "°F → °C" }
        var inputUnit: String { self == .celsiusToFahrenheit ? "°C" : "°F" }
        var outputUnit: String { self == .celsiusToFahrenheit ? "°F" : "°C" }
    }

    @State private var direction: Direction = .celsiusToFahrenheit
    @State private var input = "20"

    private var output: Double? {
        let normalized = input.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite else { return nil }
        switch direction {
        case .celsiusToFahrenheit: return value * 9 / 5 + 32
        case .fahrenheitToCelsius: return (value - 32) * 5 / 9
        }
    }

    var body: some View {
        RedroomScreen {
            RedroomSegmented(
                items: Direction.allCases,
                selection: $direction,
                title: { $0.title }
            )

            RedroomPanel(title: "Reading", variant: .optical) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("Temperature", text: $input)
                        .font(Redroom.figure(40, weight: .medium))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Redroom.text)
                        .tint(Redroom.safelight)
                        .accessibilityLabel("Input temperature in \(direction.inputUnit)")

                    Text(direction.inputUnit)
                        .font(Redroom.body(16, weight: .semibold))
                        .foregroundStyle(Redroom.textMuted)
                }

                RedroomLitRule()

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(output.map { String(format: "%.1f", $0) } ?? "—")
                        .font(Redroom.figure(32, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                        .contentTransition(.numericText())

                    Text(direction.outputUnit)
                        .font(Redroom.body(15, weight: .semibold))
                        .foregroundStyle(Redroom.textMuted)

                    Spacer(minLength: 4)

                    Image(systemName: "arrow.right")
                        .foregroundStyle(Redroom.textMuted)
                }
            }

            RedroomNote(text: "°F = (°C × 9 ÷ 5) + 32   ·   °C = (°F − 32) × 5 ÷ 9", symbol: "function")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Temperature")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Time & temperature

struct RedroomTimeTemperature: View {
    @State private var sheetSeconds = 10 * 60
    @State private var sheetCelsius: Double = 20
    @State private var waterCelsius: Double = 22
    @State private var wantedSeconds = 7 * 60
    @State private var continuousAgitation = false
    @State private var direction: DevelopmentDirection = .findTime
    @State private var editingSheetTime = false
    @State private var editingWantedTime = false

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

    var body: some View {
        RedroomScreen {
            RedroomPanel(title: "Your sheet says") {
                Button {
                    editingSheetTime = true
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Development time")
                            .font(Redroom.body(13))
                            .foregroundStyle(Redroom.textMuted)
                        Spacer(minLength: 6)
                        Text(Clock.mmss(TimeInterval(sheetSeconds)))
                            .font(Redroom.figure(28, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(HapticButtonStyle())

                RedroomLitRule(thickness: 0.5)

                RedroomThermometer(
                    title: "For water at",
                    value: $sheetCelsius,
                    range: 15...35,
                    step: 0.5,
                    height: 150
                )
            }

            RedroomPanel {
                RedroomSegmented(
                    items: DevelopmentDirection.allCases,
                    selection: $direction,
                    title: { $0.title }
                )

                if direction == .findTime {
                    RedroomThermometer(
                        title: "Your water is",
                        value: $waterCelsius,
                        range: 15...35,
                        step: 0.5,
                        height: 150
                    )
                } else {
                    Button {
                        editingWantedTime = true
                    } label: {
                        HStack {
                            Text("You want to develop for")
                                .font(Redroom.body(13))
                                .foregroundStyle(Redroom.textMuted)
                            Spacer(minLength: 6)
                            Text(Clock.mmss(TimeInterval(wantedSeconds)))
                                .font(Redroom.figure(18, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())
                }

                RedroomLitRule(thickness: 0.5)

                Toggle(isOn: $continuousAgitation) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Agitate the whole time")
                            .font(Redroom.body(14, weight: .medium))
                            .foregroundStyle(Redroom.text)
                        Text("Times are written for agitation at intervals. If the tank keeps moving, take 10% off.")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(RedroomToggleStyle())
            }

            RedroomPanel(
                title: direction == .findTime ? "Develop for" : "Use water at",
                variant: .optical
            ) {
                Text(direction == .findTime
                     ? Clock.mmss(outcome.seconds)
                     : Units.temperature(workingCelsius))
                    .font(Redroom.figure(46, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText())

                Text(summary)
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(outcome.warnings, id: \.self) { warning in
                    RedroomWarning(
                        title: "Treat this as a starting point",
                        detail: warning.message(scale: Preferences.shared.temperatureScale)
                    )
                }
            }

            RedroomPanel(title: "Nearby temperatures") {
                let rows = nearbyRows
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack {
                        Text(Units.temperature(row.id))
                            .font(Redroom.figure(13))
                            .foregroundStyle(Redroom.textMuted)
                        Spacer(minLength: 6)
                        Text(Clock.mmss(row.seconds))
                            .font(Redroom.figure(13, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(Units.temperature(row.id)): \(Clock.mmss(row.seconds))")

                    if index < rows.count - 1 {
                        RedroomLitRule(thickness: 0.5)
                    }
                }
            }

            RedroomNote(text: "The converter's own arithmetic is t = t₀ × e^(0.1 × (T₀ − T)), worked in Celsius. It is an estimate, not a published figure: test a combination before important work.")

            RedroomToolSourceLink(
                title: "Massive Dev Chart · Time/Temp Converter",
                detail: "The converter this tool reproduces, written for Digitaltruth by Matthew Roughan.",
                url: "https://www.digitaltruth.com/devchart.php?doc=timetemp"
            )
            RedroomToolSourceLink(
                title: "Film Developing Time Calculator",
                detail: "Roughan's own page: the formula, the 10% for continuous agitation, and the warnings.",
                url: "https://roughan.info/math/developing_time_calculator/"
            )
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Times & temperature")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $editingSheetTime) {
            RedroomDurationSheet(title: "Time from your sheet", seconds: $sheetSeconds)
        }
        .sheet(isPresented: $editingWantedTime) {
            RedroomDurationSheet(title: "Time you want", seconds: $wantedSeconds)
        }
    }

    private var summary: String {
        if direction == .findTime {
            return "\(Clock.mmss(outcome.nominalSeconds)) at \(Units.temperature(outcome.nominalCelsius)) becomes \(Clock.mmss(outcome.seconds)) at \(Units.temperature(outcome.actualCelsius))."
        }
        if abs(requiredCelsius - workingCelsius) > 0.05 {
            return "That time needs water at \(Units.temperature(requiredCelsius)). The setting stops at \(Units.temperature(workingCelsius)), which gives \(Clock.mmss(outcome.seconds))."
        }
        return "Water at \(Units.temperature(workingCelsius)) gives \(Clock.mmss(outcome.seconds))."
    }

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
}

// MARK: - Live readout

private struct RedroomTicker<Content: View>: View {
    var running: Bool
    var interval: TimeInterval
    @ViewBuilder var content: (Date) -> Content

    var body: some View {
        if running {
            TimelineView(.periodic(from: .now, by: interval)) { context in
                content(context.date)
            }
        } else {
            content(Date())
        }
    }
}

// MARK: - Stopwatch

struct RedroomStopwatch: View {
    @State private var accumulated: TimeInterval = 0
    @State private var runningSince: Date?
    @State private var laps: [TimeInterval] = []

    private func elapsed(at date: Date) -> TimeInterval {
        accumulated + (runningSince.map { date.timeIntervalSince($0) } ?? 0)
    }

    var body: some View {
        RedroomScreen {
            VStack(spacing: 8) {
                RedroomLabel("Elapsed time")

                RedroomTicker(running: runningSince != nil, interval: 0.1) { date in
                    let current = elapsed(at: date)
                    Text(Clock.mmss(current))
                        .font(Redroom.figure(54, weight: .medium))
                        .foregroundStyle(Redroom.text)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .accessibilityLabel("Elapsed \(Clock.mmss(current))")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .redroomGlass(variant: .optical, cornerRadius: RedroomMetrics.cardRadius)

            HStack(spacing: 8) {
                Button {
                    if runningSince == nil {
                        runningSince = Date()
                    } else {
                        accumulated = elapsed(at: Date())
                        runningSince = nil
                    }
                } label: {
                    Text(runningSince == nil ? "Start" : "Pause")
                }
                .buttonStyle(RedroomPrimaryButtonStyle())

                Button {
                    if runningSince != nil {
                        laps.insert(elapsed(at: Date()), at: 0)
                    }
                } label: {
                    Text("Lap")
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
                .disabled(runningSince == nil)
            }

            if !laps.isEmpty {
                RedroomPanel(title: "Laps", detail: "Reset clears the watch and every split.") {
                    ForEach(Array(laps.enumerated()), id: \.offset) { index, lap in
                        HStack {
                            Text(String(format: "Lap %02d", laps.count - index))
                                .font(Redroom.body(13))
                                .foregroundStyle(Redroom.textMuted)
                            Spacer(minLength: 6)
                            Text(Clock.mmss(lap))
                                .font(Redroom.figure(13, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                            Text(Clock.mmss(lap - (index + 1 < laps.count ? laps[index + 1] : 0)))
                                .font(Redroom.figure(12))
                                .foregroundStyle(Redroom.textMuted)
                                .frame(width: 68, alignment: .trailing)
                        }
                        .padding(.vertical, 7)

                        if index < laps.count - 1 {
                            RedroomLitRule(thickness: 0.5)
                        }
                    }

                    Button("Reset") {
                        accumulated = 0
                        runningSince = nil
                        laps.removeAll()
                    }
                    .font(Redroom.body(13, weight: .semibold))
                    .foregroundStyle(Redroom.safelight)
                }
            } else if accumulated > 0 || runningSince != nil {
                RedroomNote(text: "Lap splits appear here while the stopwatch is running.")
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Stopwatch")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Interval timer

struct RedroomIntervalTimer: View {
    private enum Phase {
        case ready
        case work
        case rest
        case finished

        var title: String {
            switch self {
            case .ready: return "Ready"
            case .work: return "Work"
            case .rest: return "Rest"
            case .finished: return "Complete"
            }
        }
    }

    @State private var workSeconds = 60
    @State private var restSeconds = 15
    @State private var rounds = 8
    @State private var currentRound = 1
    @State private var phase: Phase = .ready
    @State private var remaining: TimeInterval = 60
    @State private var deadline: Date?
    @State private var isRunning = false

    private var editable: Bool { !isRunning && phase != .work && phase != .rest }

    var body: some View {
        RedroomScreen {
            countdown

            if editable {
                RedroomPanel(title: "Your interval") {
                    RedroomStepper(
                        title: "Work",
                        value: Clock.mmss(TimeInterval(workSeconds)),
                        decrement: workSeconds > 5 ? { workSeconds -= 5 } : nil,
                        increment: workSeconds < 3600 ? { workSeconds += 5 } : nil
                    )
                    RedroomStepper(
                        title: "Rest",
                        value: Clock.mmss(TimeInterval(restSeconds)),
                        decrement: restSeconds > 0 ? { restSeconds -= 5 } : nil,
                        increment: restSeconds < 1800 ? { restSeconds += 5 } : nil
                    )
                    RedroomStepper(
                        title: "Rounds",
                        value: "\(rounds)",
                        decrement: rounds > 1 ? { rounds -= 1 } : nil,
                        increment: rounds < 50 ? { rounds += 1 } : nil
                    )

                    RedroomNote(text: "Zero rest runs each work interval straight into the next.")
                }
            }

            HStack(spacing: 8) {
                Button {
                    toggle(at: Date())
                } label: {
                    Text(isRunning ? "Pause" : (phase == .finished ? "Again" : "Start"))
                }
                .buttonStyle(RedroomPrimaryButtonStyle())

                Button {
                    reset()
                } label: {
                    Text("Reset")
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Interval timer")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { date in
            advanceTimer(at: date)
        }
    }

    private var countdown: some View {
        VStack(spacing: 8) {
            RedroomLabel(phase.title)

            RedroomTicker(running: isRunning, interval: 0.2) { date in
                let value = isRunning ? max(0, (deadline ?? date).timeIntervalSince(date)) : remaining
                Text(Clock.mmssCeil(value))
                    .font(Redroom.figure(54, weight: .medium))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Text(phase == .ready ? "Configure your intervals below." : "Round \(min(currentRound, rounds)) of \(rounds)")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .redroomGlass(variant: .optical, cornerRadius: RedroomMetrics.cardRadius)
    }

    private func toggle(at date: Date) {
        if isRunning {
            advanceTimer(at: date)
            guard isRunning else { return }
            remaining = max(0, (deadline ?? date).timeIntervalSince(date))
            deadline = nil
            isRunning = false
            return
        }

        if phase == .finished || phase == .ready {
            currentRound = 1
            phase = .work
            remaining = TimeInterval(workSeconds)
        }

        if remaining <= 0 {
            remaining = TimeInterval(workSeconds)
        }
        deadline = date.addingTimeInterval(remaining)
        isRunning = true
    }

    private func reset() {
        isRunning = false
        deadline = nil
        phase = .ready
        currentRound = 1
        remaining = TimeInterval(workSeconds)
    }

    private func advanceTimer(at now: Date) {
        guard isRunning, var boundary = deadline else { return }
        guard now >= boundary else {
            remaining = max(0, boundary.timeIntervalSince(now))
            return
        }

        while isRunning && now >= boundary {
            switch phase {
            case .work:
                if restSeconds > 0 {
                    phase = .rest
                    remaining = TimeInterval(restSeconds)
                    boundary = boundary.addingTimeInterval(TimeInterval(restSeconds))
                } else {
                    currentRound += 1
                    if currentRound > rounds {
                        finish()
                    } else {
                        phase = .work
                        remaining = TimeInterval(workSeconds)
                        boundary = boundary.addingTimeInterval(TimeInterval(workSeconds))
                    }
                }
            case .rest:
                currentRound += 1
                if currentRound > rounds {
                    finish()
                } else {
                    phase = .work
                    remaining = TimeInterval(workSeconds)
                    boundary = boundary.addingTimeInterval(TimeInterval(workSeconds))
                }
            case .ready, .finished:
                finish()
            }
        }

        if isRunning {
            deadline = boundary
            remaining = max(0, boundary.timeIntervalSince(now))
        }
    }

    private func finish() {
        phase = .finished
        remaining = 0
        deadline = nil
        isRunning = false
    }
}

// MARK: - Wash & rinse

struct RedroomWashRinse: View {
    private enum Selection: String, CaseIterable, Identifiable {
        case wash = "Wash"
        case rinse = "Final rinse"
        var id: String { rawValue }
    }

    private enum Method: String, CaseIterable, Identifiable {
        case fillAndDump = "Fill & dump"
        case runningWater = "Running water"
        var id: String { rawValue }
    }

    @State private var selection: Selection = .wash
    @State private var method: Method = .fillAndDump
    @State private var washElapsedBeforeStart: TimeInterval = 0
    @State private var washStartedAt: Date?
    @State private var washStep = 0
    @State private var inversions = 0
    @State private var washComplete = false
    @State private var rinseDuration = 30
    @State private var rinseRemaining: TimeInterval = 30
    @State private var rinseDeadline: Date?
    @State private var rinseRunning = false

    private let inversionSchedule = [5, 10, 20]

    var body: some View {
        RedroomScreen {
            RedroomSegmented(
                items: Selection.allCases,
                selection: $selection,
                title: { $0.rawValue }
            )

            if selection == .wash {
                washContent
            } else {
                rinseContent
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Wash & rinse")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { date in
            if rinseRunning, let rinseDeadline, date >= rinseDeadline {
                self.rinseRemaining = 0
                self.rinseDeadline = nil
                self.rinseRunning = false
            }
        }
    }

    private var washContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            RedroomPanel(
                title: "Wash the fixer away",
                detail: "Use the method recommended for your film and fixer. The fill-and-dump sequence below is a published ILFORD method, not a universal time target."
            ) {
                RedroomSegmented(
                    items: Method.allCases,
                    selection: $method,
                    title: { $0.rawValue }
                )

                if method == .fillAndDump {
                    HStack(spacing: 8) {
                        ForEach(Array(inversionSchedule.enumerated()), id: \.offset) { index, count in
                            VStack(spacing: 3) {
                                Text("\(count)")
                                    .font(Redroom.figure(18, weight: .semibold))
                                    .foregroundStyle(washStep == index && !washComplete ? Redroom.text : Redroom.textMuted)
                                Text("inversions")
                                    .font(Redroom.label(8))
                                    .foregroundStyle(Redroom.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(washStep == index && !washComplete ? Redroom.deepRed.opacity(0.5) : Redroom.color(0x0B0404))
                            }
                        }
                    }

                    if washComplete {
                        Label("Three changes complete", systemImage: "checkmark.circle.fill")
                            .font(Redroom.body(13, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            RedroomLabel("Change \(washStep + 1) of 3")
                            Text("Fill with fresh water. Invert the tank \(inversionSchedule[washStep]) times, then drain.")
                                .font(Redroom.body(13, weight: .medium))
                                .foregroundStyle(Redroom.text)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Inversions counted: \(inversions) / \(inversionSchedule[washStep])")
                                .font(Redroom.figure(12))
                                .foregroundStyle(Redroom.textMuted)
                        }
                    }

                    HStack(spacing: 8) {
                        Button {
                            guard !washComplete else { return }
                            inversions = min(inversions + 1, inversionSchedule[washStep])
                        } label: {
                            Text("Count inversion")
                        }
                        .buttonStyle(RedroomSecondaryButtonStyle())
                        .disabled(washComplete || inversions >= inversionSchedule[washStep])

                        Button {
                            guard !washComplete, inversions >= inversionSchedule[washStep] else { return }
                            if washStep == inversionSchedule.count - 1 {
                                washComplete = true
                            } else {
                                washStep += 1
                                inversions = 0
                            }
                        } label: {
                            Text(washStep == inversionSchedule.count - 1 ? "Finish" : "Drained · next")
                        }
                        .buttonStyle(RedroomPrimaryButtonStyle())
                        .disabled(washComplete || inversions < inversionSchedule[washStep])
                    }
                } else {
                    RedroomNote(text: "Keep fresh water flowing through the tank. There is no single running-water duration shown here; follow the instructions for your film and fixer.")
                }
            }

            RedroomPanel(title: "Wash elapsed") {
                HStack(alignment: .firstTextBaseline) {
                    RedroomTicker(running: washStartedAt != nil, interval: 0.2) { date in
                        let elapsed = washElapsedBeforeStart + (washStartedAt.map { date.timeIntervalSince($0) } ?? 0)
                        Text(Clock.mmss(elapsed))
                            .font(Redroom.figure(24, weight: .medium))
                            .foregroundStyle(Redroom.text)
                            .contentTransition(.numericText())
                    }
                    Spacer(minLength: 6)
                    Text(Clock.mmss(washElapsedBeforeStart))
                        .font(Redroom.body(10))
                        .foregroundStyle(Redroom.textMuted)
                        .opacity(0)
                }

                HStack(spacing: 8) {
                    Button {
                        if let started = washStartedAt {
                            washElapsedBeforeStart += Date().timeIntervalSince(started)
                            washStartedAt = nil
                        } else {
                            washStartedAt = Date()
                        }
                    } label: {
                        Text(washStartedAt == nil ? "Start wash timer" : "Pause")
                    }
                    .buttonStyle(RedroomPrimaryButtonStyle())

                    Button("Reset") {
                        washStartedAt = nil
                        washElapsedBeforeStart = 0
                        washStep = 0
                        inversions = 0
                        washComplete = false
                    }
                    .buttonStyle(RedroomSecondaryButtonStyle())
                }
            }

            RedroomToolSourceLink(
                title: "ILFORD PHOTO · film processing chart",
                detail: "Manufacturer downloadable processing chart; check current instructions for the film and fixer in use.",
                url: "https://www.ilfordphoto.com/amfile/file/download/file/1953/product/691/"
            )
        }
    }

    private var rinseContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            RedroomPanel(
                title: "A clean finish",
                detail: "Use wetting agent at the dilution on its label. The app's 30-second default matches its development-session rinse; it is a timer setting, not a universal product instruction."
            ) {
                RedroomTicker(running: rinseRunning, interval: 0.2) { date in
                    let timeLeft = rinseRunning ? max(0, (rinseDeadline ?? date).timeIntervalSince(date)) : rinseRemaining
                    Text(Clock.mmssCeil(timeLeft))
                        .font(Redroom.figure(52, weight: .medium))
                        .foregroundStyle(Redroom.text)
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity)
                }

                if !rinseRunning {
                    RedroomStepper(
                        title: "Timer setting",
                        value: Clock.mmss(TimeInterval(rinseDuration)),
                        decrement: rinseDuration > 10 ? { rinseDuration -= 10; rinseRemaining = TimeInterval(rinseDuration) } : nil,
                        increment: rinseDuration < 180 ? { rinseDuration += 10; rinseRemaining = TimeInterval(rinseDuration) } : nil
                    )
                }

                HStack(spacing: 8) {
                    Button {
                        if rinseRunning {
                            rinseRemaining = max(0, (rinseDeadline ?? Date()).timeIntervalSinceNow)
                            rinseDeadline = nil
                            rinseRunning = false
                        } else {
                            if rinseRemaining <= 0 {
                                rinseRemaining = TimeInterval(rinseDuration)
                            }
                            rinseDeadline = Date().addingTimeInterval(rinseRemaining)
                            rinseRunning = true
                        }
                    } label: {
                        Text(rinseRunning ? "Pause" : (rinseRemaining == 0 ? "Start again" : "Start rinse"))
                    }
                    .buttonStyle(RedroomPrimaryButtonStyle())

                    Button("Reset") {
                        rinseRunning = false
                        rinseDeadline = nil
                        rinseRemaining = TimeInterval(rinseDuration)
                    }
                    .buttonStyle(RedroomSecondaryButtonStyle())
                }
            }

            RedroomNote(text: "Follow the wetting-agent maker's directions for dilution and handling. Do not rinse the wetting agent off unless its instructions say to.")
        }
    }
}

// MARK: - Tank visualizer

struct RedroomTankVisualizer: View {
    private static let capacity: Double = 500
    private static let reelCount = 2

    @State private var fillML: Double = 290
    @State private var tiltDegrees: Double = 0
    @State private var chemistry: PourChemistry = .developer
    @State private var format: ReelFormat = .mm35
    @State private var spin: Double = 0
    @State private var lastDragX: CGFloat = 0
    @State private var lastDragY: CGFloat = 0
    @State private var disturbance = Disturbance(magnitude: 0, at: .distantPast)
    @State private var pourConfirmed = false

    private var coveredReels: [Bool] {
        let t = format.reelThicknessFraction
        let lowerCentre = 0.34 + t / 2
        let upperCentre = lowerCentre + t + 0.06
        let tops = [lowerCentre + t / 2, upperCentre + t / 2]
        return tops.map { fillML >= Self.capacity * $0 * 1.04 }
    }

    private var coveredCount: Int { coveredReels.filter(\.self).count }

    private var coverageWarning: String? {
        let t = format.reelThicknessFraction
        let lowerCentre = 0.34 + t / 2
        let upperCentre = lowerCentre + t + 0.06
        let tops = [lowerCentre + t / 2, upperCentre + t / 2]
        guard let index = coveredReels.firstIndex(of: false) else { return nil }
        let shortfall = Int((Self.capacity * tops[index] * 1.04 - fillML).rounded(.up))
        return "Reel \(index + 1) sits above the liquid. \(Units.volume(millilitres: Double(shortfall))) more covers it."
    }

    private var waterToMake: String {
        Units.volume(millilitres: (fillML * chemistry.waterFractionOfPour).rounded())
    }

    var body: some View {
        RedroomScreen {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Paterson Super System 4")
                        .font(Redroom.body(14, weight: .medium))
                        .foregroundStyle(Redroom.text)
                    Text("\(Units.volume(millilitres: Self.capacity)) · \(Self.reelCount) reels")
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.textMuted)
                }

                Spacer(minLength: 4)

                RedroomSegmented(
                    items: ReelFormat.allCases,
                    selection: $format,
                    title: { $0.rawValue }
                )
                .frame(width: 150)
            }

            RedroomTankDrawing(
                fillFraction: fillML / Self.capacity,
                tiltDegrees: tiltDegrees,
                sloshAngle: sloshAngleOffset(now: Date()),
                spin: spin,
                chemistry: chemistry,
                format: format,
                covered: coveredReels
            )
            .frame(height: 320)
            .contentShape(Rectangle())
            .gesture(rotateGesture)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Tank with \(Self.reelCount) reels. \(Units.volumePhrase(millilitres: fillML)) of "
                    + "\(chemistry.label.lowercased()); \(coveredCount) of \(Self.reelCount) reels covered."
            )

            HStack(spacing: 8) {
                ForEach(PourChemistry.allCases) { chem in
                    Button {
                        guard chemistry != chem else { return }
                        withAnimation(.easeOut(duration: 0.25)) {
                            chemistry = chem
                        }
                        disturb(2)
                    } label: {
                        VStack(spacing: 5) {
                            Circle()
                                .fill(chemistry == chem ? chem.color : Redroom.color(0x140808))
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Circle().strokeBorder(
                                        chemistry == chem ? chem.color : Redroom.textDisabled,
                                        lineWidth: 1
                                    )
                                }
                            Text(chem.shortLabel)
                                .font(Redroom.label(9))
                                .foregroundStyle(chemistry == chem ? Redroom.text : Redroom.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(HapticButtonStyle())
                    .accessibilityLabel("\(chem.label) chemistry")
                    .accessibilityAddTraits(chemistry == chem ? .isSelected : [])
                }
            }

            if let warning = coverageWarning {
                RedroomWarning(title: "A reel is above the liquid", detail: warning)
            }

            RedroomPanel {
                RedroomStepper(
                    title: "Fill",
                    value: Units.volume(millilitres: fillML),
                    decrement: fillML > 0 ? { fillML = max(0, fillML - 10) } : nil,
                    increment: fillML < Self.capacity ? { fillML = min(Self.capacity, fillML + 10) } : nil
                )

                RedroomStepper(
                    title: "Tilt",
                    value: "\(Int(tiltDegrees))°",
                    decrement: tiltDegrees > -25 ? { tiltDegrees -= 1 } : nil,
                    increment: tiltDegrees < 25 ? { tiltDegrees += 1 } : nil
                )

                RedroomNote(text: "Drag the tank to rotate its reels.")
            }

            RedroomPanel(title: "This pour", variant: .optical) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        RedroomLabel(chemistry.label)
                        Text(Units.volume(millilitres: fillML))
                            .font(Redroom.figure(20, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        RedroomLabel("Water to make")
                        Text(waterToMake)
                            .font(Redroom.figure(20, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 2) {
                        RedroomLabel("Covers")
                        Text("\(coveredCount) of \(Self.reelCount)")
                            .font(Redroom.figure(20, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    }
                }

                Button {
                    Haptics.success()
                    disturb(7)
                    pourConfirmed = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.8))
                        pourConfirmed = false
                    }
                } label: {
                    Text(pourConfirmed
                         ? "\(Units.volume(millilitres: fillML)) of \(chemistry.label.lowercased()) — ready to pour"
                         : "Use this volume")
                }
                .buttonStyle(RedroomPrimaryButtonStyle())
            }

            RedroomNote(text: "Water to make assumes common stock dilutions — developer 1+1, stop 1+19, fixer 1+4. Wash is water.")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Tank")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var rotateGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let dx = value.translation.width - lastDragX
                let dy = value.translation.height - lastDragY
                lastDragX = value.translation.width
                lastDragY = value.translation.height
                guard abs(dx) >= abs(dy) else { return }
                spin = (spin + Double(dx) * 0.014)
                    .truncatingRemainder(dividingBy: 2 * Double.pi)
                disturb(min(6, abs(Double(dx)) * 0.12))
            }
            .onEnded { value in
                if abs(value.translation.width) >= 24,
                   abs(value.translation.width) >= abs(value.translation.height) {
                    Haptics.impact(.light)
                }
                lastDragX = 0
                lastDragY = 0
            }
    }

    // MARK: Slosh

    private struct Disturbance {
        let magnitude: Double
        let at: Date
    }

    private func disturb(_ magnitude: Double) {
        let now = Date()
        let elapsed = now.timeIntervalSince(disturbance.at)
        let carry = elapsed >= 0 && elapsed < 3
            ? disturbance.magnitude * exp(-1.8 * elapsed)
            : 0
        disturbance = Disturbance(magnitude: min(9, max(magnitude, carry)), at: now)
    }

    private func sloshAngleOffset(now: Date) -> Double {
        let elapsed = now.timeIntervalSince(disturbance.at)
        guard elapsed >= 0, elapsed < 5 else { return 0 }
        return disturbance.magnitude * exp(-2.6 * elapsed) * cos(9.0 * elapsed)
    }
}

// MARK: - Tank drawing

/// The tank drawn as a vessel the safelight can see through: a glass body, the
/// liquid at its own level, two reels, and the level line lit along the surface.
struct RedroomTankDrawing: View {
    let fillFraction: Double
    let tiltDegrees: Double
    let sloshAngle: Double
    let spin: Double
    let chemistry: PourChemistry
    let format: ReelFormat
    let covered: [Bool]

    @Environment(\.redroomLight) private var light
    @State private var frame: CGRect = .zero

    private var clampedFill: Double { min(max(fillFraction, 0), 1) }

    var body: some View {
        let sample = RedroomLightSample.make(frame: frame, light: light)

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                draw(context: context, size: size, time: timeline.date.timeIntervalSinceReferenceDate, sample: sample)
            }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { value in
            frame = value
        }
    }

    private func draw(
        context: GraphicsContext,
        size: CGSize,
        time: Double,
        sample: RedroomLightSample
    ) {
        let bodyWidth = min(size.width * 0.52, 210)
        let bodyHeight = bodyWidth * 1.38
        let body = CGRect(
            x: size.width / 2 - bodyWidth / 2,
            y: size.height - bodyHeight - size.height * 0.08,
            width: bodyWidth,
            height: bodyHeight
        )
        let wall = bodyWidth * 0.05
        let interior = CGRect(
            x: body.minX + wall,
            y: body.minY + bodyHeight * 0.13,
            width: bodyWidth - wall * 2,
            height: bodyHeight * 0.82
        )

        var tank = context
        tank.translateBy(x: body.midX, y: body.maxY)
        tank.rotate(by: .degrees(tiltDegrees))
        tank.translateBy(x: -body.midX, y: -body.maxY)

        // Glass body.
        tank.fill(
            Path(roundedRect: body, cornerRadius: 18),
            with: .linearGradient(
                Gradient(colors: [
                    Redroom.color(0x140808).opacity(0.9),
                    Redroom.color(0x080303).opacity(0.95)
                ]),
                startPoint: CGPoint(x: body.midX, y: body.minY),
                endPoint: CGPoint(x: body.midX, y: body.maxY)
            )
        )

        tank.drawLayer { inside in
            inside.clip(to: Path(roundedRect: interior, cornerRadius: 12))

            let level = interior.height * CGFloat(clampedFill)
            let surfaceY = interior.maxY - level
            let angle = -tiltDegrees + sloshAngle

            // Liquid.
            inside.drawLayer { liquid in
                liquid.translateBy(x: interior.midX, y: surfaceY)
                liquid.rotate(by: .degrees(angle))

                var bodyPath = Path()
                bodyPath.addRect(CGRect(x: -700, y: 0, width: 1400, height: interior.height * 2))
                liquid.fill(
                    bodyPath,
                    with: .linearGradient(
                        Gradient(colors: [
                            chemistry.color.opacity(0.38),
                            chemistry.color.opacity(0.22),
                            chemistry.color.opacity(0.75)
                        ]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: 0, y: interior.height)
                    )
                )

                // The surface: the lamp caught on the meniscus.
                var crest = Path()
                crest.move(to: CGPoint(x: -700, y: 0))
                var x: Double = -700
                while x <= 700 {
                    let ripple = sin(x * 0.045 + time * 6.0) * 1.4
                    crest.addLine(to: CGPoint(x: x, y: ripple))
                    x += 6
                }
                liquid.stroke(
                    crest,
                    with: .color(.white.opacity(0.32 + 0.25 * sample.direct)),
                    style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
                )
            }

            // Reels.
            let thickness = interior.height * CGFloat(format.reelThicknessFraction)
            let radius = interior.width * 0.40
            let lowerCentre = interior.height * 0.34 + thickness / 2
            let upperCentre = lowerCentre + thickness + interior.height * 0.06

            for (index, centreY) in [lowerCentre, upperCentre].enumerated() {
                let centre = CGPoint(x: interior.midX, y: interior.maxY - centreY)
                drawReel(
                    &inside,
                    centre: centre,
                    radius: radius,
                    thickness: thickness,
                    spin: spin,
                    submerged: covered.indices.contains(index) ? covered[index] : false
                )
            }
        }

        // The glass edges, lit from the lamp.
        let litStart = CGPoint(
            x: body.minX + body.width * sample.start.x,
            y: body.minY + body.height * sample.start.y
        )
        let litEnd = CGPoint(
            x: body.minX + body.width * sample.end.x,
            y: body.minY + body.height * sample.end.y
        )
        tank.stroke(
            Path(roundedRect: body, cornerRadius: 18),
            with: .linearGradient(
                Gradient(colors: [
                    Redroom.safelight.opacity(0.55 * sample.direct + 0.06),
                    Redroom.deepRed.opacity(0.35)
                ]),
                startPoint: litStart,
                endPoint: litEnd
            ),
            lineWidth: 1.4
        )

        // Lid.
        let lid = CGRect(x: body.minX - 4, y: body.minY - 10, width: bodyWidth + 8, height: bodyHeight * 0.12)
        tank.fill(
            Path(roundedRect: lid, cornerRadius: 7),
            with: .linearGradient(
                Gradient(colors: [Redroom.color(0x1B0B0B), Redroom.color(0x0A0404)]),
                startPoint: CGPoint(x: lid.midX, y: lid.minY),
                endPoint: CGPoint(x: lid.midX, y: lid.maxY)
            )
        )
        tank.stroke(
            Path(roundedRect: lid, cornerRadius: 7),
            with: .color(Redroom.safelight.opacity(0.30 * sample.direct + 0.05)),
            lineWidth: 1
        )
    }

    private func drawReel(
        _ layer: inout GraphicsContext,
        centre: CGPoint,
        radius: CGFloat,
        thickness: CGFloat,
        spin: Double,
        submerged: Bool
    ) {
        let ratio: CGFloat = 0.30
        let topY = centre.y - thickness / 2
        let side = CGRect(x: centre.x - radius, y: topY, width: radius * 2, height: thickness)
        let face = CGRect(
            x: centre.x - radius,
            y: topY - radius * ratio,
            width: radius * 2,
            height: radius * 2 * ratio
        )

        layer.fill(
            Path(roundedRect: side, cornerRadius: min(5, thickness * 0.3)),
            with: .linearGradient(
                Gradient(colors: [Redroom.color(0x241010), Redroom.color(0x3A1A1A)]),
                startPoint: CGPoint(x: centre.x, y: topY),
                endPoint: CGPoint(x: centre.x, y: topY + thickness)
            )
        )
        layer.fill(
            Path(ellipseIn: face),
            with: .linearGradient(
                Gradient(colors: [Redroom.color(0x3E1C1C), Redroom.color(0x1C0B0B)]),
                startPoint: CGPoint(x: centre.x, y: face.minY),
                endPoint: CGPoint(x: centre.x, y: face.maxY)
            )
        )

        layer.drawLayer { grooves in
            grooves.translateBy(x: centre.x, y: topY)
            for index in 1...5 {
                let rr = radius * CGFloat(index) / 5.5
                let rect = CGRect(x: -rr, y: -rr * ratio, width: rr * 2, height: rr * 2 * ratio)
                grooves.stroke(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(index.isMultiple(of: 2) ? 0.10 : 0.05)),
                    lineWidth: 1
                )
            }

            var spiral = Path()
            spiral.move(to: .zero)
            let total = 2.6 * 2 * Double.pi
            var angle = 0.0
            while angle < total {
                let rr = radius * 0.92 * CGFloat(angle / total)
                let turn = angle + spin
                spiral.addLine(to: CGPoint(
                    x: CGFloat(cos(turn)) * rr,
                    y: CGFloat(sin(turn)) * rr * ratio
                ))
                angle += 0.22
            }
            grooves.stroke(
                spiral,
                with: .color(.white.opacity(0.18)),
                style: StrokeStyle(lineWidth: 1, lineCap: .round)
            )
        }

        if submerged {
            layer.fill(Path(ellipseIn: face), with: .color(chemistry.color.opacity(0.18)))
            layer.fill(Path(roundedRect: side, cornerRadius: 4), with: .color(chemistry.color.opacity(0.12)))
        }
    }
}

// MARK: - Troubleshooter

struct RedroomTroubleshooter: View {
    @ObservedObject private var library = LibraryStore.shared

    @State private var filmKey: String?
    @State private var selection: TroubleshooterSymptom.ID?
    @State private var checklistExpanded = false

    private var selectedFilm: LibraryFilm? {
        if let filmKey, let film = library.film(key: filmKey) { return film }
        return library.films.first { $0.name.localizedCaseInsensitiveContains("HP5") }
            ?? library.films.first
    }

    private var selectedSymptom: TroubleshooterSymptom? {
        selection.flatMap { id in Troubleshooter.symptoms.first { $0.id == id } }
    }

    var body: some View {
        RedroomScreen {
            VStack(spacing: 4) {
                Text("What do your negatives show?")
                    .font(Redroom.display(20, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .multilineTextAlignment(.center)

                Text("Tap the closest match.")
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
            }
            .frame(maxWidth: .infinity)

            filmPill

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(Troubleshooter.symptoms) { symptom in
                    Button {
                        withAnimation(.easeOut(duration: 0.28)) {
                            selection = selection == symptom.id ? nil : symptom.id
                            checklistExpanded = false
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Image(systemName: symptomSymbol(symptom.id))
                                .font(.system(size: 15, weight: .light))
                                .foregroundStyle(selection == symptom.id ? Redroom.text : Redroom.textMuted)

                            Text(symptom.title)
                                .font(Redroom.body(13, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                                .multilineTextAlignment(.leading)

                            Text("\(symptom.causes.count) possible cause\(symptom.causes.count == 1 ? "" : "s")")
                                .font(Redroom.body(9))
                                .foregroundStyle(Redroom.textMuted)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                        .redroomGlass(
                            variant: selection == symptom.id ? .optical : .smoked,
                            cornerRadius: 16
                        )
                    }
                    .buttonStyle(HapticButtonStyle())
                    .accessibilityAddTraits(selection == symptom.id ? .isSelected : [])
                }
            }

            if let symptom = selectedSymptom {
                resultPanel(symptom)
                    .transition(.redroomShutter)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Troubleshooter")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var filmPill: some View {
        Menu {
            ForEach(library.films, id: \.key) { film in
                Button {
                    filmKey = film.key
                } label: {
                    if film.key == selectedFilm?.key {
                        Label(film.name, systemImage: "checkmark")
                    } else {
                        Text(film.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text((selectedFilm?.name ?? "Select a film").uppercased())
                    .font(Redroom.label(10))
                    .tracking(1.2)
                    .foregroundStyle(Redroom.text)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Redroom.textMuted)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background {
                Color.clear.redroomGlass(variant: .transparent, cornerRadius: 12)
            }
        }
        .accessibilityLabel("Film: \(selectedFilm?.name ?? "none selected")")
    }

    private func symptomSymbol(_ id: String) -> String {
        switch id {
        case "thin": return "circle.dotted"
        case "dense": return "circle.fill"
        case "uneven": return "circle.lefthalf.filled"
        case "water-marks": return "drop"
        case "bromide-drag": return "wind"
        case "reticulation": return "squareshape.split.3x3"
        case "grain": return "circle.grid.3x3"
        case "fogging": return "sun.haze"
        case "colour-cast": return "paintpalette"
        default: return "scribble"
        }
    }

    private func resultPanel(_ symptom: TroubleshooterSymptom) -> some View {
        let shown = checklistExpanded ? symptom.causes : Array(symptom.causes.prefix(3))

        return RedroomPanel(title: symptom.resultTitle, variant: .optical) {
            ForEach(Array(shown.enumerated()), id: \.offset) { index, cause in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(cause.title)
                            .font(Redroom.body(13, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        Text(cause.confidence.label.uppercased())
                            .font(Redroom.label(8))
                            .tracking(0.6)
                            .foregroundStyle(Redroom.textMuted)
                    }

                    Text(cause.step.label.uppercased())
                        .font(Redroom.label(8))
                        .tracking(0.8)
                        .foregroundStyle(Redroom.textMuted)

                    Text(cause.fix)
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.text)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { dot in
                            Circle()
                                .fill(dot < cause.confidence.rawValue ? Redroom.text : Redroom.textDisabled)
                                .frame(width: 5, height: 5)
                        }
                        Text("confidence")
                            .font(Redroom.label(8))
                            .foregroundStyle(Redroom.textMuted)
                            .padding(.leading, 4)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Confidence \(cause.confidence.label)")
                }
                .padding(.vertical, 8)

                if index < shown.count - 1 {
                    RedroomLitRule(thickness: 0.5)
                }
            }

            if symptom.causes.count > 3 {
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        checklistExpanded.toggle()
                    }
                } label: {
                    Text(checklistExpanded ? "Show fewer" : "Show all \(symptom.causes.count)")
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Film leader guide

struct RedroomFilmLeaderGuide: View {
    private enum Model: String, CaseIterable, Identifiable {
        case promaster = "ProMaster 98855"
        case kaiser = "Kaiser 204132"
        var id: String { rawValue }
        var short: String { self == .promaster ? "ProMaster" : "Kaiser" }
    }

    @State private var model: Model = .promaster

    private struct Step: Identifiable {
        let id: Int
        let title: String
        let detail: String
    }

    private var steps: [Step] {
        if model == .promaster {
            return [
                Step(id: 1, title: "Tighten the roll", detail: "Turn the cartridge spindle counter-clockwise a few times."),
                Step(id: 2, title: "Insert both sheets", detail: "Move sliders A and B fully right. Insert the tips of both sliding sheets into the cartridge."),
                Step(id: 3, title: "Advance slider A", detail: "Hold the cartridge against the tool and move slider A fully left, keeping slider B fully right. If it does not slide smoothly, do not force it; turn the spindle counter-clockwise several times and try again."),
                Step(id: 4, title: "Listen for the click", detail: "Slowly turn the spindle counter-clockwise until you hear a click, then stop immediately."),
                Step(id: 5, title: "Catch and withdraw", detail: "Move slider B left until it meets slider A, then slowly pull the cartridge away from the retriever. The leader should be extracted.")
            ]
        }
        return [
            Step(id: 1, title: "Tighten the roll", detail: "Turn the cartridge spindle three or four times counter-clockwise."),
            Step(id: 2, title: "Set position A", detail: "Push the retriever button into position A. Insert tongue 3 completely into the cartridge slot; the tip of tongue 4 must also disappear inside."),
            Step(id: 3, title: "Find the catch", detail: "Slowly turn the cartridge spindle counter-clockwise until you hear a quiet click."),
            Step(id: 4, title: "Set position B", detail: "Hold the cartridge and spindle firmly while pushing the button into position B."),
            Step(id: 5, title: "Extract", detail: "Turn the spindle about one turn clockwise until you feel slight resistance. Pull the retriever out of the cartridge without holding the cartridge by its spindle.")
        ]
    }

    var body: some View {
        RedroomScreen {
            RedroomSegmented(items: Model.allCases, selection: $model, title: { $0.short })

            RedroomNote(text: "These procedures are transcribed from the linked, model-specific instructions; do not combine steps from different tools.")

            RedroomPanel(title: "Retrieve the leader", variant: .optical) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text(String(format: "%02d", step.id))
                            .font(Redroom.figure(11, weight: .semibold))
                            .foregroundStyle(Redroom.textMuted)
                            .frame(width: 22, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.title)
                                .font(Redroom.body(13, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                            Text(step.detail)
                                .font(Redroom.body(12))
                                .foregroundStyle(Redroom.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 6)

                    if index < steps.count - 1 {
                        RedroomLitRule(thickness: 0.5)
                    }
                }

                RedroomNote(text: model == .promaster
                            ? "If there is no click, start over. If the sheets cannot be inserted after several attempts, stop and use the manual's darkroom or dark-bag alternative."
                            : "If the leader is not extracted, repeat the complete operation. Follow the manual's instruction to avoid direct sun or bright light while using this retriever.")
            }

            RedroomPanel(title: "Keep the film protected") {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                    Text("Once recovered, load the film onto a reel in complete darkness or in a changing bag. Retriever controls differ by model; stop rather than forcing a slider, tongue, or film.")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            RedroomToolSourceLink(
                title: "ProMaster Film Retriever · instruction book",
                detail: "Manufacturer manual for model 98855; includes the daylight-use extraction procedure.",
                url: "https://manuals.promaster.com/prodfiles/98855/Instruction%20Book/98855_FilmRetriever.pdf"
            )
            RedroomToolSourceLink(
                title: "Kaiser 35 mm Film Retriever · instructions",
                detail: "Model 204132 manual; includes its bright-light caution and complete extraction sequence.",
                url: "https://www.freestylephoto.com/static/pdf/product_pdf/kaiser/204132_Kaiser-35mm-Film-Retriever_INSTRUCTIONS.pdf"
            )
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Leader retrieval")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Tank capacity reference

struct RedroomTankCapacityReference: View {
    private struct Row: Identifiable {
        let id: String
        let tank: String
        let filmLoad: String
        let solutionVolume: String
        let note: String
    }

    private let rows = [
        Row(
            id: "paterson-single",
            tank: "Paterson System 4 · 35 mm tank",
            filmLoad: "1 × 35 mm reel",
            solutionVolume: "290 mL",
            note: "Manufacturer tank instructions identify the single-reel 35 mm tank; check the fill mark on your exact model."
        ),
        Row(
            id: "paterson-universal",
            tank: "Paterson System 4 · Universal tank",
            filmLoad: "2 × 35 mm reels or 1 × 120 reel",
            solutionVolume: "500 mL",
            note: "Common inversion-processing reference volume. Actual minimums vary with the tank and loaded reels; confirm the molded mark."
        )
    ]

    var body: some View {
        RedroomScreen {
            RedroomNote(text: "These are reference figures, not a substitute for the minimum volume printed for your tank and reel combination.")

            ForEach(rows) { row in
                RedroomPanel(title: row.tank) {
                    RedroomValueRow(label: "Film load", value: row.filmLoad)
                    RedroomValueRow(label: "Reference volume", value: row.solutionVolume, emphasised: true)
                    Text(row.note)
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            RedroomPanel(title: "Tank markings take priority") {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "ruler")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                    Text("A listed film-load capacity is not automatically a safe working volume. Confirm the minimum liquid level for inversion with your tank's own instructions before mixing chemistry.")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            RedroomToolSourceLink(
                title: "Paterson Super System 4 · tank instructions",
                detail: "Manufacturer guide covering film formats and reel capacity. Verify fill volumes against your tank's markings.",
                url: "https://patersonphotographic.com/wp-content/uploads/2025/05/Tanks.pdf"
            )
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Tank capacities")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Chemical safety

struct RedroomChemicalSafety: View {
    private struct Section: Identifiable {
        let id: String
        let symbol: String
        let title: String
        var warning: Bool = false
        let points: [String]
    }

    private let sections: [Section] = [
        Section(
            id: "skin",
            symbol: "hand.raised.fill",
            title: "Protect skin and eyes",
            points: [
                "Wear chemical-resistant gloves specified by the product SDS; use eye protection when measuring or mixing concentrates.",
                "Avoid splashes, skin contact, and breathing powder or mist. Wash hands after handling and keep food and drink away from the work area."
            ]
        ),
        Section(
            id: "air",
            symbol: "wind",
            title: "Ventilate the room",
            points: [
                "Work with good general ventilation and keep containers closed when not in use.",
                "If fumes or irritation occur, stop, move to fresh air, and follow the SDS emergency guidance. Do not use a respirator as a substitute for required ventilation."
            ]
        ),
        Section(
            id: "never",
            symbol: "xmark.octagon.fill",
            title: "Never mix these",
            warning: true,
            points: [
                "Never mix household chlorine bleach with acids or ammonia-containing cleaners; toxic chlorine or chloramine gases can result.",
                "Do not combine photographic baths, concentrates, or leftover waste with one another unless the product instructions explicitly direct it. Keep stop, developer, and fixer in separate, labeled containers.",
                "Do not pour an unknown chemical into a drain or another waste container. Mixing incompatible leftovers can cause dangerous reactions."
            ]
        ),
        Section(
            id: "storage",
            symbol: "shippingbox.fill",
            title: "Store and dispose carefully",
            points: [
                "Keep products in their original, labeled containers and follow their storage and disposal instructions.",
                "Do not assume spent fixer or other photographic chemistry is drain-safe. Check the product SDS and local sewer or hazardous-waste rules; use a local collection program when required."
            ]
        )
    ]

    var body: some View {
        RedroomScreen {
            RedroomNote(text: "Product formulations differ. The label and current safety data sheet (SDS) for the exact product take precedence over this general checklist.")

            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 7) {
                        Image(systemName: section.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Text(section.title)
                            .font(Redroom.body(14, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Spacer(minLength: 0)
                    }

                    ForEach(section.points, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Text(section.warning ? "!" : "·")
                                .font(Redroom.body(11, weight: .bold))
                                .foregroundStyle(Redroom.textMuted)
                                .frame(width: 10, alignment: .leading)
                                .padding(.top, 1)

                            Text(point)
                                .font(Redroom.body(12))
                                .foregroundStyle(Redroom.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .redroomGlass(
                    variant: section.warning ? .wet : .smoked,
                    cornerRadius: RedroomMetrics.cardRadius
                )
            }

            RedroomToolSourceLink(
                title: "U.S. EPA · Household Hazardous Waste",
                detail: "Do not mix leftover hazardous products; follow labels and contact local agencies for disposal rules.",
                url: "https://www.epa.gov/hw/household-hazardous-waste-hhw"
            )
            RedroomToolSourceLink(
                title: "CDC · Chlorine chemical fact sheet",
                detail: "Chlorine exposure and the hazards of mixing household bleach with other cleaners.",
                url: "https://www.cdc.gov/chemical-emergencies/chemical-fact-sheets/chlorine.html"
            )
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Tools", title: "Chemical safety")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
