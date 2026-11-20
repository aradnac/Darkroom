//
//  Feedback.swift
//  Darkroom
//
//  Alerts a darkroom actually needs: a chime you can hear with the phone face down
//  on the bench, and a haptic for when it is in your hand. The audio route is shared
//  with the microphone so voice commands and prompts can run together.
//

import AVFoundation
import AudioToolbox
import UIKit
import SwiftUI

enum Chime {
    case agitate
    case settle
    case stageComplete
    case finished
    case tick
}

/// One place that decides how the app talks to the audio session, so the chimes and
/// the microphone never fight over the category.
enum AudioRoute {
    private(set) static var listening = false
    private static var configured = false

    static func setListening(_ on: Bool) {
        guard listening != on else { return }
        listening = on
        configured = false
        FeedbackCenter.shared.reconfigure()
    }

    /// Applies the category this route needs and activates the session.
    @discardableResult
    static func activate() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            if !configured {
                if listening {
                    try session.setCategory(
                        .playAndRecord,
                        mode: .default,
                        options: [.mixWithOthers, .defaultToSpeaker]
                    )
                } else {
                    try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                }
                configured = true
            }
            try session.setActive(true, options: [])
            return true
        } catch {
            return false
        }
    }
}

final class FeedbackCenter {
    static let shared = FeedbackCenter()

    private struct Tone {
        let frequency: Double
        let start: Double
        let duration: Double
        let amplitude: Double
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    private var prepared = false

    private init() {}

    func play(_ chime: Chime) {
        guard AudioRoute.activate() else {
            AudioServicesPlaySystemSound(1057)
            return
        }
        guard let buffer = render(tones(for: chime)) else { return }
        if prepared {
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
        }
        if !engine.isRunning {
            try? engine.start()
        }
    }

    /// The route changed, so tear the graph down; it is rebuilt on the next play.
    func reconfigure() {
        guard prepared else { return }
        player.stop()
        if engine.isRunning {
            engine.stop()
        }
    }

    private func tones(for chime: Chime) -> [Tone] {
        switch chime {
        case .agitate:
            return [
                Tone(frequency: 988, start: 0, duration: 0.15, amplitude: 0.50),
                Tone(frequency: 1480, start: 0.10, duration: 0.12, amplitude: 0.30)
            ]
        case .settle:
            return [
                Tone(frequency: 587, start: 0, duration: 0.12, amplitude: 0.38)
            ]
        case .stageComplete:
            return [
                Tone(frequency: 784, start: 0, duration: 0.26, amplitude: 0.48),
                Tone(frequency: 1175, start: 0.15, duration: 0.34, amplitude: 0.40)
            ]
        case .finished:
            return [
                Tone(frequency: 659, start: 0, duration: 0.26, amplitude: 0.44),
                Tone(frequency: 988, start: 0.17, duration: 0.30, amplitude: 0.40),
                Tone(frequency: 1319, start: 0.36, duration: 0.60, amplitude: 0.38)
            ]
        case .tick:
            return [
                Tone(frequency: 1319, start: 0, duration: 0.07, amplitude: 0.34)
            ]
        }
    }

    private func prepareIfNeeded() {
        guard !prepared else { return }
        engine.attach(player)
        if let format {
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        prepared = true
    }

    private func render(_ tones: [Tone]) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        prepareIfNeeded()

        let longest = tones.map { $0.start + $0.duration }.max() ?? 0.3
        let total = longest + 0.05
        let frames = AVAudioFrameCount(total * format.sampleRate)
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        guard let channels = buffer.floatChannelData else { return nil }
        let samples = channels[0]
        let sampleRate = format.sampleRate

        for index in 0..<Int(frames) {
            let time = Double(index) / sampleRate
            var value = 0.0
            for tone in tones {
                let local = time - tone.start
                guard local >= 0, local < tone.duration else { continue }
                let progress = local / tone.duration
                let envelope = sin(Double.pi * progress) * exp(-1.5 * progress)
                value += sin(2 * Double.pi * tone.frequency * local) * envelope * tone.amplitude
            }
            samples[index] = Float(max(-1, min(1, value * 0.6)))
        }
        return buffer
    }
}

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}



/// Adds a quiet tap haptic to app-owned buttons without changing their appearance.
struct HapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.hapticFeedbackOnPress(isPressed: configuration.isPressed)
    }
}

extension View {
    func hapticFeedbackOnPress(isPressed: Bool) -> some View {
        onChange(of: isPressed) { _, pressed in
            guard pressed else { return }
            Haptics.impact(.light)
        }
    }
}
