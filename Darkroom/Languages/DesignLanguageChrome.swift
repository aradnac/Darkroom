//
//  DesignLanguageChrome.swift
//  Darkroom
//
//  The system's own navigation bar, dressed by the active design language. Most
//  screens draw their own header; a screen that still relies on the system bar
//  should at least match the language's field, rule and face.
//

import SwiftUI
import UIKit

enum ThemeLanguageChrome {
    static func apply(_ store: ThemeLanguageStore = .shared) {
        guard store.isActive else {
            reset()
            return
        }

        let style = DLStyle(store: store)
        let palette = style.palette

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(palette.field)
        appearance.shadowColor = UIColor(palette.line)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(palette.ink),
            .font: font(style.spec.type.bodyDesign, size: 16, weight: .semibold),
            .kern: style.spec.type.labelUppercase ? 0.8 : 0
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(palette.ink),
            .font: font(style.spec.type.displayDesign, size: 28, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(palette.accent)

        let toolbar = UIToolbarAppearance()
        toolbar.configureWithOpaqueBackground()
        toolbar.backgroundColor = UIColor(palette.surface)
        toolbar.shadowColor = UIColor(palette.line)
        UIToolbar.appearance().standardAppearance = toolbar
        UIToolbar.appearance().scrollEdgeAppearance = toolbar
        UIToolbar.appearance().tintColor = UIColor(palette.accent)
    }

    static func reset() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactScrollEdgeAppearance = navigation
        UINavigationBar.appearance().tintColor = nil

        let toolbar = UIToolbarAppearance()
        toolbar.configureWithDefaultBackground()
        UIToolbar.appearance().standardAppearance = toolbar
        UIToolbar.appearance().scrollEdgeAppearance = toolbar
        UIToolbar.appearance().tintColor = nil
    }

    private static func font(_ design: Font.Design, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let systemDesign: UIFontDescriptor.SystemDesign?
        switch design {
        case .serif: systemDesign = .serif
        case .rounded: systemDesign = .rounded
        case .monospaced: systemDesign = .monospaced
        default: systemDesign = nil
        }
        guard let systemDesign,
              let descriptor = base.fontDescriptor.withDesign(systemDesign) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
