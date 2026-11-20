//
//  SettingsScreens.swift
//  Darkroom
//
//  The Settings subscreens and the pieces they share: a numbered hub row, a paper
//  card that becomes a glass panel in the other languages, and the four screens
//  behind units, development defaults, alerts and appearance.
//

import SwiftUI

// MARK: - Shared pieces

/// A settings screen's frame: the overline, the headline, the blurb, then cards.
struct SettingsScreen<Content: View>: View {
    let index: String
    let title: String
    let blurb: String
    private let content: Content

    init(index: String, title: String, blurb: String, @ViewBuilder content: () -> Content) {
        self.index = index
        self.title = title
        self.blurb = blurb
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    OverlineText(text: "Bench preferences · \(index)", color: Theme.amber)
                    Text(title)
                        .font(Theme13Type.headline(27))
                        .foregroundStyle(Theme.ink)
                    Text(blurb)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)

                content
            }
            .padding(20)
            .padding(.bottom, 28)
        }
        .background { LiquidBackdrop() }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The card every setting sits in: a flat paper plate in the print language, a
/// glass panel in the other two.
struct SettingsCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(Theme13PaperSurface(marked: false))
    }
}

struct SettingsCardHeading: View {
    let title: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            if let detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct SettingsNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkFaint)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A hub row: the numbered colophon line that opens a screen.
struct SettingsHubRow<Destination: View>: View {
    let index: String
    let title: String
    let detail: String
    let systemImage: String
    private let destination: Destination

    init(
        index: String,
        title: String,
        detail: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) {
        self.index = index
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 14) {
                Text(index)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.amber)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .modifier(Theme13PaperSurface(marked: false))
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(detail)
    }
}

// MARK: - Units

struct UnitsSettingsView: View {
    @ObservedObject private var preferences = Preferences.shared

    var body: some View {
        SettingsScreen(
            index: "03",
            title: "Units",
            blurb: "What every working reading and quantity is shown in. Published figures stay as their source gives them, and times are never converted."
        ) {
            SettingsCard {
                SettingsCardHeading(
                    title: "Temperature",
                    detail: "Published times stay as their source gives them; the readings around them follow this choice."
                )

                Picker("Temperature", selection: Binding(
                    get: { preferences.temperatureScale },
                    set: { preferences.setTemperatureScale($0) }
                )) {
                    ForEach(TemperatureScale.allCases) { scale in
                        Text(scale.title).tag(scale)
                    }
                }
                .pickerStyle(.segmented)

                SettingsNote(text: "The working range reads \(Units.shortTemperature(18)) to \(Units.shortTemperature(24)).")
            }

            SettingsCard {
                SettingsCardHeading(
                    title: "Volumes",
                    detail: "Chemical volumes, tank pours and every calculator."
                )

                Picker("Volumes", selection: Binding(
                    get: { preferences.volumeUnit },
                    set: { preferences.setVolumeUnit($0) }
                )) {
                    ForEach(VolumeUnit.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                SettingsNote(text: "A 500 ml tank reads \(Units.volume(millilitres: 500)).")
            }
        }
    }
}

// MARK: - Development defaults

struct DevelopmentDefaultsView: View {
    @ObservedObject private var preferences = Preferences.shared

    private var stepPercent: Int {
        Int((preferences.reuseStep * 100).rounded())
    }

    /// What a third use of a developer costs, at the chosen step.
    private var thirdUsePercent: Int {
        Int(((pow(1 + preferences.reuseStep, 2) - 1) * 100).rounded())
    }

    var body: some View {
        SettingsScreen(
            index: "04",
            title: "Development",
            blurb: "What a new session starts from, and how the app works out a number it does not hold."
        ) {
            SettingsCard {
                SettingsCardHeading(
                    title: "Agitation",
                    detail: "The pattern for the developer stage. The stop and the fixer keep the agitation their own instructions give."
                )

                Picker("Agitation", selection: Binding(
                    get: { preferences.agitationScheme },
                    set: { preferences.setAgitationScheme($0) }
                )) {
                    ForEach(AgitationScheme.allCases) { scheme in
                        Text(scheme.title).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)

                SettingsNote(text: preferences.agitationScheme.blurb)

                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)

                Text("Intensity")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.ink)

                Picker("Intensity", selection: Binding(
                    get: { preferences.agitationIntensity },
                    set: { preferences.setAgitationIntensity($0) }
                )) {
                    ForEach(AgitationIntensity.allCases) { intensity in
                        Text(intensity.label).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)

                SettingsNote(text: "\(preferences.agitationIntensity.blurb) Inversions last \(Int(preferences.agitationIntensity.inversionSeconds)) s.")
            }

            SettingsCard {
                SettingsCardHeading(
                    title: "Reuse penalty",
                    detail: "Each prior use of a reusable developer compounds this much extra time, so the third use carries more than twice the first step."
                )

                Stepper(
                    value: Binding(
                        get: { stepPercent },
                        set: { preferences.setReuseStep(Double($0) / 100) }
                    ),
                    in: 5...25
                ) {
                    LabeledContent("Per prior use", value: "\(stepPercent) %")
                }

                SettingsNote(text: "A third use is +\(thirdUsePercent)% on the base time — \(stepPercent)% compounded twice.")
            }

            SettingsCard {
                SettingsCardHeading(
                    title: "Outside the published range",
                    detail: "Past the outermost published time the app continues the slope between the nearest two times. This scales that slope."
                )

                Stepper(
                    value: Binding(
                        get: { preferences.extrapolationFactor },
                        set: { preferences.setExtrapolationFactor($0) }
                    ),
                    in: Preferences.extrapolationRange,
                    step: 0.05
                ) {
                    LabeledContent("Factor", value: String(format: "×%.2f", preferences.extrapolationFactor))
                }

                SettingsNote(text: "×1.00 keeps the published slope. Below softens the change for each degree beyond the range; above steepens it.")
            }

            SettingsCard {
                SettingsCardHeading(
                    title: "Stage times",
                    detail: "What a new session begins with. The fixer is still set by your leader's clearing time unless you take the default."
                )

                Stepper(
                    value: Binding(
                        get: { preferences.stopSeconds },
                        set: { preferences.setStopSeconds($0) }
                    ),
                    in: Preferences.stopRange,
                    step: 5
                ) {
                    LabeledContent("Stop bath", value: "\(Int(preferences.stopSeconds)) s")
                }

                Stepper(
                    value: Binding(
                        get: { preferences.fixSeconds },
                        set: { preferences.setFixSeconds($0) }
                    ),
                    in: Preferences.fixRange,
                    step: 30
                ) {
                    LabeledContent("Default fix", value: Clock.mmss(preferences.fixSeconds))
                }

                Stepper(
                    value: Binding(
                        get: { preferences.washSeconds },
                        set: { preferences.setWashSeconds($0) }
                    ),
                    in: Preferences.washRange,
                    step: 30
                ) {
                    LabeledContent("Wash", value: Clock.mmss(preferences.washSeconds))
                }

                Stepper(
                    value: Binding(
                        get: { preferences.finalRinseSeconds },
                        set: { preferences.setFinalRinseSeconds($0) }
                    ),
                    in: Preferences.rinseRange,
                    step: 15
                ) {
                    LabeledContent("Final rinse", value: Clock.mmss(preferences.finalRinseSeconds))
                }
            }

            SettingsCard {
                SettingsCardHeading(title: "Session")

                Toggle(isOn: Binding(
                    get: { preferences.spokenPrompts },
                    set: { preferences.setSpokenPrompts($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speak each prompt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Text("A new session starts with the voice on. You can still turn it off in setup.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Theme.switchTint)

                Toggle(isOn: Binding(
                    get: { preferences.voiceCommands },
                    set: { value in
                        preferences.setVoiceCommands(value)
                        if value {
                            Task { _ = await VoiceCommander.requestAccess() }
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice commands")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Text("The running screen listens for go, next stage and add thirty seconds. iOS asks for the microphone the first time this is on.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Theme.switchTint)

                Toggle(isOn: Binding(
                    get: { preferences.keepAwake },
                    set: { preferences.setKeepAwake($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keep the screen awake")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Text("The running screen stays lit for the whole session.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Theme.switchTint)
            }
        }
    }
}

// MARK: - Alerts

struct AlertSettingsView: View {
    @ObservedObject private var preferences = Preferences.shared

    var body: some View {
        SettingsScreen(
            index: "05",
            title: "Alerts",
            blurb: "Every prompt gets a sound and a haptic of its own. Notifications still post at each agitation, whatever is chosen here."
        ) {
            ForEach(FeedbackEvent.allCases) { event in
                eventCard(event)
            }
        }
    }

    private func eventCard(_ event: FeedbackEvent) -> some View {
        SettingsCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(event.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    preferences.play(event)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.amber)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Try \(event.title)")
            }

            Picker("Sound", selection: Binding(
                get: { preferences.sound(for: event) },
                set: { preferences.setSound($0, for: event) }
            )) {
                ForEach(FeedbackSound.allCases) { sound in
                    Text(sound.title).tag(sound)
                }
            }

            Picker("Haptic", selection: Binding(
                get: { preferences.haptic(for: event) },
                set: { preferences.setHaptic($0, for: event) }
            )) {
                ForEach(FeedbackHaptic.allCases) { haptic in
                    Text(haptic.title).tag(haptic)
                }
            }
        }
    }
}
