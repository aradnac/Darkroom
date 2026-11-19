//
//  Pickers.swift
//  Darkroom
//
//  The film and developer lists, and the minutes-and-seconds wheel used for times.
//

import SwiftUI

struct FilmPickerView: View {
    @Binding var selection: Film
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(StarterLibrary.films) { film in
                    Button {
                        selection = film
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(film.fullName)
                                    .foregroundStyle(Theme.ink)
                                Text("\(film.formatSummary) · ISO \(film.iso)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                            Spacer()
                            if film == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.amber)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                LiquidBackdrop()
            }
            .navigationTitle("Film")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DeveloperPickerView: View {
    @Binding var selection: Developer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(StarterLibrary.developers) { developer in
                    Button {
                        selection = developer
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(developer.name)
                                    .foregroundStyle(Theme.ink)
                                Text("\(developer.manufacturer) · \(developer.dilutions.map(\.label).joined(separator: " · "))")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                            Spacer()
                            if developer == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.amber)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                LiquidBackdrop()
            }
            .navigationTitle("Developer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Minutes and seconds on two wheels, stored as a whole number of seconds.
struct DurationSheet: View {
    let title: String
    @Binding var seconds: Int
    @Environment(\.dismiss) private var dismiss

    private var minutes: Binding<Int> {
        Binding(
            get: { seconds / 60 },
            set: { seconds = $0 * 60 + seconds % 60 }
        )
    }

    private var remainder: Binding<Int> {
        Binding(
            get: { seconds % 60 },
            set: { seconds = (seconds / 60) * 60 + $0 }
        )
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Minutes", selection: minutes) {
                    ForEach(0...59, id: \.self) { value in
                        Text("\(value) min").tag(value)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Seconds", selection: remainder) {
                    ForEach(0...59, id: \.self) { value in
                        Text("\(value) s").tag(value)
                    }
                }
                .pickerStyle(.wheel)
            }
            .padding(.horizontal, 12)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(340)])
    }
}
