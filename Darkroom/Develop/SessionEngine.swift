//
//  SessionEngine.swift
//  Darkroom
//
//  Runs a plan: stage timing, the agitation choreography, spoken prompts, the
//  microphone, and the hand-off to the film-leader clearing step before the fixer.
//  Elapsed time is measured from dates, so a session stays accurate while the screen
//  sleeps.
//

import Foundation
import Observation

@MainActor
@Observable
final class SessionEngine {
    enum Phase: Equatable {
        /// Waiting for the tap-anywhere GO.
        case ready
        case running
        case paused
        /// Waiting for the film-leader clearing time before the fixer starts.
        case clearing
        case finished
    }

    private(set) var plan: SessionPlan
    private(set) var stageIndex = 0
    private(set) var phase: Phase = .ready
    private(set) var now = Date()
    /// A spoken question that has been answered, shown for a few seconds.
    private(set) var answer: String?

    let voice = VoiceCommander()
    let speaker = PromptSpeaker()

    @ObservationIgnored private var accumulated: TimeInterval = 0
    @ObservationIgnored private var runStartedAt: Date?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastPromptKey: String?
    @ObservationIgnored private var answerTimer: Timer?

    init(plan: SessionPlan) {
        self.plan = plan
        voice.onCommand = { [weak self] command in
            self?.handle(command)
        }
        speaker.onSpeakingChanged = { [weak self] speaking in
            self?.voice.setSuppressed(speaking)
        }
    }

    // MARK: - Values the views read

    var stageCount: Int { plan.stages.count }

    var currentStage: SessionStage { plan.stages[stageIndex] }

    /// Seconds spent in the current stage, not counting paused time.
    var stageElapsed: TimeInterval {
        var value = accumulated
        if let start = runStartedAt {
            value += now.timeIntervalSince(start)
        }
        return value
    }

    var stageRemaining: TimeInterval {
        max(0, currentStage.duration - stageElapsed)
    }

    var currentPrompt: SessionPrompt {
        currentStage.prompt(at: min(stageElapsed, currentStage.duration))
    }

    // MARK: - Lifecycle

    func activateVoice() {
        guard plan.voiceCommands else { return }
        if case .unavailable = voice.status { return }
        voice.start()
    }

    func stop() {
        stopTimer()
        voice.stop()
        speaker.stop()
        AgitationAlerts.cancel()
    }

    // MARK: - Commands

    func goTapped() {
        guard phase == .ready else { return }
        begin()
    }

    func togglePause() {
        switch phase {
        case .running:
            now = Date()
            accumulated = stageElapsed
            runStartedAt = nil
            stopTimer()
            phase = .paused
            AgitationAlerts.cancel()
        case .paused:
            now = Date()
            runStartedAt = now
            phase = .running
            startTimer()
            refreshAlerts()
        case .ready, .clearing, .finished:
            break
        }
    }

    func skipStage() {
        switch phase {
        case .ready, .running, .paused:
            if stageIndex + 1 < stageCount {
                advance()
            } else {
                finish()
            }
        case .clearing, .finished:
            break
        }
    }

    func addTime(_ seconds: TimeInterval) {
        switch phase {
        case .ready, .running, .paused:
            plan.stages[stageIndex].duration = max(0, plan.stages[stageIndex].duration + seconds)
            Haptics.impact(.light)
            refreshAlerts()
        case .clearing, .finished:
            break
        }
    }

    /// Sets the fixer time from the film leader's clearing time.
    func confirmClearing(seconds: TimeInterval, multiplier: Double) {
        guard phase == .clearing else { return }
        plan.stages[stageIndex].duration = seconds * multiplier
        plan.stages[stageIndex].needsClearing = false
        phase = .ready
    }

    /// Called when the app comes back to the foreground, so a stage that ended in
    /// the background completes at once.
    func refresh() {
        guard phase == .running else { return }
        tick()
    }

    // MARK: - Timing

    private func begin() {
        now = Date()
        accumulated = 0
        runStartedAt = now
        lastPromptKey = nil
        phase = .running
        if currentStage.segments.isEmpty {
            FeedbackCenter.shared.play(.settle)
        }
        Haptics.impact(.medium)
        startTimer()
        tick()
    }

    private func tick() {
        now = Date()
        guard phase == .running else { return }

        if stageElapsed >= currentStage.duration {
            completeStage()
        } else {
            announcePromptIfChanged()
        }
    }

    private func completeStage() {
        if stageIndex + 1 >= stageCount {
            finish()
        } else {
            FeedbackCenter.shared.play(.stageComplete)
            Haptics.success()
            advance()
        }
    }

    private func advance() {
        stageIndex += 1
        accumulated = 0
        runStartedAt = nil
        lastPromptKey = nil
        now = Date()
        stopTimer()
        AgitationAlerts.cancel()
        phase = currentStage.needsClearing ? .clearing : .ready
    }

    private func finish() {
        accumulated = 0
        runStartedAt = nil
        stopTimer()
        AgitationAlerts.cancel()
        phase = .finished
        FeedbackCenter.shared.play(.finished)
        Haptics.success()
    }

    /// The choreography: each change of prompt sounds, is spoken if asked for, and
    /// re-times the notifications for what is coming.
    private func announcePromptIfChanged() {
        let prompt = currentPrompt
        let key = "\(stageIndex)-\(prompt.segmentIndex)"
        guard key != lastPromptKey else { return }
        lastPromptKey = key

        guard let kind = prompt.kind else {
            refreshAlerts()
            return
        }

        kind.announce()
        if plan.spokenPrompts {
            speaker.say(prompt.title)
        }
        refreshAlerts()
    }

    private func refreshAlerts() {
        guard phase == .running else {
            AgitationAlerts.cancel()
            return
        }

        let elapsed = stageElapsed
        let inversion = plan.intensity.inversionSeconds
        var upcoming: [(title: String, detail: String, seconds: TimeInterval)] = []

        for segment in currentStage.segments where segment.start > elapsed + 1 {
            guard upcoming.count < 30 else { break }
            upcoming.append((
                title: segment.kind.title,
                detail: segment.kind.detail(inversionSeconds: inversion),
                seconds: segment.start - elapsed
            ))
        }

        AgitationAlerts.schedule(upcoming)
    }

    // MARK: - Voice

    private func handle(_ command: VoiceCommand) {
        switch command {
        case .go:
            if phase == .ready {
                begin()
                showAnswer("Started \(currentStage.kind.title).")
            } else {
                showAnswer("The timer is already \(phase == .paused ? "paused" : "running").")
            }

        case .addSeconds(let seconds):
            guard phase == .running || phase == .paused || phase == .ready else { return }
            addTime(seconds)
            showAnswer("Added \(Int(seconds)) seconds. \(Clock.mmssCeil(stageRemaining)) left.")

        case .nextStage:
            guard phase != .clearing, phase != .finished else { return }
            if stageIndex + 1 < stageCount {
                advance()
                showAnswer("Next: \(currentStage.kind.title).")
            } else {
                finish()
            }

        case .startFixer:
            startFixer()

        case .rollCount:
            showAnswer(rollCountAnswer())
        }
    }

    private func startFixer() {
        let target = stageIndex
        guard let fixIndex = plan.stages.firstIndex(where: { $0.kind == .fix }) else { return }

        if fixIndex < target || (fixIndex == target && phase == .running) {
            showAnswer("The fixer is already done.")
            return
        }
        if fixIndex == target, phase == .ready {
            begin()
            showAnswer("Fixing.")
            return
        }

        jump(to: fixIndex)
        showAnswer("Fixer. \(currentStage.needsClearing ? "Time the leader first." : "Tap go to start.")")
    }

    private func jump(to index: Int) {
        guard index >= 0, index < stageCount, phase != .finished else { return }
        stageIndex = index
        accumulated = 0
        runStartedAt = nil
        lastPromptKey = nil
        now = Date()
        stopTimer()
        AgitationAlerts.cancel()
        phase = currentStage.needsClearing ? .clearing : .ready
    }

    private func rollCountAnswer() -> String {
        let bottles = ChemistryStore.shared.batches.filter {
            $0.developer.localizedCaseInsensitiveContains(plan.developer.name)
        }
        guard !bottles.isEmpty else {
            return "No bottle of \(plan.developer.name) is in the cupboard yet."
        }
        let rolls = bottles.reduce(0) { $0 + $1.rollsDeveloped }
        let uses = bottles.reduce(0) { $0 + $1.useCount }
        return "\(plan.developer.name): \(rolls) \(rolls == 1 ? "roll" : "rolls") in \(uses) \(uses == 1 ? "use" : "uses"), across \(bottles.count) \(bottles.count == 1 ? "bottle" : "bottles")."
    }

    private func showAnswer(_ text: String) {
        answer = text
        answerTimer?.invalidate()
        answerTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.answer = nil
            }
        }
    }

    // MARK: - Timers

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

private extension AgitationKind {
    /// The sound and haptic that mark this prompt.
    func announce() {
        switch self {
        case .initial, .invert, .continuous:
            FeedbackCenter.shared.play(.agitate)
            Haptics.impact(.heavy)
        case .tap:
            FeedbackCenter.shared.play(.settle)
            Haptics.impact(.medium)
        case .rest:
            FeedbackCenter.shared.play(.settle)
            Haptics.impact(.light)
        }
    }
}
