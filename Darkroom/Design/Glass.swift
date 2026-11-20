//
//  Glass.swift
//  Darkroom
//
//  The frosted panel and the two button styles that carry the whole interface.
//  When the print theme is active they become paper plates and block buttons.
//

import SwiftUI

struct GlassPanel: ViewModifier {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared
    var radius: CGFloat = 26
    var tint: Color?
    var glowing: Bool = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if themeStore.isTheme13Active {
            paper(content)
        } else if themeStore.isSoftGlassActive {
            softGlass(content)
        } else {
            glass(content)
        }
    }

    // MARK: Soft glass

    private func softGlass(_ content: Content) -> some View {
        let shapeRadius = max(radius, SoftGlassTheme.cardRadius)
        return content
            .background {
                ZStack {
                    // The field is pinned under the frost: a card presented
                    // outside the root's dark scheme would otherwise pick up a
                    // light material and vanish under the language's white ink.
                    RoundedRectangle(cornerRadius: shapeRadius, style: .continuous)
                        .fill(SoftGlassTheme.background.opacity(0.72))
                    RoundedRectangle(cornerRadius: shapeRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: shapeRadius, style: .continuous)
                        .fill(SoftGlassTheme.panelGradient)
                    if let tint {
                        RoundedRectangle(cornerRadius: shapeRadius, style: .continuous)
                            .fill(tint.opacity(0.10))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: shapeRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.24),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.45), radius: 26, x: 0, y: 16)
            .shadow(color: glowing ? Color.white.opacity(0.16) : Color.clear, radius: 34, x: 0, y: 0)
    }

    // MARK: Print theme

    private func paper(_ content: Content) -> some View {
        let palette = themeStore.palette
        let dark = themeStore.isDarkAppearance
        return content
            .background(alignment: .topLeading) {
                Rectangle()
                    .fill(palette.stroke(isDark: dark).opacity(0.75))
                    .offset(x: 3, y: 3)
            }
            .background {
                Rectangle().fill(palette.plate(isDark: dark))
            }
            .overlay(alignment: .leading) {
                if let tint {
                    Rectangle()
                        .fill(tint)
                        .frame(width: 4)
                        .padding(.vertical, 12)
                }
            }
            .overlay {
                Rectangle()
                    .stroke(palette.stroke(isDark: dark), lineWidth: 1.5)
            }
    }

    // MARK: Darkroom

    private func glass(_ content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Theme.panelGradient)
                    if let tint {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(tint.opacity(0.10))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.025)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.42), radius: 20, x: 0, y: 12)
            .shadow(color: glowing ? Theme.amber.opacity(0.20) : Color.clear, radius: 28, x: 0, y: 0)
    }
}

extension View {
    func glassPanel(radius: CGFloat = 26, tint: Color? = nil, glowing: Bool = false) -> some View {
        modifier(GlassPanel(radius: radius, tint: tint, glowing: glowing))
    }

    func glassCard(radius: CGFloat = 26, tint: Color? = nil) -> some View {
        glassPanel(radius: radius, tint: tint)
    }
}

// MARK: - Primary action

struct AmberCapsuleStyle: ButtonStyle {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared
    var height: CGFloat = 56

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if themeStore.isTheme13Active {
            let palette = themeStore.palette
            let box = themeStore.compactControls ? min(height, 44) : height
            configuration.label.hapticFeedbackOnPress(isPressed: configuration.isPressed)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(palette.accentInk)
                .frame(maxWidth: .infinity)
                .frame(height: box)
                .background(alignment: .topLeading) {
                    Rectangle()
                        .fill(palette.accent2)
                        .offset(x: configuration.isPressed ? 0 : 4, y: configuration.isPressed ? 0 : 4)
                }
                .background {
                    Rectangle().fill(palette.accent)
                }
                .overlay {
                    Rectangle().stroke(palette.border, lineWidth: 2)
                }
                .offset(x: configuration.isPressed ? 4 : 0, y: configuration.isPressed ? 4 : 0)
                .animation(.linear(duration: 0.06), value: configuration.isPressed)
        } else if themeStore.isSoftGlassActive {
            let compact = themeStore.compactControls
            configuration.label.hapticFeedbackOnPress(isPressed: configuration.isPressed)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(SoftGlassTheme.amberInk)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? min(height, 46) : height)
                .background {
                    Capsule().fill(SoftGlassTheme.amberGradient)
                }
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.55), lineWidth: 0.8)
                }
                .overlay {
                    Capsule().fill(Color.black.opacity(configuration.isPressed ? 0.08 : 0))
                }
                .shadow(
                    color: .black.opacity(configuration.isPressed ? 0.26 : 0.50),
                    radius: configuration.isPressed ? 10 : 22,
                    x: 0,
                    y: configuration.isPressed ? 6 : 14
                )
                .scaleEffect(configuration.isPressed ? 0.96 : 1)
                .animation(.spring(response: 0.34, dampingFraction: 0.62), value: configuration.isPressed)
        } else {
            let compact = themeStore.compactControls
            configuration.label.hapticFeedbackOnPress(isPressed: configuration.isPressed)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.amberInk)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? min(height, 44) : height)
                .background {
                    Capsule().fill(Theme.amberGradient)
                }
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.34), lineWidth: 0.8)
                }
                .shadow(
                    color: Theme.amber.opacity(configuration.isPressed ? 0.18 : 0.34),
                    radius: configuration.isPressed ? 9 : 20,
                    x: 0,
                    y: configuration.isPressed ? 5 : 10
                )
                .scaleEffect(configuration.isPressed ? 0.96 : 1)
                .animation(.spring(response: 0.34, dampingFraction: 0.62), value: configuration.isPressed)
        }
    }
}

// MARK: - Secondary action

struct GlassCapsuleStyle: ButtonStyle {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared
    var height: CGFloat = 56

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if themeStore.isTheme13Active {
            let palette = themeStore.palette
            let dark = themeStore.isDarkAppearance
            let box = themeStore.compactControls ? min(height, 44) : height
            configuration.label.hapticFeedbackOnPress(isPressed: configuration.isPressed)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(palette.ink(isDark: dark))
                .frame(maxWidth: .infinity)
                .frame(height: box)
                .background {
                    Rectangle().fill(configuration.isPressed ? palette.secondarySurface : palette.plate(isDark: dark))
                }
                .overlay {
                    Rectangle().stroke(palette.stroke(isDark: dark), lineWidth: configuration.isPressed ? 2 : 1.5)
                }
                .animation(.linear(duration: 0.06), value: configuration.isPressed)
        } else if themeStore.isSoftGlassActive {
            let compact = themeStore.compactControls
            configuration.label.hapticFeedbackOnPress(isPressed: configuration.isPressed)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? min(height, 44) : height)
                .background {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.16 : 0.06))
                }
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 6)
                .scaleEffect(configuration.isPressed ? 0.965 : 1)
                .animation(.spring(response: 0.34, dampingFraction: 0.62), value: configuration.isPressed)
        } else {
            let compact = themeStore.compactControls
            configuration.label.hapticFeedbackOnPress(isPressed: configuration.isPressed)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? min(height, 44) : height)
                .background {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0.055))
                }
                .overlay {
                    Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                }
                .scaleEffect(configuration.isPressed ? 0.965 : 1)
                .animation(.spring(response: 0.34, dampingFraction: 0.62), value: configuration.isPressed)
        }
    }
}
