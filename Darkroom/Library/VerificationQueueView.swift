//
//  VerificationQueueView.swift
//  Darkroom
//
//  Everything the library still owes a source. Nothing here is a guess: each row
//  is either a documented pairing with no time, or a field that has never been
//  filled because no document would fill it.
//

import SwiftUI

struct VerificationQueueView: View {
    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.dismiss) private var dismiss

    private var grouped: [(kind: VerificationItem.Kind, items: [VerificationItem])] {
        let items = store.verificationItems
        return VerificationItem.Kind.allCases.compactMap { kind in
            let matching = items.filter { $0.kind == kind }
            return matching.isEmpty ? nil : (kind, matching)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Every record the library still owes a source. A pairing with no sourced time stays blank here rather than borrowing a number from somewhere else.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    if grouped.isEmpty {
                        emptyState
                    } else {
                        ForEach(grouped, id: \.kind) { group in
                            section(group)
                        }
                    }
                }
                .padding(20)
            }
            .background { LiquidBackdrop() }
            .navigationTitle("Verification queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing outstanding")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("Every record in the library carries a source.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 22)
    }

    private func section(_ group: (kind: VerificationItem.Kind, items: [VerificationItem])) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(group.kind.label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Theme.inkFaint)
                Spacer(minLength: 6)
                Text("\(group.items.count)")
                    .font(.figures(13, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }

            VStack(spacing: 0) {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                    row(item)

                    if index < group.items.count - 1 {
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

    @ViewBuilder
    private func row(_ item: VerificationItem) -> some View {
        if let filmKey = item.filmKey {
            NavigationLink {
                FilmDetailView(filmKey: filmKey)
            } label: {
                content(item)
            }
            .buttonStyle(HapticButtonStyle())
        } else if let developerKey = item.developerKey {
            NavigationLink {
                DeveloperDetailView(developerKey: developerKey)
            } label: {
                content(item)
            }
            .buttonStyle(HapticButtonStyle())
        } else {
            content(item)
        }
    }

    private func content(_ item: VerificationItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

extension VerificationItem.Kind: CaseIterable {
    static var allCases: [VerificationItem.Kind] {
        [.time, .film, .capacity, .reuse]
    }
}
