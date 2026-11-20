//
//  RedroomChemistryScreens.swift
//  Darkroom
//
//  The Chemistry bench in REDROOM. The dilution is mixed in a glass vessel whose
//  two layers are the stock and the water; every bottle in the cupboard is drawn
//  as the bottle it is, filled to the level that is actually left in it.
//
//  The sums are ChemistryMath's and ChemicalBatch's, unchanged.
//

import SwiftUI

// MARK: - Tab

struct RedroomChemistryTab: View {
    var body: some View {
        NavigationStack {
            RedroomChemistryHome()
        }
    }
}

// MARK: - Home

struct RedroomChemistryHome: View {
    @State private var store = ChemistryStore.shared
    @State private var showingAdd = false

    @State private var totalMl: Double = 500
    @State private var ratio = MixRatio.presets[1]
    @State private var editingVolume = false

    private var split: (stockMl: Double, waterMl: Double) {
        ChemistryMath.split(totalMl: totalMl, ratio: ratio)
    }

    var body: some View {
        RedroomScreen {
            RedroomScreenHeader(
                kicker: "In the cupboard",
                title: "Chemistry",
                actionSymbol: "plus",
                actionLabel: "Add a batch",
                action: { showingAdd = true }
            )
            .redroomReveal(.safelightFade)

            dilutionPanel

            calculators

            bottlesSection
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) {
            RedroomAddBatch()
        }
        .sheet(isPresented: $editingVolume) {
            RedroomAmountSheet(title: "Working volume", millilitres: $totalMl)
        }
    }

    // MARK: Dilution

    private var dilutionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                RedroomLabel("Working solution")
                Spacer(minLength: 6)
                Text(ratio.label)
                    .font(Redroom.figure(14, weight: .semibold))
                    .foregroundStyle(Redroom.text)
            }

            HStack(alignment: .center, spacing: 16) {
                Button {
                    editingVolume = true
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Working volume")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                        Text(Amount.ml(totalMl))
                            .font(Redroom.figure(28, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                            .contentTransition(.numericText())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityLabel("Working volume")
                .accessibilityValue(Amount.ml(totalMl))

                Spacer(minLength: 0)

                RedroomMixtureVessel(
                    stockMl: split.stockMl,
                    waterMl: split.waterMl,
                    capacityMl: totalMl
                )
                .frame(width: 58, height: 132)
            }

            RedroomValueRow(label: "Stock", value: Amount.ml(split.stockMl))
            RedroomValueRow(label: "Water", value: Amount.ml(split.waterMl))

            RedroomRatioPicker(ratio: $ratio)

            RedroomNote(text: "Use the figure moulded on your own tank. The split above is what that volume needs at \(ratio.label).")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .optical, cornerRadius: RedroomMetrics.cardRadius)
    }

    // MARK: Calculators

    private var calculators: some View {
        HStack(spacing: 10) {
            NavigationLink {
                RedroomVolumeCalculator()
            } label: {
                calculatorTile(symbol: "drop", title: "Volume", detail: "Tank and reels")
            }
            .buttonStyle(HapticButtonStyle())

            NavigationLink {
                RedroomStockMixing()
            } label: {
                calculatorTile(symbol: "flask", title: "Mixing", detail: "Stock bottles")
            }
            .buttonStyle(HapticButtonStyle())
        }
    }

    private func calculatorTile(symbol: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Redroom.safelight)

            Text(title)
                .font(Redroom.body(15, weight: .semibold))
                .foregroundStyle(Redroom.text)

            Text(detail)
                .font(Redroom.body(11))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 20)
    }

    // MARK: Bottles

    private var bottlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bottles")
                    .font(Redroom.display(18, weight: .semibold))
                    .foregroundStyle(Redroom.text)

                Spacer(minLength: 6)

                Button {
                    showingAdd = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(Redroom.body(13, weight: .semibold))
                        .foregroundStyle(Redroom.safelight)
                }
                .buttonStyle(HapticButtonStyle())
            }

            if store.batches.isEmpty {
                RedroomEmptyState(
                    title: "Nothing in the cupboard yet",
                    detail: "Add a bottle to track how many rolls it can still do, when it expires, and how much each reuse lengthens the next development.",
                    symbol: "flask"
                )
            } else {
                ForEach(store.batches) { batch in
                    NavigationLink {
                        RedroomBatchDetail(batchID: batch.id)
                    } label: {
                        ChemicalBottle(
                            name: batch.name,
                            detail: "\(batch.developer) · \(Amount.litres(batch.litres)) · \(batch.rollsText) · used \(batch.useCount)×",
                            level: level(for: batch),
                            warning: batch.isExpired || batch.isExhausted
                        )
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }
        }
    }

    /// The bottle is as full as the rolls it can still develop.
    private func level(for batch: ChemicalBatch) -> Double {
        RedroomQuantities.bottleLevel(remaining: batch.remainingRolls, capacity: batch.capacityRolls)
    }
}

// MARK: - Mixture vessel

/// A glass beaker holding the working solution: the stock in deep red at the
/// foot, the water above it, both lit from the safelight's side of the glass.
struct RedroomMixtureVessel: View {
    let stockMl: Double
    let waterMl: Double
    let capacityMl: Double

    @Environment(\.redroomLight) private var light
    @State private var frame: CGRect = .zero

    private var total: Double { max(stockMl + waterMl, 0.001) }
    private var fill: Double {
        guard capacityMl > 0 else { return 0 }
        return min(1, max(0, total / capacityMl))
    }

    var body: some View {
        let sample = RedroomLightSample.make(frame: frame, light: light)

        GeometryReader { proxy in
            let liquidHeight = proxy.size.height * fill
            let stockHeight = liquidHeight * (stockMl / total)
            let waterHeight = liquidHeight * (waterMl / total)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Redroom.color(0x0B0404).opacity(0.9))

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Redroom.color(0x3A1212),
                                    Redroom.color(0x22090B)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: waterHeight)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Redroom.safelightSecondary.opacity(0.85),
                                    Redroom.deepRed
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: stockHeight)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Rectangle()
                    .fill(Redroom.safelight.opacity(0.55 * sample.direct))
                    .frame(height: 1.5)
                    .offset(y: -liquidHeight)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Redroom.safelight.opacity(0.55 * sample.direct + 0.06),
                                Redroom.deepRed.opacity(0.35)
                            ],
                            startPoint: sample.start,
                            endPoint: sample.end
                        ),
                        lineWidth: 1.2
                    )
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { value in
                frame = value
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Working solution")
        .accessibilityValue("\(Amount.ml(stockMl)) stock, \(Amount.ml(waterMl)) water")
    }
}

// MARK: - Ratio picker

struct RedroomRatioPicker: View {
    @Binding var ratio: MixRatio

    @State private var showingCustom = false
    @State private var customStock: Double = 1
    @State private var customWater: Double = 7

    private var customRatio: MixRatio {
        MixRatio(id: "custom", stockParts: customStock, waterParts: customWater)
    }

    private var isCustom: Bool { ratio.id == "custom" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(MixRatio.presets) { preset in
                        Button {
                            Haptics.impact(.light)
                            ratio = preset
                            showingCustom = false
                        } label: {
                            RedroomChip(text: preset.label, emphasised: ratio.id == preset.id)
                        }
                        .buttonStyle(HapticButtonStyle())
                        .accessibilityAddTraits(ratio.id == preset.id ? .isSelected : [])
                    }

                    Button {
                        showingCustom = true
                        ratio = customRatio
                    } label: {
                        RedroomChip(
                            text: isCustom ? customRatio.label : "Custom",
                            emphasised: isCustom
                        )
                    }
                    .buttonStyle(HapticButtonStyle())
                    .accessibilityAddTraits(isCustom ? .isSelected : [])
                }
                .padding(.vertical, 1)
            }

            if showingCustom {
                RedroomStepper(
                    title: "Parts stock",
                    value: MixRatio.number(customStock),
                    decrement: customStock > 1 ? { customStock -= 1; ratio = customRatio } : nil,
                    increment: customStock < 10 ? { customStock += 1; ratio = customRatio } : nil
                )

                RedroomStepper(
                    title: "Parts water",
                    value: MixRatio.number(customWater),
                    decrement: customWater > 1 ? { customWater -= 1; ratio = customRatio } : nil,
                    increment: customWater < 200 ? { customWater += 1; ratio = customRatio } : nil
                )
            }

            Text(ratio.summary)
                .font(Redroom.body(11))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Volume calculator

struct RedroomVolumeCalculator: View {
    @State private var basis: VolumeBasis = .wholeTank
    @State private var enteredMl: Double = 500
    @State private var reels = 2
    @State private var ratio = MixRatio.presets[1]

    private var totalMl: Double {
        switch basis {
        case .wholeTank: return enteredMl
        case .perReel: return enteredMl * Double(reels)
        }
    }

    private var split: (stockMl: Double, waterMl: Double) {
        ChemistryMath.split(totalMl: totalMl, ratio: ratio)
    }

    var body: some View {
        RedroomScreen {
            RedroomPanel(title: "Tank") {
                RedroomSegmented(
                    items: VolumeBasis.allCases,
                    selection: $basis,
                    title: { $0.label }
                )

                RedroomStepper(
                    title: basis == .wholeTank ? "Capacity" : "Per reel",
                    value: Amount.ml(enteredMl),
                    decrement: enteredMl > 50 ? { enteredMl -= 10 } : nil,
                    increment: enteredMl < 2000 ? { enteredMl += 10 } : nil
                )

                RedroomStepper(
                    title: "Reels",
                    value: "\(reels)",
                    decrement: reels > 1 ? { reels -= 1 } : nil,
                    increment: reels < 4 ? { reels += 1 } : nil
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach([290.0, 500.0, 600.0, 1000.0], id: \.self) { preset in
                            Button {
                                enteredMl = preset
                            } label: {
                                RedroomChip(
                                    text: "\(Int(preset))",
                                    emphasised: abs(enteredMl - preset) < 0.5
                                )
                            }
                            .buttonStyle(HapticButtonStyle())
                        }
                    }
                    .padding(.vertical, 1)
                }
            }

            RedroomPanel(title: "Dilution") {
                RedroomRatioPicker(ratio: $ratio)
            }

            RedroomPanel(title: "To mix", variant: .optical) {
                HStack(alignment: .center, spacing: 16) {
                    RedroomMixtureVessel(
                        stockMl: split.stockMl,
                        waterMl: split.waterMl,
                        capacityMl: totalMl
                    )
                    .frame(width: 58, height: 132)

                    VStack(alignment: .leading, spacing: 6) {
                        RedroomValueRow(label: "To mix", value: Amount.ml(totalMl))
                        RedroomValueRow(label: "Stock", value: Amount.ml(split.stockMl))
                        RedroomValueRow(label: "Water", value: Amount.ml(split.waterMl))
                    }
                }

                Text(coverageSentence)
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            RedroomNote(text: "Use the figure moulded on your own tank for the number of reels inside it. Tanks differ, so check the mark before you pour.")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Chemistry", title: "Volume")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var coverageSentence: String {
        let rolls = reels == 1 ? "one reel" : "\(reels) reels"
        switch basis {
        case .wholeTank:
            return "One fill of \(Amount.ml(totalMl)) covers \(rolls). The split above is what that volume needs at \(ratio.label)."
        case .perReel:
            return "\(rolls.capitalized) at \(Amount.ml(enteredMl)) each — make up \(Amount.ml(totalMl)) in total at \(ratio.label)."
        }
    }
}

// MARK: - Stock mixing

struct RedroomStockMixing: View {
    @State private var bottleMl: Double = 1000
    @State private var sessionMl: Double = 300
    @State private var ratio = MixRatio.presets[1]

    private var result: (count: Int, stockPerSession: Double, waterPerSession: Double, leftoverMl: Double) {
        ChemistryMath.sessions(bottleMl: bottleMl, sessionMl: sessionMl, ratio: ratio)
    }

    var body: some View {
        RedroomScreen {
            RedroomPanel(title: "Stock bottle") {
                RedroomStepper(
                    title: "Bottle",
                    value: Amount.ml(bottleMl),
                    decrement: bottleMl > 100 ? { bottleMl -= 50 } : nil,
                    increment: bottleMl < 5000 ? { bottleMl += 50 } : nil
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach([250.0, 500.0, 1000.0, 5000.0], id: \.self) { preset in
                            Button {
                                bottleMl = preset
                            } label: {
                                RedroomChip(
                                    text: preset >= 1000 ? Units.litres(preset / 1000) : Units.volume(millilitres: preset),
                                    emphasised: abs(bottleMl - preset) < 0.5
                                )
                            }
                            .buttonStyle(HapticButtonStyle())
                        }
                    }
                    .padding(.vertical, 1)
                }

                RedroomStepper(
                    title: "Each session",
                    value: Amount.ml(sessionMl),
                    decrement: sessionMl > 100 ? { sessionMl -= 25 } : nil,
                    increment: sessionMl < 1000 ? { sessionMl += 25 } : nil
                )
            }

            RedroomPanel(title: "Dilution") {
                RedroomRatioPicker(ratio: $ratio)
            }

            RedroomPanel(title: "From this bottle", variant: .optical) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(result.count)")
                        .font(Redroom.figure(48, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                        .contentTransition(.numericText())
                    Text(result.count == 1 ? "session" : "sessions")
                        .font(Redroom.body(16, weight: .medium))
                        .foregroundStyle(Redroom.textMuted)
                }

                Text("of \(Amount.ml(sessionMl)) at \(ratio.label), from \(Amount.litres(bottleMl / 1000)) of stock.")
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                RedroomLitRule(thickness: 0.5)

                RedroomValueRow(label: "Stock each", value: Amount.ml(result.stockPerSession))
                RedroomValueRow(label: "Water each", value: Amount.ml(result.waterPerSession))
                RedroomValueRow(label: "Left over", value: Amount.ml(result.leftoverMl))
            }

            RedroomNote(text: "Whole sessions only: the leftover is what is not enough for another full tank. Shelf life and capacity per bottle are set on the bottle itself, in the cupboard.")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Chemistry", title: "Mixing")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Batch detail

struct RedroomBatchDetail: View {
    let batchID: UUID

    @State private var store = ChemistryStore.shared
    @State private var loggingUse = false
    @State private var showingActions = false
    @State private var editing = false
    @State private var confirmingDelete = false
    @State private var editingBaseTime = false
    @State private var baseSeconds = 600

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let batch = store.batch(batchID) {
                content(batch)
            } else {
                RedroomScreen {
                    RedroomEmptyState(
                        title: "This bottle has been removed",
                        detail: "It is no longer in the cupboard.",
                        symbol: "flask"
                    )
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(
                kicker: "Chemistry",
                title: store.batch(batchID)?.name ?? "Bottle",
                actionSymbol: "ellipsis",
                actionLabel: "Bottle actions",
                action: { showingActions = true }
            )
            .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("This bottle", isPresented: $showingActions, titleVisibility: .visible) {
            Button("Edit") {
                editing = true
            }
            Button("Delete", role: .destructive) {
                confirmingDelete = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete this bottle?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.delete(batchID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $editing) {
            if let batch = store.batch(batchID) {
                RedroomAddBatch(existing: batch)
            }
        }
        .sheet(isPresented: $loggingUse) {
            if let batch = store.batch(batchID) {
                RedroomLogUseSheet(batchName: batch.name) { rolls, note in
                    store.logUse(rolls: rolls, note: note, for: batchID)
                }
            }
        }
        .sheet(isPresented: $editingBaseTime) {
            RedroomDurationSheet(title: "Base time", seconds: $baseSeconds)
        }
    }

    private func content(_ batch: ChemicalBatch) -> some View {
        RedroomScreen {
            summary(batch)
            nextUse(batch)
            ledger(batch)
        }
    }

    // MARK: Summary

    private func summary(_ batch: ChemicalBatch) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                GeometryReader { proxy in
                    ChemicalBottleShape(level: level(batch), warning: batch.isExpired || batch.isExhausted)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .frame(width: 54, height: 92)

                VStack(alignment: .leading, spacing: 4) {
                    Text(batch.developer)
                        .font(Redroom.body(13))
                        .foregroundStyle(Redroom.textMuted)
                    Text(batch.isReusable ? "Reusable" : "One-shot")
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.textMuted)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(batch.remainingRolls)")
                        .font(Redroom.figure(38, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                    Text("of \(batch.capacityRolls) rolls")
                        .font(Redroom.body(10))
                        .foregroundStyle(Redroom.textMuted)
                }
            }

            RedroomLitRule()

            RedroomValueRow(label: "Bottle", value: Amount.litres(batch.litres))
            RedroomValueRow(label: "Mixed on", value: batch.mixedOn.formatted(.dateTime.day().month(.abbreviated).year()))
            RedroomValueRow(label: "Keeps", value: batch.expiryLabel ?? "no limit set")
            RedroomValueRow(label: "Has developed", value: batch.rollsText)
            RedroomValueRow(label: "Uses", value: "\(batch.useCount)")

            if batch.isExpired {
                RedroomWarning(
                    title: "Past its shelf life",
                    detail: "This bottle was mixed on \(batch.mixedOn.formatted(.dateTime.day().month(.abbreviated).year())). Its keeping date has passed."
                )
            } else if batch.isExhausted {
                RedroomWarning(
                    title: "Exhausted",
                    detail: "It has developed its full capacity of \(batch.capacityRolls) rolls. Mix a fresh one before the next session."
                )
            }

            if !batch.notes.isEmpty {
                RedroomNote(text: batch.notes, symbol: "note.text")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .optical, cornerRadius: RedroomMetrics.cardRadius)
    }

    private func level(_ batch: ChemicalBatch) -> Double {
        RedroomQuantities.bottleLevel(remaining: batch.remainingRolls, capacity: batch.capacityRolls)
    }

    // MARK: Next use

    private func nextUse(_ batch: ChemicalBatch) -> some View {
        RedroomPanel(title: "Next use") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(batch.nextUsePenaltyText)
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 6)

                Text("Use \(batch.nextUseNumber)")
                    .font(Redroom.figure(14, weight: .semibold))
                    .foregroundStyle(Redroom.text)
            }

            if batch.isReusable {
                RedroomLitRule(thickness: 0.5)

                HStack(alignment: .center, spacing: 10) {
                    Button {
                        editingBaseTime = true
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("On a base time of")
                                .font(Redroom.body(10))
                                .foregroundStyle(Redroom.textMuted)
                            Text(Clock.mmss(TimeInterval(baseSeconds)))
                                .font(Redroom.figure(18, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("This use")
                            .font(Redroom.body(10))
                            .foregroundStyle(Redroom.textMuted)
                        Text(Clock.mmss(Double(baseSeconds) * batch.nextUseFactor))
                            .font(Redroom.figure(18, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                    }
                }
            }
        }
    }

    // MARK: Ledger

    private func ledger(_ batch: ChemicalBatch) -> some View {
        RedroomPanel(
            title: "Ledger",
            detail: "\(batch.rollsDeveloped) rolls in \(batch.useCount) \(batch.useCount == 1 ? "use" : "uses")"
        ) {
            if batch.uses.isEmpty {
                Text("Nothing logged yet.")
                    .font(Redroom.body(13))
                    .foregroundStyle(Redroom.textMuted)
            } else {
                ForEach(Array(batch.uses.reversed().enumerated()), id: \.offset) { _, use in
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(use.date.formatted(.dateTime.day().month(.abbreviated).year()))
                                .font(Redroom.body(13, weight: .medium))
                                .foregroundStyle(Redroom.text)
                            if !use.note.isEmpty {
                                Text(use.note)
                                    .font(Redroom.body(11))
                                    .foregroundStyle(Redroom.textMuted)
                            }
                        }

                        Spacer(minLength: 6)

                        Text("\(use.rolls) \(use.rolls == 1 ? "roll" : "rolls")")
                            .font(Redroom.figure(12, weight: .medium))
                            .foregroundStyle(Redroom.textMuted)
                    }
                    .padding(.vertical, 3)
                }
            }

            Button {
                loggingUse = true
            } label: {
                Text("Log a use")
            }
            .buttonStyle(RedroomSecondaryButtonStyle())
        }
    }
}

// MARK: - Bottle shape

/// The bottle itself, at the size it is drawn on a card.
struct ChemicalBottleShape: View {
    let level: Double
    var warning: Bool = false

    private var clamped: Double { min(max(level, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let liquidHeight = max(4, height * 0.78 * clamped)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Redroom.color(0x0E0505).opacity(0.9))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Redroom.textDisabled.opacity(0.55), lineWidth: 1)
                    }

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Redroom.safelightSecondary.opacity(0.55),
                                Redroom.deepRed.opacity(0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: liquidHeight)
                    .padding(.horizontal, 3)
                    .padding(.bottom, 3)

                Capsule()
                    .fill(Redroom.safelight.opacity(0.7))
                    .frame(height: 2)
                    .padding(.horizontal, 6)
                    .offset(y: -(liquidHeight) - 1)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Redroom.color(0x120606))
                    .frame(width: width * 0.36, height: height * 0.16)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
                    }
                    .offset(y: -height * 0.82)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Add batch

struct RedroomAddBatch: View {
    var existing: ChemicalBatch?

    @Environment(\.dismiss) private var dismiss
    @State private var store = ChemistryStore.shared

    @State private var name: String
    @State private var developer: String
    @State private var litres: Double
    @State private var mixedOn: Date
    @State private var hasShelfLife: Bool
    @State private var shelfLifeMonths: Int
    @State private var capacityRolls: Int
    @State private var isReusable: Bool
    @State private var notes: String

    init(existing: ChemicalBatch? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _developer = State(initialValue: existing?.developer ?? "")
        _litres = State(initialValue: existing?.litres ?? 1)
        _mixedOn = State(initialValue: existing?.mixedOn ?? Date())
        _hasShelfLife = State(initialValue: (existing?.shelfLifeMonths ?? 0) > 0)
        _shelfLifeMonths = State(initialValue: existing?.shelfLifeMonths ?? 6)
        _capacityRolls = State(initialValue: existing?.capacityRolls ?? 16)
        _isReusable = State(initialValue: existing?.isReusable ?? true)
        _notes = State(initialValue: existing?.notes ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !developer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        RedroomSheetBody(
            kicker: existing == nil ? "A fresh bottle" : "The bottle as it is",
            title: existing == nil ? "New bottle" : "Edit bottle",
            detail: "Take the roll capacity from the developer's own datasheet.",
            confirmTitle: "Save",
            onConfirm: { save() }
        ) {
            RedroomPanel(title: "On the label") {
                field("Name", text: $name, prompt: "D-76 stock, 1 L")
                field("Developer", text: $developer, prompt: "Kodak D-76")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.textMuted)
                    TextField("Optional", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(Redroom.body(14))
                        .foregroundStyle(Redroom.text)
                        .tint(Redroom.safelight)
                        .lineLimit(2...5)
                        .padding(11)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Redroom.color(0x0D0505))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
                        }
                }
            }

            RedroomPanel(title: "Keeping") {
                RedroomStepper(
                    title: "Bottle",
                    value: Amount.litres(litres),
                    decrement: litres > 0.25 ? { litres -= 0.25 } : nil,
                    increment: litres < 5 ? { litres += 0.25 } : nil
                )

                RedroomStepper(
                    title: "Mixed on",
                    value: mixedOn.formatted(.dateTime.day().month(.abbreviated)),
                    decrement: { mixedOn = Calendar.current.date(byAdding: .day, value: -1, to: mixedOn) ?? mixedOn },
                    increment: {
                        let next = Calendar.current.date(byAdding: .day, value: 1, to: mixedOn) ?? mixedOn
                        mixedOn = min(next, Date())
                    }
                )

                Toggle("Has a shelf life", isOn: $hasShelfLife)
                    .font(Redroom.body(14))
                    .toggleStyle(RedroomToggleStyle())

                if hasShelfLife {
                    RedroomStepper(
                        title: "Shelf life",
                        value: "\(shelfLifeMonths) months",
                        decrement: shelfLifeMonths > 1 ? { shelfLifeMonths -= 1 } : nil,
                        increment: shelfLifeMonths < 60 ? { shelfLifeMonths += 1 } : nil
                    )
                }
            }

            RedroomPanel(title: "Capacity") {
                RedroomStepper(
                    title: "Rolls per batch",
                    value: "\(capacityRolls)",
                    decrement: capacityRolls > 1 ? { capacityRolls -= 1 } : nil,
                    increment: capacityRolls < 100 ? { capacityRolls += 1 } : nil
                )

                Toggle("Can be reused", isOn: $isReusable)
                    .font(Redroom.body(14))
                    .toggleStyle(RedroomToggleStyle())

                RedroomNote(text: "Each logged use is counted against the capacity, and each reuse adds 10%, compounded, to the next development.")
            }

            if !isValid {
                RedroomWarning(
                    title: "A name and a developer are needed",
                    detail: "Both are printed on the bottle, so both are asked for here."
                )
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Redroom.body(11))
                .foregroundStyle(Redroom.textMuted)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(Redroom.body(14))
                .foregroundStyle(Redroom.text)
                .tint(Redroom.safelight)
                .padding(11)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Redroom.color(0x0D0505))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
                }
        }
    }

    private func save() {
        guard isValid else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDeveloper = developer.trimmingCharacters(in: .whitespacesAndNewlines)
        let months: Int? = hasShelfLife ? shelfLifeMonths : nil

        if var batch = existing {
            batch.name = trimmedName
            batch.developer = trimmedDeveloper
            batch.litres = litres
            batch.mixedOn = mixedOn
            batch.shelfLifeMonths = months
            batch.capacityRolls = capacityRolls
            batch.isReusable = isReusable
            batch.notes = notes
            store.update(batch)
        } else {
            store.add(ChemicalBatch(
                name: trimmedName,
                developer: trimmedDeveloper,
                litres: litres,
                mixedOn: mixedOn,
                shelfLifeMonths: months,
                capacityRolls: capacityRolls,
                isReusable: isReusable,
                notes: notes
            ))
        }

        dismiss()
    }
}

// MARK: - Log use

struct RedroomLogUseSheet: View {
    let batchName: String
    let onSave: (Int, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rolls = 1
    @State private var note = ""

    var body: some View {
        RedroomSheetBody(
            kicker: batchName,
            title: "Log a use",
            detail: "What this bottle did today.",
            confirmTitle: "Save",
            onConfirm: {
                onSave(rolls, note)
                dismiss()
            }
        ) {
            RedroomPanel {
                RedroomStepper(
                    title: "Rolls developed",
                    value: "\(rolls)",
                    decrement: rolls > 1 ? { rolls -= 1 } : nil,
                    increment: rolls < 10 ? { rolls += 1 } : nil
                )

                TextField("Note, optional", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Redroom.body(14))
                    .foregroundStyle(Redroom.text)
                    .tint(Redroom.safelight)
                    .lineLimit(2...4)
                    .padding(11)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Redroom.color(0x0D0505))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
                    }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Amount sheet

/// A volume set on a dial.
struct RedroomAmountSheet: View {
    let title: String
    @Binding var millilitres: Double

    @Environment(\.dismiss) private var dismiss

    private var binding: Binding<Double> {
        Binding(
            get: { millilitres },
            set: { millilitres = ($0 / 10).rounded() * 10 }
        )
    }

    var body: some View {
        RedroomSheetBody(
            kicker: "Chemistry",
            title: title,
            confirmTitle: "Done",
            onConfirm: { dismiss() }
        ) {
            RedroomRotaryDial(
                title: title,
                value: binding,
                range: 0...2000,
                step: 10,
                format: { Amount.ml($0) },
                diameter: 176
            )
            .frame(maxWidth: .infinity)

            RedroomPanel {
                RedroomValueRow(label: "Volume", value: Amount.ml(millilitres), emphasised: true)
            }
        }
        .presentationDetents([.medium])
    }
}
