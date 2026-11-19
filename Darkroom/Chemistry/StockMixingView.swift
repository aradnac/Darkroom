//
//  StockMixingView.swift
//  Darkroom
//
//  How many working-strength sessions a bottle of stock will give, and how much
//  stock and water each of them uses.
//

import SwiftUI

struct StockMixingView: View {
    @State private var bottleMl: Double = 1000
    @State private var sessionMl: Double = 300
    @State private var ratio = MixRatio.presets[1]

    private var result: (count: Int, stockPerSession: Double, waterPerSession: Double, leftoverMl: Double) {
        ChemistryMath.sessions(bottleMl: bottleMl, sessionMl: sessionMl, ratio: ratio)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                bottleCard
                dilutionCard
                resultCard
                footnote
            }
            .padding(20)
        }
        .background {
            LiquidBackdrop()
        }
        .navigationTitle("Mixing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bottleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Stock bottle")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            Stepper(value: $bottleMl, in: 100...5000, step: 50) {
                LabeledContent("Bottle", value: Amount.ml(bottleMl))
            }

            HStack(spacing: 8) {
                ForEach([250.0, 500.0, 1000.0, 5000.0], id: \.self) { preset in
                    Button {
                        bottleMl = preset
                    } label: {
                        Text(preset >= 1000 ? "\(Int(preset / 1000)) L" : "\(Int(preset)) ml")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(abs(bottleMl - preset) < 0.5 ? Theme.amberInk : Theme.inkSoft)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background {
                                Capsule().fill(abs(bottleMl - preset) < 0.5
                                    ? AnyShapeStyle(Theme.amberGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.06)))
                            }
                            .overlay {
                                Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                            }
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }

            Stepper(value: $sessionMl, in: 100...1000, step: 25) {
                LabeledContent("Each session", value: Amount.ml(sessionMl))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private var dilutionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Dilution")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(ratio.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }

            RatioPicker(ratio: $ratio)

            Text(ratio.summary)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(result.count)")
                    .font(.figures(52, weight: .semibold))
                    .foregroundStyle(Theme.amber)
                Text(result.count == 1 ? "session" : "sessions")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.ink)
            }

            Text("of \(Amount.ml(sessionMl)) at \(ratio.label), from \(Amount.litres(bottleMl / 1000)) of stock.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            HStack(spacing: 0) {
                AmountReadout(label: "Stock each", value: Amount.ml(result.stockPerSession), tint: Theme.amber)
                AmountReadout(label: "Water each", value: Amount.ml(result.waterPerSession))
                AmountReadout(label: "Left over", value: Amount.ml(result.leftoverMl))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26, tint: Theme.amber)
    }

    private var footnote: some View {
        Text("Whole sessions only: the leftover is what is not enough for another full tank. Shelf life and capacity per bottle are set on the bottle itself, in the cupboard.")
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkFaint)
            .fixedSize(horizontal: false, vertical: true)
    }
}
