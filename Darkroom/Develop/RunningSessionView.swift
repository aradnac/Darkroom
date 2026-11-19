//
//  RunningSessionView.swift
//  Darkroom
//
//  The full-screen session: the stage ring, the big GO, the next-action card with the
//  moving liquid, the controls and the stage strip. Tapping anywhere starts a stage
//  that is waiting for GO.
//

import SwiftUI
import UIKit

struct RunningSessionView: View {
    let engine: SessionEngine
    let onClose: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var confirmingEnd = false

    var body: some View {
        ZStack {
            LiquidBackdrop(tint: Theme.amber, intensity: engine.phase == .running ? 1 : 0.6)

            VStack(spacing: 0) {
                topBar
                header
                if let answer = engine.answer {
                    answerCard(answer)
                }
                voiceLine
                Spacer(minLength: 8)
                timerDial
                Spacer(minLength: 12)
                nextCard
                controls
                stageStrip
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            engine.goTapped()
        }
        .sheet(isPresented: clearingBinding) {
            ClearingSheet(engine: engine)
        }
        .sheet(isPresented: finishedBinding) {
            SessionSummaryView(plan: engine.plan, onDone: onClose)
        }
        .confirmationDialog("End this session?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End session", role: .destructive) {
                onClose()
            }
            Button("Keep going", role: .cancel) {}
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
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
        Binding(
            get: { engine.phase == .clearing },
            set: { _ in }
        )
    }

    private var finishedBinding: Binding<Bool> {
        Binding(
            get: { engine.phase == .finished },
            set: { _ in }
        )
    }

    // MARK: - Top bar and header

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.amber)
                    .frame(width: 8, height: 8)
                Text(engine.currentStage.kind.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .glassCard(radius: 99)

            Spacer(minLength: 0)

            Text(String(format: "%.1f °C", engine.plan.temperature))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .glassCard(radius: 99)

            Button {
                if engine.phase == .finished {
                    onClose()
                } else {
                    confirmingEnd = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(engine.plan.film.fullName.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(3)
                .foregroundStyle(Theme.inkSoft)
            Text("\(engine.plan.developer.name) \(engine.plan.dilution.label)")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.top, 12)
    }

    private func answerCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.amber)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 18, tint: Theme.amber)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var voiceLine: some View {
        if engine.plan.voiceCommands {
            HStack(spacing: 6) {
                Image(systemName: engine.voice.isListening ? "mic.fill" : "mic.slash")
                    .font(.system(size: 10, weight: .semibold))
                Text(engine.voice.statusLine)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(engine.voice.isListening ? Theme.amber : Theme.inkFaint)
            .padding(.top, 8)
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Dial

    private var timerDial: some View {
        ZStack {
            StageRing(
                stages: engine.plan.stages,
                current: engine.stageIndex,
                progress: stageProgress,
                diameter: 240,
                lineWidth: 16
            )

            VStack(spacing: 4) {
                Text(dialCaption)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(Theme.inkFaint)
                Text(dialTime)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.amber)
                    .contentTransition(.numericText(countsDown: true))
                Text("OF \(durationText(engine.currentStage))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .tracking(2)
                    .foregroundStyle(Theme.inkFaint)
            }
            .opacity(engine.phase == .ready ? 0 : 1)

            if engine.phase == .ready {
                goButton
            }
        }
        .frame(width: 240, height: 240)
    }

    /// The hands-free start: one large target when the chemistry is in your hands.
    private var goButton: some View {
        Button {
            engine.goTapped()
        } label: {
            VStack(spacing: 2) {
                Text("GO")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.amberInk)
                Text(engine.currentStage.kind.title.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(Theme.amberInk.opacity(0.7))
            }
            .frame(width: 142, height: 142)
            .background {
                Circle().fill(Theme.amberGradient)
            }
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Theme.amber.opacity(0.45), radius: 30, x: 0, y: 0)
        }
        .buttonStyle(HapticButtonStyle())
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

    /// How far through the current stage we are, for the dial's amber fill.
    private var stageProgress: Double {
        let duration = engine.currentStage.duration
        guard duration > 0 else { return 0 }
        return min(1, max(0, engine.stageElapsed / duration))
    }

    // MARK: - Next action

    private var nextCard: some View {
        HStack(alignment: .center, spacing: 14) {
            AgitationLiquid(
                kind: isTiming ? engine.currentPrompt.kind : nil,
                width: 52,
                height: 72
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(cardHeadline)
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.amber)
                Text(cardBody)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.ink.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(cardCountdown)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.amber)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(16)
        .glassCard(radius: 26)
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

    /// Shown only when this stage was given a target of its own.
    private var stageTemperatureNote: String {
        guard let target = engine.currentStage.targetTemperature,
              abs(target - engine.plan.temperature) > 0.05 else { return "" }
        return String(format: " Target %.1f °C.", target)
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

    // MARK: - Controls

    private var controlsLocked: Bool {
        engine.phase == .clearing || engine.phase == .finished
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    primaryAction()
                } label: {
                    Label(primaryTitle, systemImage: primaryIcon)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.amber)
                .controlSize(.large)
                .disabled(controlsLocked)

                Button {
                    engine.skipStage()
                } label: {
                    Label("Skip stage", systemImage: "forward.end.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .disabled(controlsLocked)
            }

            HStack(spacing: 10) {
                Button("+30 s") {
                    engine.addTime(30)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(controlsLocked)

                Button("+1 min") {
                    engine.addTime(60)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(controlsLocked)
            }
        }
        .padding(.top, 12)
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

    private var primaryIcon: String {
        switch engine.phase {
        case .ready, .paused: return "play.fill"
        case .running, .clearing, .finished: return "pause.fill"
        }
    }

    // MARK: - Stage strip

    private var stageStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(engine.plan.stages.enumerated()), id: \.element.id) { index, stage in
                    stageChip(stage, index: index)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
        .padding(.top, 12)
    }

    private func stageChip(_ stage: SessionStage, index: Int) -> some View {
        let finished = engine.phase == .finished
        let done = finished || index < engine.stageIndex
        let current = !finished && index == engine.stageIndex

        return VStack(spacing: 5) {
            Image(systemName: done ? "checkmark.circle.fill" : (current ? "circle.inset.filled" : "circle"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(done || current ? Theme.amber : Theme.inkFaint)

            Text(stage.kind.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(durationText(stage))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .frame(width: 84)
        .padding(.vertical, 9)
        .glassCard(radius: 16, tint: current ? Theme.amber : nil)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(current ? Theme.amber.opacity(0.7) : Color.clear, lineWidth: 1)
        }
        .opacity(done ? 0.5 : 1)
    }

    private func durationText(_ stage: SessionStage) -> String {
        stage.needsClearing ? "--:--" : Clock.mmss(stage.duration)
    }
}
