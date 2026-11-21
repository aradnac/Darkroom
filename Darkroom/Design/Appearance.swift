//
//  Appearance.swift
//  Darkroom
//
//  The app-wide visual state that is not a choice of its own: whether the tab
//  stack must be rebuilt, and whether Settings is on screen. The theme lives in
//  ThemeLanguageStore, the palette and the other preferences in Preferences;
//  this store reads them and tells the root when they change.
//

import SwiftUI

/// Publishes the revision the app root re-dresses itself on. Writes that the
/// native tab stack reads bump it, so the stack is rebuilt with the new look.
final class AppearanceStore: ObservableObject {
    static let shared = AppearanceStore()

    @Published private(set) var revision: Int = 0

    /// Set by the Tools hub and the Develop header; the app root presents
    /// Settings as a sheet so the tabs behind it can be rebuilt without tearing
    /// down the screen.
    @Published var isShowingSettings = false {
        didSet {
            guard oldValue != isShowingSettings else { return }
            if !isShowingSettings {
                bumpRevision()
            }
        }
    }

    private init() {}

    // MARK: Derived

    /// True while the Soft Light theme owns the interface.
    var isSoftGlassActive: Bool { ThemeLanguageStore.shared.selected == .softLight }

    /// The compact density shortens the native controls as it tightens the rest.
    var compactControls: Bool { ThemeLanguageStore.shared.density == .compact }

    /// Re-dresses the app root. Called by every write the native screens read.
    func bumpRevision() {
        revision &+= 1
    }
}
