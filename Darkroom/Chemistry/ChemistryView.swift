//
//  ChemistryView.swift
//  Darkroom
//
//  The dilution calculator, the two volume tools, and every bottle in the cupboard
//  with what is left in it.
//

import SwiftUI

struct ChemistryView: View {
    @State private var store = ChemistryStore.shared
    @State private var showingAdd = false

    @State private var totalMl: Double = 500
    @State private var ratio = MixRatio.presets[1]
    @State private var editingVolume = false

    private var split: (stockMl: Double, waterMl: Double) {
        ChemistryMath.split(totalMl: totalMl, ratio: ratio)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    dilutionCard
                    calculatorLinks
                    bottlesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background {
                LiquidBackdrop()
            }
            .appNavigationChrome(index: "03", title: "Chemistry") {
                AppBarButton(symbol: "plus", label: "Add a batch") {
                    showingAdd = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddBatchView()
            }
            .sheet(isPresented: $editingVolume) {
                AmountSheet(title: "Working volume", millilitres: $totalMl)
            }
        }
    }

    // MARK: - Dilution

    private var dilutionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Dilution")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(ratio.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }

            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        editingVolume = true
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Working volume")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.inkFaint)
                            Text(Amount.ml(totalMl))
                                .font(.figures(32, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .buttonStyle(HapticButtonStyle())

                    Slider(value: $totalMl, in: 50...2000, step: 10)
                        .tint(Theme.amber)

                    Text(ratio.summary)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VolumeGauge(
                    stockMl: split.stockMl,
                    waterMl: split.waterMl,
                    capacityMl: totalMl,
                    width: 66,
                    height: 150
                )
            }

            HStack(spacing: 0) {
                AmountReadout(label: "Stock", value: Amount.ml(split.stockMl), tint: Theme.amber)
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: 36)
                AmountReadout(label: "Water", value: Amount.ml(split.waterMl))
            }

            RatioPicker(ratio: $ratio)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26, tint: Theme.amber)
    }

    // MARK: - Calculators

    private var calculatorLinks: some View {
        HStack(spacing: 12) {
            NavigationLink {
                VolumeCalculatorView()
            } label: {
                calculatorCard(systemImage: "drop", title: "Volume", detail: "Tank and reels")
            }
            .buttonStyle(HapticButtonStyle())

            NavigationLink {
                StockMixingView()
            } label: {
                calculatorCard(systemImage: "flask", title: "Mixing", detail: "Stock bottles")
            }
            .buttonStyle(HapticButtonStyle())
        }
    }

    private func calculatorCard(systemImage: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Theme.amber)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(radius: 22)
    }

    // MARK: - Bottles

    private var bottlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bottles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    showingAdd = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(HapticButtonStyle())
                .foregroundStyle(Theme.amber)
            }

            if store.batches.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nothing in the cupboard yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Add a bottle to track how many rolls it can still do, when it expires, and how much each reuse lengthens the next development.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(radius: 24)
            } else {
                ForEach(store.batches) { batch in
                    NavigationLink {
                        BatchDetailView(batchID: batch.id)
                    } label: {
                        batchRow(batch)
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }
        }
    }

    private func batchRow(_ batch: ChemicalBatch) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(batch.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(batch.developer) · \(Amount.litres(batch.litres))")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(batch.remainingRolls)")
                        .font(.figures(22, weight: .semibold))
                        .foregroundStyle(batch.isExhausted ? Theme.inkFaint : Theme.amber)
                    Text("rolls left")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkFaint)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.leading, 4)
                    .padding(.top, 4)
            }

            HStack(spacing: 8) {
                pill(batch.rollsText)
                if let expiry = batch.expiryLabel {
                    pill(expiry, tint: batch.isExpired ? Theme.amber : Theme.inkSoft)
                }
                pill("used \(batch.useCount)×")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 22)
    }

    private func pill(_ text: String, tint: Color = Theme.inkSoft) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule().fill(Color.white.opacity(0.06))
            }
    }
}
