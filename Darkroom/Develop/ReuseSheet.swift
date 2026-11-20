//
//  ReuseSheet.swift
//  Darkroom
//
//  Asked right before a session starts: which use of the developer this is. A fresh
//  mix is use 1; each earlier use adds 10%, compounded, so use 3 is +21%.
//

import SwiftUI

struct ReuseSheet: View {
    let developerName: String
    let compensatedSeconds: TimeInterval?
    let initialUse: Int
    let onStart: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var use: Int

    init(
        developerName: String,
        compensatedSeconds: TimeInterval?,
        initialUse: Int,
        onStart: @escaping (Int) -> Void
    ) {
        self.developerName = developerName
        self.compensatedSeconds = compensatedSeconds
        self.initialUse = initialUse
        self.onStart = onStart
        _use = State(initialValue: initialUse)
    }

    private var finalSeconds: TimeInterval? {
        guard let compensatedSeconds else { return nil }
        return (compensatedSeconds * DevelopmentSetup.reuseFactor(uses: use)).rounded()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        OverlineText(text: "Before the developer goes in", color: Theme.amber)
                        Text("Which use is this?")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(developerName), mixed fresh, is use 1. Each earlier use adds 10%, compounded.")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 14) {
                        Stepper(value: $use, in: 1...20) {
                            LabeledContent("Use", value: "\(use)")
                        }

                        Text(DevelopmentSetup.reuseArithmetic(uses: use))
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(18)
                    .glassCard(radius: 26)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Development time for this use")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.inkSoft)
                        Text(finalSeconds.map { Clock.mmss($0) } ?? "--:--")
                            .font(.figures(44, weight: .semibold))
                            .foregroundStyle(Theme.amber)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(radius: 26)

                    Button {
                        onStart(use)
                        dismiss()
                    } label: {
                        Label("Start session", systemImage: "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.amberInk)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Theme.amber)
                    .controlSize(.large)
                    .disabled(finalSeconds == nil)
                }
                .padding(20)
            }
            .background {
                LiquidBackdrop()
            }
            .navigationTitle("Developer use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
