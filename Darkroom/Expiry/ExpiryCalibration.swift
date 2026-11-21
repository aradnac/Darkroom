//
//  ExpiryCalibration.swift
//  Darkroom
//
//  Roll observations and the hierarchical calibration they feed: global → film
//  family → this film → this roll. A single roll is never allowed to rewrite a
//  film's behaviour, and the validation is kept separate from the fitting.
//

import Combine
import Foundation

// MARK: - Observations

/// How a roll actually came out. Deliberately ordinal: nobody knows by how
/// much a scan was under, and pretending otherwise would build false precision
/// into the calibration.
enum ExpiryRollOutcome: String, Codable, CaseIterable, Identifiable, Sendable {
    case underexposed
    case good
    case overexposed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .underexposed: return "Underexposed"
        case .good: return "Good"
        case .overexposed: return "Overexposed"
        }
    }

    var detail: String {
        switch self {
        case .underexposed: return "Thin shadows, detail lost in the dark parts."
        case .good: return "Shadows and highlights both where they should be."
        case .overexposed: return "Dense, highlights blocked, shadows flat but present."
        }
    }

    /// The residual in stops of *needed extra exposure*: positive means the
    /// film wanted more light than the model suggested.
    var residualStops: Double {
        switch self {
        case .underexposed: return 0.5
        case .good: return 0
        case .overexposed: return -0.5
        }
    }
}

/// How much a reported outcome is trusted.
enum ExpiryCalibrationEvidence: String, Codable, CaseIterable, Identifiable, Sendable {
    case anecdotal
    case personal
    case controlled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anecdotal: return "Someone else's report"
        case .personal: return "My own result"
        case .controlled: return "Side-by-side test"
        }
    }

    var weight: Double {
        switch self {
        case .anecdotal: return 0.45
        case .personal: return 0.75
        case .controlled: return 1.0
        }
    }
}

/// One roll's outcome, with everything needed to weigh it.
struct ExpiryCalibrationPoint: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var filmKey: String
    var group: ExpiryBehaviourGroup
    /// How old the film was estimated to be when it was shot.
    var ageYears: Double
    var storage: String
    var exposureIndex: Int
    /// 1 = barely usable, 5 = a clean, well-scanned negative.
    var quality: Int
    var evidence: ExpiryCalibrationEvidence
    var source: String
    var notes: String
    var outcome: ExpiryRollOutcome
    var recorded: Date

    init(
        id: String = UUID().uuidString,
        filmKey: String,
        group: ExpiryBehaviourGroup,
        ageYears: Double,
        storage: String,
        exposureIndex: Int,
        quality: Int,
        evidence: ExpiryCalibrationEvidence = .personal,
        source: String = "",
        notes: String = "",
        outcome: ExpiryRollOutcome,
        recorded: Date = Date()
    ) {
        self.id = id
        self.filmKey = filmKey
        self.group = group
        self.ageYears = ageYears
        self.storage = storage
        self.exposureIndex = exposureIndex
        self.quality = quality
        self.evidence = evidence
        self.source = source
        self.notes = notes
        self.outcome = outcome
        self.recorded = recorded
    }

    var weight: Double {
        let qualityShare = Double(max(1, min(5, quality))) / 5
        return max(0.05, evidence.weight * qualityShare)
    }
}

// MARK: - The adjustment

/// What the calibration does to a prediction. Everything is in stops and the
/// whole correction is hard-bounded, so no amount of logged rolls can turn the
/// model into something that contradicts its own physics.
struct ExpiryCalibrationAdjustment: Hashable, Sendable {
    var deltaStops: Double
    var filmDelta: Double
    var groupDelta: Double
    var filmObservations: Int
    var groupObservations: Int
    var leaveOneOutError: Double
    var leaveOneOutCount: Int

    static let none = ExpiryCalibrationAdjustment(
        deltaStops: 0,
        filmDelta: 0,
        groupDelta: 0,
        filmObservations: 0,
        groupObservations: 0,
        leaveOneOutError: 0,
        leaveOneOutCount: 0
    )

    /// The adjustment is capped well below a third of a stop until a film has a
    /// real sample behind it.
    static let maximumShiftStops = 0.5

    var isActive: Bool { abs(deltaStops) >= 0.02 }

    var summary: String {
        guard filmObservations > 0 || groupObservations > 0 else {
            return "No rolls logged yet, so nothing has been adjusted."
        }
        let direction = deltaStops > 0 ? "more exposure" : "less exposure"
        let amount = String(format: "%.2f", abs(deltaStops))
        return "\(filmObservations) roll\(filmObservations == 1 ? "" : "s") for this film and \(groupObservations) across the family shift the estimate \(amount) stop\(amount == "1.00" ? "" : "s") toward \(direction)."
    }
}

// MARK: - Analyser

/// Hierarchical shrinkage. Each level is pulled toward the one above it by a
/// prior strength expressed in effective observations, so a thin sample moves
/// almost nothing and a fat one moves the film, not the family.
struct ExpiryCalibrationAnalyser: Sendable {
    /// Pseudo-observations standing behind a film's own sample. Twenty is
    /// deliberately heavy: one roll, however well controlled, moves this film's
    /// prediction by only about a twentieth of a stop, while a few dozen move
    /// it most of the half-stop the clamp allows.
    var filmPriorStrength: Double = 20
    /// Pseudo-observations standing behind a family's sample.
    var groupPriorStrength: Double = 20

    /// The shrinkage itself, with no validation inside it. Every leave-one-out
    /// pass calls this, so fitting and validating cannot recurse into each other.
    struct Fit: Sendable {
        var deltaStops: Double
        var filmDelta: Double
        var groupDelta: Double
        var filmObservations: Int
        var groupObservations: Int
    }

    func fit(
        forFilm filmKey: String,
        group: ExpiryBehaviourGroup,
        points: [ExpiryCalibrationPoint]
    ) -> Fit? {
        guard !points.isEmpty else { return nil }

        let groupPoints = points.filter { $0.group == group }
        let filmPoints = points.filter { $0.filmKey == filmKey }

        let groupWeight = groupPoints.reduce(0) { $0 + $1.weight }
        let groupWeighted = groupPoints.reduce(0) { $0 + $1.weight * $1.outcome.residualStops }
        // Global prior is zero: with no evidence, films age as the group says.
        let groupDelta = groupWeight + groupPriorStrength > 0
            ? groupWeighted / (groupWeight + groupPriorStrength)
            : 0

        let filmWeight = filmPoints.reduce(0) { $0 + $1.weight }
        let filmResidual = filmPoints.reduce(0) { $0 + $1.weight * ($1.outcome.residualStops - groupDelta) }
        let filmDelta = groupDelta + (filmWeight + filmPriorStrength > 0
            ? filmResidual / (filmWeight + filmPriorStrength)
            : 0)

        let bounded = max(
            -ExpiryCalibrationAdjustment.maximumShiftStops,
            min(ExpiryCalibrationAdjustment.maximumShiftStops, filmDelta)
        )

        return Fit(
            deltaStops: bounded,
            filmDelta: filmDelta,
            groupDelta: groupDelta,
            filmObservations: filmPoints.count,
            groupObservations: groupPoints.count
        )
    }

    func adjustment(
        forFilm filmKey: String,
        group: ExpiryBehaviourGroup,
        points: [ExpiryCalibrationPoint]
    ) -> ExpiryCalibrationAdjustment {
        guard let fitted = fit(forFilm: filmKey, group: group, points: points) else {
            return .none
        }

        let loo = leaveOneOut(filmKey: filmKey, group: group, points: points)

        return ExpiryCalibrationAdjustment(
            deltaStops: fitted.deltaStops,
            filmDelta: fitted.filmDelta,
            groupDelta: fitted.groupDelta,
            filmObservations: fitted.filmObservations,
            groupObservations: fitted.groupObservations,
            leaveOneOutError: loo.error,
            leaveOneOutCount: loo.count
        )
    }

    /// Each observation is predicted from the others, never from itself. The
    /// held-out fits go through `fit` directly, so this is one pass over the
    /// rolls rather than a fit that re-validates inside every fold.
    func leaveOneOut(
        filmKey: String,
        group: ExpiryBehaviourGroup,
        points: [ExpiryCalibrationPoint]
    ) -> (error: Double, count: Int) {
        let own = points.filter { $0.filmKey == filmKey }
        guard own.count >= 2 else { return (0, 0) }

        var total = 0.0
        var count = 0
        for point in own {
            let remaining = points.filter { $0.id != point.id }
            let prediction = fit(forFilm: filmKey, group: group, points: remaining)?.deltaStops ?? 0
            total += abs(point.outcome.residualStops - prediction)
            count += 1
        }
        guard count > 0 else { return (0, 0) }
        return (total / Double(count), count)
    }
}

// MARK: - Store

/// Logged rolls, persisted as JSON in the app's defaults beside the other
/// preferences. Nothing here reaches the network.
final class ExpiryCalibrationStore: ObservableObject {
    static let shared = ExpiryCalibrationStore()

    @Published private(set) var points: [ExpiryCalibrationPoint]

    private static let key = "expiry.calibration.points"
    private let defaults: UserDefaults
    private let analyser = ExpiryCalibrationAnalyser()

    /// Observations gathered from the public record while the model was built.
    /// They inform the fitted behaviour and are never used for validation:
    /// leave-one-out runs over the reader's own rolls only.
    static let researchObservations: [ExpiryCalibrationPoint] = [
        ExpiryCalibrationPoint(
            id: "research-tmax-100-2009",
            filmKey: "kodak-t-max-100",
            group: .slowModernBW,
            ageYears: 15,
            storage: "Room temperature, sealed in its canister",
            exposureIndex: 100,
            quality: 4,
            evidence: .anecdotal,
            source: "Reported by the app's owner: a roll dated 2009, stored at room temperature, gave solid results at box speed.",
            notes: "A single anecdote. It supports T-Max 100 keeping well; it does not establish why, and it is weighed well below a measured series.",
            outcome: .good,
            recorded: Date(timeIntervalSince1970: 1_770_000_000)
        )
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([ExpiryCalibrationPoint].self, from: data) {
            points = decoded
        } else {
            points = []
        }
    }

    var allPoints: [ExpiryCalibrationPoint] { points + Self.researchObservations }

    /// Rolls are split by date: the most recent fifth is held out and never used
    /// for fitting, so the reported hold-out error is measured on data the fit
    /// has not seen. Fewer than five rolls cannot be split usefully, so
    /// everything fits and the hold-out error stays unknown rather than being
    /// quietly computed on the training data.
    static func split(
        _ points: [ExpiryCalibrationPoint]
    ) -> (fitting: [ExpiryCalibrationPoint], validation: [ExpiryCalibrationPoint]) {
        let sorted = points.sorted { $0.recorded < $1.recorded }
        guard sorted.count >= 5 else { return (sorted, []) }
        let held = max(1, sorted.count / 5)
        return (Array(sorted.dropLast(held)), Array(sorted.suffix(held)))
    }

    /// What the model is fitted on: the reader's older rolls, plus the
    /// observations from the public record.
    var fittingPoints: [ExpiryCalibrationPoint] {
        Self.split(points).fitting + Self.researchObservations
    }

    /// What it is checked against, and never fitted on.
    var holdoutPoints: [ExpiryCalibrationPoint] {
        Self.split(points).validation
    }

    func adjustment(filmKey: String, group: ExpiryBehaviourGroup) -> ExpiryCalibrationAdjustment {
        analyser.adjustment(forFilm: filmKey, group: group, points: fittingPoints)
    }

    func points(forFilm filmKey: String) -> [ExpiryCalibrationPoint] {
        points.filter { $0.filmKey == filmKey }
    }

    /// Per-film prediction error, how much data is behind it, and the error on
    /// the held-out rolls when there are enough of them to hold any back.
    func validation(
        filmKey: String,
        group: ExpiryBehaviourGroup
    ) -> (error: Double, count: Int, samples: Int, holdoutError: Double, holdoutCount: Int) {
        let fitSet = fittingPoints
        let loo = analyser.leaveOneOut(filmKey: filmKey, group: group, points: fitSet)

        let held = holdoutPoints.filter { $0.filmKey == filmKey }
        var holdoutError = 0.0
        if !held.isEmpty,
           let base = analyser.fit(forFilm: filmKey, group: group, points: fitSet)?.deltaStops {
            let total = held.reduce(0) { $0 + abs($1.outcome.residualStops - base) }
            holdoutError = total / Double(held.count)
        }

        return (loo.error, loo.count, points(forFilm: filmKey).count, holdoutError, held.count)
    }

    func add(_ point: ExpiryCalibrationPoint) {
        points.append(point)
        persist()
    }

    func remove(id: String) {
        points.removeAll { $0.id == id }
        persist()
    }

    func removeAll() {
        points.removeAll()
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(points) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

// MARK: - Running a calculation off the main thread

/// The thin seam between a screen and the engine: a fast synchronous answer and
/// a background full one.
enum ExpiryCalculator {
    /// Kept small enough that the fast path is instant on the main thread.
    static let quickEngine = ExpiryEngine(sampleCount: 1)
    /// Two thousand samples, run on a background task.
    static let fullEngine = ExpiryEngine(sampleCount: 2000)

    static func quick(
        _ request: ExpiryRequest,
        calibration: ExpiryCalibrationAdjustment = .none
    ) -> ExpiryEstimate {
        quickEngine.quickEstimate(request, calibration: calibration)
    }

    static func full(
        _ request: ExpiryRequest,
        calibration: ExpiryCalibrationAdjustment = .none
    ) async -> ExpiryEstimate {
        await Task.detached(priority: .userInitiated) {
            fullEngine.estimate(request, calibration: calibration)
        }
        .value
    }
}
