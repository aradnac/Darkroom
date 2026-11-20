//
//  ClearingSheet.swift
//  Darkroom
//
//  Asked before the fixer starts: how long the film leader took to clear, and the
//  multiple of that time to fix for.
//

import SwiftUI

struct ClearingSheet: View {
    let engine: SessionEngine

    @State private var clearingSeconds = 30
    @State private var multiplier = 3

    private var fixSeconds: Int {
        clearingSeconds * multiplier
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        OverlineText(text: "Before the fixer", color: Theme.amber)
                        Text("Film leader clearing time")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Put a strip of film leader in the fixer and time how long it takes to turn clear.")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 14) {
                        Stepper(value: $clearingSeconds, in: 5...600) {
                            LabeledContent("Clearing time", value: "\(clearingSeconds) s")
                        }

                        Picker("Fix multiple", selection: $multiplier) {
                            Text("2×").tag(2)
                            Text("3×").tag(3)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(18)
                    .glassCard(radius: 26)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fix time")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.inkSoft)
                        Text(Clock.mmss(TimeInterval(fixSeconds)))
                            .font(.figures(44, weight: .semibold))
                            .foregroundStyle(Theme.amber)
                        Text("Three times the clearing time is the default. Two times is the common practice in published guides.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(radius: 26)

                    Button {
                        engine.confirmClearing(
                            seconds: TimeInterval(clearingSeconds),
                            multiplier: Double(multiplier)
                        )
                    } label: {
                        Label("Start fixing", systemImage: "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.amberInk)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Theme.amber)
                    .controlSize(.large)

                    VStack(spacing: 8) {
                        Button {
                            engine.useStandardFix(seconds: Preferences.shared.fixSeconds)
                        } label: {
                            Text("Fix for \(Clock.mmss(Preferences.shared.fixSeconds)) instead")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)

                        Text("Your default fix time from Settings, for when you would rather not time the leader.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
            }
            .background {
                LiquidBackdrop()
            }
            .navigationTitle("Fixer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
    }
}
