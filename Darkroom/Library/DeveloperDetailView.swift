//
//  DeveloperDetailView.swift
//  Darkroom
//
//  One developer: its dilutions, what a litre actually yields, how it is reused,
//  and every film in the library that has a sourced time in it.
//

import SwiftUI

struct DeveloperDetailView: View {
    let developerKey: String

    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if let developer = store.developer(key: developerKey) {
                content(developer)
            } else {
                missing
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var missing: some View {
        VStack(alignment: .leading, spacing: 10) {
            OverlineText(text: "Library", color: Theme.amber)
            Text("This developer is no longer in the library.")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Button("Go back") { dismiss() }
                .buttonStyle(AmberCapsuleStyle(height: 48))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { LiquidBackdrop() }
    }

    private func content(_ developer: LibraryDeveloper) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    CircleIconButton(systemImage: "chevron.left", size: 42) {
                        dismiss()
                    }
                    .accessibilityLabel("Back")
                    Spacer(minLength: 8)
                }

                VStack(spacing: 6) {
                    Text(kicker(developer).uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(Theme.inkSoft)

                    Text(developer.name)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                factsSection(developer)
                dilutionsSection(developer)
                filmsSection(developer)
                sourcesSection(developer)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background { LiquidBackdrop() }
    }

    private func kicker(_ developer: LibraryDeveloper) -> String {
        [developer.manufacturer, developer.type].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: Facts

    private func factsSection(_ developer: LibraryDeveloper) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LibrarySectionTitle(text: "Capacity and reuse")

            factCard(
                title: "Capacity",
                symbol: "cylinder.split.1x2",
                fact: developer.capacity
            )
            factCard(
                title: "Reuse",
                symbol: "arrow.triangle.2.circlepath",
                fact: developer.reuse
            )
        }
    }

    private func factCard(title: String, symbol: String, fact: LibraryFact?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.inkSoft)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 6)
                if let fact {
                    LibraryBadge(kind: fact.provenance.kind)
                }
            }

            Text(fact?.value ?? "Not documented")
                .font(.system(size: 15))
                .foregroundStyle(fact == nil ? Theme.inkSoft : Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 20)
    }

    // MARK: Dilutions

    private func dilutionsSection(_ developer: LibraryDeveloper) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LibrarySectionTitle(text: "Dilutions")

            VStack(spacing: 0) {
                ForEach(Array(developer.dilutions.enumerated()), id: \.element.id) { index, dilution in
                    HStack(spacing: 10) {
                        Text(dilution.label)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)

                        Text(dilution.ratio ?? "Ratio not documented")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkSoft)

                        Spacer(minLength: 6)

                        if let provenance = dilution.provenance {
                            LibraryBadge(kind: provenance.kind)
                        } else {
                            LibraryBadge(kind: .unverified)
                        }
                    }
                    .padding(.vertical, 13)

                    if index < developer.dilutions.count - 1 {
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

    // MARK: Films

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
            VStack(alignment: .leading, spacing: 10) {
                LibrarySectionTitle(text: "Films with a documented time")

                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        NavigationLink {
                            FilmDetailView(filmKey: row.filmKey)
                        } label: {
                            HStack(spacing: 10) {
                                Text(row.filmName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text(row.dilution)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.inkSoft)

                                Spacer(minLength: 6)

                                Text(row.time)
                                    .font(.figures(15, weight: .semibold))
                                    .foregroundStyle(row.time == "—" ? Theme.inkFaint : Theme.amber)

                                LibraryBadge(kind: row.provenance)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                            .padding(.vertical, 13)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(HapticButtonStyle())

                        if index < rows.count - 1 {
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

    // MARK: Sources

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
            VStack(alignment: .leading, spacing: 10) {
                LibrarySectionTitle(text: "Sources")

                VStack(spacing: 0) {
                    ForEach(Array(sources.enumerated()), id: \.element.key) { index, source in
                        Button {
                            if let url = URL(string: source.url), !source.url.isEmpty {
                                openURL(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(Theme.inkSoft)

                                Text(source.title)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.ink)
                                    .multilineTextAlignment(.leading)

                                Spacer(minLength: 6)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(HapticButtonStyle())

                        if index < sources.count - 1 {
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
