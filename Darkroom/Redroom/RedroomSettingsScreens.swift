//
//  RedroomSettingsScreens.swift
//  Darkroom
//
//  The room's settings. The safelight intensity is the room's own control; units,
//  development defaults and alerts are the same preferences every other language
//  edits, drawn on the room's panels with the room's steppers and switches.
//

import SwiftUI

// MARK: - Hub

struct RedroomSettingsView: View {
    @ObservedObject private var store = Theme13SettingsStore.shared
    @ObservedObject private var preferences = Preferences.shared

    @AppStorage("redroom.intensity") private var intensityRaw = RedroomIntensity.normal.rawValue

    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false
    @State private var showingLightingTest = false

    private var developmentDetail: String {
        "\(preferences.agitationScheme.title) · \(preferences.temperatureScale.title) readings"
    }

    var body: some View {
        NavigationStack {
            RedroomScreen {
                RedroomScreenHeader(
                    kicker: "The room",
                    title: "Settings",
                    actionSymbol: "xmark",
                    actionLabel: "Close settings",
                    action: { dismiss() }
                )
                .redroomReveal(.safelightFade)

                safelightPanel

                languagePanel

                RedroomSectionHeader(title: "Preferences")

                NavigationLink {
                    RedroomUnitsSettings()
                } label: {
                    RedroomNavRow(
                        title: "Units",
                        detail: "\(preferences.temperatureScale.title) · \(preferences.volumeUnit.title)",
                        symbol: "ruler"
                    )
                }
                .buttonStyle(HapticButtonStyle())

                NavigationLink {
                    RedroomDevelopmentDefaults()
                } label: {
                    RedroomNavRow(
                        title: "Development defaults",
                        detail: developmentDetail,
                        symbol: "slider.horizontal.3"
                    )
                }
                .buttonStyle(HapticButtonStyle())

                NavigationLink {
                    RedroomAlertSettings()
                } label: {
                    RedroomNavRow(
                        title: "Alerts",
                        detail: "Sound and haptic for each prompt",
                        symbol: "bell.badge"
                    )
                }
                .buttonStyle(HapticButtonStyle())

                #if DEBUG
                NavigationLink {
                    RedroomLightingTest()
                } label: {
                    RedroomNavRow(
                        title: "Lighting test",
                        detail: "Debug only: every surface, every intensity",
                        symbol: "light.max"
                    )
                }
                .buttonStyle(HapticButtonStyle())
                #endif

                Button {
                    confirmingReset = true
                } label: {
                    RedroomNavRow(
                        title: "Reset preferences",
                        detail: "Units, defaults, alerts and the design language",
                        symbol: "arrow.counterclockwise"
                    )
                }
                .buttonStyle(HapticButtonStyle())

                RedroomNote(text: "REDROOM keeps the app's own data: the library, the bottles, the sessions and every preference above. Only the drawing changes.")
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Redroom.background)
            .confirmationDialog(
                "Reset every preference?",
                isPresented: $confirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.resetPreferences()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Units, development defaults, alerts, appearance, accent and the chosen design language return to their defaults.")
            }
        }
        .redroomSheet()
    }

    // MARK: Safelight

    private var safelightPanel: some View {
        RedroomPanel(
            title: "Safelight",
            detail: "Scales the glow, the reflections and the highlights. Type colour never changes, so every reading keeps its contrast in every room.",
            variant: .optical
        ) {
            ForEach(RedroomIntensity.allCases) { level in
                Button {
                    Haptics.impact(.light)
                    withAnimation(.easeOut(duration: 0.35)) {
                        intensityRaw = level.rawValue
                    }
                } label: {
                    HStack(spacing: 10) {
                        RedroomIndicator(on: level == intensity, size: 7)

                        Text(level.title)
                            .font(Redroom.body(14, weight: .medium))
                            .foregroundStyle(Redroom.text)

                        Spacer(minLength: 6)

                        Text(String(format: "×%.2f", level.lightFactor))
                            .font(Redroom.figure(12, weight: .medium))
                            .foregroundStyle(Redroom.textMuted)

                        if level == intensity {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Redroom.text)
                        }
                    }
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityAddTraits(level == intensity ? .isSelected : [])
            }
        }
    }

    private var intensity: RedroomIntensity {
        RedroomIntensity(rawValue: intensityRaw) ?? .normal
    }

    // MARK: Language

    private var languagePanel: some View {
        RedroomPanel(title: "Design language", detail: "The app's other languages keep their own data and settings; only the room changes.") {
            Text("REDROOM")
                .font(Redroom.display(17, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Redroom.text)

            RedroomNote(text: "One safelight at the top of the room, and every surface answers it.", symbol: "light.max")

            RedroomLitRule(thickness: 0.5)

            Button {
                store.selectTheme("darkroom")
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Redroom.textMuted)
                    Text("Return to the darkroom language")
                        .font(Redroom.body(13, weight: .medium))
                        .foregroundStyle(Redroom.text)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Redroom.textMuted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(HapticButtonStyle())
        }
    }
}

// MARK: - Units

struct RedroomUnitsSettings: View {
    @ObservedObject private var preferences = Preferences.shared

    var body: some View {
        RedroomScreen {
            RedroomSectionHeader(title: "Units")

            RedroomNote(text: "What every working reading and quantity is shown in. Published figures stay as their source gives them, and times are never converted.")

            RedroomPanel(title: "Temperature", detail: "Published times stay as their source gives them; the readings around them follow this choice.") {
                RedroomSegmented(
                    items: TemperatureScale.allCases,
                    selection: Binding(
                        get: { preferences.temperatureScale },
                        set: { preferences.setTemperatureScale($0) }
                    ),
                    title: { $0.title }
                )

                RedroomNote(text: "The working range reads \(Units.shortTemperature(18)) to \(Units.shortTemperature(24)).")
            }

            RedroomPanel(title: "Volumes", detail: "Chemical volumes, tank pours and every calculator.") {
                RedroomSegmented(
                    items: VolumeUnit.allCases,
                    selection: Binding(
                        get: { preferences.volumeUnit },
                        set: { preferences.setVolumeUnit($0) }
                    ),
                    title: { $0.title }
                )

                RedroomNote(text: "A 500 ml tank reads \(Units.volume(millilitres: 500)).")
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Settings", title: "Units")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Development defaults

struct RedroomDevelopmentDefaults: View {
    @ObservedObject private var preferences = Preferences.shared

    private var stepPercent: Int {
        Int((preferences.reuseStep * 100).rounded())
    }

    private var thirdUsePercent: Int {
        Int(((pow(1 + preferences.reuseStep, 2) - 1) * 100).rounded())
    }

    var body: some View {
        RedroomScreen {
            RedroomSectionHeader(title: "Development")
            RedroomNote(text: "What a new session starts from, and how the app works out a number it does not hold.")

            RedroomPanel(title: "Agitation", detail: "The pattern for the developer stage. The stop and the fixer keep the agitation their own instructions give.") {
                RedroomSegmented(
                    items: AgitationScheme.allCases,
                    selection: Binding(
                        get: { preferences.agitationScheme },
                        set: { preferences.setAgitationScheme($0) }
                    ),
                    title: { $0.title }
                )

                RedroomNote(text: preferences.agitationScheme.blurb)

                RedroomLitRule(thickness: 0.5)

                RedroomSegmented(
                    items: AgitationIntensity.allCases,
                    selection: Binding(
                        get: { preferences.agitationIntensity },
                        set: { preferences.setAgitationIntensity($0) }
                    ),
                    title: { $0.label }
                )

                RedroomNote(text: "\(preferences.agitationIntensity.blurb) Inversions last \(Int(preferences.agitationIntensity.inversionSeconds)) s.")
            }

            RedroomPanel(title: "Reuse penalty", detail: "Each prior use of a reusable developer compounds this much extra time, so the third use carries more than twice the first step.") {
                RedroomStepper(
                    title: "Per prior use",
                    value: "\(stepPercent) %",
                    decrement: stepPercent > 5 ? { preferences.setReuseStep(Double(stepPercent - 1) / 100) } : nil,
                    increment: stepPercent < 25 ? { preferences.setReuseStep(Double(stepPercent + 1) / 100) } : nil
                )

                RedroomNote(text: "A third use is +\(thirdUsePercent)% on the base time — \(stepPercent)% compounded twice.")
            }

            RedroomPanel(title: "Outside the published range", detail: "Past the outermost published time the app continues the slope between the nearest two times. This scales that slope.") {
                RedroomStepper(
                    title: "Factor",
                    value: String(format: "×%.2f", preferences.extrapolationFactor),
                    decrement: preferences.extrapolationFactor > Preferences.extrapolationRange.lowerBound
                        ? { preferences.setExtrapolationFactor(preferences.extrapolationFactor - 0.05) } : nil,
                    increment: preferences.extrapolationFactor < Preferences.extrapolationRange.upperBound
                        ? { preferences.setExtrapolationFactor(preferences.extrapolationFactor + 0.05) } : nil
                )

                RedroomNote(text: "×1.00 keeps the published slope. Below softens the change for each degree beyond the range; above steepens it.")
            }

            RedroomPanel(title: "Stage times", detail: "What a new session begins with. The fixer is still set by your leader's clearing time unless you take the default.") {
                RedroomStepper(
                    title: "Stop bath",
                    value: "\(Int(preferences.stopSeconds)) s",
                    decrement: preferences.stopSeconds > Preferences.stopRange.lowerBound
                        ? { preferences.setStopSeconds(preferences.stopSeconds - 5) } : nil,
                    increment: preferences.stopSeconds < Preferences.stopRange.upperBound
                        ? { preferences.setStopSeconds(preferences.stopSeconds + 5) } : nil
                )

                RedroomStepper(
                    title: "Default fix",
                    value: Clock.mmss(preferences.fixSeconds),
                    decrement: preferences.fixSeconds > Preferences.fixRange.lowerBound
                        ? { preferences.setFixSeconds(preferences.fixSeconds - 30) } : nil,
                    increment: preferences.fixSeconds < Preferences.fixRange.upperBound
                        ? { preferences.setFixSeconds(preferences.fixSeconds + 30) } : nil
                )

                RedroomStepper(
                    title: "Wash",
                    value: Clock.mmss(preferences.washSeconds),
                    decrement: preferences.washSeconds > Preferences.washRange.lowerBound
                        ? { preferences.setWashSeconds(preferences.washSeconds - 30) } : nil,
                    increment: preferences.washSeconds < Preferences.washRange.upperBound
                        ? { preferences.setWashSeconds(preferences.washSeconds + 30) } : nil
                )

                RedroomStepper(
                    title: "Final rinse",
                    value: Clock.mmss(preferences.finalRinseSeconds),
                    decrement: preferences.finalRinseSeconds > Preferences.rinseRange.lowerBound
                        ? { preferences.setFinalRinseSeconds(preferences.finalRinseSeconds - 15) } : nil,
                    increment: preferences.finalRinseSeconds < Preferences.rinseRange.upperBound
                        ? { preferences.setFinalRinseSeconds(preferences.finalRinseSeconds + 15) } : nil
                )
            }

            RedroomPanel(title: "Session") {
                Toggle(isOn: Binding(
                    get: { preferences.spokenPrompts },
                    set: { preferences.setSpokenPrompts($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speak each prompt")
                            .font(Redroom.body(14, weight: .medium))
                            .foregroundStyle(Redroom.text)
                        Text("A new session starts with the voice on. You can still turn it off in setup.")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(RedroomToggleStyle())

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
                            .font(Redroom.body(14, weight: .medium))
                            .foregroundStyle(Redroom.text)
                        Text("The running screen listens for go, next stage and add thirty seconds. iOS asks for the microphone the first time this is on.")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(RedroomToggleStyle())

                Toggle(isOn: Binding(
                    get: { preferences.keepAwake },
                    set: { preferences.setKeepAwake($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keep the screen awake")
                            .font(Redroom.body(14, weight: .medium))
                            .foregroundStyle(Redroom.text)
                        Text("The running screen stays lit for the whole session.")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(RedroomToggleStyle())
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Settings", title: "Development")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Alerts

struct RedroomAlertSettings: View {
    @ObservedObject private var preferences = Preferences.shared

    var body: some View {
        RedroomScreen {
            RedroomSectionHeader(title: "Alerts")
            RedroomNote(text: "Every prompt gets a sound and a haptic of its own. Notifications still post at each agitation, whatever is chosen here.")

            ForEach(FeedbackEvent.allCases) { event in
                eventPanel(event)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Settings", title: "Alerts")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func eventPanel(_ event: FeedbackEvent) -> some View {
        RedroomPanel {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(Redroom.body(14, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                    Text(event.detail)
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)

                Button {
                    preferences.play(event)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Redroom.text)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Try \(event.title)")
            }

            Text("Sound")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)

            RedroomSegmented(
                items: FeedbackSound.allCases,
                selection: Binding(
                    get: { preferences.sound(for: event) },
                    set: { preferences.setSound($0, for: event) }
                ),
                title: { $0.title }
            )

            Text("Haptic")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)

            RedroomSegmented(
                items: FeedbackHaptic.allCases,
                selection: Binding(
                    get: { preferences.haptic(for: event) },
                    set: { preferences.setHaptic($0, for: event) }
                ),
                title: { $0.title }
            )
        }
    }
}
