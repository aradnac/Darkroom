//
//  RedroomLibraryScreens.swift
//  Darkroom
//
//  The Recipes bench in REDROOM: the catalogue as a rack of film strips, one
//  film as a contact sheet with the provenance of every number stamped beside
//  it, and the verification queue as the room's own list of what it still owes a
//  source.
//
//  The library, the chart client, the importer and the film index are the app's;
//  only the drawing is the room's.
//

import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Tab

struct RedroomRecipesTab: View {
    var body: some View {
        NavigationStack {
            RedroomLibraryBrowser()
        }
    }
}

// MARK: - Provenance badge

/// Where a number came from, said in words and with a mark. The colour only
/// agrees with the word.
struct RedroomProvenanceBadge: View {
    let kind: LibraryProvenanceKind
    var text: String?

    private var title: String { text ?? kind.label }

    private var symbol: String {
        switch kind {
        case .datasheet: return "checkmark.seal"
        case .community: return "person.2"
        case .unverified: return "questionmark.circle"
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
            Text(title.uppercased())
                .font(Redroom.label(8))
                .tracking(0.5)
        }
        .foregroundStyle(kind == .unverified ? Redroom.textMuted : Redroom.text)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background {
            Capsule().fill(kind == .unverified ? Redroom.color(0x140808) : Redroom.deepRed.opacity(0.6))
        }
        .overlay {
            Capsule().strokeBorder(
                kind == .unverified ? Redroom.textDisabled.opacity(0.5) : Redroom.safelight.opacity(0.4),
                lineWidth: 1
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.detail)")
    }
}

// MARK: - Browser

struct RedroomLibraryBrowser: View {
    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.openURL) private var openURL

    @State private var query = ""
    @State private var mode: Mode = .films
    @State private var process: FilmProcess?
    @State private var status: FilmStatus?
    @State private var showingQueue = false
    @State private var showingIdentifier = false
    @State private var importing = false
    @State private var importMessage = ""
    @State private var showingImportResult = false

    enum Mode: String, CaseIterable, Identifiable {
        case films
        case developers

        var id: String { rawValue }

        var label: String {
            switch self {
            case .films: return "Films"
            case .developers: return "Developers"
            }
        }
    }

    var body: some View {
        RedroomScreen {
            RedroomScreenHeader(
                kicker: "Reference library",
                title: "Recipes",
                actionSymbol: "checkmark.seal",
                actionLabel: "Verification queue",
                action: { showingQueue = true }
            )
            .redroomReveal(.safelightFade)

            searchField

            identifyRow

            RedroomSegmented(items: Mode.allCases, selection: $mode, title: { $0.label })

            if mode == .films {
                filters
                filmList
            } else {
                developerList
            }

            chartSources
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { FilmCatalog.shared.load() }
        .sheet(isPresented: $showingIdentifier) {
            RedroomFilmFinder()
        }
        .sheet(isPresented: $showingQueue) {
            RedroomVerificationQueue()
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.json, .commaSeparatedText, .plainText]
        ) { result in
            switch result {
            case .success(let url):
                importMessage = store.importFile(at: url)
            case .failure(let error):
                importMessage = error.localizedDescription
            }
            showingImportResult = true
        }
        .alert("Import", isPresented: $showingImportResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage)
        }
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Redroom.textMuted)

            TextField("Name, maker or DX code", text: $query)
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

    private var identifyRow: some View {
        Button {
            showingIdentifier = true
        } label: {
            RedroomNavRow(
                title: "Identify a film",
                detail: "Photo, name, maker or DX code",
                symbol: "barcode.viewfinder"
            )
        }
        .buttonStyle(HapticButtonStyle())
    }

    // MARK: Filters

    private var filters: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    Button {
                        process = nil
                    } label: {
                        RedroomChip(text: "All processes", emphasised: process == nil)
                    }
                    .buttonStyle(HapticButtonStyle())

                    ForEach(FilmProcess.allCases) { item in
                        Button {
                            process = item
                        } label: {
                            RedroomChip(text: item.label, emphasised: process == item)
                        }
                        .buttonStyle(HapticButtonStyle())
                    }
                }
                .padding(.vertical, 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    Button {
                        status = nil
                    } label: {
                        RedroomChip(text: "Any status", emphasised: status == nil)
                    }
                    .buttonStyle(HapticButtonStyle())

                    ForEach(FilmStatus.allCases) { item in
                        Button {
                            status = item
                        } label: {
                            RedroomChip(text: item.label, emphasised: status == item)
                        }
                        .buttonStyle(HapticButtonStyle())
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    // MARK: Lists

    private var filmList: some View {
        let films = store.films(matching: query, process: process, status: status)

        return VStack(alignment: .leading, spacing: 10) {
            if films.isEmpty {
                RedroomEmptyState(
                    title: "No film matches these filters",
                    detail: "Clear a filter or search for another name.",
                    symbol: "film"
                )
            } else {
                ForEach(films) { film in
                    NavigationLink {
                        RedroomFilmDetail(filmKey: film.key)
                    } label: {
                        FilmNegativeCard(
                            title: film.displayName,
                            subtitle: filmRowDetail(film)
                        )
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }
        }
    }

    private func filmRowDetail(_ film: LibraryFilm) -> String {
        let times = store.times(forFilm: film.key)
        let pending = times.filter { $0.seconds == nil || $0.provenance.kind == .unverified }.count
        var line = "\(film.manufacturer) · \(film.process.label) · \(times.count) time\(times.count == 1 ? "" : "s")"
        if pending > 0 {
            line += " · \(pending) to verify"
        }
        return line
    }

    private var developerList: some View {
        let developers = store.developers(matching: query)

        return VStack(alignment: .leading, spacing: 10) {
            if developers.isEmpty {
                RedroomEmptyState(
                    title: "No developer matches this search",
                    detail: "Try the maker's name, or clear the search.",
                    symbol: "flask"
                )
            } else {
                ForEach(developers) { developer in
                    NavigationLink {
                        RedroomDeveloperDetail(developerKey: developer.key)
                    } label: {
                        developerRow(developer)
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }
        }
    }

    private func developerRow(_ developer: LibraryDeveloper) -> some View {
        let films = store.filmCount(forDeveloper: developer.key)

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(developer.name)
                    .font(Redroom.body(15, weight: .semibold))
                    .foregroundStyle(Redroom.text)

                Text("\(developer.manufacturer) · \(developer.dilutionSummary)")
                    .font(Redroom.body(11))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(films) film\(films == 1 ? "" : "s") with a time")
                    .font(Redroom.body(10))
                    .foregroundStyle(Redroom.textMuted)
            }

            Spacer(minLength: 4)

            if developer.capacity == nil {
                RedroomProvenanceBadge(kind: .unverified)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 18)
    }

    // MARK: Sources

    private var chartSources: some View {
        VStack(alignment: .leading, spacing: 8) {
            RedroomLabel("Chart sources")

            sourceLink("35mm.org", detail: "Live times, each with its source", url: "https://35mm.org")
            sourceLink("The Massive Dev Chart", detail: "The long-running community chart", url: "https://www.digitaltruth.com/devchart.php")
            sourceLink("FilmDev", detail: "Community recipes with photographs", url: "https://filmdev.org/recipes/")

            Button {
                importing = true
            } label: {
                Text("Import records")
                    .font(Redroom.body(12, weight: .semibold))
                    .foregroundStyle(Redroom.safelight)
            }
            .buttonStyle(HapticButtonStyle())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 18)
        .padding(.top, 4)
    }

    private func sourceLink(_ title: String, detail: String, url: String) -> some View {
        Button {
            if let link = URL(string: url) {
                openURL(link)
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Redroom.body(13, weight: .medium))
                        .foregroundStyle(Redroom.text)
                    Text(detail)
                        .font(Redroom.body(10))
                        .foregroundStyle(Redroom.textMuted)
                }

                Spacer(minLength: 4)

                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Redroom.textMuted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
    }
}

// MARK: - Film detail

struct RedroomFilmDetail: View {
    let filmKey: String

    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.openURL) private var openURL

    @State private var showingCrossProcess = false
    @State private var sessionSelection: RedroomSessionSelection?
    @State private var chartState: ChartSectionState = .idle
    @State private var showingAllChartTimes = false

    var body: some View {
        Group {
            if let film = store.film(key: filmKey) {
                content(film)
            } else {
                RedroomScreen {
                    RedroomEmptyState(
                        title: "This film is no longer in the library",
                        detail: "It was removed with an import, or the library was reset.",
                        symbol: "film"
                    )
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(
                kicker: "Recipes",
                title: store.film(key: filmKey)?.displayName ?? "Film",
                actionSymbol: store.isFavourite(filmKey) ? "star.fill" : "star",
                actionLabel: store.isFavourite(filmKey) ? "Remove from favourites" : "Keep in favourites",
                action: { store.toggleFavourite(filmKey) }
            )
            .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCrossProcess) {
            RedroomCrossProcessSheet(filmKey: filmKey)
        }
        .sheet(item: $sessionSelection) { selection in
            NavigationStack {
                RedroomSessionSetup(
                    film: selection.film,
                    developer: selection.developer,
                    dilution: selection.dilution
                )
                .background(Redroom.background)
            }
        }
    }

    private func content(_ film: LibraryFilm) -> some View {
        RedroomScreen {
            header(film)
            chips(film)
            factTiles(film)

            ForEach(temperatureGroups(film), id: \.temperature) { group in
                timesSection(group: group)
            }

            chartSection(film)
            crossProcessSection(film)
            sourcesSection(film)
            startButton(film)
        }
        .task(id: filmKey) {
            await loadChart(film)
        }
    }

    private func header(_ film: LibraryFilm) -> some View {
        VStack(spacing: 5) {
            Text("\(film.manufacturer) · \(film.process.label)".uppercased())
                .font(Redroom.label(10))
                .tracking(2)
                .foregroundStyle(Redroom.textMuted)

            Text(film.displayName)
                .font(Redroom.display(28, weight: .bold))
                .foregroundStyle(Redroom.text)
                .multilineTextAlignment(.center)

            if let generationLabel = film.generationLabel {
                Text(generationLabel)
                    .font(Redroom.body(11))
                    .foregroundStyle(Redroom.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func chips(_ film: LibraryFilm) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                RedroomChip(text: "ISO \(film.iso)")
                ForEach(film.formats) { format in
                    RedroomChip(text: format.label)
                }
                RedroomChip(text: film.status.label, emphasised: film.status == .current)
            }
            .padding(.vertical, 1)
        }
        .frame(maxWidth: .infinity)
    }

    private func factTiles(_ film: LibraryFilm) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            factTile(symbol: "circle.lefthalf.filled", label: "Latitude", fact: film.latitude)
            factTile(symbol: "circle.grid.3x3.fill", label: "Grain", fact: film.grain)
            factTile(symbol: "circle.dotted", label: "Contrast", fact: film.contrast)
            factTile(symbol: "minus", label: "Reciprocity", fact: film.reciprocity)
        }
    }

    private func factTile(symbol: String, label: String, fact: LibraryFact?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Redroom.textMuted)
                Text(label.uppercased())
                    .font(Redroom.label(8))
                    .tracking(1)
                    .foregroundStyle(Redroom.textMuted)
            }

            Text(fact?.value ?? "Not documented")
                .font(Redroom.body(11, weight: fact == nil ? .regular : .medium))
                .foregroundStyle(fact == nil ? Redroom.textMuted : Redroom.text)
                .fixedSize(horizontal: false, vertical: true)

            if let fact {
                RedroomProvenanceBadge(kind: fact.provenance.kind)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .redroomGlass(variant: .smoked, cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    // MARK: Times

    private struct TimeRow: Identifiable {
        let entry: LibraryTimeEntry
        let developerName: String
        let dilutionLabel: String

        var id: String { entry.id }

        var timeText: String {
            guard let seconds = entry.seconds else { return "—" }
            return Clock.mmss(TimeInterval(seconds))
        }
    }

    private struct TemperatureGroup {
        let temperature: Double
        let rows: [TimeRow]
    }

    private func temperatureGroups(_ film: LibraryFilm) -> [TemperatureGroup] {
        let entries = store.times(forFilm: film.key)
        let primary = store.primaryTemperature(forFilm: film.key)
        let grouped = Dictionary(grouping: entries, by: \.celsius)

        return grouped
            .sorted { left, right in
                if left.key == primary { return true }
                if right.key == primary { return false }
                return left.key < right.key
            }
            .map { celsius, entries in
                let rows = entries
                    .map { entry in
                        TimeRow(
                            entry: entry,
                            developerName: store.developer(key: entry.developer)?.name ?? entry.developer,
                            dilutionLabel: store.dilutionLabel(
                                developerKey: entry.developer,
                                dilution: entry.dilution
                            )
                        )
                    }
                    .sorted { $0.developerName.localizedCaseInsensitiveCompare($1.developerName) == .orderedAscending }
                return TemperatureGroup(temperature: celsius, rows: rows)
            }
    }

    private func timesSection(group: TemperatureGroup) -> some View {
        RedroomPanel(title: "Development times · \(store.temperatureLabel(group.temperature))") {
            ForEach(Array(group.rows.enumerated()), id: \.element.id) { index, row in
                NavigationLink {
                    RedroomDeveloperDetail(developerKey: row.entry.developer)
                } label: {
                    timeRow(row)
                }
                .buttonStyle(HapticButtonStyle())

                if index < group.rows.count - 1 {
                    RedroomLitRule(thickness: 0.5)
                }
            }
        }
    }

    private func timeRow(_ row: TimeRow) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.developerName)
                    .font(Redroom.body(14, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(row.dilutionLabel)
                    .font(Redroom.body(11))
                    .foregroundStyle(Redroom.textMuted)
            }

            Spacer(minLength: 4)

            Text(row.timeText)
                .font(Redroom.figure(15, weight: .semibold))
                .foregroundStyle(Redroom.text)

            RedroomProvenanceBadge(kind: row.entry.provenance.kind)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: Cross-process

    @ViewBuilder
    private func crossProcessSection(_ film: LibraryFilm) -> some View {
        let entries = store.crossProcess(forFilm: film.key)
        let classes = CrossProcessClass.allCases.filter { item in
            entries.contains { $0.classification == item }
        }

        if !entries.isEmpty {
            Button {
                showingCrossProcess = true
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cross-processing")
                            .font(Redroom.body(13, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Text("\(entries.count) documented option\(entries.count == 1 ? "" : "s")")
                            .font(Redroom.body(11))
                            .foregroundStyle(Redroom.textMuted)
                    }

                    Spacer(minLength: 4)

                    ForEach(classes.prefix(3)) { item in
                        RedroomChip(text: item.label)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Redroom.textMuted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .redroomGlass(variant: .smoked, cornerRadius: 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(HapticButtonStyle())
        }
    }

    // MARK: Chart

    @ViewBuilder
    private func chartSection(_ film: LibraryFilm) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RedroomLabel("Live chart · 35mm.org")

            switch chartState {
            case .idle, .loading:
                chartLoadingCard
            case .empty:
                chartMessageCard("35mm.org has no published times for this film yet.")
            case .failed(let message):
                chartFailureCard(message, film: film)
            case .loaded(let result):
                if result.times.isEmpty {
                    chartMessageCard("35mm.org has no published times for this film yet.")
                } else {
                    chartListCard(result)
                }
            }
        }
    }

    private var chartLoadingCard: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(Redroom.safelight)
            Text("Reading the chart…")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 18)
    }

    private func chartMessageCard(_ text: String) -> some View {
        Text(text)
            .font(Redroom.body(12))
            .foregroundStyle(Redroom.textMuted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .redroomGlass(variant: .smoked, cornerRadius: 18)
    }

    private func chartFailureCard(_ message: String, film: LibraryFilm) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Button("Try again") {
                Task { await loadChart(film) }
            }
            .font(Redroom.body(12, weight: .semibold))
            .foregroundStyle(Redroom.safelight)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 18)
    }

    private func chartListCard(_ result: ChartFilmTimes) -> some View {
        let sorted = sortedChartTimes(result.times)
        let shown = showingAllChartTimes ? sorted : Array(sorted.prefix(8))
        let hiddenCount = sorted.count - shown.count

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, time in
                chartRow(time)

                if index < shown.count - 1 {
                    RedroomLitRule(thickness: 0.5)
                }
            }

            if hiddenCount > 0 {
                Button {
                    showingAllChartTimes = true
                } label: {
                    Text("Show \(hiddenCount) more")
                        .font(Redroom.body(12, weight: .semibold))
                        .foregroundStyle(Redroom.safelight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HapticButtonStyle())
            }

            chartAttribution(result)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: RedroomMetrics.cardRadius)
    }

    private func chartRow(_ time: ChartTime) -> some View {
        Button {
            if let url = time.url.flatMap(URL.init(string:)) {
                openURL(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(time.developer.name)
                        .font(Redroom.body(13, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(time.dilution.label)
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.textMuted)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(time.time)
                        .font(Redroom.figure(14, weight: .semibold))
                        .foregroundStyle(Redroom.text)

                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Redroom.textMuted)
                }

                HStack(spacing: 8) {
                    Text(chartSubtitle(time))
                        .font(Redroom.body(10))
                        .foregroundStyle(Redroom.textMuted)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    chartBadge(time)
                }
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
    }

    private func chartSubtitle(_ time: ChartTime) -> String {
        var parts: [String] = []
        if let ei = time.ei { parts.append("EI \(ei)") }
        parts.append(store.temperatureLabel(time.temperatureC))
        if let format = time.format, format != "any" { parts.append(format) }
        return parts.joined(separator: " · ")
    }

    private func chartBadge(_ time: ChartTime) -> some View {
        let kind: LibraryProvenanceKind
        switch time.confidence {
        case "verified": kind = .datasheet
        case "community": kind = .community
        default: kind = .unverified
        }
        return RedroomProvenanceBadge(kind: kind, text: time.confidenceLabel)
    }

    private func chartAttribution(_ result: ChartFilmTimes) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.attribution)

            if let url = result.filmURL {
                Button("Open this film on 35mm.org") {
                    openURL(url)
                }
                .foregroundStyle(Redroom.safelight)
            }
        }
        .font(Redroom.body(10))
        .foregroundStyle(Redroom.textMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            RedroomLitRule(thickness: 0.5)
        }
    }

    private func sortedChartTimes(_ times: [ChartTime]) -> [ChartTime] {
        times.sorted { left, right in
            if left.developer.name != right.developer.name {
                return left.developer.name.localizedCaseInsensitiveCompare(right.developer.name) == .orderedAscending
            }
            if left.dilution.label != right.dilution.label {
                return left.dilution.label < right.dilution.label
            }
            if (left.ei ?? 0) != (right.ei ?? 0) {
                return (left.ei ?? 0) < (right.ei ?? 0)
            }
            return left.temperatureC < right.temperatureC
        }
    }

    @MainActor
    private func loadChart(_ film: LibraryFilm) async {
        if case .loaded(_) = chartState { return }
        if case .loading = chartState { return }

        chartState = .loading
        do {
            let result = try await DevelopmentChartClient.shared.times(
                manufacturer: film.manufacturer,
                name: film.name,
                iso: film.iso
            )
            chartState = result.times.isEmpty ? .empty : .loaded(result)
        } catch {
            chartState = .failed(error.localizedDescription)
        }
    }

    // MARK: Sources

    @ViewBuilder
    private func sourcesSection(_ film: LibraryFilm) -> some View {
        let sources = store.sources(forFilm: film.key)
        if !sources.isEmpty {
            RedroomPanel(title: "Sources") {
                ForEach(Array(sources.enumerated()), id: \.element.key) { index, source in
                    Button {
                        if let url = URL(string: source.url), !source.url.isEmpty {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Redroom.textMuted)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.title)
                                    .font(Redroom.body(13))
                                    .foregroundStyle(Redroom.text)
                                    .multilineTextAlignment(.leading)
                                if !source.retrieved.isEmpty {
                                    Text("Retrieved \(source.retrieved)")
                                        .font(Redroom.body(10))
                                        .foregroundStyle(Redroom.textMuted)
                                }
                            }

                            Spacer(minLength: 4)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Redroom.textMuted)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())

                    if index < sources.count - 1 {
                        RedroomLitRule(thickness: 0.5)
                    }
                }
            }
        }
    }

    // MARK: Action

    private func startButton(_ film: LibraryFilm) -> some View {
        Button {
            presentSession(film)
        } label: {
            Text("Start session with this film")
        }
        .buttonStyle(RedroomPrimaryButtonStyle())
        .padding(.top, 4)
    }

    private func presentSession(_ film: LibraryFilm) {
        guard let legacyFilm = store.legacyFilm(key: film.key) else { return }

        var developer: Developer?
        var dilution: Dilution?
        if let record = store.times(forFilm: film.key).first(where: { $0.seconds != nil }),
           let match = store.legacyDevelopers.first(where: { $0.id == record.developer }) {
            developer = match
            dilution = match.dilution(id: record.dilution) ?? match.dilutions.first
        }

        sessionSelection = RedroomSessionSelection(film: legacyFilm, developer: developer, dilution: dilution)
    }
}

/// Carries a film into the room's session setup.
struct RedroomSessionSelection: Identifiable {
    let id = UUID()
    let film: Film
    let developer: Developer?
    let dilution: Dilution?
}

private enum ChartSectionState {
    case idle
    case loading
    case loaded(ChartFilmTimes)
    case empty
    case failed(String)
}

// MARK: - Cross-process sheet

private struct RedroomCrossProcessSheet: View {
    let filmKey: String

    @ObservedObject private var store = LibraryStore.shared

    var body: some View {
        RedroomSheetBody(
            kicker: "Recipes",
            title: "Cross-processing",
            detail: "What each classification means is decided by who tested it, not by how it looks."
        ) {
            ForEach(store.crossProcess(forFilm: filmKey)) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("\(entry.fromProcess.label) → \(entry.toProcess.label)")
                            .font(Redroom.body(14, weight: .semibold))
                            .foregroundStyle(Redroom.text)
                        Spacer(minLength: 4)
                        RedroomProvenanceBadge(kind: entry.provenance.kind)
                    }

                    Text(entry.classification.label.uppercased())
                        .font(Redroom.label(9))
                        .tracking(0.8)
                        .foregroundStyle(Redroom.safelight)

                    Text(entry.summary)
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .redroomGlass(variant: .smoked, cornerRadius: 18)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Developer detail

struct RedroomDeveloperDetail: View {
    let developerKey: String

    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if let developer = store.developer(key: developerKey) {
                content(developer)
            } else {
                RedroomScreen {
                    RedroomEmptyState(
                        title: "This developer is no longer in the library",
                        detail: "It was removed with an import, or the library was reset.",
                        symbol: "flask"
                    )
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(
                kicker: "Recipes",
                title: store.developer(key: developerKey)?.name ?? "Developer"
            )
            .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(_ developer: LibraryDeveloper) -> some View {
        RedroomScreen {
            VStack(spacing: 5) {
                Text(kicker(developer).uppercased())
                    .font(Redroom.label(10))
                    .tracking(2)
                    .foregroundStyle(Redroom.textMuted)

                Text(developer.name)
                    .font(Redroom.display(28, weight: .bold))
                    .foregroundStyle(Redroom.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            factsSection(developer)
            dilutionsSection(developer)
            filmsSection(developer)
            sourcesSection(developer)
        }
    }

    private func kicker(_ developer: LibraryDeveloper) -> String {
        [developer.manufacturer, developer.type].compactMap { $0 }.joined(separator: " · ")
    }

    private func factsSection(_ developer: LibraryDeveloper) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RedroomSectionHeader(title: "Capacity and reuse")
            factCard(title: "Capacity", symbol: "cylinder.split.1x2", fact: developer.capacity)
            factCard(title: "Reuse", symbol: "arrow.triangle.2.circlepath", fact: developer.reuse)
        }
    }

    private func factCard(title: String, symbol: String, fact: LibraryFact?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Redroom.textMuted)
                Text(title.uppercased())
                    .font(Redroom.label(8))
                    .tracking(1)
                    .foregroundStyle(Redroom.textMuted)
                Spacer(minLength: 4)
                if let fact {
                    RedroomProvenanceBadge(kind: fact.provenance.kind)
                }
            }

            Text(fact?.value ?? "Not documented")
                .font(Redroom.body(13))
                .foregroundStyle(fact == nil ? Redroom.textMuted : Redroom.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked, cornerRadius: 16)
    }

    private func dilutionsSection(_ developer: LibraryDeveloper) -> some View {
        RedroomPanel(title: "Dilutions") {
            ForEach(Array(developer.dilutions.enumerated()), id: \.element.id) { index, dilution in
                HStack(spacing: 8) {
                    Text(dilution.label)
                        .font(Redroom.body(14, weight: .semibold))
                        .foregroundStyle(Redroom.text)

                    Text(dilution.ratio ?? "Ratio not documented")
                        .font(Redroom.body(11))
                        .foregroundStyle(Redroom.textMuted)

                    Spacer(minLength: 4)

                    RedroomProvenanceBadge(kind: dilution.provenance?.kind ?? .unverified)
                }
                .padding(.vertical, 7)

                if index < developer.dilutions.count - 1 {
                    RedroomLitRule(thickness: 0.5)
                }
            }
        }
    }

    private struct FilmRow: Identifiable {
        let id: String
        let filmKey: String
        let filmName: String
        let dilution: String
        let time: String
        let provenance: LibraryProvenanceKind
    }

    private func filmRows(_ developer: LibraryDeveloper) -> [FilmRow] {
        store.times(forDeveloper: developer.key)
            .compactMap { entry in
                guard let film = store.film(key: entry.film) else { return nil }
                return FilmRow(
                    id: entry.id,
                    filmKey: film.key,
                    filmName: film.displayName,
                    dilution: store.dilutionLabel(developerKey: developer.key, dilution: entry.dilution),
                    time: entry.seconds.map { Clock.mmss(TimeInterval($0)) } ?? "—",
                    provenance: entry.provenance.kind
                )
            }
            .sorted { $0.filmName.localizedCaseInsensitiveCompare($1.filmName) == .orderedAscending }
    }

    @ViewBuilder
    private func filmsSection(_ developer: LibraryDeveloper) -> some View {
        let rows = filmRows(developer)
        if !rows.isEmpty {
            RedroomPanel(title: "Films with a documented time") {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    NavigationLink {
                        RedroomFilmDetail(filmKey: row.filmKey)
                    } label: {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.filmName)
                                    .font(Redroom.body(13, weight: .semibold))
                                    .foregroundStyle(Redroom.text)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text(row.dilution)
                                    .font(Redroom.body(10))
                                    .foregroundStyle(Redroom.textMuted)
                            }

                            Spacer(minLength: 4)

                            Text(row.time)
                                .font(Redroom.figure(13, weight: .semibold))
                                .foregroundStyle(Redroom.text)

                            RedroomProvenanceBadge(kind: row.provenance)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Redroom.textMuted)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())

                    if index < rows.count - 1 {
                        RedroomLitRule(thickness: 0.5)
                    }
                }
            }
        }
    }

    private func sources(for developer: LibraryDeveloper) -> [LibrarySource] {
        var keys: [String] = []
        for fact in [developer.capacity, developer.reuse] {
            if let key = fact?.provenance.source, !keys.contains(key) { keys.append(key) }
        }
        for dilution in developer.dilutions {
            if let key = dilution.provenance?.source, !keys.contains(key) { keys.append(key) }
        }
        return keys.compactMap { store.source(key: $0) }
    }

    @ViewBuilder
    private func sourcesSection(_ developer: LibraryDeveloper) -> some View {
        let sources = sources(for: developer)
        if !sources.isEmpty {
            RedroomPanel(title: "Sources") {
                ForEach(Array(sources.enumerated()), id: \.element.key) { index, source in
                    Button {
                        if let url = URL(string: source.url), !source.url.isEmpty {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Redroom.textMuted)

                            Text(source.title)
                                .font(Redroom.body(13))
                                .foregroundStyle(Redroom.text)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: 4)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Redroom.textMuted)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(HapticButtonStyle())

                    if index < sources.count - 1 {
                        RedroomLitRule(thickness: 0.5)
                    }
                }
            }
        }
    }
}

// MARK: - Verification queue

struct RedroomVerificationQueue: View {
    @ObservedObject private var store = LibraryStore.shared

    private var grouped: [(kind: VerificationItem.Kind, items: [VerificationItem])] {
        let items = store.verificationItems
        return VerificationItem.Kind.allCases.compactMap { kind in
            let matching = items.filter { $0.kind == kind }
            return matching.isEmpty ? nil : (kind, matching)
        }
    }

    var body: some View {
        RedroomSheetBody(
            kicker: "Recipes",
            title: "To verify",
            detail: "Every record the library still owes a source. A pairing with no sourced time stays blank rather than borrowing a number from somewhere else."
        ) {
            if grouped.isEmpty {
                RedroomEmptyState(
                    title: "Nothing outstanding",
                    detail: "Every record in the library carries a source.",
                    symbol: "checkmark.seal"
                )
            } else {
                ForEach(grouped, id: \.kind) { group in
                    RedroomPanel(title: group.kind.label, detail: "\(group.items.count) outstanding") {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                            row(item)

                            if index < group.items.count - 1 {
                                RedroomLitRule(thickness: 0.5)
                            }
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func row(_ item: VerificationItem) -> some View {
        if let filmKey = item.filmKey {
            NavigationLink {
                RedroomFilmDetail(filmKey: filmKey)
            } label: {
                content(item)
            }
            .buttonStyle(HapticButtonStyle())
        } else if let developerKey = item.developerKey {
            NavigationLink {
                RedroomDeveloperDetail(developerKey: developerKey)
            } label: {
                content(item)
            }
            .buttonStyle(HapticButtonStyle())
        } else {
            content(item)
        }
    }

    private func content(_ item: VerificationItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Redroom.body(13, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .multilineTextAlignment(.leading)
                Text(item.subtitle)
                    .font(Redroom.body(11))
                    .foregroundStyle(Redroom.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Film finder

/// The film index, searched or read from a photograph. The index's own search
/// and Vision reading are the app's; this is the room it happens in.
struct RedroomFilmFinder: View {
    @ObservedObject private var store = LibraryStore.shared
    @ObservedObject private var catalog = FilmCatalog.shared
    @Environment(\.openURL) private var openURL

    @State private var query = ""
    @State private var hits: [IdentifierHit] = []
    @State private var isScanning = false
    @State private var scanNote: String?
    @State private var readingText: String?
    @State private var pickedItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var catalogEntry: CatalogFilm?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        RedroomSheetBody(
            kicker: "Recipes",
            title: "Film finder",
            detail: "Search the film index by name, manufacturer or the DX code on the canister — or photograph the canister and let the app read it."
        ) {
            searchField
            scanPanel
            results
            attribution
        }
        .task { catalog.load() }
        .onAppear { refreshSearch() }
        .onChange(of: query) { _, _ in refreshSearch() }
        .onChange(of: catalog.isLoaded) { _, _ in refreshSearch() }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await readPicked(item) }
        }
        .photosPicker(isPresented: $showingLibrary, selection: $pickedItem, matching: .images)
        .fullScreenCover(isPresented: $showingCamera) {
            FilmCameraPicker { image in
                Task { await scan(image) }
            }
        }
        .sheet(item: $catalogEntry) { entry in
            RedroomCatalogSheet(entry: entry)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Redroom.textMuted)

            TextField("Name, manufacturer or DX code", text: $query)
                .font(Redroom.body(14))
                .foregroundStyle(Redroom.text)
                .tint(Redroom.safelight)
                .textInputAutocapitalization(.words)
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

    private var scanPanel: some View {
        RedroomPanel(title: "Identify from a photo") {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Reads the printed name, ISO and any code it can decode.")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                if cameraAvailable {
                    Button {
                        showingCamera = true
                    } label: {
                        Text("Take a photo")
                    }
                    .buttonStyle(RedroomPrimaryButtonStyle())
                }

                Button {
                    showingLibrary = true
                } label: {
                    Text("Choose a photo")
                }
                .buttonStyle(RedroomSecondaryButtonStyle())
            }

            if isScanning {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Redroom.safelight)
                    Text("Reading the canister…")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                }
            }

            if let readingText {
                Text("It read: \(readingText)")
                    .font(Redroom.body(10))
                    .foregroundStyle(Redroom.textMuted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let scanNote {
                RedroomNote(text: scanNote, symbol: "barcode.viewfinder")
            }

            RedroomNote(text: "The DX code along a 35 mm canister is not a standard barcode, so a clear photo of the printed name is the most reliable thing to point at.")
        }
    }

    @ViewBuilder
    private var results: some View {
        if !catalog.isLoaded {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Redroom.safelight)
                Text("Loading the film index…")
                    .font(Redroom.body(12))
                    .foregroundStyle(Redroom.textMuted)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .redroomGlass(variant: .smoked, cornerRadius: 18)
        } else if hits.isEmpty {
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                RedroomNote(text: "Nothing in the index matches that.", symbol: "questionmark.circle")
            }
        } else {
            let libraryHits = hits.filter { $0.libraryKey != nil }
            let indexHits = hits.filter { $0.libraryKey == nil }

            if !libraryHits.isEmpty {
                hitSection(title: "In your development library", hits: libraryHits)
            }
            if !indexHits.isEmpty {
                hitSection(title: "Film index", hits: indexHits)
            }
        }
    }

    private func hitSection(title: String, hits: [IdentifierHit]) -> some View {
        RedroomPanel(title: title, detail: "\(hits.count) match\(hits.count == 1 ? "" : "es")") {
            ForEach(Array(hits.enumerated()), id: \.element.id) { index, hit in
                row(hit)

                if index < hits.count - 1 {
                    RedroomLitRule(thickness: 0.5)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ hit: IdentifierHit) -> some View {
        if let key = hit.libraryKey {
            NavigationLink {
                RedroomFilmDetail(filmKey: key)
            } label: {
                rowContent(hit)
            }
            .buttonStyle(HapticButtonStyle())
        } else {
            Button {
                catalogEntry = hit.entry
            } label: {
                rowContent(hit)
            }
            .buttonStyle(HapticButtonStyle())
        }
    }

    private func rowContent(_ hit: IdentifierHit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(hit.entry.name)
                    .font(Redroom.body(14, weight: .semibold))
                    .foregroundStyle(Redroom.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                if hit.libraryKey != nil {
                    RedroomChip(text: "Times", emphasised: true)
                }
            }

            Text(hit.entry.makerLine)
                .font(Redroom.body(11))
                .foregroundStyle(Redroom.textMuted)

            HStack(spacing: 8) {
                if let dx = hit.entry.dxLine {
                    Text(dx)
                        .font(Redroom.figure(10, weight: .regular))
                        .foregroundStyle(Redroom.textMuted)
                }
                if let years = hit.entry.yearsLine {
                    Text(years)
                        .font(Redroom.body(10))
                        .foregroundStyle(Redroom.textMuted)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Redroom.textMuted)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var attribution: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Film index from The Big Film Database (dxdatabase), used under CC BY-SA 4.0.")
                .font(Redroom.body(10))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open the source") {
                if let url = URL(string: "https://github.com/dxdatabase/Open-source-film-database") {
                    openURL(url)
                }
            }
            .font(Redroom.body(11, weight: .semibold))
            .foregroundStyle(Redroom.safelight)
        }
    }

    private func refreshSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            hits = []
            return
        }
        hits = catalog.search(trimmed).map(hit(for:))
    }

    private func hit(for entry: CatalogFilm) -> IdentifierHit {
        let film = store.libraryFilm(for: entry)
        return IdentifierHit(
            id: entry.id,
            entry: entry,
            libraryKey: film?.key,
            libraryTitle: film.map { "\($0.manufacturer) \($0.name) \($0.iso)" }
        )
    }

    private func readPicked(_ item: PhotosPickerItem) async {
        defer { pickedItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            scanNote = "That photo could not be read."
            return
        }
        await scan(image)
    }

    @MainActor
    private func scan(_ image: UIImage) async {
        isScanning = true
        scanNote = nil
        readingText = nil

        let reading = await FilmScan.read(image)
        let entries = catalog.identify(texts: reading.texts, barcodes: reading.barcodes)
        hits = entries.map(hit(for:))
        readingText = reading.texts.isEmpty ? nil : reading.texts.prefix(3).joined(separator: " · ")

        if entries.isEmpty {
            scanNote = "Nothing matched. Try a sharper photo of the printed name and ISO, or type the DX code instead."
        } else {
            scanNote = "\(entries.count) possible match\(entries.count == 1 ? "" : "es") — check the name before you trust it."
        }

        isScanning = false
    }
}

// MARK: - Index entry sheet

private struct RedroomCatalogSheet: View {
    let entry: CatalogFilm

    var body: some View {
        RedroomSheetBody(
            kicker: entry.makerLine,
            title: entry.name,
            detail: "The index knows this canister, but the development library has no documented times for it yet."
        ) {
            RedroomPanel {
                if let dx = entry.dxLine {
                    RedroomValueRow(label: "DX code", value: dx)
                }
                if let years = entry.yearsLine {
                    RedroomValueRow(label: "Years", value: years)
                }
                if let country = entry.country {
                    RedroomValueRow(label: "Country", value: country)
                }
                if let distributor = entry.distributor {
                    RedroomValueRow(label: "Distributor", value: distributor)
                }
                if let notes = entry.notes {
                    RedroomValueRow(label: "Notes", value: notes)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
