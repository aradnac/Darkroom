//
//  SessionSummaryView.swift
//  Darkroom
//
//  Shown when the last stage is done. Nothing is kept yet; the summary can be
//  discarded.
//

import SwiftUI

struct SessionSummaryView: View {
    let plan: SessionPlan
    let onDone: () -> Void

    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    private var totalSeconds: TimeInterval {
        plan.stages.reduce(0) { $0 + $1.duration }
    }

    /// The session's numbers, in the order they are shown in both layouts.
    private var details: [(label: String, value: String)] {
        var rows: [(label: String, value: String)] = [
            ("Rolls", "\(plan.rollCount)")
        ]
        if plan.exposureIndex != plan.film.iso {
            rows.append(("Exposure index", "EI \(plan.exposureIndex)"))
        }
        rows.append(("Developer time", Clock.mmss(plan.developmentTime)))
        if plan.reuseCount > 1 {
            rows.append(("Developer reuse", "use \(plan.reuseCount)"))
        }
        rows.append(("Agitation", plan.intensity.label))
        rows.append(("Temperature", Units.temperature(plan.temperature)))
        rows.append(("Wash", plan.washMethod.label))
        rows.append(("Total session", Clock.mmss(totalSeconds)))
        return rows
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if themeStore.isTheme13Active {
                        paperSummary
                    } else {
                        glassSummary
                    }

                    actions
                }
                .padding(20)
            }
            .background {
                LiquidBackdrop()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    // MARK: Print theme

    private var paperSummary: some View {
        Theme13ReceiptPlate(
            index: "03",
            title: "Developed",
            subtitle: "\(plan.film.fullName) · \(plan.developer.name) \(plan.dilution.label)",
            rows: details
        )
    }

    // MARK: Darkroom

    private var glassSummary: some View {
        VStack(spacing: 22) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(Theme.amber)
                .padding(.top, 12)

            VStack(spacing: 6) {
                Text("Roll developed")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(plan.film.fullName) · \(plan.developer.name) \(plan.dilution.label)")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                ForEach(Array(details.enumerated()), id: \.offset) { _, row in
                    summaryRow(row.label, row.value)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .glassCard(radius: 26)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if themeStore.isTheme13Active {
            VStack(spacing: 12) {
                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AmberCapsuleStyle(height: 52))

                Button("Discard", role: .destructive) {
                    onDone()
                }
                .buttonStyle(GlassCapsuleStyle(height: 48))
            }
        } else {
            VStack(spacing: 12) {
                Button {
                    onDone()
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.amberInk)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.amber)
                .controlSize(.large)

                Button("Discard", role: .destructive) {
                    onDone()
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 12)
    }
}
