//
//  ChemistryControls.swift
//  Darkroom
//
//  The two pieces the calculators share: a vessel that shows how a volume splits,
//  and the ratio chips.
//

import SwiftUI

struct VolumeGauge: View {
    let stockMl: Double
    let waterMl: Double
    let capacityMl: Double
    var width: CGFloat = 66
    var height: CGFloat = 156

    private var total: Double { max(stockMl + waterMl, 0.001) }

    private var fillFraction: Double {
        guard capacityMl > 0 else { return 0 }
        return min(1, max(0, total / capacityMl))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.035))

            GeometryReader { proxy in
                let liquidHeight = proxy.size.height * fillFraction
                let stockHeight = liquidHeight * (stockMl / total)
                let waterHeight = liquidHeight * (waterMl / total)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: waterHeight)
                    Rectangle()
                        .fill(Theme.amberGradient)
                        .frame(height: stockHeight)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        }
        .frame(width: width, height: height)
    }
}

struct RatioPicker: View {
    @Binding var ratio: MixRatio

    @State private var showingCustom = false
    @State private var customStock: Double = 1
    @State private var customWater: Double = 7

    private var customRatio: MixRatio {
        MixRatio(id: "custom", stockParts: customStock, waterParts: customWater)
    }

    private var isCustom: Bool { ratio.id == "custom" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MixRatio.presets) { preset in
                        chip(preset.label, selected: ratio.id == preset.id) {
                            ratio = preset
                            showingCustom = false
                        }
                    }

                    chip(isCustom ? customRatio.label : "Custom", selected: isCustom) {
                        showingCustom = true
                        ratio = customRatio
                    }
                }
            }

            if showingCustom {
                VStack(spacing: 10) {
                    Stepper(value: $customStock, in: 1...10, step: 1) {
                        LabeledContent("Parts stock", value: MixRatio.number(customStock))
                    }
                    Stepper(value: $customWater, in: 1...200, step: 1) {
                        LabeledContent("Parts water", value: MixRatio.number(customWater))
                    }
                }
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .onChange(of: customStock) { _, _ in ratio = customRatio }
                .onChange(of: customWater) { _, _ in ratio = customRatio }
            }
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(selected ? Theme.amberInk : Theme.inkSoft)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background {
                    Capsule().fill(selected
                        ? AnyShapeStyle(Theme.amberGradient)
                        : AnyShapeStyle(Color.white.opacity(0.06)))
                }
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
        }
        .buttonStyle(HapticButtonStyle())
    }
}

/// A small readout used by both calculators.
struct AmountReadout: View {
    let label: String
    let value: String
    var tint: Color = Theme.ink

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
            Text(value)
                .font(.figures(22, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A millilitre wheel, for when a slider is not exact enough.
struct AmountSheet: View {
    let title: String
    @Binding var millilitres: Double

    @Environment(\.dismiss) private var dismiss

    private var selection: Binding<Int> {
        Binding(
            get: { Int(millilitres.rounded()) },
            set: { millilitres = Double($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Picker(title, selection: selection) {
                ForEach(Array(stride(from: 0, through: 2000, by: 10)), id: \.self) { value in
                    Text("\(value) ml").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(320)])
    }
}
