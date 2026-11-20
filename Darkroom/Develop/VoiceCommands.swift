//
//  VoiceCommands.swift
//  Darkroom
//
//  Listening for a handful of short commands, on the device where it can, and
//  turning what was said into something the session can act on.
//
//  Three things make commands actually work at the sink:
//
//    • "go" is acted on from a partial transcript. The recogniser only marks a
//      result final after a pause, and the hands pouring chemistry do not pause,
//      so waiting for `isFinal` meant the one command the screen advertises
//      never fired.
//    • Numbers may be spoken as words — "add thirty seconds", "add a minute",
//      "half a minute" — not only as digits.
//    • Recognition that cannot run on the device falls back to the service once
//      before it gives up, and the microphone reopens after a phone call, a
//      route change or a media-services reset instead of going quiet.
//

import Foundation
import AVFoundation
import Observation
import Speech

enum VoiceCommand: Equatable {
    case go
    case nextStage
    case startFixer
    case addSeconds(TimeInterval)
    case rollCount

    var confirmation: String {
        switch self {
        case .go:
            return "Started."
        case .nextStage:
            return "Next stage."
        case .startFixer:
            return "Fixer."
        case let .addSeconds(seconds):
            return "Added \(Int(seconds)) seconds."
        case .rollCount:
            return ""
        }
    }

    /// Only the few phrases a darkroom needs, matched on whole words.
    static func parse(_ transcript: String, isFinal: Bool) -> VoiceCommand? {
        let cleaned = transcript
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "!", with: " ")
            .replacingOccurrences(of: "?", with: " ")
            .replacingOccurrences(of: "'", with: "")
        let words = cleaned.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return nil }
        let phrase = words.joined(separator: " ")
        let stripped = phrase.trimmingCharacters(in: .whitespaces)

        if phrase.contains("how many rolls") || phrase.contains("how many films") {
            return .rollCount
        }
        if phrase.contains("start fixer") || phrase.contains("start the fixer")
            || phrase.contains("start fixing") || phrase.contains("fixer now") {
            return .startFixer
        }
        if phrase.contains("next stage") || phrase.contains("skip stage")
            || phrase.contains("next step") {
            return .nextStage
        }
        if let added = seconds(in: words) {
            return .addSeconds(added)
        }

        // Bare go and start count as soon as they are heard, not only once the
        // recogniser settles: on a continuous request a final result may not
        // arrive until the microphone closes. The whole utterance, or the last
        // word of a short one, has to be the command itself — so the opening of
        // "start fixer" can never read as "start".
        if isFinal {
            if goPhrases.contains(stripped) {
                return .go
            }
        } else {
            let trailing = words.suffix(2).joined(separator: " ")
            if goPhrases.contains(trailing) {
                return .go
            }
        }

        return nil
    }

    private static let goPhrases: Set<String> = [
        "go", "go now", "ok go", "okay go", "start", "start now", "lets go", "ready"
    ]

    // MARK: Spoken numbers

    private static let numberWords: [String: Double] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
        "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
        "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40,
        "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80,
        "ninety": 90, "half": 0.5
    ]

    private static func seconds(in words: [String]) -> TimeInterval? {
        if let addIndex = words.firstIndex(of: "add"), addIndex + 1 < words.count {
            return seconds(in: words[(addIndex + 1)...])
        }
        // "thirty seconds more" and "another thirty seconds" say the same thing.
        guard words.contains("more") || words.first == "another" else { return nil }
        return seconds(in: words[...])
    }

    private static func seconds(in words: ArraySlice<String>) -> TimeInterval? {
        var amount: Double = 0
        var foundNumber = false
        var unit: String?

        for word in words {
            if let value = Double(word) {
                amount += value
                foundNumber = true
                continue
            }
            if let value = numberWords[word] {
                amount += value
                foundNumber = true
                continue
            }
            if ["second", "seconds", "sec", "secs"].contains(word) {
                unit = "s"
                break
            }
            if ["minute", "minutes", "min", "mins"].contains(word) {
                unit = "m"
                break
            }
            if word == "a" || word == "an" {
                // "a minute" is one; "one and a half minutes" keeps its one.
                if !foundNumber {
                    amount = 1
                    foundNumber = true
                }
                continue
            }
            if word == "and" {
                continue
            }
            // Anything else before the unit — "uh", "please" — is ignored.
        }

        guard let unit, foundNumber else { return nil }
        let total = unit == "m" ? amount * 60 : amount
        guard total > 0, total <= 600 else { return nil }
        return total
    }
}

/// On-device speech recognition, listening for those phrases. It shuts itself down
/// quietly when the device cannot do it at all, and it never listens to its own
/// prompts.
@MainActor
@Observable
final class VoiceCommander {
    enum Status: Equatable {
        case off
        case starting
        case listening
        case unavailable(String)
    }

    private(set) var status: Status = .off
    var onCommand: ((VoiceCommand) -> Void)?

    var isListening: Bool { status == .listening }

    var statusLine: String {
        switch status {
        case .off:
            return "Voice off"
        case .starting:
            return "Opening the microphone…"
        case .listening:
            return "Listening — say “go” when the chemistry is in"
        case let .unavailable(reason):
            return reason
        }
    }

    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var restartTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var running = false
    @ObservationIgnored private var starting = false
    @ObservationIgnored private var suppressed = false
    @ObservationIgnored private var consecutiveFailures = 0
    /// Set when the recogniser is opened: true when this device can work on board.
    @ObservationIgnored private var usingOnDevice = true
    /// The server recogniser is only fallen back to once per listen.
    @ObservationIgnored private var triedServer = false
    /// The last transcript acted on, so a settling partial is heard once.
    @ObservationIgnored private var lastHandledText = ""
    /// Guards against one utterance being heard twice through two callbacks.
    @ObservationIgnored private var lastCommand: VoiceCommand?
    @ObservationIgnored private var lastCommandAt = Date.distantPast
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    // MARK: - Lifecycle

    func start() {
        guard !running, !starting else { return }
        starting = true
        status = .starting
        let version = generation

        Task { [weak self] in
            guard let self else { return }
            let allowed = await Self.requestPermissions()
            guard version == self.generation else {
                self.starting = false
                return
            }
            guard allowed else {
                self.starting = false
                self.status = .unavailable("Microphone or speech permission was declined. Allow it in Settings › Darkroom.")
                return
            }
            self.begin()
        }
    }

    func stop() {
        generation += 1
        starting = false
        teardown()
        status = .off
    }

    /// Reopens the microphone from scratch. The running screen calls this when
    /// the reader asks again, and when the app comes back to the foreground.
    func restart() {
        generation += 1
        starting = false
        teardown()
        status = .off
        start()
    }

    private func teardown() {
        running = false
        restartTask?.cancel()
        restartTask = nil

        task?.cancel()
        task = nil

        request?.endAudio()
        request = nil

        if let audioEngine {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        stopObservingAudio()

        if AudioRoute.listening {
            AudioRoute.setListening(false)
        }
    }

    /// The app's own spoken prompt is playing, so anything heard now is not a command.
    func setSuppressed(_ value: Bool) {
        guard suppressed != value, running else { return }
        suppressed = value
        if value {
            restartTask?.cancel()
            restartTask = nil
            task?.cancel()
            task = nil
            request?.endAudio()
            request = nil
        } else {
            restart(after: 0.2)
        }
    }

    // MARK: - Permissions

    /// Asks for the microphone and the speech permission now. The setup screen
    /// calls this when voice commands are switched on, so the system prompt
    /// appears at the moment the user asks for the feature rather than at the
    /// start of the first session.
    static func requestAccess() async -> Bool {
        await requestPermissions()
    }

    private static func requestPermissions() async -> Bool {
        let microphone = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard microphone else { return false }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Opening the microphone

    /// The current locale when it can recognise, English when that is the only
    /// model installed, and the current locale as a last resort.
    private static func makeRecogniser() -> SFSpeechRecognizer? {
        if let current = SFSpeechRecognizer(locale: Locale.current), current.isAvailable {
            return current
        }
        for identifier in ["en-US", "en-GB"] {
            if let english = SFSpeechRecognizer(locale: Locale(identifier: identifier)),
               english.isAvailable {
                return english
            }
        }
        return SFSpeechRecognizer(locale: Locale.current)
    }

    private func begin() {
        starting = false
        guard let recogniser = Self.makeRecogniser(), recogniser.isAvailable else {
            status = .unavailable("Speech recognition is not available here")
            return
        }

        // On-board recognition is preferred because a darkroom usually has no
        // network. A device without the model falls back to the service once,
        // rather than refusing to listen at all.
        usingOnDevice = recogniser.supportsOnDeviceRecognition
        triedServer = !usingOnDevice

        guard openAudio(with: recogniser) else { return }
        observeAudioChanges()
        running = true
        status = .listening
    }

    private func openAudio(with recogniser: SFSpeechRecognizer) -> Bool {
        AudioRoute.setListening(true)
        guard AudioRoute.activate() else {
            status = .unavailable("The audio session could not be opened for the microphone")
            AudioRoute.setListening(false)
            return false
        }

        let audioEngine = AVAudioEngine()
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            status = .unavailable("No microphone input is available")
            AudioRoute.setListening(false)
            return false
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = usingOnDevice
        request.taskHint = .dictation

        let box = RequestBox(request)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            box.request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            status = .unavailable("The microphone could not be opened")
            AudioRoute.setListening(false)
            return false
        }

        self.audioEngine = audioEngine
        self.request = request
        self.task = recogniser.recognitionTask(with: request) { [weak self] result, error in
            Self.forward(result: result, error: error, to: self)
        }
        return true
    }

    // MARK: - Results

    /// The callback arrives off the main actor; everything below runs on it.
    private nonisolated static func forward(
        result: SFSpeechRecognitionResult?,
        error: Error?,
        to commander: VoiceCommander?
    ) {
        let text = result?.bestTranscription.formattedString
        let isFinal = result?.isFinal ?? false
        let failed = error != nil
        Task { @MainActor [weak commander] in
            commander?.handle(text: text, isFinal: isFinal, failed: failed)
        }
    }

    private func handle(text: String?, isFinal: Bool, failed: Bool) {
        if let text, !suppressed {
            // A partial transcript keeps reporting the same words as it settles;
            // acting on each one would add thirty seconds three times over.
            let cleaned = text.lowercased()
            if cleaned != lastHandledText {
                if let command = VoiceCommand.parse(text, isFinal: isFinal) {
                    lastHandledText = cleaned
                    deliver(command)
                }
            }
            if isFinal {
                lastHandledText = ""
            }
        }

        guard running else { return }

        if failed {
            // On-device recognition fails at once when the locale's model is not
            // installed. Try the service once before counting it as broken.
            if usingOnDevice && !triedServer {
                usingOnDevice = false
                triedServer = true
                consecutiveFailures = 0
                restart(after: 0.25)
                return
            }

            consecutiveFailures += 1
            if consecutiveFailures >= 3 {
                teardown()
                status = .unavailable("The microphone stopped responding. Open the session again to retry.")
            } else {
                restart(after: 1.2)
            }
        } else {
            consecutiveFailures = 0
            if isFinal {
                restart(after: 0.4)
            }
        }
    }

    private func deliver(_ command: VoiceCommand) {
        // Partial and final callbacks can both carry the same phrase.
        if command == lastCommand, Date().timeIntervalSince(lastCommandAt) < 1.0 {
            return
        }
        lastCommand = command
        lastCommandAt = Date()
        Haptics.impact(.light)
        onCommand?(command)
    }

    // MARK: - Restarting

    private func restart(after delay: TimeInterval) {
        restartTask?.cancel()
        restartTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled, self.running, !self.suppressed else { return }
            self.restartRecognition()
        }
    }

    private func restartRecognition() {
        guard running,
              let recogniser = Self.makeRecogniser(),
              let audioEngine else { return }

        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil

        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)

        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = usingOnDevice
        request.taskHint = .dictation

        let box = RequestBox(request)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            box.request.append(buffer)
        }

        AudioRoute.activate()
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                status = .unavailable("The microphone could not be opened")
                return
            }
        }
        self.request = request

        task = recogniser.recognitionTask(with: request) { [weak self] result, error in
            Self.forward(result: result, error: error, to: self)
        }
    }

    // MARK: - The audio session changing underneath us

    private func observeAudioChanges() {
        stopObservingAudio()
        let centre = NotificationCenter.default

        observers.append(centre.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let ended = raw == AVAudioSession.InterruptionType.ended.rawValue
            Task { @MainActor [weak self] in
                guard let self, self.running else { return }
                if ended {
                    self.restartForRouteChange()
                } else {
                    self.task?.cancel()
                    self.task = nil
                    self.request?.endAudio()
                    self.request = nil
                }
            }
        })

        observers.append(centre.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.running else { return }
                self.restartForRouteChange()
            }
        })

        observers.append(centre.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.running else { return }
                self.restartForRouteChange()
            }
        })
    }

    private func stopObservingAudio() {
        let centre = NotificationCenter.default
        for observer in observers {
            centre.removeObserver(observer)
        }
        observers.removeAll()
    }

    /// After a call or a change of route the audio graph has to be rebuilt from
    /// nothing: the tap, the engine and the category all go back to their start.
    private func restartForRouteChange() {
        AudioRoute.setListening(false)
        AudioRoute.setListening(true)
        reconfigureGraph()
        restart(after: 0.4)
    }

    private func reconfigureGraph() {
        guard let audioEngine else { return }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}

/// Lets the audio tap, which runs off the main actor, hand buffers to the request.
private final class RequestBox: @unchecked Sendable {
    let request: SFSpeechAudioBufferRecognitionRequest

    init(_ request: SFSpeechAudioBufferRecognitionRequest) {
        self.request = request
    }
}
