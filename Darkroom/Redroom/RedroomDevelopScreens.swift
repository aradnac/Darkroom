//
//  RedroomDevelopScreens.swift
//  Darkroom
//
//  The Develop bench in REDROOM. The same data, the same engine, the same
//  calculator — drawn as a darkroom: a published-time plate under the lamp, the
//  session setup as a column of anodised panels with a rotary dial and a
//  thermometer, the running session as a tray of chemistry with the countdown
//  engraved above it.
//
//  Nothing here re-implements a rule: every figure comes from DevelopmentSetup,
//  SessionPlan and SessionEngine, exactly as the other themes' screens get it.
//

import SwiftUI

// MARK: - Tab

struct RedroomDevelopTab: View {
    var body: some View {
        NavigationStack {
            RedroomDevelopHome()
        }
    }
}

// MARK: - Home

struct RedroomDevelopHome: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var revealed = false

    private let steps: [(title: String, detail: String)] = [
        ("Pre-soak", "Optional soak in water before the developer."),
        ("Developer", "Timed, with agitation prompts and a tap for bubbles."),
        ("Stop", "20 to 40 seconds with constant agitation."),
        ("Fix", "Set by your film leader's clearing time, times three."),
        ("Wash", "Running water, or fill and dump."),
        ("Final rinse", "A wetting agent, without a rinse.")
    ]

    var body: some View {
        RedroomScreen {
            RedroomScreenHeader(
                kicker: "At the sink",
                title: "Develop"
            )
            .redroomReveal(.safelightFade)

            heroPanel

            NavigationLink {
                RedroomSessionSetup()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(RedroomPrimaryButtonStyle())

            stagePanel
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !revealed else { return }
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(.easeOut(duration: 0.4).delay(0.1)) { revealed = true }
            }
        }
    }

    // MARK: Plates

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            RedroomLabel("Published time")

            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(featured?.figure ?? "--:--")
                        .font(Redroom.figure(44, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                        .contentTransition(.numericText())

                    Text(featured?.pair ?? "No sourced time yet")
                        .font(Redroom.body(13, weight: .medium))
                        .foregroundStyle(Redroom.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(featured?.temperature ?? "Add a film and a developer to the library")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                }

                Spacer(minLength: 4)

                RedroomRingGauge(
                    fraction: featured.map { min(max($0.seconds / (40 * 60), 0.04), 1) } ?? 0,
                    caption: featured.map { "\(Int(($0.seconds / 60).rounded()))" } ?? "--"
                )
                .frame(width: 84, height: 84)
            }

            RedroomLitRule()

            Text(featured?.note ?? "A published time appears here as soon as the library holds one for a film and developer pair.")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .optical, cornerRadius: RedroomMetrics.cardRadius)
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 14)
        .accessibilityElement(children: .combine)
    }

    private var stagePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            RedroomSectionHeader(title: "How a session runs")

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", index + 1))
                        .font(Redroom.figure(11, weight: .semibold))
                        .foregroundStyle(Redroom.safelight)
                        .frame(width: 22, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(Redroom.body(15, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Text(step.detail)
                            .font(Redroom.body(12))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)

                if index < steps.count - 1 {
                    RedroomLitRule(thickness: 0.5)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: RedroomMetrics.cardRadius)
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 18)
    }

    // MARK: Featured time

    private struct Featured {
        let figure: String
        let pair: String
        let temperature: String
        let note: String
        let seconds: TimeInterval
    }

    private var featured: Featured? {
        let library = LibraryStore.shared

        for film in StarterLibrary.films {
            let entries = library.times(forFilm: film.id).filter { $0.seconds != nil }
            guard let entry = entries.first(where: { abs($0.celsius - 20) < 0.05 }) ?? entries.first,
                  let seconds = entry.seconds else { continue }

            let developerName = library.developer(key: entry.developer)?.name ?? entry.developer
            let dilution = library.dilutionLabel(developerKey: entry.developer, dilution: entry.dilution)
            let temperature = library.temperatureLabel(entry.celsius)
            let source = library.source(key: entry.provenance.source)?.publisher
            let note = source.map { "Published time at \(temperature), sourced from \($0)." }
                ?? "Published time at \(temperature)."

            return Featured(
                figure: String(format: "%02d:%02d", seconds / 60, seconds % 60),
                pair: "\(film.displayName) · \(developerName) \(dilution)",
                temperature: temperature,
                note: note,
                seconds: TimeInterval(seconds)
            )
        }

        return nil
    }
}

// MARK: - Ring gauge

/// A ring of engraved ticks with the safelight's fill around it. Used for a
/// published time and for the running stage.
struct RedroomRingGauge: View {
    let fraction: Double
    var caption: String?

    @Environment(\.redroomLight) private var light
    @State private var frame: CGRect = .zero

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        let sample = RedroomLightSample.make(frame: frame, light: light)

        ZStack {
            Circle()
                .fill(Redroom.color(0x0A0303))

            Canvas { context, size in
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                let outer = radius - 1
                let inner = radius - 6

                for tick in 0..<48 {
                    let angle = Double(tick) / 48 * 2 * .pi - .pi / 2
                    let isMajor = tick % 4 == 0
                    var path = Path()
                    path.move(to: CGPoint(
                        x: centre.x + CGFloat(cos(angle)) * outer,
                        y: centre.y + CGFloat(sin(angle)) * outer
                    ))
                    path.addLine(to: CGPoint(
                        x: centre.x + CGFloat(cos(angle)) * (isMajor ? inner : inner + 2),
                        y: centre.y + CGFloat(sin(angle)) * (isMajor ? inner : inner + 2)
                    ))
                    context.stroke(
                        path,
                        with: .color(Redroom.textMuted.opacity(isMajor ? 0.55 : 0.25)),
                        lineWidth: isMajor ? 1.2 : 0.8
                    )
                }
            }

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(
                        colors: [Redroom.deepRed, Redroom.safelightSecondary, Redroom.safelight],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(7)
                .shadow(color: Redroom.safelight.opacity(0.45 * sample.direct), radius: 6)

            if let caption {
                Text(caption)
                    .font(Redroom.figure(17, weight: .semibold))
                    .foregroundStyle(Redroom.text)
            }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { value in
            frame = value
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}

// MARK: - Session setup

struct RedroomSessionSetup: View {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    @State private var setup: DevelopmentSetup
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

    private struct SessionRun: Identifiable {
        let id = UUID()
        let engine: SessionEngine
    }

    private struct RollEditor: Identifiable {
        let id: Int
        let index: Int
    }

    private struct PointEditor: Identifiable {
        let id: Double
        let celsius: Double
    }

    init(film: Film? = nil, developer: Developer? = nil, dilution: Dilution? = nil) {
        let films = StarterLibrary.films
        let developers = StarterLibrary.developers
        let resolvedFilm = film ?? films[0]
        let resolvedDeveloper = developer ?? developers[0]
        let resolvedDilution = dilution ?? resolvedDeveloper.dilutions[0]
        _setup = State(initialValue: DevelopmentSetup(
            film: resolvedFilm,
            developer: resolvedDeveloper,
            dilution: resolvedDilution
        ))
    }

    var body: some View {
        RedroomScreen {
            filmPlate

            developerPanel

            exposurePanel

            timePanel

            rollsPanel

            agitationPanel

            stagePanel

            if !setup.adjustments.isEmpty {
                adjustmentsPanel
            }

            startSection
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "New session", title: setup.film.displayName)
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $choosingFilm) {
            RedroomFilmPicker(selection: Binding(
                get: { setup.film },
                set: { setup.setFilm($0) }
            ))
        }
        .sheet(isPresented: $choosingDeveloper) {
            RedroomDeveloperPicker(selection: Binding(
                get: { setup.developer },
                set: { setup.setDeveloper($0) }
            ))
        }
        .sheet(item: $rollEditor) { editor in
            RedroomFilmPicker(selection: Binding(
                get: { setup.rolls.indices.contains(editor.index) ? setup.rolls[editor.index] : setup.film },
                set: { setup.setRollFilm($0, at: editor.index) }
            ))
        }
        .sheet(item: $pointEditor) { editor in
            RedroomDurationSheet(
                title: "Time at \(DevelopmentSetup.temperatureLabel(editor.celsius))",
                seconds: Binding(
                    get: { Int((setup.pointSeconds(at: editor.celsius) ?? 0).rounded()) },
                    set: { setup.setPointSeconds(TimeInterval($0), at: editor.celsius) }
                )
            )
        }
        .sheet(isPresented: $editingWanted) {
            RedroomDurationSheet(title: "Time you want", seconds: $wantedSeconds)
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
            RedroomReuseSheet(
                developerName: "\(setup.developer.name) \(setup.dilution.label)",
                compensatedSeconds: setup.compensatedSeconds,
                initialUse: setup.reuseCount
            ) { use in
                confirmedUse = use
            }
        }
        .fullScreenCover(item: $run) { session in
            RedroomRunningSession(engine: session.engine) {
                run = nil
            }
        }
    }

    // MARK: Film and developer

    private var filmPlate: some View {
        Button {
            choosingFilm = true
        } label: {
            FilmNegativeCard(
                title: setup.film.fullName,
                subtitle: "\(setup.film.formatSummary) · ISO \(setup.film.iso) · \(setup.film.process.label)",
                selected: true
            )
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Film")
        .accessibilityValue(setup.film.fullName)
    }

    private var developerPanel: some View {
        RedroomPanel(title: "Developer") {
            Button {
                choosingDeveloper = true
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(setup.developer.name) \(setup.dilution.label)")
                            .font(Redroom.body(16, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Text(setup.developer.manufacturer)
                            .font(Redroom.body(12))
                            .foregroundStyle(Redroom.textMuted)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Redroom.textMuted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(HapticButtonStyle())

            if setup.developer.dilutions.count > 1 {
                RedroomSegmented(
                    items: setup.developer.dilutions,
                    selection: Binding(
                        get: { setup.dilution },
                        set: { setup.setDilution($0) }
                    ),
                    title: { $0.label }
                )
            }
        }
    }

    private var exposurePanel: some View {
        RedroomPanel(title: "Exposure index", detail: exposureNote) {
            RedroomSegmented(
                items: Array(-2...3),
                selection: Binding(
                    get: { setup.pushStops },
                    set: { setup.setPushStops($0) }
                ),
                title: { stopTitle($0) }
            )
        }
    }

    private func stopTitle(_ stops: Int) -> String {
        if stops == 0 { return "ISO" }
        return stops > 0 ? "+\(stops)" : "−\(-stops)"
    }

    private var exposureNote: String {
        if setup.pushStops == 0 {
            return "Box speed. The time you enter is the standard time for ISO \(setup.film.iso)."
        }
        return "\(setup.exposureSummary). No documented time is held for this exposure index, so enter your own."
    }

    // MARK: Time

    private var timePanel: some View {
        RedroomPanel(title: "Development time") {
            Button {
                pointEditor = PointEditor(id: setup.nominalCelsius, celsius: setup.nominalCelsius)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Your sheet says")
                            .font(Redroom.body(13))
                            .foregroundStyle(Redroom.textMuted)
                        Text("at \(DevelopmentSetup.temperatureLabel(setup.nominalCelsius))")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                    }

                    Spacer(minLength: 8)

                    Text(setup.baseText)
                        .font(Redroom.figure(30, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                        .contentTransition(.numericText())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(HapticButtonStyle())

            RedroomLitRule(thickness: 0.5)

            HStack(alignment: .center, spacing: 14) {
                RedroomRotaryDial(
                    title: "Water",
                    value: Binding(
                        get: { setup.temperature },
                        set: { setup.setTemperature($0) }
                    ),
                    range: 18...24,
                    step: 0.5,
                    format: { Units.shortTemperature($0) },
                    diameter: 118
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(timeDirection == .findTime ? "Develop for" : "Use water at")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)

                    Text(timeDirection == .findTime ? setup.adjustedText : Units.temperature(setup.temperature))
                        .font(Redroom.figure(26, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                        .contentTransition(.numericText())

                    RedroomSegmented(
                        items: DevelopmentDirection.allCases,
                        selection: $timeDirection,
                        title: { $0.title }
                    )
                }
            }

            if timeDirection == .findTemperature {
                Button {
                    editingWanted = true
                } label: {
                    HStack {
                        Text("You want to develop for")
                            .font(Redroom.body(13))
                            .foregroundStyle(Redroom.textMuted)
                        Spacer(minLength: 6)
                        Text(Clock.mmss(TimeInterval(wantedSeconds)))
                            .font(Redroom.figure(17, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(HapticButtonStyle())

                if let wantedNote {
                    RedroomNote(text: wantedNote)
                }
            }

            compensationRow

            Toggle(isOn: Binding(
                get: { setup.continuousAgitation },
                set: { setup.setContinuousAgitation($0) }
            )) {
                Text("Agitate the whole time")
                    .font(Redroom.body(14))
                    .foregroundStyle(Redroom.text)
            }
            .toggleStyle(RedroomToggleStyle())

            if setup.continuousAgitation {
                RedroomNote(text: "Times are written for agitation at intervals. If the tank keeps moving, take 10% off.")
            }

            moreTimes
        }
    }

    @ViewBuilder
    private var compensationRow: some View {
        if setup.compensationIsWarning {
            RedroomWarning(title: "A starting point, not a time", detail: setup.compensationNote)
        } else {
            RedroomNote(
                text: setup.compensationNote,
                symbol: setup.compensationIsEstimate ? "function" : "checkmark.circle"
            )
        }
    }

    private var moreTimes: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                if setup.points.isEmpty {
                    Text("No times yet. Tap the time above to enter the one from your sheet.")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(setup.points) { point in
                                Button {
                                    pointEditor = PointEditor(id: point.celsius, celsius: point.celsius)
                                } label: {
                                    RedroomChip(
                                        text: "\(DevelopmentSetup.temperatureLabel(point.celsius)) · \(Clock.mmss(point.seconds))"
                                    )
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
                        .padding(.vertical, 1)
                    }
                }

                Button {
                    pointEditor = PointEditor(id: setup.temperature, celsius: setup.temperature)
                } label: {
                    Text("Add another time")
                        .font(Redroom.body(13, weight: .semibold))
                        .foregroundStyle(Redroom.safelight)
                }
                .buttonStyle(HapticButtonStyle())

                RedroomNote(text: "With two or more times the app uses the nearest ones from your sheet instead of estimating.")
            }
            .padding(.top, 10)
        } label: {
            Text("More times from your sheet")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
        }
        .tint(Redroom.textMuted)
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

    private func applyWantedTime() {
        guard timeDirection == .findTemperature else { return }
        guard let celsius = setup.temperature(forSeconds: TimeInterval(wantedSeconds)) else { return }
        setup.setTemperature(celsius, step: 0.1)
    }

    // MARK: Rolls

    private var rollsPanel: some View {
        RedroomPanel(title: "Rolls") {
            RedroomStepper(
                title: "Rolls in the tank",
                value: "\(setup.rollCount)",
                decrement: setup.rollCount > 1 ? { setup.setRollCount(setup.rollCount - 1) } : nil,
                increment: setup.rollCount < 6 ? { setup.setRollCount(setup.rollCount + 1) } : nil
            )

            if setup.rollCount > 1 {
                ForEach(Array(setup.rolls.enumerated()), id: \.offset) { pair in
                    Button {
                        rollEditor = RollEditor(id: pair.offset, index: pair.offset)
                    } label: {
                        HStack(spacing: 8) {
                            Text("Roll \(pair.offset + 1)")
                                .font(Redroom.body(13))
                                .foregroundStyle(Redroom.textMuted)
                            Spacer(minLength: 6)
                            Text(pair.element.displayName)
                                .font(Redroom.body(13, weight: .medium))
                                .foregroundStyle(Redroom.text)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Redroom.textMuted)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }

            if let warning = setup.mixedWarning {
                RedroomWarning(title: "These rolls cannot share a time", detail: warning)
            } else {
                RedroomNote(
                    text: setup.rollCount == 1
                        ? "One roll of \(setup.film.displayName)."
                        : "All \(setup.rollCount) rolls: \(setup.film.displayName).",
                    symbol: "checkmark.circle"
                )
            }
        }
    }

    // MARK: Agitation

    private var agitationPanel: some View {
        RedroomPanel(title: "Agitation", detail: "\(setup.intensity.blurb) \(agitationNote)") {
            RedroomSegmented(
                items: AgitationIntensity.allCases,
                selection: Binding(
                    get: { setup.intensity },
                    set: { setup.intensity = $0 }
                ),
                title: { $0.label }
            )

            RedroomLitRule(thickness: 0.5)

            Toggle("Speak each prompt", isOn: $setup.spokenPrompts)
                .font(Redroom.body(14))
                .toggleStyle(RedroomToggleStyle())

            Toggle(isOn: Binding(
                get: { setup.voiceCommands },
                set: { value in
                    setup.voiceCommands = value
                    Preferences.shared.setVoiceCommands(value)
                    if value {
                        Task { _ = await VoiceCommander.requestAccess() }
                    }
                }
            )) {
                Text("Voice commands")
                    .font(Redroom.body(14))
                    .foregroundStyle(Redroom.text)
            }
            .toggleStyle(RedroomToggleStyle())

            RedroomNote(text: "Spoken prompts say the action aloud. Voice commands let the phone listen for go, next stage, start fixer, add thirty seconds, and how many rolls a developer has done; iOS will ask for the microphone the first time.")
        }
    }

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

    // MARK: Stages

    private var stagePanel: some View {
        RedroomPanel(title: "Stages") {
            Toggle("Pre-soak", isOn: $setup.preSoakEnabled)
                .font(Redroom.body(14))
                .toggleStyle(RedroomToggleStyle())

            if setup.preSoakEnabled {
                RedroomStepper(
                    title: "Pre-soak time",
                    value: Clock.mmss(setup.preSoakSeconds),
                    decrement: setup.preSoakSeconds > 30 ? { setup.preSoakSeconds -= 30 } : nil,
                    increment: setup.preSoakSeconds < 600 ? { setup.preSoakSeconds += 30 } : nil
                )
            }

            RedroomStepper(
                title: "Stop bath",
                value: "\(Int(setup.stopSeconds)) s",
                decrement: setup.stopSeconds > 20 ? { setup.stopSeconds -= 5 } : nil,
                increment: setup.stopSeconds < 40 ? { setup.stopSeconds += 5 } : nil
            )

            RedroomLitRule(thickness: 0.5)

            Text("Wash method")
                .font(Redroom.body(13))
                .foregroundStyle(Redroom.textMuted)

            RedroomSegmented(
                items: WashMethod.allCases,
                selection: $setup.washMethod,
                title: { $0.label }
            )

            RedroomStepper(
                title: "Wash time",
                value: Clock.mmss(setup.washSeconds),
                decrement: setup.washSeconds > 60 ? { setup.washSeconds -= 30 } : nil,
                increment: setup.washSeconds < 1800 ? { setup.washSeconds += 30 } : nil
            )

            RedroomValueRow(
                label: "Final rinse",
                value: "\(Int(SessionPlan.finalRinseSeconds)) s, wetting agent"
            )

            RedroomLitRule(thickness: 0.5)

            Toggle("Match every stage to the working temperature", isOn: $setup.matchStageTemperatures)
                .font(Redroom.body(14))
                .toggleStyle(RedroomToggleStyle())

            if !setup.matchStageTemperatures {
                ForEach(StageKind.allCases) { kind in
                    RedroomStepper(
                        title: kind.title,
                        value: DevelopmentSetup.temperatureLabel(setup.targetTemperature(for: kind)),
                        decrement: {
                            setup.setStageTemperature(setup.targetTemperature(for: kind) - 0.5, for: kind)
                        },
                        increment: {
                            setup.setStageTemperature(setup.targetTemperature(for: kind) + 0.5, for: kind)
                        }
                    )
                }
            }
        }
    }

    // MARK: Adjustments

    private var adjustmentsPanel: some View {
        RedroomPanel(title: "Adjustments", detail: "Every change to the time since this bench was opened.") {
            ForEach(Array(setup.adjustments.reversed().enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(Redroom.body(13, weight: .medium))
                            .foregroundStyle(Redroom.text)
                        Text("\(item.from) → \(item.to)")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                    }

                    Spacer(minLength: 6)

                    Text(Clock.signed(item.delta))
                        .font(Redroom.figure(14, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: Start

    private var startSection: some View {
        VStack(spacing: 10) {
            Button {
                askingReuse = true
            } label: {
                Text("Start session")
            }
            .buttonStyle(RedroomPrimaryButtonStyle())
            .disabled(!setup.canStart)

            Text(setup.canStart
                 ? "Next: which use of the developer this is. Tap anywhere on the running screen to start."
                 : "Set the development time to start.")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private func startPendingSession() {
        guard let use = confirmedUse else { return }
        confirmedUse = nil
        setup.setReuseCount(use)
        guard let plan = setup.makePlan() else { return }
        run = SessionRun(engine: SessionEngine(plan: plan))
    }
}

// MARK: - Running session

struct RedroomRunningSession: View {
    let engine: SessionEngine
    let onClose: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmingEnd = false
    @Namespace private var stageSelection

    var body: some View {
        ZStack {
            RedroomSafelight()

            VStack(spacing: 0) {
                topBar
                header

                if let answer = engine.answer {
                    answerCard(answer)
                }

                voiceLine

                Spacer(minLength: 6)

                timerBlock

                Spacer(minLength: 10)

                nextTray
                controls
                stageStrip
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .contentShape(Rectangle())
        .preferredColorScheme(.dark)
        .onTapGesture {
            engine.goTapped()
        }
        .sheet(isPresented: clearingBinding) {
            RedroomClearingSheet(engine: engine)
        }
        .sheet(isPresented: finishedBinding) {
            RedroomSessionSummary(plan: engine.plan, onDone: onClose)
        }
        .confirmationDialog("End this session?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End session", role: .destructive) {
                onClose()
            }
            Button("Keep going", role: .cancel) {}
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = Preferences.shared.keepAwake
            AgitationAlerts.requestPermission()
            engine.activateVoice()
            SessionActivityController.shared.start(engine: engine)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            SessionActivityController.shared.end()
            engine.stop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                engine.refresh()
                engine.recheckVoice()
                SessionActivityController.shared.update(engine: engine)
            }
        }
        .onChange(of: engine.phase) { _, _ in
            SessionActivityController.shared.update(engine: engine)
        }
        .onChange(of: engine.stageIndex) { _, _ in
            SessionActivityController.shared.update(engine: engine)
        }
        .onChange(of: engine.currentPrompt.segmentIndex) { _, _ in
            SessionActivityController.shared.update(engine: engine)
        }
        .onChange(of: engine.plan.stages[engine.stageIndex].duration) { _, _ in
            SessionActivityController.shared.update(engine: engine)
        }
    }

    private var clearingBinding: Binding<Bool> {
        Binding(get: { engine.phase == .clearing }, set: { _ in })
    }

    private var finishedBinding: Binding<Bool> {
        Binding(get: { engine.phase == .finished }, set: { _ in })
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                RedroomIndicator(on: engine.phase == .running, size: 6)
                Text(engine.currentStage.kind.title)
                    .font(Redroom.body(13, weight: .semibold))
                    .foregroundStyle(Redroom.text)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background {
                Color.clear.redroomGlass(variant: .optical, cornerRadius: 13)
            }

            Spacer(minLength: 0)

            Text(Units.temperature(engine.plan.temperature))
                .font(Redroom.figure(12, weight: .medium))
                .foregroundStyle(Redroom.text)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background {
                    Color.clear.redroomGlass(variant: .transparent, cornerRadius: 13)
                }

            Button {
                if engine.phase == .finished {
                    onClose()
                } else {
                    confirmingEnd = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .frame(width: 38, height: 38)
                    .background {
                        Color.clear.redroomGlass(variant: .transparent, cornerRadius: 13)
                    }
            }
            .buttonStyle(HapticButtonStyle())
            .accessibilityLabel("End this session")
        }
    }

    private var header: some View {
        VStack(spacing: 3) {
            Text(engine.plan.film.fullName.uppercased())
                .font(Redroom.label(11))
                .tracking(2.2)
                .foregroundStyle(Redroom.textMuted)
            Text("\(engine.plan.developer.name) \(engine.plan.dilution.label) · stage \(min(engine.stageIndex + 1, engine.stageCount)) of \(engine.stageCount)")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(.top, 10)
    }

    private func answerCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Redroom.text)
                .padding(.top, 1)
            Text(text)
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .frosted, cornerRadius: 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var voiceLine: some View {
        if engine.plan.voiceCommands {
            HStack(spacing: 6) {
                Image(systemName: engine.voice.isListening ? "mic.fill" : "mic.slash")
                    .font(.system(size: 9, weight: .semibold))
                Text(engine.voice.statusLine)
                    .font(Redroom.body(10, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(engine.voice.isListening ? Redroom.text : Redroom.textMuted)
            .padding(.top, 7)
        }
    }

    // MARK: Timer

    private var timerBlock: some View {
        ZStack {
            RedroomRingGauge(fraction: stageProgress)
                .frame(width: 232, height: 232)

            VStack(spacing: 4) {
                Text(dialCaption)
                    .font(Redroom.label(10))
                    .tracking(2.4)
                    .foregroundStyle(Redroom.textMuted)

                Text(dialTime)
                    .font(Redroom.figure(50, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText(countsDown: true))

                Text("OF \(durationText(engine.currentStage))")
                    .font(Redroom.figure(11, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(Redroom.textMuted)
            }
            .opacity(engine.phase == .ready ? 0 : 1)

            if engine.phase == .ready {
                goButton
            }
        }
        .frame(width: 232, height: 232)
    }

    private var goButton: some View {
        Button {
            engine.goTapped()
        } label: {
            VStack(spacing: 2) {
                Text("GO")
                    .font(Redroom.display(38, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Redroom.text)
                Text(engine.currentStage.kind.title.uppercased())
                    .font(Redroom.label(8))
                    .tracking(1.6)
                    .foregroundStyle(Redroom.textMuted)
            }
            .frame(width: 138, height: 138)
            .background {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Redroom.deepRed.opacity(0.95),
                                Redroom.color(0x1A0507)
                            ],
                            center: .top,
                            startRadius: 2,
                            endRadius: 120
                        )
                    )
            }
            .overlay {
                Circle()
                    .strokeBorder(Redroom.safelight.opacity(0.8), lineWidth: 1.5)
            }
            .shadow(color: Redroom.safelight.opacity(0.5), radius: 26)
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Start \(engine.currentStage.kind.title)")
    }

    private var dialCaption: String {
        switch engine.phase {
        case .ready: return "READY"
        case .running: return "REMAINING"
        case .paused: return "PAUSED"
        case .clearing: return "WAITING"
        case .finished: return "DONE"
        }
    }

    private var dialTime: String {
        if engine.phase == .clearing || engine.currentStage.needsClearing {
            return "--:--"
        }
        if engine.phase == .finished {
            return "00:00"
        }
        return Clock.mmssCeil(engine.stageRemaining)
    }

    private var stageProgress: Double {
        let duration = engine.currentStage.duration
        guard duration > 0 else { return 0 }
        return min(1, max(0, engine.stageElapsed / duration))
    }

    // MARK: Next action

    private var nextTray: some View {
        DarkroomLiquidTray(depth: isTiming ? 1.15 : 0.85) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(cardHeadline)
                        .font(Redroom.label(10))
                        .tracking(1.4)
                        .foregroundStyle(Redroom.textMuted)

                    Text(cardBody)
                        .font(Redroom.body(13))
                        .foregroundStyle(Redroom.text)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Text(cardCountdown)
                    .font(Redroom.figure(28, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText(countsDown: true))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var isTiming: Bool {
        engine.phase == .running || engine.phase == .paused
    }

    private var cardHeadline: String {
        switch engine.phase {
        case .ready:
            return "READY · \(engine.currentStage.kind.title.uppercased())"
        case .clearing:
            return "FIXER"
        case .finished:
            return "SESSION COMPLETE"
        case .running, .paused:
            return engine.currentPrompt.title.uppercased()
        }
    }

    private var cardBody: String {
        switch engine.phase {
        case .ready:
            return "Tap anywhere or say go to start. \(engine.currentStage.instruction)" + stageTemperatureNote
        case .clearing:
            return "Put a strip of film leader in the fixer and time how long it takes to turn clear."
        case .finished:
            return "Rinse, then hang the film to dry in a dust-free place."
        case .running, .paused:
            return engine.currentPrompt.detail + stageTemperatureNote
        }
    }

    private var stageTemperatureNote: String {
        guard let target = engine.currentStage.targetTemperature,
              abs(target - engine.plan.temperature) > 0.05 else { return "" }
        return " Target \(Units.temperature(target))."
    }

    private var cardCountdown: String {
        switch engine.phase {
        case .ready:
            return Clock.mmssCeil(engine.currentStage.duration)
        case .clearing:
            return "--:--"
        case .finished:
            return "00:00"
        case .running, .paused:
            return Clock.mmssCeil(engine.currentPrompt.remaining)
        }
    }

    // MARK: Controls

    private var controlsLocked: Bool {
        engine.phase == .clearing || engine.phase == .finished
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    primaryAction()
                } label: {
                    Text(primaryTitle)
                }
                .buttonStyle(RedroomPrimaryButtonStyle())
                .disabled(controlsLocked)

                Button {
                    engine.skipStage()
                } label: {
                    Text("Skip")
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
                .frame(maxWidth: 108)
                .disabled(controlsLocked)
            }

            HStack(spacing: 8) {
                Button("+30 s") {
                    engine.addTime(30)
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .disabled(controlsLocked)

                Button("+1 min") {
                    engine.addTime(60)
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .disabled(controlsLocked)
            }
        }
        .padding(.top, 10)
    }

    private func primaryAction() {
        switch engine.phase {
        case .ready:
            engine.goTapped()
        case .running, .paused:
            engine.togglePause()
        case .clearing, .finished:
            break
        }
    }

    private var primaryTitle: String {
        switch engine.phase {
        case .ready: return "Start"
        case .paused: return "Resume"
        case .running, .clearing, .finished: return "Pause"
        }
    }

    // MARK: Stage strip

    private var stageStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(engine.plan.stages.enumerated()), id: \.element.id) { index, stage in
                    stageChip(stage, index: index)
                }
            }
            .padding(.horizontal, 2)
            .animation(reduceMotion ? nil : .snappy(duration: 0.42, extraBounce: 0.06), value: engine.stageIndex)
        }
        .scrollClipDisabled()
        .padding(.top, 10)
    }

    private func stageChip(_ stage: SessionStage, index: Int) -> some View {
        let finished = engine.phase == .finished
        let done = finished || index < engine.stageIndex
        let current = !finished && index == engine.stageIndex

        return VStack(spacing: 4) {
            Image(systemName: done ? "checkmark.circle.fill" : (current ? "circle.inset.filled" : "circle"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(current ? Redroom.text : Redroom.textMuted)

            Text(stage.kind.title)
                .font(Redroom.label(8))
                .tracking(0.6)
                .foregroundStyle(Redroom.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(durationText(stage))
                .font(Redroom.figure(11, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
        }
        .frame(width: 78)
        .padding(.vertical, 8)
        .background {
            if current {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.clear)
                    .redroomGlass(variant: .optical, cornerRadius: 14)
                    .matchedGeometryEffect(id: "redroomStageSelection", in: stageSelection)
            } else {
                Color.clear.redroomGlass(variant: .transparent, cornerRadius: 14)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(current ? Redroom.safelight.opacity(0.75) : Color.clear, lineWidth: 1)
        }
        .opacity(done ? 0.55 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.kind.title), \(durationText(stage))")
        .accessibilityAddTraits(current ? .isSelected : [])
    }

    private func durationText(_ stage: SessionStage) -> String {
        stage.needsClearing ? "--:--" : Clock.mmss(stage.duration)
    }
}

// MARK: - Summary

struct RedroomSessionSummary: View {
    let plan: SessionPlan
    let onDone: () -> Void

    private var totalSeconds: TimeInterval {
        plan.stages.reduce(0) { $0 + $1.duration }
    }

    private var details: [(label: String, value: String)] {
        var rows: [(label: String, value: String)] = [("Rolls", "\(plan.rollCount)")]
        if plan.exposureIndex != plan.film.iso {
            rows.append(("Exposure index", "EI \(plan.exposureIndex)"))
        }
        rows.append(("Developer time", Clock.mmss(plan.developmentTime)))
        if plan.reuseCount > 1 {
            rows.append(("Developer reuse", "use \(plan.reuseCount)"))
        }
        rows.append(("Agitation", plan.intensity.label))
        rows.append(("Temperature", Units.temperature(plan.temperature)))
        rows.append(("Wash", plan.washMethod.label))
        rows.append(("Total session", Clock.mmss(totalSeconds)))
        return rows
    }

    var body: some View {
        RedroomSheetBody(
            kicker: "Session complete",
            title: "Developed"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(Redroom.text)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Roll developed")
                            .font(Redroom.display(21, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Text("\(plan.film.fullName) · \(plan.developer.name) \(plan.dilution.label)")
                            .font(Redroom.body(12))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                RedroomPanel {
                    ForEach(Array(details.enumerated()), id: \.offset) { index, row in
                        RedroomValueRow(label: row.label, value: row.value)
                        if index < details.count - 1 {
                            RedroomLitRule(thickness: 0.5)
                        }
                    }
                }

                RedroomNote(text: "Rinse, then hang the film to dry in a dust-free place.", symbol: "wind")

                VStack(spacing: 10) {
                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(RedroomPrimaryButtonStyle())

                    Button("Discard", role: .destructive) {
                        onDone()
                    }
                    .buttonStyle(RedroomSecondaryButtonStyle())
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Film picker

struct RedroomFilmPicker: View {
    @Binding var selection: Film
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RedroomSheetBody(
            kicker: "Load the tank",
            title: "Film",
            detail: "Every film the app holds a published time for."
        ) {
            ForEach(StarterLibrary.films) { film in
                Button {
                    selection = film
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    FilmNegativeCard(
                        title: film.fullName,
                        subtitle: "\(film.formatSummary) · ISO \(film.iso) · \(film.process.label)",
                        selected: film == selection
                    )
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityAddTraits(film == selection ? .isSelected : [])
            }
        }
    }
}

// MARK: - Developer picker

struct RedroomDeveloperPicker: View {
    @Binding var selection: Developer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RedroomSheetBody(
            kicker: "Mix the chemistry",
            title: "Developer",
            detail: "Each with the dilutions the app holds for it."
        ) {
            ForEach(StarterLibrary.developers) { developer in
                Button {
                    selection = developer
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(developer.name)
                                .font(Redroom.body(16, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                            Text("\(developer.manufacturer) · \(developer.dilutions.map(\.label).joined(separator: " · "))")
                                .font(Redroom.body(12))
                                .foregroundStyle(Redroom.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 4)

                        if developer == selection {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Redroom.text)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redroomGlass(
                        variant: developer == selection ? .optical : .transparent,
                        cornerRadius: 16
                    )
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityAddTraits(developer == selection ? .isSelected : [])
            }
        }
    }
}

// MARK: - Duration sheet

/// Minutes and seconds on two dials, turned by hand.
struct RedroomDurationSheet: View {
    let title: String
    @Binding var seconds: Int

    @Environment(\.dismiss) private var dismiss

    private var minutes: Binding<Double> {
        Binding(
            get: { Double(seconds / 60) },
            set: { seconds = Int($0) * 60 + seconds % 60 }
        )
    }

    private var remainder: Binding<Double> {
        Binding(
            get: { Double(seconds % 60) },
            set: { seconds = (seconds / 60) * 60 + Int($0) }
        )
    }

    var body: some View {
        RedroomSheetBody(
            kicker: "Set the time",
            title: title,
            detail: "Turn either dial. The time is stored as minutes and seconds.",
            confirmTitle: "Done",
            onConfirm: { dismiss() }
        ) {
            HStack(spacing: 14) {
                RedroomRotaryDial(
                    title: "Minutes",
                    value: minutes,
                    range: 0...59,
                    step: 1,
                    format: { "\(Int($0)) min" },
                    diameter: 128
                )

                RedroomRotaryDial(
                    title: "Seconds",
                    value: remainder,
                    range: 0...59,
                    step: 1,
                    format: { "\(Int($0)) s" },
                    diameter: 128
                )
            }
            .frame(maxWidth: .infinity)

            RedroomPanel {
                RedroomValueRow(label: "Time", value: Clock.mmss(TimeInterval(seconds)), emphasised: true)
            }
        }
    }
}

// MARK: - Reuse sheet

struct RedroomReuseSheet: View {
    let developerName: String
    let compensatedSeconds: TimeInterval?
    let initialUse: Int
    let onStart: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var use: Int

    init(
        developerName: String,
        compensatedSeconds: TimeInterval?,
        initialUse: Int,
        onStart: @escaping (Int) -> Void
    ) {
        self.developerName = developerName
        self.compensatedSeconds = compensatedSeconds
        self.initialUse = initialUse
        self.onStart = onStart
        _use = State(initialValue: initialUse)
    }

    private var finalSeconds: TimeInterval? {
        guard let compensatedSeconds else { return nil }
        return (compensatedSeconds * DevelopmentSetup.reuseFactor(uses: use)).rounded()
    }

    var body: some View {
        RedroomSheetBody(
            kicker: "Before the developer goes in",
            title: "Which use?",
            detail: "\(developerName), mixed fresh, is use 1. Each earlier use adds 10%, compounded."
        ) {
            RedroomPanel {
                RedroomStepper(
                    title: "Use",
                    value: "\(use)",
                    decrement: use > 1 ? { use -= 1 } : nil,
                    increment: use < 20 ? { use += 1 } : nil
                )

                Text(DevelopmentSetup.reuseArithmetic(uses: use))
                    .font(Redroom.body(13))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            RedroomPanel(title: "Time for this use") {
                Text(finalSeconds.map { Clock.mmss($0) } ?? "--:--")
                    .font(Redroom.figure(40, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText())
            }

            Button {
                onStart(use)
                dismiss()
            } label: {
                Text("Start session")
            }
            .buttonStyle(RedroomPrimaryButtonStyle())
            .disabled(finalSeconds == nil)
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Clearing sheet

struct RedroomClearingSheet: View {
    let engine: SessionEngine

    @State private var clearingSeconds = 30
    @State private var multiplier = 3

    private var fixSeconds: Int { clearingSeconds * multiplier }

    var body: some View {
        RedroomSheetBody(
            kicker: "Before the fixer",
            title: "Leader clearing",
            detail: "Put a strip of film leader in the fixer and time how long it takes to turn clear."
        ) {
            RedroomPanel {
                RedroomStepper(
                    title: "Clearing time",
                    value: "\(clearingSeconds) s",
                    decrement: clearingSeconds > 5 ? { clearingSeconds -= 5 } : nil,
                    increment: clearingSeconds < 600 ? { clearingSeconds += 5 } : nil
                )

                RedroomSegmented(
                    items: [2, 3],
                    selection: $multiplier,
                    title: { "\($0)×" }
                )
            }

            RedroomPanel(title: "Fix time") {
                Text(Clock.mmss(TimeInterval(fixSeconds)))
                    .font(Redroom.figure(40, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .contentTransition(.numericText())

                RedroomNote(text: "Three times the clearing time is the default. Two times is the common practice in published guides.")
            }

            Button {
                engine.confirmClearing(
                    seconds: TimeInterval(clearingSeconds),
                    multiplier: Double(multiplier)
                )
            } label: {
                Text("Start fixing")
            }
            .buttonStyle(RedroomPrimaryButtonStyle())

            Button {
                engine.useStandardFix(seconds: Preferences.shared.fixSeconds)
            } label: {
                Text("Fix for \(Clock.mmss(Preferences.shared.fixSeconds)) instead")
            }
            .buttonStyle(RedroomSecondaryButtonStyle())

            RedroomNote(text: "Your default fix time from Settings, for when you would rather not time the leader.")
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
    }
}
