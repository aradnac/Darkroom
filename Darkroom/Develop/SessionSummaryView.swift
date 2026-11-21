//
//  SessionSummaryView.swift
//  Darkroom
//
//  Shown when the last stage is done. The session has already been written to
//  the journal; this screen is where the negatives get their notes and an
//  optional photograph, and where the record can be discarded if the session was
//  not worth keeping.
//

import PhotosUI
import SwiftUI
import UIKit

struct SessionSummaryView: View {
    let plan: SessionPlan
    /// The journal entry the engine wrote when this session finished.
    var recordID: UUID?
    let onDone: () -> Void

    @State private var notes = ""
    @State private var photo: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false

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
        if let published = plan.publishedSeconds {
            rows.append(("Published at temp", Clock.mmss(published)))
        }
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
                    glassSummary
                    journalSection
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
        .onAppear(perform: loadRecord)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoItem, matching: .images)
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

    // MARK: Journal

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.amber)
                Text("Logged to the journal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }

            Text("The numbers above are saved. Add what the negatives turn out like — thin or dense, grain, scratches — and a photograph if you take one.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Notes on the negatives", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(Theme.ink)
                .tint(Theme.amber)
                .lineLimit(3...8)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.surfaceRaised)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                }
                .onChange(of: notes) { _, value in
                    guard let recordID else { return }
                    JournalStore.shared.setNotes(value, for: recordID)
                }
                .accessibilityLabel("Notes on the negatives")

            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Photograph of the negatives")

                HStack(spacing: 10) {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Text("Change photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 44))

                    Button("Remove", role: .destructive) {
                        self.photo = nil
                        photoItem = nil
                        if let recordID {
                            JournalStore.shared.setPhoto(nil, for: recordID)
                        }
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 44))
                }
            } else {
                Button {
                    showingPhotoPicker = true
                } label: {
                    Label("Add a photo of the negatives", systemImage: "photo")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassCapsuleStyle(height: 48))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 26)
    }

    // MARK: Actions

    private var actions: some View {
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

            Button("Discard session", role: .destructive) {
                discard()
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }

    // MARK: Record

    private func loadRecord() {
        guard let recordID, let record = JournalStore.shared.record(recordID) else { return }
        notes = record.negativeNotes
        if let data = JournalStore.shared.photoData(for: record) {
            photo = UIImage(data: data)
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.8) else { return }
        if let recordID {
            JournalStore.shared.setPhoto(jpeg, for: recordID)
        }
        photo = image
    }

    private func discard() {
        if let recordID {
            JournalStore.shared.discard(recordID)
        }
        onDone()
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
