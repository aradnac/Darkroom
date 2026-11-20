//
//  LibraryBrowserView.swift
//  Darkroom
//
//  The Recipes tab: the searchable catalogue of films and developers, filtered by
//  process and status, with the verification queue and the import pipeline one
//  tap away.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryBrowserView: View {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                searchField
                identifyRow
                SegmentedPill(options: Mode.allCases, selection: $mode) { $0.label }

                if mode == .films {
                    VStack(alignment: .leading, spacing: 14) {
                        filters
                        filmList
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    developerList
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                chartSources
            }
            .animation(.snappy(duration: 0.32, extraBounce: 0.04), value: mode)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background { LiquidBackdrop() }
        .task { FilmCatalog.shared.load() }
        .sheet(isPresented: $showingIdentifier) {
            FilmIdentifierView()
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
        .sheet(isPresented: $showingQueue) {
            VerificationQueueView()
        }
        .alert("Import", isPresented: $showingImportResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                OverlineText(text: "Reference library", color: Theme.amber)
                Text("Recipes")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }

            Spacer(minLength: 6)

            CircleIconButton(systemImage: "checkmark.seal", size: 40) {
                showingQueue = true
            }
            .overlay(alignment: .topTrailing) {
                let pending = store.verificationItems.count
                if pending > 0 {
                    Text("\(pending)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.amberInk)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background { Capsule().fill(Theme.amber) }
                        .offset(x: 4, y: -4)
                }
            }
            .accessibilityLabel("Verification queue")

            CircleIconButton(systemImage: "square.and.arrow.down", size: 40) {
                importing = true
            }
            .accessibilityLabel("Import records")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.inkFaint)

            TextField("Name, maker or DX code", text: $query)
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

    private var identifyRow: some View {
        Button {
            showingIdentifier = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Theme.amber)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Identify a film")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Photo, name, maker or DX code")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSoft)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
    }

    // MARK: Chart sources

    private var chartSources: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHART SOURCES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.inkFaint)

            sourceLink("35mm.org", detail: "Live times, each with its source", url: "https://35mm.org")
            sourceLink("The Massive Dev Chart", detail: "The long-running community chart", url: "https://www.digitaltruth.com/devchart.php")
            sourceLink("FilmDev", detail: "Community recipes with photographs", url: "https://filmdev.org/recipes/")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 20)
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
    }

    // MARK: Filters

    private var filters: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All processes", isOn: process == nil) {
                        process = nil
                    }
                    ForEach(FilmProcess.allCases) { item in
                        filterChip(item.label, isOn: process == item) {
                            process = item
                        }
                    }
                }
                .padding(.vertical, 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("Any status", isOn: status == nil) {
                        status = nil
                    }
                    ForEach(FilmStatus.allCases) { item in
                        filterChip(item.label, isOn: status == item) {
                            status = item
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

    // MARK: Lists

    private var filmList: some View {
        let films = store.films(matching: query, process: process, status: status)
        return LazyVStack(spacing: 10) {
            if films.isEmpty {
                emptyState("No film matches these filters.")
            } else {
                ForEach(films) { film in
                    NavigationLink {
                        FilmDetailView(filmKey: film.key)
                    } label: {
                        filmRow(film)
                    }
                    .buttonStyle(HapticButtonStyle())
                }
            }
        }
    }

    private func filmRow(_ film: LibraryFilm) -> some View {
        let times = store.times(forFilm: film.key)
        let pending = times.filter { $0.seconds == nil || $0.provenance.kind == .unverified }.count

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(film.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 4)

                LibraryChip(text: film.status.label, emphasised: film.status == .current)
            }

            Text("\(film.manufacturer) · \(film.process.label) · \(film.formatSummary)")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text("\(times.count) time\(times.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)

                if pending > 0 {
                    Text("\(pending) to verify")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.amber)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background { Capsule().fill(Theme.accentWash) }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softGlassRowSurface(key: film.key)
        .contentShape(Rectangle())
    }

    private var developerList: some View {
        let developers = store.developers(matching: query)
        return LazyVStack(spacing: 10) {
            if developers.isEmpty {
                emptyState("No developer matches this search.")
            } else {
                ForEach(developers) { developer in
                    NavigationLink {
                        DeveloperDetailView(developerKey: developer.key)
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

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(developer.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 4)

                if developer.capacity == nil {
                    LibraryBadge(kind: .unverified)
                }
            }

            Text("\(developer.manufacturer) · \(developer.dilutionSummary)")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text("\(films) film\(films == 1 ? "" : "s") with a time")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softGlassRowSurface(key: developer.key)
        .contentShape(Rectangle())
    }

    private func emptyState(_ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nothing here yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 20)
    }
}
