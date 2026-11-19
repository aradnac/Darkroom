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

    @State private var setup = DevelopmentSetup(
        film: StarterLibrary.films[0],
        developer: StarterLibrary.developers[0],
        dilution: StarterLibrary.developers[0].dilutions[0]
    )

    @State private var choosingFilm = false
    @State private var choosingDeveloper = false
    @State private var rollEditor: RollEditor?
    @State private var pointEditor: PointEditor?
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
    /// screen hands one over — and falls back to the library's first entry.
    init(film: Film? = nil, developer: Developer? = nil, dilution: Dilution? = nil) {
        let films = StarterLibrary.films
        let developers = StarterLibrary.developers
        let resolvedFilm = film ?? films[0]
        let resolvedDeveloper = developer ?? developers[0]
        let resolvedDilution = dilution ?? resolvedDeveloper.dilutions[0]
        _setup = State(
            initialValue: DevelopmentSetup(
                film: resolvedFilm,
                developer: resolvedDeveloper,
                dilution: resolvedDilution
            )
        )
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
                timeCard
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
            Text("Time and temperature")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            VStack(spacing: 6) {
                Text(DevelopmentSetup.temperatureLabel(setup.temperature))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassCard(radius: 99, tint: Theme.amber)

                Slider(
                    value: Binding(get: { setup.temperature }, set: { setup.setTemperature($0) }),
                    in: 18...24,
                    step: 0.5
                )
                .tint(Theme.amber)

                HStack {
                    Text("18 °C")
                    Spacer()
                    Text("24 °C")
                }
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
            }

            HStack(spacing: 0) {
                Button {
                    pointEditor = PointEditor(id: 20, celsius: 20)
                } label: {
                    readout("Base at 20 °C", value: setup.baseText)
                }
                .buttonStyle(HapticButtonStyle())

                Divider()
                    .frame(height: 48)

                readout("Adjusted", value: setup.adjustedText)
            }

            compensationRow
            pointsRow
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
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
            Image(systemName: setup.compensationIsEstimate ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(setup.compensationIsEstimate ? Theme.amber : Theme.inkFaint)
                .padding(.top, 1)

            Text(setup.compensationNote)
                .font(.system(size: 12))
                .foregroundStyle(setup.compensationIsEstimate ? Theme.amber : Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pointsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Times for this pair")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)

                Spacer()

                if !setup.hasPoint(at: setup.temperature) {
                    Button {
                        pointEditor = PointEditor(id: setup.temperature, celsius: setup.temperature)
                    } label: {
                        Text("Add \(DevelopmentSetup.temperatureLabel(setup.temperature))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.amber)
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }

            if setup.points.isEmpty {
                Text("None yet — tap the base time to enter one.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)
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
        }
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

            Text("\(setup.intensity.blurb) Inversions last \(Int(setup.intensity.inversionSeconds)) s, every 60 s after the first 30 s, with a tap on the bench for bubbles.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            Toggle("Speak each prompt", isOn: $setup.spokenPrompts)
                .tint(Theme.amber)

            Toggle("Voice commands", isOn: $setup.voiceCommands)
                .tint(Theme.amber)

            Text("Spoken prompts say the action aloud. Voice commands listen on the device for go, next stage, start fixer, add thirty seconds, and how many rolls a developer has done.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Stages

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Pre-soak", isOn: $setup.preSoakEnabled)
                .tint(Theme.amber)

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
                .tint(Theme.amber)

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
