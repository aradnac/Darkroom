//
//  VolumeCalculatorView.swift
//  Darkroom
//
//  How much chemistry a tank and a reel count need, and how that volume splits into
//  stock and water at the chosen dilution.
//

import SwiftUI

/// Whether the figure you enter is for the whole tank or for each reel in it.
enum VolumeBasis: String, CaseIterable, Identifiable {
    case wholeTank
    case perReel

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wholeTank: return "The whole tank"
        case .perReel: return "Each reel"
        }
    }
}

struct VolumeCalculatorView: View {
    @State private var basis: VolumeBasis = .wholeTank
    @State private var enteredMl: Double = 500
    @State private var reels = 2
    @State private var ratio = MixRatio.presets[1]

    /// The working volume to mix: the whole tank at once, or the per-reel figure
    /// multiplied up for every reel loaded.
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                tankCard
                dilutionCard
                mixCard
                footnote
            }
            .padding(20)
        }
        .background {
            LiquidBackdrop()
        }
        .navigationTitle("Volume")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tankCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tank")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            Picker("Volume for", selection: $basis) {
                ForEach(VolumeBasis.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Stepper(value: $enteredMl, in: 50...2000, step: 10) {
                LabeledContent(basis == .wholeTank ? "Capacity" : "Per reel", value: Amount.ml(enteredMl))
            }

            Stepper(value: $reels, in: 1...4) {
                LabeledContent("Reels", value: "\(reels)")
            }

            HStack(spacing: 8) {
                ForEach([290.0, 500.0, 600.0, 1000.0], id: \.self) { preset in
                    Button {
                        enteredMl = preset
                    } label: {
                        Text("\(Int(preset))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(abs(enteredMl - preset) < 0.5 ? Theme.amberInk : Theme.inkSoft)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background {
                                Capsule().fill(abs(enteredMl - preset) < 0.5
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

    private var mixCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 18) {
                VolumeGauge(
                    stockMl: split.stockMl,
                    waterMl: split.waterMl,
                    capacityMl: totalMl,
                    width: 66,
                    height: 150
                )

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    AmountReadout(label: "To mix", value: Amount.ml(totalMl))
                    AmountReadout(label: "Stock", value: Amount.ml(split.stockMl), tint: Theme.amber)
                    AmountReadout(label: "Water", value: Amount.ml(split.waterMl))
                }
                .frame(width: 112)
            }

            Text(coverageSentence)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26, tint: Theme.amber)
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

    private var footnote: some View {
        Text("Use the figure moulded on your own tank for the number of reels inside it. Tanks differ, so check the mark before you pour.")
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkFaint)
            .fixedSize(horizontal: false, vertical: true)
    }
}
