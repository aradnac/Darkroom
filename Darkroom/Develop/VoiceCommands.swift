//
//  VoiceCommands.swift
//  Darkroom
//
//  Listening for a handful of short commands, on the device, and turning what was
//  said into something the session can act on.
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
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "!", with: " ")
            .replacingOccurrences(of: "?", with: " ")
        let words = cleaned.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return nil }
        let phrase = words.joined(separator: " ")

        if phrase.contains("start fixer") || phrase.contains("start the fixer") || phrase.contains("start fixing") {
            return .startFixer
        }
        if phrase.contains("next stage") || phrase.contains("skip stage") {
            return .nextStage
        }
        if phrase.contains("how many rolls") {
            return .rollCount
        }
        if let added = seconds(in: words) {
            return .addSeconds(added)
        }

        // Bare go and start only count once the recogniser has settled, so the
        // beginning of "start fixer" cannot start the whole stage.
        if isFinal {
            let stripped = phrase.trimmingCharacters(in: .whitespaces)
            if stripped == "go" || stripped == "start" || stripped == "start now" || stripped == "go now" {
                return .go
            }
        }

        return nil
    }

    private static func seconds(in words: [String]) -> TimeInterval? {
        guard let addIndex = words.firstIndex(of: "add") else { return nil }
        var amount: Double?
        var unit: String?

        for word in words[(addIndex + 1)...] {
            if let value = Double(word) {
                amount = value
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
            if word == "a" || word == "an" || word == "one" {
                amount = amount ?? 1
                continue
            }
        }

        guard let unit else { return nil }
        let value = amount ?? 1
        let seconds = unit == "m" ? value * 60 : value
        guard seconds > 0, seconds <= 600 else { return nil }
        return seconds
    }
}

/// On-device speech recognition, listening for those phrases. It shuts itself down
/// quietly when the device cannot do it, and it never listens to its own prompts.
@MainActor
@Observable
final class VoiceCommander {
    enum Status: Equatable {
        case off
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

    func start() {
        guard !running, !starting else { return }
        starting = true
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
                self.status = .unavailable("Microphone or speech permission was declined")
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

    // MARK: - Private

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

    private func begin() {
        starting = false
        guard let recogniser = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer(),
              recogniser.isAvailable else {
            status = .unavailable("Speech recognition is not available here")
            return
        }
        guard recogniser.supportsOnDeviceRecognition else {
            status = .unavailable("This device cannot recognise speech on board")
            return
        }

        do {
            AudioRoute.setListening(true)
            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            request.taskHint = .dictation

            let box = RequestBox(request)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                box.request.append(buffer)
            }

            engine.prepare()
            try engine.start()

            audioEngine = engine
            self.request = request

            let recogniserTask = recogniser.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let isFinal = result?.isFinal ?? false
                let failed = error != nil
                Task { @MainActor [weak self] in
                    self?.handle(text: text, isFinal: isFinal, failed: failed)
                }
            }
            task = recogniserTask
            running = true
            status = .listening
        } catch {
            status = .unavailable("The microphone could not be opened")
            AudioRoute.setListening(false)
        }
    }

    private func handle(text: String?, isFinal: Bool, failed: Bool) {
        if let text, !suppressed {
            if let command = VoiceCommand.parse(text, isFinal: isFinal) {
                Haptics.impact(.light)
                onCommand?(command)
            }
        }

        guard running else { return }

        if failed {
            consecutiveFailures += 1
            // A device without the on-device model fails every time; stop asking.
            if consecutiveFailures >= 3 {
                teardown()
                status = .unavailable("On-device recognition keeps failing")
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

    private func restart(after delay: TimeInterval) {
        restartTask?.cancel()
        restartTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled, self.running, !self.suppressed else { return }
            self.restartRecognition()
        }
    }

    private func restartRecognition() {
        guard let recogniser = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer(),
              let audioEngine else { return }

        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil

        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)

        let format = input.outputFormat(forBus: 0)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.taskHint = .dictation

        let box = RequestBox(request)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            box.request.append(buffer)
        }

        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
        self.request = request

        task = recogniser.recognitionTask(with: request) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor [weak self] in
                self?.handle(text: text, isFinal: isFinal, failed: failed)
            }
        }
    }
}

/// Lets the audio tap, which runs off the main actor, hand buffers to the request.
private final class RequestBox: @unchecked Sendable {
    let request: SFSpeechAudioBufferRecognitionRequest

    init(_ request: SFSpeechAudioBufferRecognitionRequest) {
        self.request = request
    }
}
