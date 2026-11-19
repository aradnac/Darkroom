//
//  BatchDetailView.swift
//  Darkroom
//
//  One bottle: what is left, when it expires, the penalty the next use carries, and
//  every use it has had.
//

import SwiftUI

struct BatchDetailView: View {
    let batchID: UUID

    @State private var store = ChemistryStore.shared
    @State private var loggingUse = false
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
                VStack(spacing: 8) {
                    Text("This bottle has been removed.")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    LiquidBackdrop()
                }
            }
        }
        .navigationTitle(store.batch(batchID)?.name ?? "Bottle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit") {
                        editing = true
                    }
                    Button("Delete", role: .destructive) {
                        confirmingDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
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
                AddBatchView(existing: batch)
            }
        }
        .sheet(isPresented: $loggingUse) {
            if let batch = store.batch(batchID) {
                LogUseSheet(batchName: batch.name) { rolls, note in
                    store.logUse(rolls: rolls, note: note, for: batchID)
                }
            }
        }
        .sheet(isPresented: $editingBaseTime) {
            DurationSheet(title: "Base time", seconds: $baseSeconds)
        }
    }

    private func content(_ batch: ChemicalBatch) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard(batch)
                nextUseCard(batch)
                ledgerCard(batch)
            }
            .padding(20)
        }
        .background {
            LiquidBackdrop()
        }
    }

    // MARK: - Summary

    private func summaryCard(_ batch: ChemicalBatch) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(batch.developer)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkSoft)
                    Text(batch.isReusable ? "Reusable" : "One-shot")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(batch.remainingRolls)")
                        .font(.figures(44, weight: .semibold))
                        .foregroundStyle(batch.isExhausted ? Theme.inkFaint : Theme.amber)
                    Text("rolls left of \(batch.capacityRolls)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                }
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            VStack(spacing: 0) {
                row("Bottle", Amount.litres(batch.litres))
                row("Mixed on", batch.mixedOn.formatted(.dateTime.day().month(.abbreviated).year()))
                row("Keeps", batch.expiryLabel ?? "no limit set")
                row("Has developed", batch.rollsText)
                row("Uses", "\(batch.useCount)")
            }

            if !batch.notes.isEmpty {
                Text(batch.notes)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26, tint: Theme.amber)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 9)
    }

    // MARK: - Next use

    private func nextUseCard(_ batch: ChemicalBatch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Next use")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("Use \(batch.nextUseNumber)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(batch.nextUsePenaltyText)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if batch.isReusable {
                    Text("+\(batch.nextUsePenaltyPercent)%")
                        .font(.figures(24, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }
            }

            if batch.isReusable {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("On a base time of")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                        Button {
                            editingBaseTime = true
                        } label: {
                            Text(Clock.mmss(TimeInterval(baseSeconds)))
                                .font(.figures(22, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                        .buttonStyle(HapticButtonStyle())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("This use")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                        Text(Clock.mmss(Double(baseSeconds) * batch.nextUseFactor))
                            .font(.figures(22, weight: .semibold))
                            .foregroundStyle(Theme.amber)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: - Ledger

    private func ledgerCard(_ batch: ChemicalBatch) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Ledger")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(batch.rollsDeveloped) rolls in \(batch.useCount) \(batch.useCount == 1 ? "use" : "uses")")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
            }

            if batch.uses.isEmpty {
                Text("Nothing logged yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkFaint)
            } else {
                ForEach(batch.uses.reversed()) { use in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(use.date.formatted(.dateTime.day().month(.abbreviated).year()))
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.ink)
                            if !use.note.isEmpty {
                                Text(use.note)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                        }
                        Spacer(minLength: 8)
                        Text("\(use.rolls) \(use.rolls == 1 ? "roll" : "rolls")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.vertical, 2)
                }
            }

            Button {
                loggingUse = true
            } label: {
                Label("Log a use", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }
}

private struct LogUseSheet: View {
    let batchName: String
    let onSave: (Int, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rolls = 1
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        OverlineText(text: batchName, color: Theme.amber)
                        Text("Log a use")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    }

                    VStack(spacing: 14) {
                        Stepper(value: $rolls, in: 1...10) {
                            LabeledContent("Rolls developed", value: "\(rolls)")
                        }

                        TextField("Note, optional", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2...4)
                            .padding(12)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            }
                    }
                    .padding(18)
                    .glassCard(radius: 26)
                }
                .padding(20)
            }
            .background {
                LiquidBackdrop()
            }
            .navigationTitle("Log a use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(rolls, note)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
