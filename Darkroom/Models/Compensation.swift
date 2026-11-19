//
//  Compensation.swift
//  Darkroom
//
//  The arithmetic behind a session: how a time at one temperature becomes a time at
//  another, and how a reused developer lengthens it.
//

import Foundation

enum CompensationRules {
    /// Each prior use of a reusable developer compounds this much extra time.
    static let reuseStep = 0.10
}

enum PointOrigin: String, Hashable {
    /// From a manufacturer datasheet or a published chart.
    case published
    /// Entered by the user.
    case user
}

struct TemperaturePoint: Identifiable, Hashable {
    let celsius: Double
    var seconds: TimeInterval
    var origin: PointOrigin

    var id: Double { celsius }
}

/// How a time at a given temperature was arrived at.
enum TemperatureEstimate: Equatable {
    case measured(celsius: Double, origin: PointOrigin)
    case interpolated(lower: Double, upper: Double)
    case extrapolated(lower: Double, upper: Double)

    /// True when the number had to be worked past the times the app holds.
    var isEstimate: Bool {
        switch self {
        case .measured: return false
        case .interpolated: return false
        case .extrapolated: return true
        }
    }

    var note: String {
        switch self {
        case let .measured(celsius, origin):
            let owner = origin == .published ? "Published" : "Your"
            return "\(owner) time at \(TemperatureEstimate.label(celsius))"
        case let .interpolated(lower, upper):
            return "Interpolated between your \(TemperatureEstimate.label(lower)) and \(TemperatureEstimate.label(upper)) times."
        case let .extrapolated(lower, upper):
            return "Worked out past your \(TemperatureEstimate.label(lower)) to \(TemperatureEstimate.label(upper)) times — treat it as a starting point."
        }
    }

    static func label(_ celsius: Double) -> String {
        String(format: "%.1f °C", celsius)
    }
}

struct TemperatureCurve {
    let points: [TemperaturePoint]

    init(points: [TemperaturePoint]) {
        self.points = points.sorted { $0.celsius < $1.celsius }
    }

    var isEmpty: Bool { points.isEmpty }

    /// The time at the given temperature, and how it was found. Times are
    /// interpolated in the log domain, which keeps the ratio between neighbouring
    /// points smooth instead of bending the curve through them.
    func estimate(at celsius: Double) -> (seconds: TimeInterval, estimate: TemperatureEstimate)? {
        guard let first = points.first, let last = points.last else { return nil }

        if let exact = points.first(where: { abs($0.celsius - celsius) < 0.005 }) {
            return (exact.seconds, .measured(celsius: exact.celsius, origin: exact.origin))
        }

        // A single time is not a curve. Rather than invent a rate of change, say so
        // and ask for a second time at another temperature.
        if points.count == 1 {
            return nil
        }

        if celsius < first.celsius {
            let seconds = interpolate(first, points[1], to: celsius)
            return (clamp(seconds), .extrapolated(lower: first.celsius, upper: points[1].celsius))
        }

        if celsius > last.celsius {
            let lower = points[points.count - 2]
            let seconds = interpolate(lower, last, to: celsius)
            return (clamp(seconds), .extrapolated(lower: lower.celsius, upper: last.celsius))
        }

        let lower = points.last(where: { $0.celsius < celsius }) ?? first
        let upper = points.first(where: { $0.celsius > celsius }) ?? last
        let seconds = interpolate(lower, upper, to: celsius)
        return (clamp(seconds), .interpolated(lower: lower.celsius, upper: upper.celsius))
    }

    private func interpolate(_ low: TemperaturePoint, _ high: TemperaturePoint, to celsius: Double) -> TimeInterval {
        let span = high.celsius - low.celsius
        guard abs(span) > 0.0001 else { return low.seconds }
        let position = (celsius - low.celsius) / span
        let lowLog = log(max(1, low.seconds))
        let highLog = log(max(1, high.seconds))
        return exp(lowLog + (highLog - lowLog) * position)
    }

    private func clamp(_ seconds: TimeInterval) -> TimeInterval {
        min(max(seconds, 1), 6 * 3600)
    }
}

/// One entry in the setup's history: what changed, and what it did to the time the
/// session will actually use.
struct TimeAdjustment: Identifiable, Hashable {
    let id = UUID()
    let at: Date
    let label: String
    let from: String
    let to: String
    let delta: TimeInterval
}
