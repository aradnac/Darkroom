//
//  AddBatchView.swift
//  Darkroom
//
//  Adds a bottle to the cupboard, or edits one that is already there.
//

import SwiftUI

struct AddBatchView: View {
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    fieldsCard
                    keepingCard
                    capacityCard
                }
                .padding(20)
            }
            .background {
                LiquidBackdrop()
            }
            .navigationTitle(existing == nil ? "New bottle" : "Edit bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var fieldsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            field("Name", text: $name, prompt: "D-76 stock, 1 L")
            field("Developer", text: $developer, prompt: "Kodak D-76")

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)
                TextField("Optional", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2...5)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    }
            }
        }
        .padding(18)
        .glassCard(radius: 26)
    }

    private var keepingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Keeping")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            Stepper(value: $litres, in: 0.25...5, step: 0.25) {
                LabeledContent("Bottle", value: Amount.litres(litres))
            }

            DatePicker("Mixed on", selection: $mixedOn, displayedComponents: .date)

            Toggle("Has a shelf life", isOn: $hasShelfLife)
                .tint(Theme.amber)

            if hasShelfLife {
                Stepper(value: $shelfLifeMonths, in: 1...60, step: 1) {
                    LabeledContent("Shelf life", value: "\(shelfLifeMonths) months")
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private var capacityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Capacity")
                .font(.system(size: 17))
                .foregroundStyle(Theme.inkSoft)

            Stepper(value: $capacityRolls, in: 1...100, step: 1) {
                LabeledContent("Rolls per batch", value: "\(capacityRolls)")
            }

            Toggle("Can be reused", isOn: $isReusable)
                .tint(Theme.amber)

            Text("Take the roll capacity from the developer's own datasheet. Each logged use is counted against it, and each reuse adds 10%, compounded, to the next development.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(Theme.ink)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                }
        }
    }

    private func save() {
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
