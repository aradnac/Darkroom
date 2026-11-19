//
//  PromptSpeaker.swift
//  Darkroom
//
//  Says the agitation prompt aloud, and tells the rest of the app when it is
//  talking so the microphone ignores its own voice.
//

import AVFoundation

@MainActor
final class PromptSpeaker {
    var onSpeakingChanged: ((Bool) -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private let speechDelegate = SpeechStateDelegate()
    private var lastSpoken = ""
    private var lastSpokenAt = Date.distantPast

    init() {
        speechDelegate.onChange = { [weak self] speaking in
            self?.onSpeakingChanged?(speaking)
        }
        synthesizer.delegate = speechDelegate
    }

    func say(_ text: String) {
        guard !text.isEmpty else { return }
        // Prompts repeat every minute; do not say the same thing twice in a row.
        if text == lastSpoken, Date().timeIntervalSince(lastSpokenAt) < 2 {
            return
        }
        lastSpoken = text
        lastSpokenAt = Date()

        AudioRoute.activate()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

private final class SpeechStateDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onChange: ((Bool) -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onChange?(true)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onChange?(false)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onChange?(false)
    }
}
