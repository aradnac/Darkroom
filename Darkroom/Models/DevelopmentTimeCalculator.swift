//
//  DevelopmentTimeCalculator.swift
//  Darkroom
//
//  A development time at one temperature, moved to another. This is the engine
//  behind the Massive Dev Chart's Time/Temp Converter: an exponential correction
//  with the same fixed reduction for continuous agitation.
//

import Foundation

enum DevelopmentTimeCalculator {
    /// The exponent the converter uses, per degree Celsius. Ten degrees cooler
    /// multiplies the time by e; ten degrees warmer divides it by e.
    ///
    /// The original calculator was written for Digitaltruth by Matthew Roughan,
    /// who publishes the formula: t = t₀ · e^(α(T₀ − T)), α = 0.1.
    static let alpha = 0.1

    /// A chart's time assumes agitation at intervals. Worked continuously the
    /// negative develops faster, so the converter takes a fixed amount off.
    /// Digitaltruth's help text says 15%; the calculator's own labels and the
    /// published port both say 10%, and the code is what this follows.
    static let continuousAgitationReduction = 0.10

    /// A correction further than this from the chart temperature is a guide
    /// rather than a measurement, and the tool says so.
    static let wideDifference: Double = 5

    /// Shorter than this and pouring, draining and the clock itself matter as
    /// much as the arithmetic.
    static let shortTime: TimeInterval = 5 * 60

    // MARK: - Warnings

    enum Warning: Hashable {
        case wideTemperatureDifference(Double)
        case shortTime(TimeInterval)

        /// The message, in the temperature scale the bench reads in.
        func message(scale: TemperatureScale) -> String {
            switch self {
            case let .wideTemperatureDifference(degrees):
                let shown = String(format: "%.1f", scale == .celsius ? degrees : degrees * 9 / 5)
                return "The working temperature is \(shown) \(scale.symbol) from the chart's. A correction that size is a guide, not a measurement — test the combination before trusting it with work that matters."
            case let .shortTime(seconds):
                return "\(Clock.mmss(seconds)) is short enough that pouring and draining change the result. Keep the temperature steady and be quick at the tank."
            }
        }
    }

    // MARK: - Outcome

    struct Outcome: Equatable {
        let nominalCelsius: Double
        let actualCelsius: Double
        let nominalSeconds: TimeInterval
        /// e^(α(T₀ − T)) — the temperature part of the correction on its own.
        let temperatureFactor: Double
        /// 1, or what is left after the continuous-agitation reduction.
        let agitationFactor: Double
        /// The corrected time, to the nearest second.
        let seconds: TimeInterval
        let warnings: [Warning]
    }

    // MARK: - The calculation

    /// The time to use at `actualCelsius`, from a time measured at
    /// `nominalCelsius`. Both temperatures are in Celsius.
    static func calculate(
        nominalSeconds: TimeInterval,
        nominalCelsius: Double,
        actualCelsius: Double,
        continuousAgitation: Bool
    ) -> Outcome {
        let base = max(1, nominalSeconds)
        let temperatureFactor = exp(alpha * (nominalCelsius - actualCelsius))
        let agitationFactor = continuousAgitation ? 1 - continuousAgitationReduction : 1
        let raw = base * temperatureFactor * agitationFactor
        let seconds = min(max(raw.rounded(), 1), 6 * 3600)

        var warnings: [Warning] = []
        let difference = abs(actualCelsius - nominalCelsius)
        if difference >= wideDifference {
            warnings.append(.wideTemperatureDifference(difference))
        }
        if seconds < shortTime {
            warnings.append(.shortTime(seconds))
        }

        return Outcome(
            nominalCelsius: nominalCelsius,
            actualCelsius: actualCelsius,
            nominalSeconds: base,
            temperatureFactor: temperatureFactor,
            agitationFactor: agitationFactor,
            seconds: seconds,
            warnings: warnings
        )
    }

    /// The other way round: the water temperature that makes the development take
    /// `seconds`, from a time measured at `nominalCelsius`. The inverse of
    /// `calculate(nominalSeconds:nominalCelsius:actualCelsius:continuousAgitation:)`.
    static func temperature(
        forSeconds seconds: TimeInterval,
        nominalSeconds: TimeInterval,
        nominalCelsius: Double,
        continuousAgitation: Bool
    ) -> Double {
        let base = max(1, nominalSeconds)
        let target = max(1, seconds)
        let agitationFactor = continuousAgitation ? 1 - continuousAgitationReduction : 1
        let ratio = target / (base * agitationFactor)
        guard ratio > 0 else { return nominalCelsius }
        return nominalCelsius - log(ratio) / alpha
    }
}


/// Which way round the calculator is being asked: a time for the water you have,
/// or the water for the time you want.
enum DevelopmentDirection: String, CaseIterable, Identifiable {
    case findTime
    case findTemperature

    var id: String { rawValue }

    var title: String {
        switch self {
        case .findTime: return "Find the time"
        case .findTemperature: return "Find the temperature"
        }
    }
}
