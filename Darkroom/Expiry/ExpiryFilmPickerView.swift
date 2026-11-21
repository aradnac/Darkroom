//
//  ExpiryFilmPickerView.swift
//  Darkroom
//
//  Choosing the stock the expired-film calculator is being asked about. It reads
//  the same catalogue the Recipes tab does, and it will take a film the library
//  does not hold rather than refusing to answer — that film simply comes back
//  labelled as a guess.
//

import SwiftUI

/// What the calculator was pointed at.
enum ExpiryFilmSelection: Equatable {
    case library(String)
    case unlisted(name: String, iso: Int, process: FilmProcess)

    var filmKey: String {
        switch self {
        case .library(let key): return key
        case .unlisted: return "unlisted"
        }
    }
}

struct ExpiryFilmPickerView: View {
    @ObservedObject private var store = LibraryStore.shared
    @Environment(\.dismiss) private var dismiss

    let selection: ExpiryFilmSelection
    let onSelect: (ExpiryFilmSelection) -> Void

    @State private var query = ""
    @State private var unlistedName = ""
    @State private var unlistedISO = "400"
    @State private var unlistedProcess: FilmProcess = .blackAndWhite

    init(selection: ExpiryFilmSelection, onSelect: @escaping (ExpiryFilmSelection) -> Void) {
        self.selection = selection
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField

                List {
                    ForEach(films) { film in
                        Button {
                            onSelect(.library(film.key))
                            dismiss()
                        } label: {
                            row(for: film)
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        unlistedForm
                    } header: {
                        Text("NOT IN THE LIBRARY")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background { LiquidBackdrop() }
            .navigationTitle("Film stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: Data

    private var films: [LibraryFilm] {
        store.films(matching: query, process: nil, status: nil)
    }

    private func row(for film: LibraryFilm) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(film.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(film.manufacturer) · \(film.process.label)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if case .library(let key) = selection, key == film.key {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }
        }
        .contentShape(Rectangle())
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.inkFaint)

            TextField("Name or maker", text: $query)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .tint(Theme.amber)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkFaint)
                }
                .buttonStyle(HapticButtonStyle())
                .accessibilityLabel("Clear the search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surfaceRaised)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Unlisted

    private var unlistedForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Any film can be run through the model. One the library does not hold gets the conservative family and an educated guess, because nothing more can honestly be said about it.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                TextField("Name", text: $unlistedName)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.amber)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Theme.surfaceRaised)
                    }

                TextField("ISO", text: $unlistedISO)
                    .keyboardType(.numberPad)
                    .font(.figures(14))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.amber)
                    .frame(width: 64)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Theme.surfaceRaised)
                    }
            }

            Picker("Process", selection: $unlistedProcess) {
                ForEach(FilmProcess.allCases) { process in
                    Text(process.label).tag(process)
                }
            }
            .pickerStyle(.segmented)

            Button {
                onSelect(.unlisted(name: unlistedName, iso: iso, process: unlistedProcess))
                dismiss()
            } label: {
                Text("Use this film")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.amberInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background { Capsule().fill(Theme.amberGradient) }
            }
            .buttonStyle(HapticButtonStyle())
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.clear)
    }

    private var iso: Int {
        let digits = unlistedISO.filter(\.isNumber)
        return max(1, min(6400, Int(digits) ?? 400))
    }
}
