//
//  DevelopmentSetup.swift
//  Darkroom
//
//  Everything the setup screen asks, and the arithmetic that turns it into the time
//  the session will actually run: temperature compensation, push or pull, and the
//  compounding penalty for a reused developer.
//

import Foundation

struct DevelopmentSetup {
    // MARK: Choices

    private(set) var film: Film
    private(set) var developer: Developer
    private(set) var dilution: Dilution

    var temperature: Double = 20
    /// The temperature the chart's time was measured at — what the base readout
    /// and every correction are measured from.
    private(set) var nominalCelsius: Double = 20
    /// The converter's continuous-agitation reduction, applied on top of the
    /// temperature correction.
    private(set) var continuousAgitation = false
    var intensity: AgitationIntensity = .normal
    private(set) var reuseCount: Int = 1
    private(set) var rolls: [Film]

    var preSoakEnabled = true
    var preSoakSeconds: TimeInterval = 60
    var stopSeconds: TimeInterval = 30
    var washSeconds: TimeInterval = 300
    var washMethod: WashMethod = .runningWater
    var spokenPrompts = false
    var voiceCommands = false

    var matchStageTemperatures = true
    var stageTemperatures: [StageKind: Double] = [:]

    private(set) var pushStops: Int = 0
    private(set) var pointsByStops: [Int: [TemperaturePoint]] = [:]
    private(set) var adjustments: [TimeAdjustment] = []

    init(film: Film, developer: Developer, dilution: Dilution) {
        let preferences = Preferences.shared
        self.film = film
        self.developer = developer
        self.dilution = dilution
        self.rolls = [film]
        self.intensity = preferences.agitationIntensity
        self.continuousAgitation = preferences.agitationScheme == .continuous
        self.stopSeconds = preferences.stopSeconds
        self.washSeconds = preferences.washSeconds
        self.spokenPrompts = preferences.spokenPrompts
        self.voiceCommands = preferences.voiceCommands
    }

    // MARK: - Derived values

    var rollCount: Int { rolls.count }

    /// The exposure index the film will be shot and developed at.
    var exposureIndex: Int {
        Int((Double(film.iso) * pow(2, Double(pushStops))).rounded())
    }

    var exposureSummary: String {
        guard pushStops != 0 else { return "ISO \(film.iso) · box speed" }
        let word = pushStops > 0 ? "push" : "pull"
        let stops = abs(pushStops)
        return "EI \(exposureIndex) · \(word) \(stops) \(stops == 1 ? "stop" : "stops")"
    }

    var points: [TemperaturePoint] {
        pointsByStops[pushStops] ?? []
    }

    var curve: TemperatureCurve {
        TemperatureCurve(points: points)
    }

    var compensation: (seconds: TimeInterval, estimate: TemperatureEstimate)? {
        guard let found = curve.estimate(at: temperature) else { return nil }
        guard continuousAgitation else { return found }
        let reduced = found.seconds * (1 - DevelopmentTimeCalculator.continuousAgitationReduction)
        return (max(1, reduced.rounded()), found.estimate)
    }

    var compensatedSeconds: TimeInterval? { compensation?.seconds }

    var compensationIsEstimate: Bool { compensation?.estimate.isEstimate ?? true }

    /// A calculated time is worth flagging, but only an extrapolation is worked
    /// past the times the app holds, so only that one reads as a warning.
    var compensationIsWarning: Bool {
        guard let estimate = compensation?.estimate else { return false }
        if case .extrapolated = estimate { return true }
        return false
    }

    var compensationNote: String {
        guard let estimate = compensation?.estimate else {
            return "No time yet. Tap the time from your sheet to enter it."
        }
        if case .calculated = estimate,
           abs(nominalCelsius - temperature) >= DevelopmentTimeCalculator.wideDifference {
            return "That is a long way from your sheet's temperature, so treat this as a starting point."
        }
        return estimate.note
    }

    /// The time at the chart's temperature, which is what every other
    /// temperature is worked out from.
    var referenceSeconds: TimeInterval? {
        pointSeconds(at: nominalCelsius)
    }

    /// The water temperature that would make the development take `seconds`,
    /// from the one time from the sheet the app holds. Nil with none, or with
    /// several: a set of published points is not inverted here.
    func temperature(forSeconds seconds: TimeInterval) -> Double? {
        guard points.count == 1, let base = referenceSeconds else { return nil }
        return DevelopmentTimeCalculator.temperature(
            forSeconds: seconds,
            nominalSeconds: base,
            nominalCelsius: nominalCelsius,
            continuousAgitation: continuousAgitation
        )
    }

    var baseText: String {
        guard let seconds = referenceSeconds else { return "--:--" }
        return Clock.mmss(seconds)
    }

    var adjustedText: String {
        guard let seconds = compensatedSeconds else { return "--:--" }
        return Clock.mmss(seconds)
    }

    /// The time the session will run, after compensation and reuse.
    var developmentSeconds: TimeInterval? {
        guard let compensated = compensatedSeconds else { return nil }
        return (compensated * Self.reuseFactor(uses: reuseCount)).rounded()
    }

    var canStart: Bool {
        (developmentSeconds ?? 0) >= 10
    }

    var finalText: String {
        guard let seconds = developmentSeconds else { return "--:--" }
        return Clock.mmss(seconds)
    }

    /// Each prior use adds 10% on top of the previous increase, so use 3 is +21%.
    static func reuseFactor(uses: Int) -> Double {
        pow(1 + CompensationRules.reuseStep, Double(max(0, uses - 1)))
    }

    static func reuseArithmetic(uses: Int) -> String {
        let prior = max(0, uses - 1)
        guard prior > 0 else { return "Fresh mix — no adjustment." }
        let times = prior == 1 ? "once" : (prior == 2 ? "twice" : "\(prior) times")
        let percent = Int(((pow(1 + CompensationRules.reuseStep, Double(prior)) - 1) * 100).rounded())
        let step = Int((CompensationRules.reuseStep * 100).rounded())
        return "+\(percent)% — \(step)% compounded \(times)."
    }

    func targetTemperature(for kind: StageKind) -> Double {
        matchStageTemperatures ? temperature : (stageTemperatures[kind] ?? temperature)
    }

    var uniqueRollNames: [String] {
        var names: [String] = []
        for roll in rolls where !names.contains(roll.displayName) {
            names.append(roll.displayName)
        }
        return names
    }

    /// Set when the rolls hold different emulsions, which cannot share one time.
    var mixedWarning: String? {
        let names = uniqueRollNames
        guard names.count > 1 else { return nil }
        let list = names.joined(separator: " and ")
        if Set(rolls.map(\.process)).count > 1 {
            return "Mixed processes: \(list). These cannot be developed together in one session."
        }
        return "Mixed emulsions: \(list) need different times. Use one time for both, or develop them separately."
    }

    // MARK: - Points

    func hasPoint(at celsius: Double) -> Bool {
        points.contains { abs($0.celsius - celsius) < 0.005 }
    }

    func pointSeconds(at celsius: Double) -> TimeInterval? {
        points.first { abs($0.celsius - celsius) < 0.005 }?.seconds
    }

    // MARK: - Changes that are recorded

    mutating func setFilm(_ newFilm: Film) {
        guard newFilm.id != film.id else { return }
        let before = developmentSeconds
        let old = film.fullName
        film = newFilm
        rolls = Array(repeating: newFilm, count: max(1, rolls.count))
        pushStops = 0
        pointsByStops = [:]
        record("Film", from: old, to: newFilm.fullName, before: before)
    }

    mutating func setDeveloper(_ newDeveloper: Developer) {
        guard newDeveloper.id != developer.id else { return }
        let before = developmentSeconds
        let old = developer.name
        developer = newDeveloper
        if let first = newDeveloper.dilutions.first {
            dilution = first
        }
        pointsByStops = [:]
        record("Developer", from: old, to: newDeveloper.name, before: before)
    }

    mutating func setDilution(_ newDilution: Dilution) {
        guard newDilution.id != dilution.id else { return }
        let before = developmentSeconds
        let old = dilution.label
        dilution = newDilution
        pointsByStops = [:]
        record("Dilution", from: old, to: newDilution.label, before: before)
    }

    mutating func setTemperature(_ value: Double, step: Double = 0.5) {
        let granularity = max(0.05, step)
        let clamped = min(24, max(18, (value / granularity).rounded() * granularity))
        guard abs(clamped - temperature) > 0.001 else { return }
        let before = developmentSeconds
        let old = developmentSeconds == nil ? nil : temperature
        temperature = clamped
        record(
            "Temperature",
            from: old.map { Self.temperatureLabel($0) } ?? "--",
            to: Self.temperatureLabel(clamped),
            before: before
        )
    }

    mutating func setPushStops(_ value: Int) {
        let clamped = max(-2, min(3, value))
        guard clamped != pushStops else { return }
        let before = developmentSeconds
        let old = pushStops
        pushStops = clamped
        record(
            "Exposure index",
            from: Self.exposureLabel(film: film, stops: old),
            to: Self.exposureLabel(film: film, stops: clamped),
            before: before
        )
    }

    mutating func setReuseCount(_ value: Int) {
        let clamped = max(1, min(value, 20))
        guard clamped != reuseCount else { return }
        let before = developmentSeconds
        let old = reuseCount
        reuseCount = clamped
        record("Reuse", from: "use \(old)", to: "use \(clamped)", before: before)
    }

    mutating func setPointSeconds(_ seconds: TimeInterval, at celsius: Double) {
        guard seconds >= 10 else { return }
        let before = developmentSeconds
        var list = pointsByStops[pushStops] ?? []
        let previous: String
        if let index = list.firstIndex(where: { abs($0.celsius - celsius) < 0.005 }) {
            previous = Clock.mmss(list[index].seconds)
            list[index].seconds = seconds
        } else {
            previous = "--:--"
            list.append(TemperaturePoint(celsius: celsius, seconds: seconds, origin: .user))
        }
        pointsByStops[pushStops] = list
        record("Time at \(Self.temperatureLabel(celsius))", from: previous, to: Clock.mmss(seconds), before: before)
    }

    mutating func removePoint(at celsius: Double) {
        guard var list = pointsByStops[pushStops], list.count > 1 else { return }
        let before = developmentSeconds
        list.removeAll { abs($0.celsius - celsius) < 0.005 }
        pointsByStops[pushStops] = list
        record("Removed \(Self.temperatureLabel(celsius))", from: Self.temperatureLabel(celsius), to: "removed", before: before)
    }

    /// Moving the chart's temperature carries the entered time with it: the
    /// number belongs to the temperature it was measured at.
    mutating func setNominalCelsius(_ value: Double) {
        let clamped = min(35, max(15, (value * 2).rounded() / 2))
        guard abs(clamped - nominalCelsius) > 0.001 else { return }
        let before = developmentSeconds
        let old = nominalCelsius
        let carried = pointSeconds(at: old)
        nominalCelsius = clamped
        if let carried {
            var list = pointsByStops[pushStops] ?? []
            list.removeAll { abs($0.celsius - old) < 0.005 }
            if let index = list.firstIndex(where: { abs($0.celsius - clamped) < 0.005 }) {
                list[index].seconds = carried
            } else {
                list.append(TemperaturePoint(celsius: clamped, seconds: carried, origin: .user))
            }
            pointsByStops[pushStops] = list
        }
        record(
            "Chart temperature",
            from: Self.temperatureLabel(old),
            to: Self.temperatureLabel(clamped),
            before: before
        )
    }

    mutating func setContinuousAgitation(_ value: Bool) {
        guard value != continuousAgitation else { return }
        let before = developmentSeconds
        continuousAgitation = value
        record(
            "Continuous agitation",
            from: value ? "interval" : "continuous",
            to: value ? "continuous" : "interval",
            before: before
        )
    }

    mutating func setRollCount(_ count: Int) {
        let clamped = max(1, min(count, 6))
        guard clamped != rolls.count else { return }
        if clamped > rolls.count {
            while rolls.count < clamped {
                rolls.append(film)
            }
        } else {
            rolls.removeLast(rolls.count - clamped)
        }
    }

    mutating func setRollFilm(_ newFilm: Film, at index: Int) {
        guard rolls.indices.contains(index) else { return }
        rolls[index] = newFilm
    }

    mutating func setStageTemperature(_ value: Double, for kind: StageKind) {
        stageTemperatures[kind] = min(24, max(18, (value * 2).rounded() / 2))
    }

    // MARK: - Building the plan

    func makePlan() -> SessionPlan? {
        guard let seconds = developmentSeconds, seconds >= 10 else { return nil }

        var temperatures: [StageKind: Double] = [:]
        for kind in StageKind.allCases {
            temperatures[kind] = targetTemperature(for: kind)
        }

        return SessionPlan.make(
            film: film,
            developer: developer,
            dilution: dilution,
            temperature: temperature,
            developmentTime: seconds,
            publishedSeconds: compensation?.seconds,
            exposureIndex: exposureIndex,
            reuseCount: reuseCount,
            intensity: intensity,
            rolls: rolls,
            preSoak: preSoakEnabled ? preSoakSeconds : nil,
            stopBath: stopSeconds,
            washTime: washSeconds,
            washMethod: washMethod,
            stageTemperatures: temperatures,
            adjustments: adjustments,
            compensationNote: compensation?.estimate.note,
            compensationIsEstimate: compensation?.estimate.isEstimate ?? false,
            spokenPrompts: spokenPrompts,
            voiceCommands: voiceCommands
        )
    }

    // MARK: - Helpers

    private mutating func record(_ label: String, from: String, to: String, before: TimeInterval?) {
        guard let after = developmentSeconds else { return }
        guard let before else {
            adjustments.append(TimeAdjustment(at: Date(), label: label, from: from, to: to, delta: after))
            return
        }
        let delta = after - before
        guard abs(delta) >= 0.5 else { return }
        adjustments.append(TimeAdjustment(at: Date(), label: label, from: from, to: to, delta: delta))
    }

    static func temperatureLabel(_ value: Double) -> String {
        Units.temperature(value)
    }

    static func exposureLabel(film: Film, stops: Int) -> String {
        guard stops != 0 else { return "ISO \(film.iso)" }
        let index = Int((Double(film.iso) * pow(2, Double(stops))).rounded())
        return "EI \(index)"
    }
}
