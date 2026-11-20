//
//  RedroomJournalScreen.swift
//  Darkroom
//
//  The Journal bench in REDROOM: every finished session on a smoked card, the
//  numbers it was run at, the notes written about the negatives and a photograph
//  of them if there is one. Searched and filtered like the rest of the room, and
//  re-run straight into a new session setup.
//
//  The statistics are the room's own plates: totals, the average deviation from
//  the published time, rolls by film, developer and month, and per-chemical
//  totals with each bottle's ledger beside them.
//

import PhotosUI
import SwiftUI
import UIKit

// MARK: - Tab

struct RedroomJournalTab: View {
    var body: some View {
        NavigationStack {
            RedroomJournalHome()
        }
    }
}

// MARK: - Home

struct RedroomJournalHome: View {
    @State private var store = JournalStore.shared
    @State private var chemistry = ChemistryStore.shared

    @State private var mode: Mode = .sessions
    @State private var query = ""
    @State private var filmFilter: String?
    @State private var developerFilter: String?
    @State private var selected: SessionRecord?

    enum Mode: String, CaseIterable, Identifiable {
        case sessions
        case statistics

        var id: String { rawValue }

        var title: String {
            switch self {
            case .sessions: return "Sessions"
            case .statistics: return "Statistics"
            }
        }
    }

    private var filtered: [SessionRecord] {
        store.records(matching: query, film: filmFilter, developer: developerFilter)
    }

    private var statistics: JournalStatistics {
        JournalStatistics(records: store.records, batches: chemistry.batches)
    }

    var body: some View {
        RedroomScreen {
            RedroomScreenHeader(kicker: "Kept on the bench", title: "Journal")
                .redroomReveal(.safelightFade)

            if store.records.isEmpty {
                RedroomEmptyState(
                    title: "No sessions yet",
                    detail: "Finish a development session and it is written here with the film, the developer, the time used against the published time, and room for what the negatives turned out like.",
                    symbol: "book.closed"
                )
            } else {
                RedroomSegmented(items: Mode.allCases, selection: $mode, title: { $0.title })

                if mode == .sessions {
                    searchField
                    filters
                    list
                } else {
                    statisticsContent
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selected) { record in
            NavigationStack {
                RedroomJournalDetail(record: record)
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: Search and filters

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Redroom.textMuted)

            TextField("Film, developer or note", text: $query)
                .font(Redroom.body(14))
                .foregroundStyle(Redroom.text)
                .tint(Redroom.safelight)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Redroom.textMuted)
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityLabel("Clear the search")
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 48)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Redroom.color(0x0B0404))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    filterChip("All films", isOn: filmFilter == nil) {
                        filmFilter = nil
                    }
                    ForEach(store.filmNames, id: \.self) { name in
                        filterChip(name, isOn: filmFilter == name) {
                            filmFilter = filmFilter == name ? nil : name
                        }
                    }
                }
                .padding(.vertical, 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    filterChip("All developers", isOn: developerFilter == nil) {
                        developerFilter = nil
                    }
                    ForEach(store.developerNames, id: \.self) { name in
                        filterChip(name, isOn: developerFilter == name) {
                            developerFilter = developerFilter == name ? nil : name
                        }
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private func filterChip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RedroomChip(text: title, emphasised: isOn)
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: List

    private var list: some View {
        let records = filtered

        return VStack(alignment: .leading, spacing: 10) {
            if records.isEmpty {
                RedroomNote(text: "No session matches this search.", symbol: "magnifyingglass")
            } else {
                ForEach(records) { record in
                    Button {
                        selected = record
                    } label: {
                        recordCard(record)
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }
        }
    }

    private func recordCard(_ record: SessionRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(record.date.formatted(.dateTime.day().month(.abbreviated).year()).uppercased())
                        .font(Redroom.label(9))
                        .tracking(1)
                        .foregroundStyle(Redroom.textMuted)

                    Spacer(minLength: 4)

                    if record.rolls > 1 {
                        RedroomChip(text: "\(record.rolls) rolls")
                    }
                }

                Text(record.filmLine)
                    .font(Redroom.body(16, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text("\(record.developerLine) · \(record.timeText) at \(Units.temperature(record.temperature))")
                    .font(Redroom.body(11))
                    .foregroundStyle(Redroom.textMuted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(record.agitationLabel) · use \(record.reuseCount)" + (record.exposureIndex != 0 ? " · EI \(record.exposureIndex)" : ""))
                    .font(Redroom.body(10))
                    .foregroundStyle(Redroom.textMuted)

                if !record.negativeNotes.isEmpty {
                    Text(record.negativeNotes)
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                if record.photoFilename != nil {
                    RedroomJournalThumbnail(record: record, size: 54, radius: 12)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Redroom.textMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 18)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: Statistics

    @ViewBuilder
    private var statisticsContent: some View {
        let stats = statistics

        RedroomPanel(title: "Everything logged", variant: .optical) {
            HStack(alignment: .top, spacing: 10) {
                statisticColumn(label: "Sessions", value: "\(stats.sessions)")
                statisticColumn(label: "Rolls", value: "\(stats.rolls)")
                statisticColumn(label: "Clock", value: Clock.mmss(stats.totalTime))
            }
        }

        if let deviation = stats.deviation {
            RedroomPanel(title: "Time used against the published time") {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Clock.signed(deviation.average))
                        .font(Redroom.figure(30, weight: .semibold))
                        .foregroundStyle(Redroom.text)

                    if let percent = deviation.averagePercent {
                        Text(String(format: "%+.1f%%", percent))
                            .font(Redroom.figure(13, weight: .medium))
                            .foregroundStyle(Redroom.textMuted)
                    }

                    Spacer(minLength: 0)
                }

                RedroomNote(text: "Average across \(deviation.count) session\(deviation.count == 1 ? "" : "s") with a published time. Positive means the session ran longer than the published time at that temperature.", symbol: "clock")
            }
        } else {
            RedroomNote(text: "No published time to compare yet: every session so far had its time entered by hand.", symbol: "clock")
        }

        tallyPanel("Rolls by film", tallies: stats.byFilm)
        tallyPanel("Rolls by developer", tallies: stats.byDeveloper)
        tallyPanel("Rolls by month", tallies: Array(stats.byMonth.prefix(12)))
        chemicalsPanel(stats.chemicals)
    }

    private func statisticColumn(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(Redroom.label(8))
                .tracking(0.8)
                .foregroundStyle(Redroom.textMuted)
            Text(value)
                .font(Redroom.figure(19, weight: .semibold))
                .foregroundStyle(Redroom.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private func tallyPanel(_ title: String, tallies: [JournalStatistics.Tally]) -> some View {
        RedroomPanel(title: title) {
            if tallies.isEmpty {
                Text("Nothing logged yet.")
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
            } else {
                ForEach(Array(tallies.enumerated()), id: \.element.id) { index, tally in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(tally.name)
                            .font(Redroom.body(13))
                            .foregroundStyle(Redroom.text)
                            .lineLimit(2)

                        Spacer(minLength: 6)

                        Text("\(tally.rolls) roll\(tally.rolls == 1 ? "" : "s")")
                            .font(Redroom.figure(13, weight: .semibold))
                            .foregroundStyle(Redroom.text)

                        Text("\(tally.sessions)×")
                            .font(Redroom.body(10))
                            .foregroundStyle(Redroom.textMuted)
                            .frame(minWidth: 24, alignment: .trailing)
                    }
                    .padding(.vertical, 5)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(tally.name): \(tally.rolls) rolls in \(tally.sessions) sessions")

                    if index < tallies.count - 1 {
                        RedroomLitRule(thickness: 0.5)
                    }
                }
            }
        }
    }

    private func chemicalsPanel(_ chemicals: [JournalStatistics.ChemicalTotal]) -> some View {
        RedroomPanel(title: "Per chemical") {
            if chemicals.isEmpty {
                Text("Nothing logged yet.")
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
            } else {
                ForEach(Array(chemicals.enumerated()), id: \.element.id) { index, chemical in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(chemical.name)
                                .font(Redroom.body(13, weight: .semibold))
                                .foregroundStyle(Redroom.text)

                            Spacer(minLength: 6)

                            Text("\(chemical.rolls) roll\(chemical.rolls == 1 ? "" : "s")")
                                .font(Redroom.figure(13, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                        }

                        Text("\(chemical.sessions) session\(chemical.sessions == 1 ? "" : "s") · \(Clock.mmss(chemical.time)) of development")
                            .font(Redroom.body(10))
                            .foregroundStyle(Redroom.textMuted)

                        ForEach(chemical.batches) { batch in
                            Text("\(batch.name): \(batch.sessions) in the journal · its ledger \(batch.ledgerRolls) rolls in \(batch.ledgerUses) use\(batch.ledgerUses == 1 ? "" : "s")")
                                .font(Redroom.body(10))
                                .foregroundStyle(Redroom.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 6)

                    if index < chemicals.count - 1 {
                        RedroomLitRule(thickness: 0.5)
                    }
                }
            }
        }
    }
}

// MARK: - Detail

private struct RedroomJournalDetail: View {
    let record: SessionRecord

    @Environment(\.dismiss) private var dismiss

    @State private var draft: SessionRecord
    @State private var notes: String
    @State private var photo: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var rerun: Rerun?

    private struct Rerun: Identifiable {
        let id = UUID()
        let record: SessionRecord
    }

    init(record: SessionRecord) {
        self.record = record
        _draft = State(initialValue: record)
        _notes = State(initialValue: record.negativeNotes)
    }

    var body: some View {
        RedroomSheetBody(
            kicker: draft.date.formatted(.dateTime.day().month(.wide).year()),
            title: draft.filmLine,
            detail: "\(draft.developerLine) · \(draft.timeText) at \(Units.temperature(draft.temperature))"
        ) {
            detailsPanel

            RedroomPanel(
                title: "The negatives",
                detail: "Thin or dense, grain, scratches, marks — what this roll actually looks like."
            ) {
                TextField("Notes on the negatives", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Redroom.body(14))
                    .foregroundStyle(Redroom.text)
                    .tint(Redroom.safelight)
                    .lineLimit(3...8)
                    .padding(11)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Redroom.color(0x0D0505))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Redroom.textDisabled.opacity(0.5), lineWidth: 1)
                    }
                    .onChange(of: notes) { _, value in
                        JournalStore.shared.setNotes(value, for: draft.id)
                    }
                    .accessibilityLabel("Notes on the negatives")
            }

            photoPanel

            Button {
                rerun = Rerun(record: draft)
            } label: {
                Text("Re-run this session")
            }
            .buttonStyle(RedroomPrimaryButtonStyle())

            RedroomNote(text: "Opens a new setup with this roll's film, developer, dilution, temperature, exposure index and developer use.")

            Button {
                save()
                dismiss()
            } label: {
                Text("Close")
            }
            .buttonStyle(RedroomSecondaryButtonStyle())
        }
        .presentationDetents([.large])
        .onAppear(perform: loadPhoto)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoItem, matching: .images)
        .sheet(item: $rerun) { item in
            NavigationStack {
                RedroomSessionSetup(
                    film: JournalRerun.film(for: item.record),
                    developer: JournalRerun.developer(for: item.record),
                    dilution: JournalRerun.dilution(
                        for: item.record,
                        in: JournalRerun.developer(for: item.record)
                    ),
                    temperature: item.record.temperature,
                    pushStops: item.record.pushStops,
                    reuseCount: item.record.reuseCount
                )
                .background(Redroom.background)
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: Details

    private var detailsPanel: some View {
        RedroomPanel {
            RedroomValueRow(label: "Rolls", value: "\(draft.rolls)")
            RedroomValueRow(label: "Exposure index", value: "EI \(draft.exposureIndex)")
            RedroomValueRow(label: "Development time", value: draft.timeText, emphasised: true)
            if let published = draft.publishedSeconds {
                RedroomValueRow(label: "Published at temp", value: Clock.mmss(published))
            }
            if let deviation = draft.deviation {
                RedroomValueRow(
                    label: "Difference",
                    value: Clock.signed(deviation) + (draft.deviationPercent.map { String(format: " (%+.1f%%)", $0) } ?? "")
                )
            }
            RedroomValueRow(label: "Temperature", value: Units.temperature(draft.temperature))
            RedroomValueRow(label: "Developer use", value: "use \(draft.reuseCount)")
            RedroomValueRow(label: "Agitation", value: draft.agitationLabel)
            RedroomValueRow(label: "Wash", value: draft.washLabel)
        }
    }

    // MARK: Photo

    private var photoPanel: some View {
        RedroomPanel(title: "A photograph") {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Photograph of the negatives")

                HStack(spacing: 8) {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Text("Change photo")
                    }
                    .buttonStyle(RedroomSecondaryButtonStyle())
                    .frame(minHeight: 44)

                    Button("Remove", role: .destructive) {
                        self.photo = nil
                        photoItem = nil
                        JournalStore.shared.setPhoto(nil, for: draft.id)
                    }
                    .buttonStyle(RedroomSecondaryButtonStyle())
                    .frame(minHeight: 44)
                }
            } else {
                Button {
                    showingPhotoPicker = true
                } label: {
                    Text("Add a photo of the negatives")
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
                .frame(minHeight: 48)
            }
        }
    }

    // MARK: Actions

    private func loadPhoto() {
        guard let data = JournalStore.shared.photoData(for: draft) else { return }
        photo = UIImage(data: data)
    }

    private func load(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.8) else { return }
        JournalStore.shared.setPhoto(jpeg, for: draft.id)
        photo = image
    }

    private func save() {
        JournalStore.shared.setNotes(notes, for: draft.id)
    }
}

// MARK: - Thumbnail

private struct RedroomJournalThumbnail: View {
    let record: SessionRecord
    var size: CGFloat = 54
    var radius: CGFloat = 12

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Redroom.color(0x140808))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Redroom.textMuted)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Redroom.textDisabled.opacity(0.45), lineWidth: 1)
        }
        .task(id: record.photoFilename) {
            guard let data = JournalStore.shared.photoData(for: record) else { return }
            image = UIImage(data: data)
        }
        .accessibilityHidden(true)
    }
}
