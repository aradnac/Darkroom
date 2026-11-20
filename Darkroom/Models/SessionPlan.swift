//
//  SessionPlan.swift
//  Darkroom
//
//  A development session as data: its stages, their durations, and the agitation
//  schedule for each stage. The engine runs a plan; the views only draw it.
//

import Foundation

enum StageKind: String, CaseIterable, Identifiable {
    case preSoak
    case develop
    case stop
    case fix
    case wash
    case rinse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preSoak: return "Pre-soak"
        case .develop: return "Developer"
        case .stop: return "Stop"
        case .fix: return "Fix"
        case .wash: return "Wash"
        case .rinse: return "Rinse"
        }
    }
}

enum WashMethod: String, CaseIterable, Identifiable {
    case runningWater
    case fillAndDump

    var id: String { rawValue }

    var label: String {
        switch self {
        case .runningWater: return "Running water"
        case .fillAndDump: return "Fill and dump"
        }
    }

    var instruction: String {
        switch self {
        case .runningWater: return "Keep fresh water running through the tank."
        case .fillAndDump: return "Fill, invert, empty. Repeat until the time is up."
        }
    }
}

enum AgitationStyle {
    case off
    case interval
    case continuous
}

/// How hard the tank is worked. It changes the length of each inversion, not the
/// interval between them.
enum AgitationIntensity: String, CaseIterable, Identifiable {
    case gentle
    case normal
    case vigorous

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gentle: return "Gentle"
        case .normal: return "Normal"
        case .vigorous: return "Vigorous"
        }
    }

    var inversionSeconds: TimeInterval {
        switch self {
        case .gentle: return 5
        case .normal: return 10
        case .vigorous: return 15
        }
    }

    var blurb: String {
        switch self {
        case .gentle: return "Slow, quiet inversions."
        case .normal: return "The usual pattern for most pairs."
        case .vigorous: return "Brisk inversions, more energy in the highlights."
        }
    }
}

enum AgitationKind {
    case initial
    case invert
    case tap
    case rest
    case continuous

    var title: String {
        switch self {
        case .initial: return "Initial agitation"
        case .invert: return "Agitate now"
        case .tap: return "Tap the tank"
        case .rest: return "Rest"
        case .continuous: return "Agitate continuously"
        }
    }

    func detail(inversionSeconds: TimeInterval) -> String {
        switch self {
        case .initial:
            return "Invert gently. The first \(Int(AgitationSchedule.initialSeconds)) s are continuous."
        case .invert:
            return "Invert gently for \(Int(inversionSeconds)) s."
        case .tap:
            return "Tap the tank on the bench to free bubbles."
        case .rest:
            return "Set the tank down and let the chemistry settle."
        case .continuous:
            return "Keep the reels moving the whole time."
        }
    }
}

struct AgitationSegment {
    let kind: AgitationKind
    let start: TimeInterval
    let end: TimeInterval
}

/// The standard pattern: continuous agitation at the start, then a short inversion
/// every minute, with a tap on the bench for bubbles after each one.
enum AgitationSchedule {
    static let initialSeconds: TimeInterval = 30
    static let intervalSeconds: TimeInterval = 60
    static let tapSeconds: TimeInterval = 5

    static func segments(
        style: AgitationStyle,
        intensity: AgitationIntensity,
        duration: TimeInterval
    ) -> [AgitationSegment] {
        guard duration > 0 else { return [] }
        let inversion = intensity.inversionSeconds

        switch style {
        case .off:
            return []

        case .continuous:
            return [AgitationSegment(kind: .continuous, start: 0, end: duration)]

        case .interval:
            var segments: [AgitationSegment] = []
            segments.append(AgitationSegment(kind: .initial, start: 0, end: min(initialSeconds, duration)))
            if duration > initialSeconds {
                segments.append(AgitationSegment(kind: .rest, start: initialSeconds, end: min(intervalSeconds, duration)))
            }

            var cycle = intervalSeconds
            while cycle < duration {
                segments.append(AgitationSegment(kind: .invert, start: cycle, end: min(cycle + inversion, duration)))

                let tapStart = cycle + inversion
                if tapStart < duration {
                    segments.append(AgitationSegment(kind: .tap, start: tapStart, end: min(tapStart + tapSeconds, duration)))
                }

                let restStart = cycle + inversion + tapSeconds
                if restStart < duration {
                    segments.append(AgitationSegment(kind: .rest, start: restStart, end: min(cycle + intervalSeconds, duration)))
                }

                cycle += intervalSeconds
            }
            return segments
        }
    }
}

struct SessionPrompt {
    /// Index into the stage's agitation segments, or -1 when no segment is active.
    let segmentIndex: Int
    let kind: AgitationKind?
    let title: String
    let detail: String
    let remaining: TimeInterval
}

struct SessionStage: Identifiable {
    let id = UUID()
    let kind: StageKind

    /// Seconds in this stage. Changing it rebuilds `segments`, so it is done
    /// through `addTime` or `setDuration` rather than by assignment.
    private(set) var duration: TimeInterval

    let agitation: AgitationStyle
    let intensity: AgitationIntensity
    var needsClearing: Bool
    let instruction: String
    var targetTemperature: Double?

    /// The agitation script, built once here rather than on every read. The
    /// engine asks for it several times a second while a stage runs, and the
    /// running screen asks again for the prompt it draws.
    private(set) var segments: [AgitationSegment]

    init(
        kind: StageKind,
        duration: TimeInterval,
        agitation: AgitationStyle,
        intensity: AgitationIntensity,
        needsClearing: Bool,
        instruction: String,
        targetTemperature: Double?
    ) {
        self.kind = kind
        self.duration = duration
        self.agitation = agitation
        self.intensity = intensity
        self.needsClearing = needsClearing
        self.instruction = instruction
        self.targetTemperature = targetTemperature
        self.segments = AgitationSchedule.segments(
            style: agitation,
            intensity: intensity,
            duration: duration
        )
    }

    mutating func addTime(_ seconds: TimeInterval) {
        setDuration(duration + seconds)
    }

    mutating func setDuration(_ value: TimeInterval) {
        duration = max(0, value)
        segments = AgitationSchedule.segments(
            style: agitation,
            intensity: intensity,
            duration: duration
        )
    }

    func prompt(at elapsed: TimeInterval) -> SessionPrompt {
        let list = segments
        if let index = list.firstIndex(where: { elapsed >= $0.start && elapsed < $0.end }) {
            let segment = list[index]
            return SessionPrompt(
                segmentIndex: index,
                kind: segment.kind,
                title: segment.kind.title,
                detail: segment.kind.detail(inversionSeconds: intensity.inversionSeconds),
                remaining: max(0, segment.end - elapsed)
            )
        }
        return SessionPrompt(
            segmentIndex: -1,
            kind: nil,
            title: kind.title,
            detail: instruction,
            remaining: max(0, duration - elapsed)
        )
    }
}

struct SessionPlan {
    /// Set in Settings; a session uses whatever it holds when the plan is made.
    static var finalRinseSeconds: TimeInterval { Preferences.shared.finalRinseSeconds }

    let film: Film
    let developer: Developer
    let dilution: Dilution
    let temperature: Double
    /// The time the app worked out for that temperature before the reuse
    /// penalty, when it had one. Kept so the journal can measure the time used
    /// against the published time rather than guessing later.
    let publishedSeconds: TimeInterval?
    let exposureIndex: Int
    let reuseCount: Int
    let intensity: AgitationIntensity
    let rolls: [Film]
    let washMethod: WashMethod
    let stageTemperatures: [StageKind: Double]
    var stages: [SessionStage]
    var adjustments: [TimeAdjustment] = []
    var compensationNote: String?
    var compensationIsEstimate: Bool = false
    var spokenPrompts: Bool = false
    var voiceCommands: Bool = false

    var developmentTime: TimeInterval {
        stages.first { $0.kind == .develop }?.duration ?? 0
    }

    var rollCount: Int { rolls.count }

    var isPushOrPull: Bool { exposureIndex != film.iso }

    static func make(
        film: Film,
        developer: Developer,
        dilution: Dilution,
        temperature: Double,
        developmentTime: TimeInterval,
        publishedSeconds: TimeInterval? = nil,
        exposureIndex: Int,
        reuseCount: Int,
        intensity: AgitationIntensity,
        rolls: [Film],
        preSoak: TimeInterval?,
        stopBath: TimeInterval,
        washTime: TimeInterval,
        washMethod: WashMethod,
        stageTemperatures: [StageKind: Double],
        adjustments: [TimeAdjustment],
        compensationNote: String?,
        compensationIsEstimate: Bool,
        spokenPrompts: Bool,
        voiceCommands: Bool
    ) -> SessionPlan {
        var stages: [SessionStage] = []

        if let preSoak, preSoak > 0 {
            stages.append(SessionStage(
                kind: .preSoak,
                duration: preSoak,
                agitation: .off,
                intensity: intensity,
                needsClearing: false,
                instruction: "Soak in water at the working temperature.",
                targetTemperature: stageTemperatures[.preSoak]
            ))
        }

        stages.append(SessionStage(
            kind: .develop,
            duration: developmentTime,
            agitation: Preferences.shared.agitationScheme.style,
            intensity: intensity,
            needsClearing: false,
            instruction: "Developer is in. Agitate as shown.",
            targetTemperature: stageTemperatures[.develop]
        ))

        stages.append(SessionStage(
            kind: .stop,
            duration: stopBath,
            agitation: .continuous,
            intensity: intensity,
            needsClearing: false,
            instruction: "Stop bath. Keep the reels moving.",
            targetTemperature: stageTemperatures[.stop]
        ))

        // The fixer's time is not known until the film leader has cleared.
        stages.append(SessionStage(
            kind: .fix,
            duration: 0,
            agitation: .interval,
            intensity: intensity,
            needsClearing: true,
            instruction: "Fixer. Agitate as shown.",
            targetTemperature: stageTemperatures[.fix]
        ))

        stages.append(SessionStage(
            kind: .wash,
            duration: washTime,
            agitation: .off,
            intensity: intensity,
            needsClearing: false,
            instruction: washMethod.instruction,
            targetTemperature: stageTemperatures[.wash]
        ))

        stages.append(SessionStage(
            kind: .rinse,
            duration: finalRinseSeconds,
            agitation: .off,
            intensity: intensity,
            needsClearing: false,
            instruction: "Wetting agent. Do not rinse it off.",
            targetTemperature: stageTemperatures[.rinse]
        ))

        return SessionPlan(
            film: film,
            developer: developer,
            dilution: dilution,
            temperature: temperature,
            publishedSeconds: publishedSeconds,
            exposureIndex: exposureIndex,
            reuseCount: reuseCount,
            intensity: intensity,
            rolls: rolls,
            washMethod: washMethod,
            stageTemperatures: stageTemperatures,
            stages: stages,
            adjustments: adjustments,
            compensationNote: compensationNote,
            compensationIsEstimate: compensationIsEstimate,
            spokenPrompts: spokenPrompts,
            voiceCommands: voiceCommands
        )
    }
}
