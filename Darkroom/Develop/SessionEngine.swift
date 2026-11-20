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
    /// The journal entry this session wrote when it finished, so the summary can
    /// edit the same record and "Discard" can take it away.
    private(set) var journalRecordID: UUID?
    /// A spoken question that has been answered, shown for a few seconds.
    private(set) var answer: String?

    let voice = VoiceCommander()
    let speaker = PromptSpeaker()

    /// The exact instant of the last tick. Deliberately not observed: the
    /// engine's own boundary checks need a tenth of a second of resolution, but
    /// nothing on screen changes that often, so publishing it would make every
    /// view that reads the clock re-evaluate its body ten times a second.
    @ObservationIgnored private var preciseNow = Date()

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

    /// Seconds spent in the current stage, not counting paused time, as the
    /// display is currently showing it.
    var stageElapsed: TimeInterval {
        elapsed(at: now)
    }

    var stageRemaining: TimeInterval {
        max(0, currentStage.duration - stageElapsed)
    }

    var currentPrompt: SessionPrompt {
        prompt(at: now)
    }

    private func elapsed(at date: Date) -> TimeInterval {
        var value = accumulated
        if let start = runStartedAt {
            value += date.timeIntervalSince(start)
        }
        return value
    }

    private func prompt(at date: Date) -> SessionPrompt {
        currentStage.prompt(at: min(elapsed(at: date), currentStage.duration))
    }

    /// The readings the running screen draws from the clock: the stage
    /// countdown, the current agitation phase's countdown, and which phase it is.
    /// When none of them changes, nothing on screen can change either.
    private struct ShownClock: Equatable {
        let stageSeconds: Int
        let promptSeconds: Int
        let segment: Int
    }

    private func shownClock(at date: Date) -> ShownClock {
        let elapsedNow = elapsed(at: date)
        let stageElapsed = min(elapsedNow, currentStage.duration)
        let remaining = max(0, currentStage.duration - elapsedNow)
        let prompt = currentStage.prompt(at: stageElapsed)

        // Matches `Clock.mmssCeil`, which is what every countdown on the running
        // screen is set in.
        return ShownClock(
            stageSeconds: Int(ceil(remaining - 0.001)),
            promptSeconds: Int(ceil(prompt.remaining - 0.001)),
            segment: prompt.segmentIndex
        )
    }

    // MARK: - Lifecycle

    /// Opens the microphone, or reopens it if an earlier attempt failed. Safe to
    /// call repeatedly: the commander ignores a start while it is already
    /// listening, and a denied permission is reported rather than prompted again.
    func activateVoice() {
        guard plan.voiceCommands else { return }
        voice.start()
    }

    /// Called when the app returns to the foreground: a route change or a call
    /// can leave the recogniser closed, and the reader should not have to leave
    /// the session to get it back.
    func recheckVoice() {
        guard plan.voiceCommands else { return }
        switch voice.status {
        case .off, .starting:
            voice.start()
        case .listening:
            break
        case .unavailable:
            voice.restart()
        }
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
            preciseNow = now
            accumulated = stageElapsed
            runStartedAt = nil
            stopTimer()
            phase = .paused
            AgitationAlerts.cancel()
        case .paused:
            now = Date()
            preciseNow = now
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
            plan.stages[stageIndex].addTime(seconds)
            Haptics.impact(.light)
            refreshAlerts()
        case .clearing, .finished:
            break
        }
    }

    /// Sets the fixer time from the film leader's clearing time.
    func confirmClearing(seconds: TimeInterval, multiplier: Double) {
        guard phase == .clearing else { return }
        plan.stages[stageIndex].setDuration(seconds * multiplier)
        plan.stages[stageIndex].needsClearing = false
        phase = .ready
    }

    /// Sets the fixer time directly, for when the leader is not being timed.
    func useStandardFix(seconds: TimeInterval) {
        guard phase == .clearing else { return }
        plan.stages[stageIndex].setDuration(max(30, seconds))
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
        preciseNow = now
        accumulated = 0
        runStartedAt = now
        lastPromptKey = nil
        phase = .running
        if currentStage.segments.isEmpty {
            Preferences.shared.play(.rest)
        }
        Haptics.impact(.medium)
        startTimer()
        tick()
    }

    private func tick() {
        let instant = Date()
        preciseNow = instant
        guard phase == .running else { return }

        let precise = prompt(at: instant)

        // Publishing `now` ten times a second makes every view that reads the
        // clock re-evaluate its body ten times a second, for a display that
        // moves once. Publish only when a reading the screen actually draws
        // changes, which is roughly once a second — and at a prompt boundary, so
        // the on-screen prompt is never a beat behind the chime that marks it.
        if shownClock(at: instant) != shownClock(at: now) {
            now = instant
        }

        if elapsed(at: instant) >= currentStage.duration {
            completeStage()
        } else {
            announcePromptIfChanged(precise)
        }
    }

    private func completeStage() {
        if stageIndex + 1 >= stageCount {
            finish()
        } else {
            Preferences.shared.play(.stageComplete)
            advance()
        }
    }

    private func advance() {
        stageIndex += 1
        accumulated = 0
        runStartedAt = nil
        lastPromptKey = nil
        now = Date()
        preciseNow = now
        stopTimer()
        AgitationAlerts.cancel()
        phase = currentStage.needsClearing ? .clearing : .ready
    }

    private func finish() {
        accumulated = 0
        runStartedAt = nil
        stopTimer()
        AgitationAlerts.cancel()
        // Written before the phase changes, so the summary's sheet can never
        // appear before its record exists.
        if journalRecordID == nil {
            journalRecordID = JournalStore.shared.log(plan)
        }
        phase = .finished
        Preferences.shared.play(.finished)
    }

    /// The choreography: each change of prompt sounds, is spoken if asked for, and
    /// re-times the notifications for what is coming.
    private func announcePromptIfChanged(_ prompt: SessionPrompt) {
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

        // The exact instant, not the published one: scheduling the next prompts
        // from a reading up to a second old would fire them up to a second late.
        let elapsedNow = elapsed(at: preciseNow)
        let inversion = plan.intensity.inversionSeconds
        var upcoming: [(title: String, detail: String, seconds: TimeInterval)] = []

        for segment in currentStage.segments where segment.start > elapsedNow + 1 {
            guard upcoming.count < 30 else { break }
            upcoming.append((
                title: segment.kind.title,
                detail: segment.kind.detail(inversionSeconds: inversion),
                seconds: segment.start - elapsedNow
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
        preciseNow = now
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
    /// The sound and haptic that mark this prompt, as Settings sets them.
    func announce() {
        switch self {
        case .initial, .invert, .continuous:
            Preferences.shared.play(.agitate)
        case .tap:
            Preferences.shared.play(.tap)
        case .rest:
            Preferences.shared.play(.rest)
        }
    }
}
