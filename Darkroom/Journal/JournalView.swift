//
//  JournalView.swift
//  Darkroom
//
//  Every finished session, kept: the film, the developer and dilution, the
//  temperature, the time actually used against the published time, how many
//  rolls, which use of the developer, the agitation, the notes written about the
//  negatives and a photograph of them if one was added.
//
//  Sessions can be searched, filtered and re-run as a new setup, and the
//  statistics summarise rolls by film, by developer and by month, the average
//  deviation from the published time, and per-chemical totals with each bottle's
//  own ledger beside them.
//

import PhotosUI
import SwiftUI
import UIKit

struct JournalView: View {
    @State private var store = JournalStore.shared

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
        JournalStatistics(records: store.records, batches: ChemistryStore.shared.batches)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if store.records.isEmpty {
                        emptyState
                    } else {
                        SegmentedPill(options: Mode.allCases, selection: $mode) { $0.title }

                        if mode == .sessions {
                            searchField
                            filters
                            list
                        } else {
                            statisticsContent
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background {
                LiquidBackdrop()
            }
            .appNavigationChrome(index: "04", title: "Journal")
            .sheet(item: $selected) { record in
                NavigationStack {
                    JournalRecordDetail(record: record)
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            OverlineText(text: "Kept on the bench", color: Theme.amber)
            Text("Journal")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text(summaryLine)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 4)
    }

    private var summaryLine: String {
        let records = store.records
        guard !records.isEmpty else {
            return "Every finished session is logged here automatically."
        }
        let rolls = records.reduce(0) { $0 + $1.rolls }
        let sessions = records.count
        return "\(sessions) session\(sessions == 1 ? "" : "s") · \(rolls) roll\(rolls == 1 ? "" : "s") developed"
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.inkSoft)

            Text("No sessions yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.ink)

            Text("Finish a development session and it is written here with the film, the developer, the time used against the published time, and room for what the negatives turned out like.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }

    // MARK: Search and filters

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.inkFaint)

            TextField("Film, developer or note", text: $query)
                .font(.system(size: 16))
                .foregroundStyle(Theme.ink)
                .tint(Theme.amber)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkFaint)
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityLabel("Clear the search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(radius: 18)
    }

    @ViewBuilder
    private var filters: some View {
        let films = store.filmNames
        let developers = store.developerNames

        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All films", isOn: filmFilter == nil) {
                        filmFilter = nil
                    }
                    ForEach(films, id: \.self) { name in
                        filterChip(name, isOn: filmFilter == name) {
                            filmFilter = filmFilter == name ? nil : name
                        }
                    }
                }
                .padding(.vertical, 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All developers", isOn: developerFilter == nil) {
                        developerFilter = nil
                    }
                    ForEach(developers, id: \.self) { name in
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
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(isOn ? Theme.amberInk : Theme.inkSoft)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background {
                    Capsule().fill(isOn ? Theme.amber : Theme.surfaceRaised)
                }
                .overlay {
                    if !isOn {
                        Capsule().strokeBorder(Theme.border, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: List

    private var list: some View {
        let records = filtered

        return LazyVStack(spacing: 10) {
            if records.isEmpty {
                Text("No session matches this search.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 8)
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
                    Text(record.date.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.inkFaint)

                    Spacer(minLength: 4)

                    if record.rolls > 1 {
                        Text("\(record.rolls) ROLLS")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(Theme.inkFaint)
                    }
                }

                Text(record.filmLine)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text("\(record.developerLine) · \(record.timeText) at \(Units.temperature(record.temperature))")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(record.agitationLabel)
                    Text("·")
                    Text("use \(record.reuseCount)")
                    if record.exposureIndex != 0 {
                        Text("·")
                        Text("EI \(record.exposureIndex)")
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkFaint)

                if !record.negativeNotes.isEmpty {
                    Text(record.negativeNotes)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                if let _ = record.photoFilename {
                    JournalPhotoThumbnail(record: record, size: 54, radius: 12)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 22)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: Statistics

    @ViewBuilder
    private var statisticsContent: some View {
        let stats = statistics

        overviewCard(stats)

        if let deviation = stats.deviation {
            deviationCard(deviation)
        } else {
            noteCard(
                title: "No published time to compare",
                detail: "Every session so far had its time entered by hand, so there is nothing yet to measure the time used against."
            )
        }

        tallyCard("Rolls by film", tallies: stats.byFilm)
        tallyCard("Rolls by developer", tallies: stats.byDeveloper)
        tallyCard("Rolls by month", tallies: Array(stats.byMonth.prefix(12)))

        chemicalsCard(stats.chemicals)
    }

    private func overviewCard(_ stats: JournalStatistics) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            OverlineText(text: "Everything logged", color: Theme.amber)

            HStack(alignment: .top, spacing: 0) {
                statisticColumn(label: "Sessions", value: "\(stats.sessions)")
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: 40)
                statisticColumn(label: "Rolls", value: "\(stats.rolls)")
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: 40)
                statisticColumn(label: "Development", value: Clock.mmss(stats.totalTime))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }

    private func statisticColumn(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.figures(20, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private func deviationCard(_ deviation: JournalStatistics.Deviation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            OverlineText(text: "Time used against the published time", color: Theme.amber)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(Clock.signed(deviation.average))
                    .font(.figures(30, weight: .semibold))
                    .foregroundStyle(Theme.ink)

                if let percent = deviation.averagePercent {
                    Text(String(format: "%+.1f%%", percent))
                        .font(.figures(15, weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                }

                Spacer(minLength: 0)
            }

            Text("Average across \(deviation.count) session\(deviation.count == 1 ? "" : "s") with a published time. Positive means the session ran longer than the published time at that temperature.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24, tint: Theme.amber)
    }

    private func tallyCard(_ title: String, tallies: [JournalStatistics.Tally]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            OverlineText(text: title, color: Theme.amber)

            if tallies.isEmpty {
                Text("Nothing logged yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(tallies) { tally in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(tally.name)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)

                        Spacer(minLength: 6)

                        Text("\(tally.rolls) roll\(tally.rolls == 1 ? "" : "s")")
                            .font(.figures(14, weight: .semibold))
                            .foregroundStyle(Theme.ink)

                        Text("\(tally.sessions)×")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkFaint)
                            .frame(minWidth: 24, alignment: .trailing)
                    }
                    .padding(.vertical, 5)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(tally.name): \(tally.rolls) rolls in \(tally.sessions) sessions")

                    if tally.id != tallies.last?.id {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }

    private func chemicalsCard(_ chemicals: [JournalStatistics.ChemicalTotal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            OverlineText(text: "Per chemical", color: Theme.amber)

            if chemicals.isEmpty {
                Text("Nothing logged yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(chemicals) { chemical in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(chemical.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.ink)

                            Spacer(minLength: 6)

                            Text("\(chemical.rolls) roll\(chemical.rolls == 1 ? "" : "s")")
                                .font(.figures(14, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                        }

                        Text("\(chemical.sessions) session\(chemical.sessions == 1 ? "" : "s") · \(Clock.mmss(chemical.time)) of development")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkFaint)

                        ForEach(chemical.batches) { batch in
                            Text("\(batch.name): \(batch.sessions) in the journal · its ledger \(batch.ledgerRolls) rolls in \(batch.ledgerUses) use\(batch.ledgerUses == 1 ? "" : "s")")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 6)

                    if chemical.id != chemicals.last?.id {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }

    private func noteCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }
}

// MARK: - Detail

private struct JournalRecordDetail: View {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                detailsCard
                notesCard
                photoCard
                rerunButton
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background {
            LiquidBackdrop()
        }
        .navigationTitle(draft.filmLine)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    save()
                    dismiss()
                }
            }
        }
        .onAppear(perform: loadPhoto)
        .onChange(of: notes) { _, value in
            JournalStore.shared.setNotes(value, for: draft.id)
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoItem, matching: .images)
        .sheet(item: $rerun) { item in
            NavigationStack {
                SessionSetupView(
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
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(draft.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()).uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(Theme.inkFaint)

            Text(draft.filmLine)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(draft.developerLine) · \(draft.timeText) at \(Units.temperature(draft.temperature))")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    // MARK: Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            detailRow("Rolls", "\(draft.rolls)")
            detailRow("Exposure index", "EI \(draft.exposureIndex)")
            detailRow("Development time", draft.timeText)
            if let published = draft.publishedSeconds {
                detailRow("Published at temp", Clock.mmss(published))
            }
            if let deviation = draft.deviation {
                detailRow(
                    "Difference",
                    "\(Clock.signed(deviation))" + (draft.deviationPercent.map { String(format: " (%+.1f%%)", $0) } ?? "")
                )
            }
            detailRow("Temperature", Units.temperature(draft.temperature))
            detailRow("Developer use", "use \(draft.reuseCount)")
            detailRow("Agitation", draft.agitationLabel)
            detailRow("Wash", draft.washLabel)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            OverlineText(text: "The negatives", color: Theme.amber)

            Text("Thin or dense, grain, scratches, marks — what this roll actually looks like.")
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
                .accessibilityLabel("Notes on the negatives")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }

    // MARK: Photo

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            OverlineText(text: "A photograph", color: Theme.amber)

            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Photograph of the negatives")

                HStack(spacing: 10) {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Text("Change photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 46))

                    Button("Remove", role: .destructive) {
                        self.photo = nil
                        photoItem = nil
                        JournalStore.shared.setPhoto(nil, for: draft.id)
                    }
                    .buttonStyle(GlassCapsuleStyle(height: 46))
                }
            } else {
                Button {
                    showingPhotoPicker = true
                } label: {
                    Label("Add a photo of the negatives", systemImage: "photo")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassCapsuleStyle(height: 52))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 24)
    }

    // MARK: Re-run

    private var rerunButton: some View {
        VStack(spacing: 8) {
            Button {
                rerun = Rerun(record: draft)
            } label: {
                Label("Re-run this session", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.amberInk)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.amber)
            .controlSize(.large)

            Text("Opens a new setup with this roll's film, developer, dilution, temperature, exposure index and developer use.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
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

/// Reads the stored photograph once, so a list of sessions does not decode every
/// image on each redraw.
private struct JournalPhotoThumbnail: View {
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
                    .fill(Theme.surfaceRaised)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Theme.inkFaint)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .task(id: record.photoFilename) {
            guard let data = JournalStore.shared.photoData(for: record) else { return }
            image = UIImage(data: data)
        }
        .accessibilityHidden(true)
    }
}
