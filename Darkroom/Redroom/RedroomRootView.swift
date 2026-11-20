//
//  RedroomRootView.swift
//  Darkroom
//
//  The root of the third design language: one safelight, five benches, and the
//  room's own navigation. Reached only when REDROOM is the selected language.
//
//  Everything the app does happens inside this one ZStack: the safelight sits at
//  the back and never takes a touch, the five places change through the chemical
//  immersion, and the bench rail at the foot is the room's own tab bar.
//

import SwiftUI

struct RedroomRootView: View {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("redroom.intensity") private var intensityRaw = RedroomIntensity.normal.rawValue

    @State private var tab: RedroomTab = .develop
    @State private var arrived = false

    private var intensity: RedroomIntensity {
        RedroomIntensity(rawValue: intensityRaw) ?? .normal
    }

    var body: some View {
        ZStack {
            RedroomSafelight()

            Group {
                switch tab {
                case .develop:
                    RedroomDevelopTab()
                case .recipes:
                    RedroomRecipesTab()
                case .chemistry:
                    RedroomChemistryTab()
                case .journal:
                    RedroomJournalTab()
                case .tools:
                    RedroomToolsTab()
                }
            }
            .id(tab)
            .transition(reduceMotion ? .opacity : .redroomImmersion)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RedroomTabBar(selection: $tab)
        }
        .environment(\.redroomLight, RedroomLightParameters(intensity: intensity))
        .preferredColorScheme(.dark)
        .opacity(arrived ? 1 : 0)
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.5), value: arrived)
        .onAppear {
            guard !arrived else { return }
            arrived = true
        }
    }
}

#if DEBUG
#Preview {
    RedroomRootView()
}
#endif
