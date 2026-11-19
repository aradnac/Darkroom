//
//  RecipesView.swift
//  Darkroom
//
//  The film and chemistry library: browse, filter, and read one film or
//  developer at a time, with the provenance of every documented number.
//

import SwiftUI

struct RecipesView: View {
    var body: some View {
        NavigationStack {
            LibraryBrowserView()
                .appNavigationChrome(index: "02", title: "Recipes")
        }
    }
}
