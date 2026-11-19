//
//  Clock.swift
//  Darkroom
//

import Foundation

enum Clock {
    /// "08:42" — rounded to the nearest second.
    static func mmss(_ seconds: TimeInterval) -> String {
        format(max(0, Int(seconds.rounded())))
    }

    /// "08:42" — rounded up, so a countdown never shows 00:00 a beat early.
    static func mmssCeil(_ seconds: TimeInterval) -> String {
        format(max(0, Int(ceil(seconds - 0.001))))
    }

    /// "12 min" style summary used in prose.
    static func minutesLabel(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60
        if abs(minutes - minutes.rounded()) < 0.01 {
            return "\(Int(minutes.rounded())) min"
        }
        return String(format: "%.1f min", minutes)
    }

    /// "+2:31" or "−0:48" for a change in a time.
    static func signed(_ seconds: TimeInterval) -> String {
        guard abs(seconds) >= 0.5 else { return "0:00" }
        let mark = seconds < 0 ? "−" : "+"
        let total = Int(abs(seconds).rounded())
        return mark + String(format: "%d:%02d", total / 60, total % 60)
    }

    private static func format(_ total: Int) -> String {
        if total >= 3600 {
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            let seconds = total % 60
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
