//
//  SessionActivityController.swift
//  Darkroom
//
//  Drives the Lock Screen card: it starts one when a session opens, keeps it in
//  step with the engine as stages and agitation prompts change, and takes it down
//  when the session closes.
//

import ActivityKit
import Foundation

@MainActor
final class SessionActivityController {
    static let shared = SessionActivityController()

    private var activity: Activity<SessionActivityAttributes>?

    private init() {}

    // MARK: Lifecycle

    func start(engine: SessionEngine) {
        Task { await begin(engine: engine) }
    }

    private func begin(engine: SessionEngine) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await endActivity()

        let state = Self.state(for: engine)
        do {
            activity = try await Activity.request(
                attributes: SessionActivityAttributes(sessionID: UUID().uuidString),
                content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600)),
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func update(engine: SessionEngine) {
        guard let activity else { return }
        let state = Self.state(for: engine)
        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))
            )
        }
    }

    func end() {
        Task { await endActivity() }
    }

    private func endActivity() async {
        guard let activity else { return }
        self.activity = nil
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    // MARK: State

    private static func state(for engine: SessionEngine) -> SessionActivityAttributes.ContentState {
        let stage = engine.currentStage
        let plan = engine.plan

        let phase: SessionActivityPhase
        var endDate: Date?

        switch engine.phase {
        case .ready:
            phase = .ready
        case .running:
            phase = .running
            endDate = Date().addingTimeInterval(max(0, engine.stageRemaining))
        case .paused:
            phase = .paused
        case .clearing:
            phase = .clearing
        case .finished:
            phase = .finished
        }

        var nextTitle: String?
        var nextDate: Date?

        if engine.phase == .running {
            let elapsed = engine.stageElapsed
            let segments = stage.segments

            if let index = segments.firstIndex(where: { elapsed >= $0.start && elapsed < $0.end }) {
                switch segments[index].kind {
                case .continuous, .invert:
                    nextTitle = "Agitate now"
                case .initial:
                    nextTitle = "Initial agitation"
                case .tap:
                    nextTitle = "Tap the tank"
                case .rest:
                    if let upcoming = segments.first(where: { $0.start > elapsed }) {
                        nextTitle = upcoming.kind.title
                        nextDate = Date().addingTimeInterval(upcoming.start - elapsed)
                    }
                }
            } else if let upcoming = segments.first(where: { $0.start > elapsed }) {
                nextTitle = upcoming.kind.title
                nextDate = Date().addingTimeInterval(upcoming.start - elapsed)
            }
        }

        return SessionActivityAttributes.ContentState(
            stageTitle: stage.kind.title,
            stageIndex: engine.stageIndex,
            stageCount: engine.stageCount,
            phase: phase,
            stageEndDate: endDate,
            remainingSeconds: Int(max(0, engine.stageRemaining).rounded()),
            durationSeconds: Int(max(0, stage.duration).rounded()),
            nextActionTitle: nextTitle,
            nextActionDate: nextDate,
            filmTitle: plan.film.displayName,
            developerTitle: "\(plan.developer.name) \(plan.dilution.label)",
            temperature: plan.temperature
        )
    }
}
