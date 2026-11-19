//
//  ProgressiveBlur.swift
//  Darkroom
//
//  A real variable-radius blur at the edge of a scrolling screen: content
//  sharpens as it leaves the chrome instead of being cut by a hard line.
//
//  The effect itself is VariableBlur (nikstar/VariableBlur, after jtrivedi),
//  vendored in Design/ThirdParty. It installs a variableBlur filter on a
//  visual-effect view's backdrop layer, so the radius follows a gradient mask
//  rather than stepping in bands.
//

import Foundation
import SwiftUI
import UIKit

/// The physical safe-area insets, read once from the key window. Used only to
/// extend a decorative background past the safe area without touching layout.
enum ScreenInsets {
    static var top: CGFloat { keyWindow?.safeAreaInsets.top ?? 0 }
    static var bottom: CGFloat { keyWindow?.safeAreaInsets.bottom ?? 0 }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}

struct ProgressiveBlur: View {
    enum Edge {
        case top
        case bottom
    }

    let edge: Edge
    var height: CGFloat = 120
    var maxBlurRadius: CGFloat = 18

    /// Zero: the gradient mask must reach a radius of exactly 0.0 at the band's
    /// inner edge, or whatever radius remains there is cut off in one frame —
    /// a hard line through the content. Never pass a negative offset for a band
    /// that ends mid-screen.
    private static let startOffset: CGFloat = 0

    /// The private filter the vendored view reaches for; if a future OS drops it
    /// we show nothing rather than a plain blur band with its grey tint.
    private static let isSupported = NSClassFromString(String("retliFAC".reversed())) != nil

    var body: some View {
        if Self.isSupported {
            VariableBlurView(
                maxBlurRadius: maxBlurRadius,
                direction: edge == .top ? .blurredTopClearBottom : .blurredBottomClearTop,
                startOffset: Self.startOffset
            )
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
