//
//  DevelopmentSimulatorView.swift
//  Darkroom
//
//  The simulator: a sandbox for seeing what a choice would do before the
//  chemistry is mixed. A film and developer, then dilution, temperature, time,
//  agitation and fixing on sliders; an example frame rendered at that setting;
//  the movement in contrast, density, grain and fog; a stop either side; and a
//  way to carry the setting straight into a session.
//
//  Only pairs the library documents a time for appear, because everything on
//  the screen is measured from that time.
//

import SwiftUI

// MARK: - Screen

struct DevelopmentSimulatorView: View {
    private static let catalog = DevelopmentSimulatorCatalog.pairs()

    private static let timeRange: ClosedRange<Double> = 60...2700
    private static let fixRange: ClosedRange<Double> = 60...1500

    @State private var pair: DevelopmentSimulatorPair?
    @State private var temperature: Double = 20
    @State private var seconds: Double = 600
    @State private var agitation: DevelopmentSimulatorAgitation = .standard
    @State private var fixSeconds: Double = DevelopmentSimulatorReading.recommendedFixSeconds
    @State private var rendered: DevelopmentSimulatorRender = .empty
    @State private var isRendering = false
    @State private var choosingPair = false
    @State private var savingSession: DevelopmentSimulatorSessionDraft?

    init() {
        let first = Self.catalog.first
        _pair = State(initialValue: first)
        _temperature = State(initialValue: first.map {
            min(DevelopmentSimulatorReading.maximumTemperature,
                max(DevelopmentSimulatorReading.minimumTemperature, $0.documentedCelsius))
        } ?? 20)
        _seconds = State(initialValue: first?.documentedSeconds ?? 600)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let pair {
                    pairChip(pair)
                    pictureCard
                    warningCards
                    dilutionRow
                    timeRow
                    temperatureRow
                    agitationRow
                    fixRow
                    stopsRow
                    saveButton(pair)
                    notes(pair)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 32)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Simulator")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $choosingPair) {
            DevelopmentSimulatorPairSheet(
                catalog: Self.catalog,
                selection: pair,
                onSelect: { apply($0) }
            )
        }
        .sheet(item: $savingSession) { draft in
            NavigationStack {
                SessionSetupView(
                    film: draft.film,
                    developer: draft.developer,
                    dilution: draft.dilution,
                    temperature: draft.temperature,
                    developmentSeconds: draft.seconds
                )
            }
        }
        .task(id: renderKey) { await render() }
    }

    // MARK: - State

    private var reading: DevelopmentSimulatorReading? {
        guard let pair else { return nil }
        return DevelopmentSimulatorReading(
            pair: pair,
            temperature: temperature,
            seconds: seconds,
            agitation: agitation,
            fixSeconds: fixSeconds,
            grainFactor: DevelopmentSimulatorCatalog.grainFactor(for: pair.film)
        )
    }

    /// The same film and developer at each dilution the library documents.
    private var dilutionOptions: [DevelopmentSimulatorPair] {
        guard let pair else { return [] }
        return Self.catalog.filter {
            $0.film.id == pair.film.id && $0.developer.id == pair.developer.id
        }
    }

    private var renderKey: String {
        guard let reading else { return "none" }
        return [
            reading.pair.id,
            "\(Int(reading.seconds))",
            "\(Int((reading.temperature * 10).rounded()))",
            reading.agitation.id,
            "\(Int(reading.fixSeconds))"
        ].joined(separator: "|")
    }

    private func apply(_ newPair: DevelopmentSimulatorPair) {
        let carried = pair == nil ? nil : temperature
        pair = newPair
        let celsius = carried ?? newPair.documentedCelsius
        temperature = min(
            DevelopmentSimulatorReading.maximumTemperature,
            max(DevelopmentSimulatorReading.minimumTemperature, celsius)
        )
        seconds = recommendedSeconds(for: newPair, at: temperature)
        Haptics.impact(.light)
    }

    private func recommendedSeconds(for pair: DevelopmentSimulatorPair, at celsius: Double) -> TimeInterval {
        DevelopmentTimeCalculator.calculate(
            nominalSeconds: pair.documentedSeconds,
            nominalCelsius: pair.documentedCelsius,
            actualCelsius: celsius,
            continuousAgitation: false
        ).seconds
    }

    private func resetToBaseline() {
        guard let pair else { return }
        temperature = min(
            DevelopmentSimulatorReading.maximumTemperature,
            max(DevelopmentSimulatorReading.minimumTemperature, pair.documentedCelsius)
        )
        seconds = pair.documentedSeconds
        agitation = .standard
        fixSeconds = DevelopmentSimulatorReading.recommendedFixSeconds
        Haptics.impact(.medium)
    }

    @MainActor
    private func render() async {
        guard let reading = self.reading else {
            rendered = .empty
            return
        }
        try? await Task.sleep(for: .milliseconds(40))
        guard !Task.isCancelled else { return }
        isRendering = true
        let images = DevelopmentSimulatorRenderer.render(reading: reading)
        guard !Task.isCancelled else {
            isRendering = false
            return
        }
        withAnimation(.easeOut(duration: 0.16)) {
            rendered = images
            isRendering = false
        }
    }

    // MARK: - Which pair

    private func pairChip(_ pair: DevelopmentSimulatorPair) -> some View {
        Button {
            choosingPair = true
        } label: {
            HStack(spacing: 7) {
                Text("\(pair.film.displayName) · \(pair.developer.name) \(pair.dilution.label)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassCard(radius: 99)
            .contentShape(Capsule())
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Film and developer: \(pair.film.fullName) in \(pair.developer.name) \(pair.dilution.label)")
        .accessibilityHint("Opens the film and developer list")
    }

    // MARK: - The example frame

    private var pictureCard: some View {
        VStack(spacing: 0) {
            ZStack {
                Theme.baseLift

                if let image = rendered.main {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isRendering {
                    ProgressView()
                        .tint(Theme.inkSoft)
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 26,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 26,
                    style: .continuous
                )
            )
            .accessibilityHidden(true)

            metricsStrip
        }
        .glassCard(radius: 26)
    }

    private var metricsStrip: some View {
        HStack(spacing: 0) {
            metric("Contrast", reading?.contrastText ?? "—")
            metricDivider
            metric("Density", reading?.densityText ?? "—")
            metricDivider
            metric("Grain", reading?.grainText ?? "—")
            metricDivider
            metric("Fog", reading?.fogText ?? "—")

            Spacer(minLength: 6)

            statePill
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.figures(13, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(width: 1, height: 24)
            .accessibilityHidden(true)
    }

    private var statePill: some View {
        let label = reading?.stateLabel ?? "Baseline"
        return Button {
            resetToBaseline()
        } label: {
            Text(label)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(Theme.amberInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background { Capsule().fill(Theme.amberGradient) }
        }
        .buttonStyle(HapticButtonStyle())
        .disabled(reading == nil)
        .accessibilityLabel("\(label). Reset to the published setting")
    }

    // MARK: - Warnings

    private var warningCards: some View {
        VStack(spacing: 8) {
            ForEach(warnings) { warning in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: warning.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(warning.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(warning.detail)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
                .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.42))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 1.0, green: 0.62, blue: 0.42).opacity(0.10))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(red: 1.0, green: 0.62, blue: 0.42).opacity(0.35), lineWidth: 1)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private struct SimulatorWarning: Identifiable {
        let id: String
        let symbol: String
        let title: String
        let detail: String
    }

    private var warnings: [SimulatorWarning] {
        guard let reading else { return [] }
        var result: [SimulatorWarning] = []
        let percent = Int(abs(reading.timeDeviationPercent).rounded())

        if reading.overDevelopment {
            result.append(
                SimulatorWarning(
                    id: "over",
                    symbol: "exclamationmark.triangle.fill",
                    title: "Over-development · \(reading.stopText)",
                    detail: "About \(percent)% past the published time. The highlights block up, contrast keeps climbing and the grain coarsens. Take that much back off the clock."
                )
            )
        }

        if reading.underDevelopment {
            result.append(
                SimulatorWarning(
                    id: "under",
                    symbol: "exclamationmark.triangle.fill",
                    title: "Under-development · \(reading.stopText)",
                    detail: "About \(percent)% short of the published time. The shadows stay empty, the negative prints flat and the separation in the midtones falls away. Add that much back."
                )
            )
        }

        if reading.overFixing {
            result.append(
                SimulatorWarning(
                    id: "fix",
                    symbol: "clock.badge.exclamationmark",
                    title: "Over-fixing",
                    detail: "Past three times the clearing time the fixer works on the image itself: density thins, the highlights lose separation and the wash takes longer. \(Clock.mmss(reading.fixSeconds)) is \(Clock.mmss(reading.fixSeconds - DevelopmentSimulatorReading.recommendedFixSeconds)) past the five-minute reference."
                )
            )
        }

        return result
    }

    // MARK: - Controls

    private var dilutionRow: some View {
        let options = dilutionOptions
        return DevelopmentSimulatorSliderRow(
            title: "Dilution",
            value: dilutionBinding(options),
            range: 0...Double(max(options.count - 1, 0)),
            step: 1,
            valueText: pair?.dilution.label ?? "—",
            note: options.count < 2 ? "One documented dilution" : nil,
            highlightsValue: false
        )
    }

    private func dilutionBinding(_ options: [DevelopmentSimulatorPair]) -> Binding<Double> {
        Binding(
            get: {
                guard let pair,
                      let index = options.firstIndex(where: { $0.id == pair.id }) else { return 0 }
                return Double(index)
            },
            set: { value in
                let index = min(max(Int(value.rounded()), 0), max(options.count - 1, 0))
                guard options.indices.contains(index) else { return }
                apply(options[index])
            }
        )
    }

    private var timeRow: some View {
        DevelopmentSimulatorSliderRow(
            title: "Development time",
            value: Binding(get: { seconds }, set: { seconds = $0 }),
            range: Self.timeRange,
            step: 15,
            marker: timeMarker,
            valueText: Clock.mmss(seconds),
            note: reading?.timeNote,
            highlightsValue: !(reading?.isTimeBaseline ?? true)
        )
    }

    private var timeMarker: Double? {
        guard let reading else { return nil }
        let span = Self.timeRange.upperBound - Self.timeRange.lowerBound
        guard span > 0 else { return nil }
        return min(max((reading.recommendedSeconds - Self.timeRange.lowerBound) / span, 0), 1)
    }

    private var temperatureRow: some View {
        DevelopmentSimulatorSliderRow(
            title: "Temperature",
            value: Binding(get: { temperature }, set: { temperature = $0 }),
            range: DevelopmentSimulatorReading.minimumTemperature...DevelopmentSimulatorReading.maximumTemperature,
            step: 0.5,
            valueText: Units.temperature(temperature),
            highlightsValue: false
        )
    }

    private var agitationRow: some View {
        DevelopmentSimulatorSliderRow(
            title: "Agitation",
            value: agitationBinding,
            range: 0...Double(DevelopmentSimulatorAgitation.all.count - 1),
            step: 1,
            valueText: agitation.label,
            highlightsValue: false
        )
    }

    private var agitationBinding: Binding<Double> {
        Binding(
            get: {
                let options = DevelopmentSimulatorAgitation.all
                let index = options.firstIndex(of: agitation) ?? 2
                return Double(index)
            },
            set: { value in
                let options = DevelopmentSimulatorAgitation.all
                let index = min(max(Int(value.rounded()), 0), options.count - 1)
                agitation = options[index]
            }
        )
    }

    private var fixRow: some View {
        DevelopmentSimulatorSliderRow(
            title: "Fix",
            value: Binding(get: { fixSeconds }, set: { fixSeconds = $0 }),
            range: Self.fixRange,
            step: 30,
            valueText: Clock.mmss(fixSeconds),
            note: fixNote,
            highlightsValue: reading?.overFixing ?? false
        )
    }

    private var fixNote: String? {
        guard let reading, reading.overFixing else { return nil }
        return "\(Int(((reading.fixSeconds - DevelopmentSimulatorReading.overFixThreshold) / 60).rounded())) min past"
    }

    // MARK: - A stop either side

    private var stopsRow: some View {
        HStack(alignment: .top, spacing: 10) {
            stopTile(caption: "−1 stop", image: rendered.minusOneStop, selected: false)
            stopTile(caption: "Selected", image: rendered.main, selected: true)
            stopTile(caption: "+1 stop", image: rendered.plusOneStop, selected: false)
        }
        .accessibilityElement(children: .contain)
    }

    private func stopTile(caption: String, image: CGImage?, selected: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.surfaceRaised)

                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        selected ? Theme.amber : Theme.border,
                        lineWidth: selected ? 1.6 : 1
                    )
            }
            .accessibilityHidden(true)

            Text(caption)
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Theme.amber : Theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
    }

    // MARK: - Session

    private func saveButton(_ pair: DevelopmentSimulatorPair) -> some View {
        Button {
            Haptics.impact(.medium)
            savingSession = DevelopmentSimulatorSessionDraft(
                film: pair.film,
                developer: pair.developer,
                dilution: pair.dilution,
                temperature: temperature,
                seconds: seconds
            )
        } label: {
            Text("Save as session")
        }
        .buttonStyle(AmberCapsuleStyle(height: 54))
        .padding(.top, 4)
        .accessibilityHint("Opens a new session with this setting")
    }

    private func notes(_ pair: DevelopmentSimulatorPair) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(baselineSentence(pair))
            Text("The picture is a model of the direction and rough size of each change, not a densitometer reading.")
        }
        .font(.system(size: 11))
        .foregroundStyle(Theme.inkFaint)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
    }

    private func baselineSentence(_ pair: DevelopmentSimulatorPair) -> String {
        let source = pair.sourceName.map { " from \($0)" } ?? ", not yet sourced"
        return "\(pair.film.fullName) in \(pair.developer.name) \(pair.dilution.label) — \(Clock.mmss(pair.documentedSeconds)) at \(Units.shortTemperature(pair.documentedCelsius))\(source)."
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Theme.inkSoft)

            Text("No documented times yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)

            Text("The simulator works from a published time, so it needs at least one black-and-white film and developer pair in the library. Import a chart or add a record to start.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }
}

// MARK: - Session draft

struct DevelopmentSimulatorSessionDraft: Identifiable {
    let id = UUID()
    let film: Film
    let developer: Developer
    let dilution: Dilution
    let temperature: Double
    let seconds: TimeInterval
}

// MARK: - A slider row

/// Label, a track with the published time marked on it, and the value in the
/// room's own metal. The filled part of the track is the accent; the knob is the
/// only thing that glows.
struct DevelopmentSimulatorSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0
    var marker: Double?
    let valueText: String
    var note: String?
    var highlightsValue: Bool = false

    @State private var isDragging = false

    private var clampedValue: Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private var fraction: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (clampedValue - range.lowerBound) / span
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 106, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                track

                if let note {
                    Text(note)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.amber)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            valueBadge
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .glassCard(radius: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(note.map { "\(valueText), \($0)" } ?? valueText)
        .accessibilityAdjustableAction { direction in
            let increment = step > 0 ? step : max(1, (range.upperBound - range.lowerBound) / 10)
            switch direction {
            case .increment:
                set(verbatim: min(range.upperBound, clampedValue + increment))
            case .decrement:
                set(verbatim: max(range.lowerBound, clampedValue - increment))
            default:
                break
            }
        }
    }

    private var track: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let knob: CGFloat = 26
            let usable = max(1, width - knob)
            let centre = knob / 2 + usable * fraction

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ink.opacity(0.14))
                    .frame(width: width, height: 5)

                Capsule()
                    .fill(Theme.amberGradient)
                    .frame(width: max(5, centre), height: 5)

                if let marker {
                    Capsule()
                        .fill(Theme.ink.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .offset(x: knob / 2 + usable * min(max(marker, 0), 1) - 1)
                }

                Circle()
                    .fill(Theme.amberGradient)
                    .frame(width: knob, height: knob)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                    }
                    .shadow(color: Theme.amber.opacity(isDragging ? 0.55 : 0.35), radius: isDragging ? 10 : 5)
                    .scaleEffect(isDragging ? 1.1 : 1)
                    .offset(x: centre - knob / 2)
            }
            .frame(height: 30)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        set(at: gesture.location.x, width: width, knob: knob)
                    }
                    .onEnded { _ in
                        isDragging = false
                        Haptics.impact(.light)
                    }
            )
        }
        .frame(height: 30)
        .animation(.easeOut(duration: 0.12), value: isDragging)
    }

    private var valueBadge: some View {
        Text(valueText)
            .font(.figures(14, weight: .semibold))
            .foregroundStyle(highlightsValue ? Theme.amber : Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, 8)
            .frame(minWidth: 56, minHeight: 33)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            }
    }

    // MARK: Changes

    private func set(at locationX: CGFloat, width: CGFloat, knob: CGFloat) {
        let usable = max(1, width - knob)
        let raw = Double((locationX - knob / 2) / usable)
        let clamped = min(max(raw, 0), 1)
        var candidate = range.lowerBound + (range.upperBound - range.lowerBound) * clamped

        if step > 0 {
            let steps = ((candidate - range.lowerBound) / step).rounded()
            candidate = range.lowerBound + steps * step
        }
        candidate = min(max(candidate, range.lowerBound), range.upperBound)

        let previousStep = step > 0 ? Int(((clampedValue - range.lowerBound) / step).rounded()) : 0
        let nextStep = step > 0 ? Int(((candidate - range.lowerBound) / step).rounded()) : 0

        isDragging = true
        guard abs(candidate - clampedValue) > 0.0001 else { return }
        value = candidate

        if step > 0, previousStep != nextStep {
            Haptics.impact(.light)
        }
    }

    private func set(verbatim newValue: Double) {
        guard abs(newValue - clampedValue) > 0.0001 else { return }
        value = newValue
        Haptics.impact(.light)
    }
}

// MARK: - Picking a pair

private struct DevelopmentSimulatorPairSheet: View {
    let catalog: [DevelopmentSimulatorPair]
    let selection: DevelopmentSimulatorPair?
    let onSelect: (DevelopmentSimulatorPair) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var filmID: String

    init(
        catalog: [DevelopmentSimulatorPair],
        selection: DevelopmentSimulatorPair?,
        onSelect: @escaping (DevelopmentSimulatorPair) -> Void
    ) {
        self.catalog = catalog
        self.selection = selection
        self.onSelect = onSelect
        _filmID = State(initialValue: selection?.film.id ?? catalog.first?.film.id ?? "")
    }

    private var films: [Film] {
        var seen: Set<String> = []
        var result: [Film] = []
        for pair in catalog where !seen.contains(pair.film.id) {
            seen.insert(pair.film.id)
            result.append(pair.film)
        }
        return result
    }

    private func pairs(forFilm id: String) -> [DevelopmentSimulatorPair] {
        catalog.filter { $0.film.id == id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Film") {
                    ForEach(films) { film in
                        Button {
                            filmID = film.id
                            if let first = pairs(forFilm: film.id).first {
                                onSelect(first)
                            }
                        } label: {
                            row(
                                title: film.fullName,
                                detail: "\(pairs(forFilm: film.id).count) documented \(pairs(forFilm: film.id).count == 1 ? "time" : "times")",
                                selected: film.id == filmID
                            )
                        }
                    }
                }

                Section("Developer") {
                    ForEach(pairs(forFilm: filmID)) { pair in
                        Button {
                            onSelect(pair)
                            dismiss()
                        } label: {
                            row(
                                title: "\(pair.developer.name) \(pair.dilution.label)",
                                detail: "\(Clock.mmss(pair.documentedSeconds)) at \(Units.shortTemperature(pair.documentedCelsius))",
                                selected: pair.id == selection?.id
                            )
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { LiquidBackdrop() }
            .navigationTitle("Film & developer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(title: String, detail: String, selected: Bool) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        DevelopmentSimulatorView()
    }
}
