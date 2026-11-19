//
//  Theme13Type.swift
//  Darkroom
//
//  The theme's type scale. The repository ships no font files, so each role is
//  carried by the closest system face and width variant, measured in the same
//  ratios the specimen sheet uses. Display faces are for 28pt and up only;
//  functional text always uses the label or mono role at 14pt or larger.
//

import SwiftUI
import UIKit

enum Theme13Type {
    /// The in-theme text-size preference, multiplied by the system Dynamic Type
    /// step, capped at 200% so layouts never lose content.
    private static var scale: CGFloat {
        let preference = Theme13SettingsStore.shared.fontScale
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: 17)
        let dynamic = min(2, max(1, scaled / 17))
        return preference * dynamic
    }

    /// Ultra-extended heavy display. Uppercase, one per screen.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size * scale, weight: .black).width(.expanded)
    }

    /// Hyper-condensed display for one to three words.
    static func condensed(_ size: CGFloat) -> Font {
        .system(size: size * scale, weight: .black).width(.compressed)
    }

    /// Editorial old-style heading.
    static func headline(_ size: CGFloat = 30, weight: Font.Weight = .semibold) -> Font {
        .system(size: size * scale, weight: weight, design: .serif)
    }

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size * scale, weight: weight, design: .serif)
    }

    /// Functional UI text. Never below 16 for body copy.
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size * scale, weight: weight)
    }

    /// Tracked technical label.
    static func label(_ size: CGFloat = 11, weight: Font.Weight = .semibold) -> Font {
        .system(size: size * scale, weight: weight)
    }

    /// Typewriter / monospaced: notes, data, numbered rows.
    static func mono(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .system(size: size * scale, weight: weight, design: .monospaced)
    }

    static func figures(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size * scale, weight: weight, design: .monospaced).monospacedDigit()
    }

    /// Long-form reading measure.
    static func reading(_ size: CGFloat = 18) -> Font {
        .system(size: size * scale, weight: .regular, design: .serif)
    }
}

extension View {
    /// Uppercase, tracked, small — the specimen label of the language.
    func t13Label(_ size: CGFloat = 10, tracking: CGFloat = 2.0) -> some View {
        self
            .font(Theme13Type.label(size))
            .tracking(tracking)
            .textCase(.uppercase)
    }

    func t13Mono(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> some View {
        self.font(Theme13Type.mono(size, weight: weight))
    }

    func t13Display(_ size: CGFloat) -> some View {
        self
            .font(Theme13Type.display(size))
            .textCase(.uppercase)
            .lineSpacing(-size * 0.12)
    }
}
