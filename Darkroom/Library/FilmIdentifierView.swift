//
//  FilmIdentifierView.swift
//  Darkroom
//
//  Which film is this? Search the DX index by name, manufacturer or the code
//  printed on the canister; or photograph the canister and let Vision read it.
//  Anything the index knows that the development library also carries opens its
//  times; anything else is shown honestly as an index entry with no times yet.
//

import PhotosUI
import SwiftUI
import UIKit

struct IdentifierHit: Identifiable {
    let id: String
    let entry: CatalogFilm
    let libraryKey: String?
    let libraryTitle: String?
}

struct FilmIdentifierView: View {
    @ObservedObject private var store = LibraryStore.shared
    @ObservedObject private var catalog = FilmCatalog.shared
    @Environment(\.dismiss) private var dismiss
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    introduction
                    searchField
                    scanCard
                    results
                    attribution
                }
                .padding(20)
            }
            .background { LiquidBackdrop() }
            .navigationTitle("Film identifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { catalog.load() }
            .onAppear { refreshSearch() }
            .onChange(of: query) { _, _ in refreshSearch() }
            .onChange(of: catalog.isLoaded) { _, _ in refreshSearch() }
            .onChange(of: pickedItem) { _, item in
                guard let item else { return }
                Task { await readPicked(item) }
            }
        }
        .photosPicker(isPresented: $showingLibrary, selection: $pickedItem, matching: .images)
        .fullScreenCover(isPresented: $showingCamera) {
            FilmCameraPicker { image in
                Task { await scan(image) }
            }
        }
        .sheet(item: $catalogEntry) { entry in
            CatalogFilmSheet(entry: entry)
        }
    }

    // MARK: Copy and search

    private var introduction: some View {
        Text("Search the film index by name, manufacturer or the DX code printed on the canister — or photograph the canister and let the app read it.")
            .font(.system(size: 13))
            .foregroundStyle(Theme.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.inkFaint)

            TextField("Name, manufacturer or DX code", text: $query)
                .font(.system(size: 16))
                .foregroundStyle(Theme.ink)
                .tint(Theme.amber)
                .textInputAutocapitalization(.words)
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

    private var scanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.amber)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Identify from a photo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Reads the printed name, ISO and any code it can decode.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                if cameraAvailable {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take a photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AmberCapsuleStyle(height: 46))
                }

                Button {
                    showingLibrary = true
                } label: {
                    Label("Choose a photo", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassCapsuleStyle(height: 46))
            }

            if isScanning {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Theme.amber)
                    Text("Reading the canister…")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            if let readingText {
                Text("It read: \(readingText)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let scanNote {
                Text(scanNote)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("The DX code along a 35 mm canister is not a standard barcode, so a clear photo of the printed name is the most reliable thing to point at.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 22)
    }

    // MARK: Results

    @ViewBuilder
    private var results: some View {
        if !catalog.isLoaded {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Theme.amber)
                Text("Loading the film index…")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 20)
        } else if hits.isEmpty {
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Nothing in the index matches that.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 2)
            }
        } else {
            let libraryHits = hits.filter { $0.libraryKey != nil }
            let indexHits = hits.filter { $0.libraryKey == nil }

            if !libraryHits.isEmpty {
                hitSection(title: "In your development library", hits: libraryHits)
            }
            if !indexHits.isEmpty {
                section("Film index", count: indexHits.count) {
                    VStack(spacing: 0) {
                        ForEach(Array(indexHits.enumerated()), id: \.element.id) { index, hit in
                            row(hit)
                            if index < indexHits.count - 1 {
                                Rectangle()
                                    .fill(Theme.hairline)
                                    .frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .glassCard(radius: 22)
                }
            }
        }
    }

    private func hitSection(title: String, hits: [IdentifierHit]) -> some View {
        section(title, count: hits.count) {
            VStack(spacing: 0) {
                ForEach(Array(hits.enumerated()), id: \.element.id) { index, hit in
                    row(hit)
                    if index < hits.count - 1 {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .glassCard(radius: 22)
        }
    }

    private func section<Content: View>(
        _ title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 6)
                Text("\(count)")
                    .font(.figures(12, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }
            content()
        }
    }

    @ViewBuilder
    private func row(_ hit: IdentifierHit) -> some View {
        if let key = hit.libraryKey {
            NavigationLink {
                FilmDetailView(filmKey: key)
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                if hit.libraryKey != nil {
                    Text("TIMES")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Theme.amberInk)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background { Capsule().fill(Theme.amber) }
                }
            }

            Text(hit.entry.makerLine)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkSoft)

            HStack(spacing: 8) {
                if let dx = hit.entry.dxLine {
                    Text(dx)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.inkFaint)
                }
                if let years = hit.entry.yearsLine {
                    Text(years)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var attribution: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Film index from The Big Film Database (dxdatabase), used under CC BY-SA 4.0.")
            Button("Open the source") {
                if let url = URL(string: "https://github.com/dxdatabase/Open-source-film-database") {
                    openURL(url)
                }
            }
            .foregroundStyle(Theme.amber)
        }
        .font(.system(size: 11))
        .foregroundStyle(Theme.inkFaint)
        .padding(.top, 4)
    }

    // MARK: Actions

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

// MARK: - Index entry

private struct CatalogFilmSheet: View {
    let entry: CatalogFilm

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.name)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(entry.makerLine)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    VStack(spacing: 0) {
                        if let dx = entry.dxLine {
                            detailRow("DX code", dx)
                        }
                        if let years = entry.yearsLine {
                            detailRow("Years", years)
                        }
                        if let country = entry.country {
                            detailRow("Country", country)
                        }
                        if let distributor = entry.distributor {
                            detailRow("Distributor", distributor)
                        }
                        if let notes = entry.notes {
                            detailRow("Notes", notes)
                        }
                    }
                    .padding(.horizontal, 16)
                    .glassCard(radius: 22)

                    Text("The index knows this canister, but the development library has no documented times for it yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .background { LiquidBackdrop() }
            .navigationTitle("Film index")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 88, alignment: .leading)

            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 11)
    }
}
