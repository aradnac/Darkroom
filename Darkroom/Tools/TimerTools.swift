//
//  TimerTools.swift
//  Darkroom
//
//  Small timing and temperature utilities for the sink.
//

import SwiftUI

// MARK: - Live read-out

/// A read-out that refreshes on its own, so the screen and the list around it
/// are not re-evaluated on every tick. Wrapping the whole `ScrollView` in a
/// timeline (as these three timers used to) re-ran every row, card and button in
/// it ten times a second for one changing number; this keeps the ticking inside
/// the one `Text` that actually changes.
private struct LiveTicker<Content: View>: View {
    var running: Bool
    var interval: TimeInterval
    @ViewBuilder var content: (Date) -> Content

    var body: some View {
        if running {
            TimelineView(.periodic(from: .now, by: interval)) { context in
                content(context.date)
            }
        } else {
            // Nothing is counting, so the reading only changes when something
            // else changes the view.
            content(Date())
        }
    }
}

private enum TemperatureDirection: String, CaseIterable, Identifiable {
    case celsiusToFahrenheit
    case fahrenheitToCelsius

    var id: String { rawValue }
    var title: String { self == .celsiusToFahrenheit ? "°C → °F" : "°F → °C" }
    var inputUnit: String { self == .celsiusToFahrenheit ? "°C" : "°F" }
    var outputUnit: String { self == .celsiusToFahrenheit ? "°F" : "°C" }
}

struct TemperatureConverterView: View {
    @State private var direction: TemperatureDirection = .celsiusToFahrenheit
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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    OverlineText(text: "Quick conversion", color: Theme.amber)
                    Text("Temperature")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("Convert a measured temperature without leaving the bench.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Picker("Conversion", selection: $direction) {
                        ForEach(TemperatureDirection.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("Temperature", text: $input)
                            .font(.system(size: 42, weight: .medium, design: .rounded).monospacedDigit())
                            .keyboardType(.decimalPad)
                            .foregroundStyle(Theme.ink)
                            .accessibilityLabel("Input temperature in \(direction.inputUnit)")
                        Text(direction.inputUnit)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)

                    HStack(alignment: .firstTextBaseline) {
                        Text(output.map { String(format: "%.1f", $0) } ?? "—")
                            .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.amber)
                            .contentTransition(.numericText())
                        Text(direction.outputUnit)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                .padding(20)
                .glassCard(radius: 25, tint: Theme.amber)

                Text("°F = (°C × 9 ÷ 5) + 32   ·   °C = (°F − 32) × 5 ÷ 9")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Temperature")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StopwatchToolView: View {
    @State private var accumulated: TimeInterval = 0
    @State private var runningSince: Date?
    @State private var laps: [TimeInterval] = []

    private func elapsed(at date: Date) -> TimeInterval {
        accumulated + (runningSince.map { date.timeIntervalSince($0) } ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    OverlineText(text: "Elapsed time", color: Theme.amber)
                    LiveTicker(running: runningSince != nil, interval: 0.1) { date in
                        let current = elapsed(at: date)
                        Text(Clock.mmss(current))
                            .font(.system(size: 58, weight: .medium, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.ink)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .accessibilityLabel("Elapsed \(Clock.mmss(current))")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .glassCard(radius: 28, tint: runningSince == nil ? nil : Theme.amber)

                HStack(spacing: 12) {
                    Button {
                        if runningSince == nil {
                            runningSince = Date()
                        } else {
                            accumulated = elapsed(at: Date())
                            runningSince = nil
                        }
                    } label: {
                        Label(runningSince == nil ? "Start" : "Pause", systemImage: runningSince == nil ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AmberCapsuleStyle(height: 52))

                    Button {
                        if runningSince != nil {
                            let split = elapsed(at: Date())
                            laps.insert(split, at: 0)
                        }
                    } label: {
                        Label("Lap", systemImage: "flag")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 52))
                    .disabled(runningSince == nil)
                    .opacity(runningSince == nil ? 0.45 : 1)
                }

                if !laps.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("LAPS")
                            Spacer()
                            Button("Reset") {
                                accumulated = 0
                                runningSince = nil
                                laps.removeAll()
                            }
                            .foregroundStyle(Theme.amber)
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.bottom, 8)

                        ForEach(Array(laps.enumerated()), id: \.offset) { index, lap in
                            HStack {
                                Text(String(format: "Lap %02d", laps.count - index))
                                    .foregroundStyle(Theme.inkSoft)
                                Spacer()
                                Text(Clock.mmss(lap))
                                    .foregroundStyle(Theme.ink)
                                Text(Clock.mmss(lap - (index + 1 < laps.count ? laps[index + 1] : 0)))
                                    .foregroundStyle(Theme.amber)
                                    .frame(width: 72, alignment: .trailing)
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                            .padding(.vertical, 11)
                            if index < laps.count - 1 {
                                Rectangle().fill(Theme.hairline).frame(height: 1)
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(radius: 22)
                } else {
                    Text("Lap splits appear here while the stopwatch is running.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .glassCard(radius: 22)
                }

                if laps.isEmpty && runningSince == nil && accumulated > 0 {
                    Button("Reset stopwatch") {
                        accumulated = 0
                        laps.removeAll()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.top, 2)
                }
            }
            .padding(20)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Stopwatch")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum IntervalPhase {
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

    var color: Color {
        switch self {
        case .work: return Theme.amber
        case .rest: return Color(red: 0.56, green: 0.77, blue: 0.92)
        case .ready, .finished: return Theme.inkSoft
        }
    }
}

struct IntervalTimerView: View {
    @State private var workSeconds = 60
    @State private var restSeconds = 15
    @State private var rounds = 8
    @State private var currentRound = 1
    @State private var phase: IntervalPhase = .ready
    @State private var remaining: TimeInterval = 60
    @State private var deadline: Date?
    @State private var isRunning = false

    private var editable: Bool { !isRunning && phase != .work && phase != .rest }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                countdownCard

                if editable {
                    settingsCard
                }

                HStack(spacing: 12) {
                    Button {
                        toggle(at: Date())
                    } label: {
                        Label(isRunning ? "Pause" : (phase == .finished ? "Again" : "Start"), systemImage: isRunning ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AmberCapsuleStyle(height: 54))

                    Button {
                        reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 54))
                }
            }
            .padding(20)
        }
        // The countdown's logic still needs a steady beat — it is what moves the
        // session from work to rest — but nothing on screen has to be rebuilt for
        // it, so the tick lives here and only the digits subscribe to a timeline.
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { date in
            advanceTimer(at: date)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Interval timer")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var countdownCard: some View {
        VStack(spacing: 12) {
            OverlineText(text: phase.title, color: phase.color)
            LiveTicker(running: isRunning, interval: 0.2) { date in
                let value = isRunning ? max(0, (deadline ?? date).timeIntervalSince(date)) : remaining
                Text(Clock.mmssCeil(value))
                    .font(.system(size: 58, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(phase.color)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            Text(phase == .ready ? "Configure your intervals below." : "Round \(min(currentRound, rounds)) of \(rounds)")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .glassCard(radius: 28, tint: phase.color)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            OverlineText(text: "Your interval", color: Theme.inkSoft)
            Stepper(value: $workSeconds, in: 5...3600, step: 5) {
                LabeledContent("Work", value: Clock.mmss(TimeInterval(workSeconds)))
            }
            .tint(Theme.amber)
            Stepper(value: $restSeconds, in: 0...1800, step: 5) {
                LabeledContent("Rest", value: Clock.mmss(TimeInterval(restSeconds)))
            }
            .tint(Theme.amber)
            Stepper(value: $rounds, in: 1...50) {
                LabeledContent("Rounds", value: "\(rounds)")
            }
            .tint(Theme.amber)
            Text("Zero rest runs each work interval straight into the next.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
        }
        .font(.system(size: 15))
        .foregroundStyle(Theme.ink)
        .padding(18)
        .glassCard(radius: 23)
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

        if phase == .finished {
            currentRound = 1
            phase = .work
            remaining = TimeInterval(workSeconds)
        } else if phase == .ready {
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

private enum WashRinseSelection: String, CaseIterable, Identifiable {
    case wash = "Wash"
    case rinse = "Final rinse"
    var id: String { rawValue }
}

private enum WashMethodSelection: String, CaseIterable, Identifiable {
    case fillAndDump = "Fill & dump"
    case runningWater = "Running water"
    var id: String { rawValue }
}

struct WashRinseTimerView: View {
    @State private var selection: WashRinseSelection = .wash
    @State private var method: WashMethodSelection = .fillAndDump
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Stage", selection: $selection) {
                    ForEach(WashRinseSelection.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if selection == .wash {
                    washContent
                } else {
                    rinseContent
                }
            }
            .padding(20)
        }
        // Only the end of the final-rinse countdown needs a steady beat; the
        // readings themselves keep their own time inside `LiveTicker`.
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { date in
            if rinseRunning, let rinseDeadline, date >= rinseDeadline {
                self.rinseRemaining = 0
                self.rinseDeadline = nil
                self.rinseRunning = false
            }
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Wash & rinse")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var washContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                OverlineText(text: "Film wash", color: Theme.amber)
                Text("Wash the fixer away.")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Use the method recommended for your film and fixer. The fill-and-dump sequence below is a published ILFORD method, not a universal time target.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Wash method")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                Picker("Wash method", selection: $method) {
                    ForEach(WashMethodSelection.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if method == .fillAndDump {
                    scheduleRow
                    if !washComplete {
                        VStack(alignment: .leading, spacing: 7) {
                            OverlineText(text: "Change \(washStep + 1) of 3", color: Theme.amber)
                            Text("Fill with fresh water. Invert the tank \(inversionSchedule[washStep]) times, then drain.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Inversions counted: \(inversions) / \(inversionSchedule[washStep])")
                                .font(.system(size: 13, design: .rounded).monospacedDigit())
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .padding(13)
                        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        Label("Three changes complete", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.amber)
                    }

                    HStack(spacing: 10) {
                        Button {
                            guard !washComplete else { return }
                            inversions = min(inversions + 1, inversionSchedule[washStep])
                        } label: {
                            Label("Count inversion", systemImage: "arrow.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassCapsuleStyle(height: 48))
                        .disabled(washComplete || inversions >= inversionSchedule[washStep])
                        .opacity(washComplete || inversions >= inversionSchedule[washStep] ? 0.45 : 1)

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
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AmberCapsuleStyle(height: 48))
                        .disabled(washComplete || inversions < inversionSchedule[washStep])
                        .opacity(washComplete || inversions < inversionSchedule[washStep] ? 0.45 : 1)
                    }
                } else {
                    Text("Keep fresh water flowing through the tank. There is no single running-water duration shown here; follow the instructions for your film and fixer.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(17)
            .glassCard(radius: 23)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Wash elapsed")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    LiveTicker(running: washStartedAt != nil, interval: 0.2) { date in
                        let elapsed = washElapsedBeforeStart + (washStartedAt.map { date.timeIntervalSince($0) } ?? 0)
                        Text(Clock.mmss(elapsed))
                            .font(.system(size: 22, weight: .medium, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.amber)
                            .contentTransition(.numericText())
                    }
                }
                HStack(spacing: 10) {
                    Button {
                        if let started = washStartedAt {
                            washElapsedBeforeStart += Date().timeIntervalSince(started)
                            washStartedAt = nil
                        } else {
                            washStartedAt = Date()
                        }
                    } label: {
                        Label(washStartedAt == nil ? "Start wash timer" : "Pause", systemImage: washStartedAt == nil ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AmberCapsuleStyle(height: 48))

                    Button("Reset") {
                        washStartedAt = nil
                        washElapsedBeforeStart = 0
                        washStep = 0
                        inversions = 0
                        washComplete = false
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 48))
                }
            }
            .padding(17)
            .glassCard(radius: 23, tint: Theme.amber)

            ToolSourceLink(
                title: "ILFORD PHOTO · film processing chart",
                detail: "Manufacturer downloadable processing chart; check current instructions for the film and fixer in use.",
                url: "https://www.ilfordphoto.com/amfile/file/download/file/1953/product/691/"
            )
        }
    }

    private var scheduleRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(inversionSchedule.enumerated()), id: \.offset) { index, count in
                VStack(spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(washStep == index && !washComplete ? Theme.amber : Theme.ink)
                    Text("inversions")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.inkFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(washStep == index && !washComplete ? 0.07 : 0.035), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
    }

    private var rinseContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                OverlineText(text: "Final rinse", color: Color(red: 0.53, green: 0.76, blue: 0.91))
                Text("A clean finish.")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Use wetting agent at the dilution on its label. The app's 30-second default matches its development-session rinse; it is a timer setting, not a universal product instruction.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 13) {
                LiveTicker(running: rinseRunning, interval: 0.2) { date in
                    let timeLeft = rinseRunning ? max(0, (rinseDeadline ?? date).timeIntervalSince(date)) : rinseRemaining
                    Text(Clock.mmssCeil(timeLeft))
                        .font(.system(size: 56, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(rinseRunning ? Theme.amber : Theme.ink)
                        .contentTransition(.numericText())
                }
                if !rinseRunning {
                    Stepper(value: $rinseDuration, in: 10...180, step: 10) {
                        LabeledContent("Timer setting", value: Clock.mmss(TimeInterval(rinseDuration)))
                    }
                    .tint(Theme.amber)
                    .onChange(of: rinseDuration) { _, value in
                        rinseRemaining = TimeInterval(value)
                    }
                }
                HStack(spacing: 10) {
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
                        Label(rinseRunning ? "Pause" : (rinseRemaining == 0 ? "Start again" : "Start rinse"), systemImage: rinseRunning ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AmberCapsuleStyle(height: 50))

                    Button("Reset") {
                        rinseRunning = false
                        rinseDeadline = nil
                        rinseRemaining = TimeInterval(rinseDuration)
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 50))
                }
            }
            .padding(20)
            .glassCard(radius: 25, tint: Color(red: 0.53, green: 0.76, blue: 0.91))

            Text("Follow the wetting-agent maker's directions for dilution and handling. Do not rinse the wetting agent off unless its instructions say to.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
