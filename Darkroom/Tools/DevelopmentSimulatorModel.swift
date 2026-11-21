//
//  DevelopmentSimulatorModel.swift
//  Darkroom
//
//  The arithmetic behind the development simulator: what a choice of dilution,
//  temperature, time, agitation and fixing is expected to do to the negative,
//  and the settings the example frame is rendered at.
//
//  Everything is measured from one published time. The model follows the
//  direction and rough size of each effect — it is not a densitometer reading,
//  and the screen says so rather than pretending otherwise.
//

import CoreGraphics
import Foundation

// MARK: - A documented pair

/// One film/developer/dilution combination the library has a published time for,
/// at the temperature that time was measured at.
struct DevelopmentSimulatorPair: Identifiable, Hashable {
    let film: Film
    let developer: Developer
    let dilution: Dilution
    let documentedSeconds: TimeInterval
    let documentedCelsius: Double
    let sourceName: String?

    var id: String { "\(film.id)|\(developer.id)|\(dilution.id)" }

    var pairLine: String { "\(film.displayName) · \(developer.name)" }

    var dilutionLine: String { "\(developer.name) \(dilution.label)" }
}

// MARK: - The pairs on offer

enum DevelopmentSimulatorCatalog {
    /// Black-and-white combinations with a published time at a bench temperature.
    /// A pairing without one is not offered, because every figure on the screen
    /// is measured from the time it documents.
    static func pairs(store: LibraryStore = .shared) -> [DevelopmentSimulatorPair] {
        var result: [DevelopmentSimulatorPair] = []
        var seen: Set<String> = []

        for time in store.document.times {
            guard time.celsius >= DevelopmentSimulatorReading.minimumTemperature,
                  time.celsius <= DevelopmentSimulatorReading.maximumTemperature,
                  let seconds = time.seconds,
                  seconds >= 60,
                  let film = store.legacyFilm(key: time.film),
                  film.process == .blackAndWhite,
                  let developer = store.legacyDevelopers.first(where: { $0.id == time.developer }),
                  let dilution = developer.dilution(id: time.dilution)
            else { continue }

            let pair = DevelopmentSimulatorPair(
                film: film,
                developer: developer,
                dilution: dilution,
                documentedSeconds: TimeInterval(seconds),
                documentedCelsius: time.celsius,
                sourceName: store.source(key: time.provenance.source)?.publisher
            )

            guard !seen.contains(pair.id) else { continue }
            seen.insert(pair.id)
            result.append(pair)
        }

        return result.sorted { left, right in
            if left.film.fullName != right.film.fullName {
                return left.film.fullName.localizedCaseInsensitiveCompare(right.film.fullName) == .orderedAscending
            }
            if left.developer.name != right.developer.name {
                return left.developer.name.localizedCaseInsensitiveCompare(right.developer.name) == .orderedAscending
            }
            return left.dilution.label < right.dilution.label
        }
    }

    /// How readily a stock shows grain, from the library's own note on it.
    static func grainFactor(for film: Film, store: LibraryStore = .shared) -> Double {
        let value = store.film(key: film.id)?.grain?.value.lowercased() ?? ""
        if value.contains("very fine") { return 0.55 }
        if value.contains("fine") { return 0.7 }
        if value.contains("coarse") { return 1.4 }
        if value.contains("moderate") { return 1.0 }
        return 1.0
    }
}

// MARK: - Agitation

/// How often the tank is worked. Continuous agitation adds activity; long rest
/// periods take it away. The reference is an inversion every minute, which is
/// what the published charts assume.
struct DevelopmentSimulatorAgitation: Identifiable, Hashable {
    /// Nil means the tank is kept moving for the whole stage.
    let intervalSeconds: Int?
    let activityStops: Double

    var id: String { intervalSeconds.map(String.init) ?? "continuous" }

    var label: String {
        guard let intervalSeconds else { return "Continuous" }
        return "Every \(intervalSeconds) s"
    }

    static let all: [DevelopmentSimulatorAgitation] = [
        DevelopmentSimulatorAgitation(intervalSeconds: nil, activityStops: 0.30),
        DevelopmentSimulatorAgitation(intervalSeconds: 30, activityStops: 0.18),
        DevelopmentSimulatorAgitation(intervalSeconds: 60, activityStops: 0),
        DevelopmentSimulatorAgitation(intervalSeconds: 90, activityStops: -0.08),
        DevelopmentSimulatorAgitation(intervalSeconds: 120, activityStops: -0.15),
        DevelopmentSimulatorAgitation(intervalSeconds: 180, activityStops: -0.25)
    ]

    static let standard = DevelopmentSimulatorAgitation(intervalSeconds: 60, activityStops: 0)
}

// MARK: - Reading

/// A setting on the simulator and everything it implies.
struct DevelopmentSimulatorReading {
    let pair: DevelopmentSimulatorPair
    let temperature: Double
    let seconds: TimeInterval
    let agitation: DevelopmentSimulatorAgitation
    let fixSeconds: TimeInterval
    let grainFactor: Double

    static let minimumTemperature = 18.0
    static let maximumTemperature = 24.0

    /// The reference fix: about twice the leader's clearing time and no less
    /// than five minutes for a fresh rapid fixer at film strength.
    static let recommendedFixSeconds: TimeInterval = 5 * 60
    /// Three times that reference is where a rapid fixer starts working on the
    /// image itself rather than on the unexposed halides.
    static let overFixThreshold: TimeInterval = 15 * 60

    static let contrastPerStop = 15.0
    static let densityPerStop = 0.12
    static let overDevelopmentStops = 0.4
    static let underDevelopmentStops = -0.4

    // MARK: Time

    /// The time the app would recommend at this working temperature, from the
    /// published time at the temperature it was measured at.
    var recommendedSeconds: TimeInterval {
        DevelopmentTimeCalculator.calculate(
            nominalSeconds: pair.documentedSeconds,
            nominalCelsius: pair.documentedCelsius,
            actualCelsius: temperature,
            continuousAgitation: false
        ).seconds
    }

    var timeStops: Double {
        log2(max(seconds, 15) / max(recommendedSeconds, 1))
    }

    var timeDeviationPercent: Double {
        (seconds / max(recommendedSeconds, 1) - 1) * 100
    }

    var isTimeBaseline: Bool {
        abs(timeStops) < 0.02
    }

    /// Time relative to the recommendation, plus whatever the agitation adds or
    /// takes away. One stop is a doubling or halving of development activity.
    var developmentStops: Double {
        timeStops + agitation.activityStops
    }

    // MARK: States

    var overDevelopment: Bool { developmentStops >= Self.overDevelopmentStops }
    var underDevelopment: Bool { developmentStops <= Self.underDevelopmentStops }
    var overFixing: Bool { fixSeconds > Self.overFixThreshold }

    var isBaseline: Bool {
        isTimeBaseline && agitation == .standard && fixSeconds == Self.recommendedFixSeconds
    }

    var stateLabel: String {
        if overFixing { return "Over-fix" }
        if overDevelopment { return "Over" }
        if underDevelopment { return "Under" }
        if isBaseline { return "Baseline" }
        return "Custom"
    }

    // MARK: Movement

    var contrastPercent: Double {
        let overFixLoss = min(6, max(0, fixSeconds - Self.overFixThreshold) / 60 * 0.8)
        return developmentStops * Self.contrastPerStop - overFixLoss
    }

    /// Highlight density, in log D, against the published setting.
    var densityDelta: Double {
        let overFixLoss = min(0.08, max(0, fixSeconds - Self.overFixThreshold) / 60 * 0.008)
        return developmentStops * Self.densityPerStop - overFixLoss
    }

    /// A thin negative still shows the emulsion's grain, so grain moves less
    /// than contrast does.
    var grainSteps: Double {
        developmentStops * 0.9
    }

    var fogDensity: Double {
        let developed = max(0, developmentStops) * 0.012
        let warm = max(0, temperature - pair.documentedCelsius) * 0.004
        return developed + warm
    }

    var contrastText: String { Self.signed(contrastPercent, decimals: 0, suffix: "%") }
    var densityText: String { Self.signed(densityDelta, decimals: 2, suffix: "") }
    var grainText: String { Self.signed(grainSteps, decimals: 1, suffix: "") }
    var fogText: String { Self.signed(fogDensity, decimals: 2, suffix: "") }

    var timeNote: String {
        guard !isTimeBaseline else { return "Published time" }
        return Self.signed(timeDeviationPercent, decimals: 0, suffix: "%")
    }

    /// The stop the development is away from the published setting, written for
    /// a warning heading.
    var stopText: String {
        Self.signed(developmentStops, decimals: 1, suffix: " stop")
    }

    // MARK: Render

    /// What the example frame should look like at this setting. The parameters
    /// only need to move in the same direction, and by about the same amount, as
    /// the negative would.
    func parameters(shiftingStops shift: Double = 0) -> DevelopmentSimulatorRenderParameters {
        let stops = developmentStops + shift
        let overFixMinutes = max(0, fixSeconds - Self.overFixThreshold) / 60
        let overFixDensity = min(0.10, overFixMinutes * 0.008)

        let contrast = min(
            2.2,
            max(0.35, 1 + (stops * Self.contrastPerStop) / 100 - min(0.06, overFixMinutes * 0.008))
        )
        let exposureEV = -stops * 0.55 + overFixDensity * 2
        let blackLift = min(0.30, max(0, -stops) * 0.055 + fogDensity * 3)
        let grain = min(0.9, max(0.05, 0.16 * grainFactor + stops * 0.22))

        return DevelopmentSimulatorRenderParameters(
            exposureEV: exposureEV,
            contrast: contrast,
            blackLift: blackLift,
            grain: grain
        )
    }

    // MARK: Formatting

    static func signed(_ value: Double, decimals: Int, suffix: String) -> String {
        let zeroThreshold = pow(10, Double(-decimals)) / 2
        let settled = abs(value) < zeroThreshold ? 0 : value
        let magnitude = String(format: "%.\(decimals)f", abs(settled))
        if settled > 0 { return "+\(magnitude)\(suffix)" }
        if settled < 0 { return "−\(magnitude)\(suffix)" }
        return "\(magnitude)\(suffix)"
    }
}

// MARK: - Render parameters

struct DevelopmentSimulatorRenderParameters {
    let exposureEV: Double
    /// A multiplier around 1: 1.15 is a tenth more separation than the base frame.
    let contrast: Double
    /// Added to every channel: the lifted blacks that read as fog.
    let blackLift: Double
    /// 0 to 1, how much noise sits over the frame.
    let grain: Double
}

struct DevelopmentSimulatorRender {
    let main: CGImage?
    let minusOneStop: CGImage?
    let plusOneStop: CGImage?

    static let empty = DevelopmentSimulatorRender(main: nil, minusOneStop: nil, plusOneStop: nil)
}
