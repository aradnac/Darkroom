//
//  Theme13Chrome.swift
//  Darkroom
//
//  System chrome for the print theme: opaque paper navigation bars with a hard
//  hairline instead of a blur, a paper tab bar with mono labels, and a serif
//  title face. Reverted to the system defaults when the darkroom is active.
//

import SwiftUI
import UIKit

enum Theme13Chrome {
    static func apply(_ store: Theme13SettingsStore) {
        let navigation = UINavigationBarAppearance()
        let tab = UITabBarAppearance()
        let toolbar = UIToolbarAppearance()

        if store.isTheme13Active {
            let palette = store.palette
            let dark = store.isDarkAppearance

            let field = UIColor(palette.bg(isDark: dark))
            let plate = UIColor(palette.plate(isDark: dark))
            let ink = UIColor(palette.ink(isDark: dark))
            let quietInk = UIColor(palette.inkAlt(isDark: dark))
            let line = UIColor(palette.stroke(isDark: dark))
            let accent = UIColor(palette.accent)
            let accentInk = UIColor(palette.accentText)

            navigation.configureWithOpaqueBackground()
            navigation.backgroundColor = field
            navigation.shadowColor = line
            navigation.titleTextAttributes = [
                .foregroundColor: ink,
                .font: serifFont(size: 17, weight: .semibold),
                .kern: 0.6
            ]
            navigation.largeTitleTextAttributes = [
                .foregroundColor: ink,
                .font: serifFont(size: 34, weight: .bold)
            ]

            tab.configureWithOpaqueBackground()
            tab.backgroundColor = plate
            tab.shadowColor = line

            let stacked = tab.stackedLayoutAppearance
            let mono = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
            stacked.normal.iconColor = quietInk
            stacked.normal.titleTextAttributes = [
                .foregroundColor: quietInk,
                .font: mono,
                .kern: 0.8
            ]
            stacked.selected.iconColor = accent
            stacked.selected.titleTextAttributes = [
                .foregroundColor: accentInk,
                .font: mono,
                .kern: 0.8
            ]

            let inline = tab.inlineLayoutAppearance
            inline.normal.iconColor = quietInk
            inline.normal.titleTextAttributes = stacked.normal.titleTextAttributes
            inline.selected.iconColor = accent
            inline.selected.titleTextAttributes = stacked.selected.titleTextAttributes

            let compactInline = tab.compactInlineLayoutAppearance
            compactInline.normal.iconColor = quietInk
            compactInline.normal.titleTextAttributes = stacked.normal.titleTextAttributes
            compactInline.selected.iconColor = accent
            compactInline.selected.titleTextAttributes = stacked.selected.titleTextAttributes

            toolbar.configureWithOpaqueBackground()
            toolbar.backgroundColor = plate
            toolbar.shadowColor = line
        } else {
            navigation.configureWithDefaultBackground()
            tab.configureWithDefaultBackground()
            toolbar.configureWithDefaultBackground()
        }

        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactScrollEdgeAppearance = navigation

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        UIToolbar.appearance().standardAppearance = toolbar
        UIToolbar.appearance().scrollEdgeAppearance = toolbar
    }

    private static func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
