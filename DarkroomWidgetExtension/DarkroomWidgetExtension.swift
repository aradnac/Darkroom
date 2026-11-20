//
//  DarkroomWidgetExtension.swift
//  DarkroomWidgetExtension
//
//  The running session on the Lock Screen and in the Dynamic Island: the stage,
//  the time it has left, and what to do next. The countdowns are rendered by the
//  system as timer text against a date, so they keep ticking while the app sleeps.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Session card shape
//
// The app carries the same declarations in Support/SessionActivityAttributes.
// The two targets are separate modules, so the shape is written here as well and
// the two must stay identical: ActivityKit matches them by type name.

enum SessionActivityPhase: String, Codable, Hashable {
    case ready
    case running
    case paused
    case clearing
    case finished
}

struct SessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stageTitle: String
        var stageIndex: Int
        var stageCount: Int
        var phase: SessionActivityPhase

        var stageEndDate: Date?

        var remainingSeconds: Int
        var durationSeconds: Int

        var nextActionTitle: String?
        var nextActionDate: Date?

        var filmTitle: String
        var developerTitle: String
        var temperatureText: String
    }

    var sessionID: String
}

// MARK: - Widget

struct DarkroomSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            SessionActivityLockScreenView(state: context.state)
                .activityBackgroundTint(
                    Color(red: 0.043, green: 0.047, blue: 0.055)
                )
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.stageTitle.uppercased())
                            .font(.caption2.weight(.semibold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.6))

                        SessionActivityTimer(state: context.state)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("STAGE \(context.state.stageIndex + 1)/\(context.state.stageCount)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))

                        Text(context.state.temperatureText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Image(systemName: "hands.and.sparkles")
                        Text(context.state.nextActionTitle ?? context.state.filmTitle)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        if let date = context.state.nextActionDate {
                            Text(date, style: .timer)
                                .monospacedDigit()
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
            } compactLeading: {
                Image(systemName: symbol(for: context.state.stageTitle))
                    .foregroundStyle(.orange)
            } compactTrailing: {
                SessionActivityTimer(state: context.state)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            } minimal: {
                SessionActivityTimer(state: context.state)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .keylineTint(.orange)
        }
    }

    private func symbol(for stage: String) -> String {
        switch stage {
        case "Pre-soak": return "drop.fill"
        case "Developer": return "timer"
        case "Stop": return "hand.raised.fill"
        case "Fix": return "hourglass"
        case "Wash": return "water.waves"
        case "Rinse": return "sparkles"
        default: return "timer"
        }
    }
}

// MARK: - Lock Screen

private struct SessionActivityLockScreenView: View {
    let state: SessionActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(state.stageTitle.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()

                Text("STAGE \(state.stageIndex + 1) OF \(state.stageCount)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(alignment: .firstTextBaseline) {
                SessionActivityTimer(state: state)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Spacer()

                Text(state.temperatureText)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
            }

            if let next = state.nextActionTitle {
                HStack(spacing: 6) {
                    Image(systemName: "hands.and.sparkles")
                    Text(next)
                    Spacer(minLength: 4)
                    if let date = state.nextActionDate {
                        Text(date, style: .timer)
                            .monospacedDigit()
                    }
                }
                .font(.footnote)
                .foregroundStyle(.orange)
            } else {
                Text("\(state.filmTitle) · \(state.developerTitle)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(14)
    }
}

// MARK: - Timer

private struct SessionActivityTimer: View {
    let state: SessionActivityAttributes.ContentState

    var body: some View {
        switch state.phase {
        case .running:
            if let end = state.stageEndDate {
                Text(end, style: .timer)
            } else {
                Text(Self.format(state.remainingSeconds))
            }
        case .ready:
            Text(Self.format(state.durationSeconds))
        case .paused:
            Text(Self.format(state.remainingSeconds))
        case .clearing:
            Text("--:--")
        case .finished:
            Text("Done")
        }
    }

    private static func format(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }
}

// MARK: - Bundle

@main
struct DarkroomWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        DarkroomSessionLiveActivity()
    }
}
