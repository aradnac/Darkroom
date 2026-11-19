//
//  JournalView.swift
//  Darkroom
//
//  Placeholder until the journal and statistics are built.
//

import SwiftUI

struct JournalView: View {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    private let bullets: [String] = [
        "Each session logged with film, developer, time and temperature",
        "Search, filter and re-run a past session",
        "Averages against the published times",
        "Totals per chemical batch"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if themeStore.isTheme13Active {
                        Theme13EmptyState(
                            index: "02",
                            headline: "Journal",
                            detail: "Every development session, kept and searchable.",
                            bullets: bullets
                        )
                    } else {
                        ComingNextView(
                            systemImage: "book.closed",
                            headline: "Journal",
                            detail: "Every development session, kept and searchable. On the roadmap as Journal and statistics.",
                            bullets: bullets
                        )
                    }
                }
                .padding(20)
            }
            .background {
                LiquidBackdrop()
            }
            .appNavigationChrome(index: "04", title: "Journal")
        }
    }
}
