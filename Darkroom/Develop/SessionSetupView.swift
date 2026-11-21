//
//  SessionSetupView.swift
//  Darkroom
//
//  Everything a session needs, worked out rather than typed in: temperature
//  compensation between the times you hold, push or pull, the compounding penalty
//  for a reused developer, stage temperatures and a record of every change.
//

import SwiftUI

struct SessionSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appearance = AppearanceStore.shared

    @State private var setup = DevelopmentSetup(
        film: StarterLibrary.films[0],
        developer: StarterLibrary.developers[0],
        dilution: StarterLibrary.developers[0].dilutions[0]
    )

    @State private var choosingFilm = false
    @State private var choosingDeveloper = false
    @State private var rollEditor: RollEditor?
    @State private var pointEditor: PointEditor?
    @State private var timeDirection: DevelopmentDirection = .findTime
    @State private var wantedSeconds = 10 * 60
    @State private var hasWantedTime = false
    @State private var editingWanted = false
    @State private var askingReuse = false
    @State private var confirmedUse: Int?
    @State private var run: SessionRun?

    /// The running screen is presented by identity, never by a flag: a cover can
    /// only appear once its engine exists, so it can never open empty and black.
    private struct SessionRun: Identifiable {
        let id = UUID()
        let engine: SessionEngine
    }

    /// The setup can be opened with a film already chosen — the film detail
    /// screen hands one over, and a journal entry hands back every number it can
    /// — and falls back to the library's first entry.
    init(
        film: Film? = nil,
        developer: Developer? = nil,
        dilution: Dilution? = nil,
        temperature: Double? = nil,
        pushStops: Int? = nil,
        reuseCount: Int? = nil,
        developmentSeconds: TimeInterval? = nil
    ) {
        let films = StarterLibrary.films
        let developers = StarterLibrary.developers
        let resolvedFilm = film ?? films[0]
        let resolvedDeveloper = developer ?? developers[0]
        let resolvedDilution = dilution ?? resolvedDeveloper.dilutions[0]

        var drafted = DevelopmentSetup(
            film: resolvedFilm,
            developer: resolvedDeveloper,
            dilution: resolvedDilution
        )
        if let temperature {
            drafted.setTemperature(temperature)
        }
        if let pushStops {
            drafted.setPushStops(pushStops)
        }
        if let reuseCount {
            drafted.setReuseCount(reuseCount)
        }
        // A setting handed over from the simulator brings its own time, measured
        // at the water it was set for: the sheet is filled in rather than asking
        // for the time again.
        if let developmentSeconds, developmentSeconds >= 10, let temperature {
            drafted.setNominalCelsius(temperature)
            drafted.setPointSeconds(developmentSeconds, at: temperature)
        }

        _setup = State(initialValue: drafted)
    }

    private struct RollEditor: Identifiable {
        let id: Int
        let index: Int
    }

    private struct PointEditor: Identifiable {
        let id: Double
        let celsius: Double
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                filmCard
                developerCard
                exposureCard
                if appearance.isSoftGlassActive {
                    softTimeCard
                } else {
                    timeCard
                }
                rollsCard
                agitationCard
                stageCard
                if !setup.adjustments.isEmpty {
                    adjustmentsCard
                }
                startButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background {
            LiquidBackdrop()
        }
        .navigationTitle("New session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $choosingFilm) {
            FilmPickerView(selection: Binding(
                get: { setup.film },
                set: { setup.setFilm($0) }
            ))
        }
        .sheet(isPresented: $choosingDeveloper) {
            DeveloperPickerView(selection: Binding(
                get: { setup.developer },
                set: { setup.setDeveloper($0) }
            ))
        }
        .sheet(item: $rollEditor) { editor in
            FilmPickerView(selection: Binding(
                get: { setup.rolls.indices.contains(editor.index) ? setup.rolls[editor.index] : setup.film },
                set: { setup.setRollFilm($0, at: editor.index) }
            ))
        }
        .sheet(item: $pointEditor) { editor in
            DurationSheet(
                title: "Time at \(DevelopmentSetup.temperatureLabel(editor.celsius))",
                seconds: Binding(
                    get: { Int((setup.pointSeconds(at: editor.celsius) ?? 0).rounded()) },
                    set: { setup.setPointSeconds(TimeInterval($0), at: editor.celsius) }
                )
            )
        }
        .sheet(isPresented: $editingWanted) {
            DurationSheet(title: "Time you want", seconds: $wantedSeconds)
        }
        .onChange(of: wantedSeconds) { _, _ in
            applyWantedTime()
        }
        .onChange(of: timeDirection) { _, direction in
            guard direction == .findTemperature else { return }
            if !hasWantedTime {
                let current = setup.compensatedSeconds ?? setup.referenceSeconds ?? 600
                wantedSeconds = Int(current.rounded())
                hasWantedTime = true
            }
            applyWantedTime()
        }
        .sheet(isPresented: $askingReuse, onDismiss: startPendingSession) {
            ReuseSheet(
                developerName: "\(setup.developer.name) \(setup.dilution.label)",
                compensatedSeconds: setup.compensatedSeconds,
                initialUse: setup.reuseCount
            ) { use in
                confirmedUse = use
            }
        }
        .fullScreenCover(item: $run) { session in
            RunningSessionView(engine: session.engine) {
                run = nil
            }
        }
    }

    // MARK: - Film and developer

    private var filmCard: some View {
        Button {
            choosingFilm = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text("Film")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(width: 84, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(setup.film.fullName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Text("\(setup.film.formatSummary) · ISO \(setup.film.iso)")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkFaint)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 26)
        }
        .buttonStyle(HapticButtonStyle())
    }

    private var developerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                choosingDeveloper = true
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Text("Developer")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 84, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(setup.developer.name)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Text(setup.developer.manufacturer)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkFaint)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            .buttonStyle(HapticButtonStyle())

            Picker("Dilution", selection: Binding(
                get: { setup.dilution },
                set: { setup.setDilution($0) }
            )) {
                ForEach(setup.developer.dilutions) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Exposure index

    private var exposureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exposure index")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            SegmentedPill(
                options: Array(-2...3),
                selection: Binding(
                    get: { setup.pushStops },
                    set: { setup.setPushStops($0) }
                ),
                title: { stopTitle($0) }
            )

            Text(exposureNote)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private func stopTitle(_ stops: Int) -> String {
        if stops == 0 { return "ISO" }
        return stops > 0 ? "+\(stops)" : "−\(-stops)"
    }

    private var exposureNote: String {
        if setup.pushStops == 0 {
            return "Box speed. The time you enter is the standard time for ISO \(setup.film.iso)."
        }
        return "\(setup.exposureSummary). There is no documented time for this exposure index in the app yet, so enter your own."
    }

    // MARK: - Time and temperature

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Development time")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            Button {
                pointEditor = PointEditor(id: setup.nominalCelsius, celsius: setup.nominalCelsius)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Your sheet says")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkSoft)

                    Spacer(minLength: 8)

                    Text(setup.baseText)
                        .font(.figures(32, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(HapticButtonStyle())

            Stepper(
                value: Binding(get: { setup.nominalCelsius }, set: { setup.setNominalCelsius($0) }),
                in: 15...35,
                step: 0.5
            ) {
                LabeledContent("at", value: DevelopmentSetup.temperatureLabel(setup.nominalCelsius))
            }

            SegmentedPill(
                options: DevelopmentDirection.allCases,
                selection: $timeDirection,
                title: { $0.title }
            )

            if timeDirection == .findTime {
                waterSlider
                readout("Develop for", value: setup.adjustedText)
            } else {
                wantedRow
                readout("Use water at", value: Units.temperature(setup.temperature))
                if let wantedNote {
                    Text(wantedNote)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            compensationRow

            Toggle(isOn: Binding(get: { setup.continuousAgitation }, set: { setup.setContinuousAgitation($0) })) {
                Text("Agitate the whole time")
                    .font(.system(size: 15))
            }
            .tint(Theme.switchTint)

            if setup.continuousAgitation {
                Text("Times are written for agitation at intervals. If the tank keeps moving, take 10% off.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            moreTimesRow
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private var waterSlider: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Your water")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)

                Spacer(minLength: 8)

                Text(Units.temperature(setup.temperature))
                    .font(.figures(15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }

            Slider(
                value: Binding(get: { setup.temperature }, set: { setup.setTemperature($0) }),
                in: 18...24,
                step: 0.5
            )
            .tint(Theme.amber)
            .accessibilityLabel("Water temperature")
            .accessibilityValue(Units.temperature(setup.temperature))

            HStack {
                Text(Units.shortTemperature(18))
                Spacer()
                Text(Units.shortTemperature(24))
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkFaint)
        }
    }

    // MARK: - Soft glass time card

    /// The time chooser as the reference draws it: the figure set in dots
    /// inside the pink radial card, a draggable tick ruler beneath it, and the
    /// quiet controls sitting directly on the black field around it.
    private var softTimeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                pointEditor = PointEditor(id: setup.nominalCelsius, celsius: setup.nominalCelsius)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Your sheet says")
                        .font(.system(size: 15))
                        .foregroundStyle(SoftGlassTheme.inkSoft)
                    Spacer(minLength: 8)
                    Text(setup.baseText)
                        .font(.figures(24, weight: .semibold))
                        .foregroundStyle(SoftGlassTheme.ink)
                    Text("at \(DevelopmentSetup.temperatureLabel(setup.nominalCelsius))")
                        .font(.system(size: 13))
                        .foregroundStyle(SoftGlassTheme.inkFaint)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(HapticButtonStyle())

            Stepper(
                value: Binding(get: { setup.nominalCelsius }, set: { setup.setNominalCelsius($0) }),
                in: 15...35,
                step: 0.5
            ) {
                Text("Sheet temperature \(DevelopmentSetup.temperatureLabel(setup.nominalCelsius))")
                    .font(.system(size: 15))
                    .foregroundStyle(SoftGlassTheme.inkSoft)
            }

            SegmentedPill(
                options: DevelopmentDirection.allCases,
                selection: $timeDirection,
                title: { $0.title }
            )

            SoftGlassRadialCard {
                VStack(spacing: 12) {
                    Text(softHeroLabel)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.92))

                    Button {
                        if timeDirection == .findTemperature {
                            editingWanted = true
                        }
                    } label: {
                        DotMatrixDigits(text: softHeroDigits, dot: 7, spacing: 3)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())
                    .disabled(timeDirection != .findTemperature)
                    .accessibilityHint(timeDirection == .findTemperature ? "Opens the time editor" : "")

                    Text("min")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white.opacity(0.90))

                    softRulerCaption
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.85))

                    SoftGlassTickRuler(range: softRulerRange, step: softRulerStep, value: softRulerBinding)
                        .padding(.horizontal, 28)

                    SoftGlassPageDots()
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 8)
            }

            if timeDirection == .findTemperature, let wantedNote {
                Text(wantedNote)
                    .font(.system(size: 12))
                    .foregroundStyle(SoftGlassTheme.inkFaint)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }

            compensationRow

            Toggle(isOn: Binding(get: { setup.continuousAgitation }, set: { setup.setContinuousAgitation($0) })) {
                Text("Agitate the whole time")
                    .font(.system(size: 15))
            }
            .tint(Theme.switchTint)

            if setup.continuousAgitation {
                Text("Times are written for agitation at intervals. If the tank keeps moving, take 10% off.")
                    .font(.system(size: 12))
                    .foregroundStyle(SoftGlassTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            moreTimesRow
        }
        .padding(.horizontal, 4)
    }

    private var softHeroLabel: String {
        timeDirection == .findTime ? "Development time" : "Time you want"
    }

    private var softHeroDigits: String {
        if timeDirection == .findTemperature {
            return Clock.mmss(TimeInterval(wantedSeconds))
        }
        if let compensated = setup.compensatedSeconds {
            return Clock.mmss(compensated)
        }
        return setup.baseText
    }

    @ViewBuilder
    private var softRulerCaption: some View {
        if timeDirection == .findTime {
            HStack {
                Text("Your water")
                Spacer()
                Text(Units.temperature(setup.temperature))
            }
            .padding(.horizontal, 28)
        } else {
            HStack {
                Text("Drag the ruler")
                Spacer()
                Image(systemName: "square.and.pencil")
            }
            .padding(.horizontal, 28)
        }
    }

    private var softRulerStep: Double {
        timeDirection == .findTime ? 0.5 : 15
    }

    /// The water window for the time direction; for the time direction, the
    /// times the water window can actually produce, so the ruler only ever
    /// offers a temperature that can be mixed.
    private var softRulerRange: ClosedRange<Double> {
        if timeDirection == .findTime {
            return 18...24
        }
        let nominal = setup.referenceSeconds ?? 600
        let at: (Double) -> TimeInterval = { temperature in
            DevelopmentTimeCalculator.calculate(
                nominalSeconds: nominal,
                nominalCelsius: setup.nominalCelsius,
                actualCelsius: temperature,
                continuousAgitation: setup.continuousAgitation
            ).seconds
        }
        let warm = at(24)
        let cool = at(18)
        return min(warm, cool)...max(warm, cool)
    }

    private var softRulerBinding: Binding<Double> {
        Binding(
            get: {
                timeDirection == .findTime
                    ? setup.temperature
                    : Double(wantedSeconds)
            },
            set: { newValue in
                if timeDirection == .findTime {
                    setup.setTemperature(newValue)
                } else {
                    wantedSeconds = Int(newValue.rounded())
                }
            }
        )
    }

    private var wantedRow: some View {
        HStack(spacing: 10) {
            Text("You want to develop for")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)

            Spacer(minLength: 8)

            Button {
                editingWanted = true
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

    /// Works back from a time the user wants to the water temperature that gives
    /// it, and holds the session at that temperature.
    private func applyWantedTime() {
        guard timeDirection == .findTemperature else { return }
        guard let celsius = setup.temperature(forSeconds: TimeInterval(wantedSeconds)) else { return }
        setup.setTemperature(celsius, step: 0.1)
    }

    private var wantedNote: String? {
        guard timeDirection == .findTemperature else { return nil }
        guard setup.temperature(forSeconds: TimeInterval(wantedSeconds)) != nil else {
            return "This needs one time from your sheet. With several, set the water by hand."
        }
        guard let actual = setup.compensatedSeconds else { return nil }
        if abs(actual - Double(wantedSeconds)) > 15 {
            return "The water only goes from 18 to 24 °C here. The closest is \(Clock.mmss(actual))."
        }
        return "That gives \(Clock.mmss(actual))."
    }

    private func readout(_ title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
            Text(value)
                .font(.figures(30, weight: .semibold))
                .foregroundStyle(Theme.amber)
        }
        .frame(maxWidth: .infinity)
    }

    private var compensationRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: setup.compensationIsWarning
                  ? "exclamationmark.triangle.fill"
                  : (setup.compensationIsEstimate ? "function" : "checkmark.circle.fill"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(setup.compensationIsEstimate ? Theme.amber : Theme.inkFaint)
                .padding(.top, 1)

            Text(setup.compensationNote)
                .font(.system(size: 12))
                .foregroundStyle(setup.compensationIsEstimate ? Theme.amber : Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var moreTimesRow: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                if setup.points.isEmpty {
                    Text("No times yet. Tap the time above to enter the one from your sheet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(setup.points) { point in
                                Button {
                                    pointEditor = PointEditor(id: point.celsius, celsius: point.celsius)
                                } label: {
                                    Text("\(DevelopmentSetup.temperatureLabel(point.celsius)) · \(Clock.mmss(point.seconds))")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundStyle(Theme.ink)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .glassCard(radius: 99)
                                }
                                .buttonStyle(HapticButtonStyle())
                                .contextMenu {
                                    if setup.points.count > 1 {
                                        Button("Remove", role: .destructive) {
                                            setup.removePoint(at: point.celsius)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    pointEditor = PointEditor(id: setup.temperature, celsius: setup.temperature)
                } label: {
                    Text("Add another time")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }
                .buttonStyle(HapticButtonStyle())

                Text("With two or more times the app uses the nearest ones from your sheet instead of estimating.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 10)
        } label: {
            Text("More times from your sheet")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
        }
        .tint(Theme.inkSoft)
    }

    // MARK: - Rolls

    private var rollsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(
                value: Binding(get: { setup.rollCount }, set: { setup.setRollCount($0) }),
                in: 1...6
            ) {
                LabeledContent("Rolls", value: "\(setup.rollCount)")
            }

            if setup.rollCount > 1 {
                ForEach(Array(setup.rolls.enumerated()), id: \.offset) { pair in
                    Button {
                        rollEditor = RollEditor(id: pair.offset, index: pair.offset)
                    } label: {
                        HStack {
                            Text("Roll \(pair.offset + 1)")
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.inkSoft)
                            Spacer()
                            Text(pair.element.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.inkFaint)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }

            if let warning = setup.mixedWarning {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 1)
                    Text(warning)
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Theme.amber)
            } else {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.amber)
                        .frame(width: 7, height: 7)
                    Text(setup.rollCount == 1
                         ? "One roll of \(setup.film.displayName)."
                         : "All \(setup.rollCount) rolls: \(setup.film.displayName).")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Agitation

    private var agitationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agitation intensity")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            SegmentedPill(
                options: AgitationIntensity.allCases,
                selection: Binding(
                    get: { setup.intensity },
                    set: { setup.intensity = $0 }
                ),
                title: { $0.label }
            )

            Text("\(setup.intensity.blurb) \(agitationNote)")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            Toggle("Speak each prompt", isOn: $setup.spokenPrompts)
                .tint(Theme.switchTint)

            Toggle("Voice commands", isOn: Binding(
                get: { setup.voiceCommands },
                set: { value in
                    setup.voiceCommands = value
                    Preferences.shared.setVoiceCommands(value)
                    if value {
                        Task { _ = await VoiceCommander.requestAccess() }
                    }
                }
            ))
            .tint(Theme.switchTint)

            Text("Spoken prompts say the action aloud. Voice commands let the phone listen for go, next stage, start fixer, add thirty seconds, and how many rolls a developer has done; iOS will ask for the microphone the first time.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Stages

    /// The default scheme chosen in Settings, spelled out for this intensity.
    private var agitationNote: String {
        switch Preferences.shared.agitationScheme {
        case .interval:
            return "Inversions last \(Int(setup.intensity.inversionSeconds)) s, every 60 s after the first 30 s, with a tap on the bench for bubbles."
        case .continuous:
            return "The reels keep moving for the whole stage — there is no interval to wait for."
        case .stand:
            return "This stage stands without agitation, so check the time your notes give for it."
        }
    }

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Pre-soak", isOn: $setup.preSoakEnabled)
                .tint(Theme.switchTint)

            if setup.preSoakEnabled {
                Stepper(value: $setup.preSoakSeconds, in: 30...600, step: 30) {
                    LabeledContent("Pre-soak time", value: Clock.mmss(setup.preSoakSeconds))
                }
            }

            Stepper(value: $setup.stopSeconds, in: 20...40, step: 5) {
                LabeledContent("Stop bath", value: "\(Int(setup.stopSeconds)) s")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Wash method")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                Picker("Wash method", selection: $setup.washMethod) {
                    ForEach(WashMethod.allCases) { method in
                        Text(method.label).tag(method)
                    }
                }
                .pickerStyle(.segmented)
            }

            Stepper(value: $setup.washSeconds, in: 60...1800, step: 30) {
                LabeledContent("Wash time", value: Clock.mmss(setup.washSeconds))
            }

            LabeledContent("Final rinse", value: "\(Int(SessionPlan.finalRinseSeconds)) s, wetting agent")

            Divider()

            Toggle("Match every stage to the working temperature", isOn: $setup.matchStageTemperatures)
                .tint(Theme.switchTint)

            if !setup.matchStageTemperatures {
                ForEach(StageKind.allCases) { kind in
                    Stepper(
                        value: Binding(
                            get: { setup.targetTemperature(for: kind) },
                            set: { setup.setStageTemperature($0, for: kind) }
                        ),
                        in: 18...24,
                        step: 0.5
                    ) {
                        LabeledContent(kind.title, value: DevelopmentSetup.temperatureLabel(setup.targetTemperature(for: kind)))
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Reuse

    private func askAboutReuse() {
        askingReuse = true
    }

    /// The reuse sheet closes first, then the session starts, so the two
    /// presentations never overlap.
    private func startPendingSession() {
        guard let use = confirmedUse else { return }
        confirmedUse = nil
        setup.setReuseCount(use)
        guard let plan = setup.makePlan() else { return }
        run = SessionRun(engine: SessionEngine(plan: plan))
    }

    // MARK: - Adjustments

    private var adjustmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            OverlineText(text: "Adjustments", color: Theme.amber)

            ForEach(setup.adjustments.reversed()) { item in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.ink)
                        Text("\(item.from) → \(item.to)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Spacer(minLength: 8)
                    Text(Clock.signed(item.delta))
                        .font(.figures(15, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Start

    private var startButton: some View {
        VStack(spacing: 10) {
            Button {
                askAboutReuse()
            } label: {
                Label("Start session", systemImage: "play.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.amberInk)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.amber)
            .controlSize(.large)
            .disabled(!setup.canStart)

            Text(setup.canStart
                 ? "Next: which use of the developer this is. Tap anywhere on the running screen to start."
                 : "Set the development time to start.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }
}
