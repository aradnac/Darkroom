//
//  SessionActivityAttributes.swift
//  Darkroom
//
//  The shape of the Lock Screen card for a running session.
//
//  The widget extension carries its own copy of this file: the app and the
//  extension are separate modules, and ActivityKit matches the two by the
//  attributes type's name, so the declarations must stay identical.
//

import ActivityKit
import Foundation

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

        /// When the current stage ends. Present only while running, so the system
        /// can tick the countdown itself without the app having to wake.
        var stageEndDate: Date?

        /// Snapshots for the paused and ready states, in whole seconds.
        var remainingSeconds: Int
        var durationSeconds: Int

        var nextActionTitle: String?
        var nextActionDate: Date?

        var filmTitle: String
        var developerTitle: String
        var temperature: Double
    }

    var sessionID: String
}
