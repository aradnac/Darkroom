//
//  SoftGlassTheme.swift
//  Darkroom
//
//  THE SECOND DESIGN LANGUAGE — "SOFT GLASS".
//
//  A near-black field lit from behind by slow colour: magenta up top, violet off
//  to the left, a cold blue pooling at the foot of the screen. On top of that
//  sit two very different kinds of surface — white capsules with black ink for
//  anything you can press, and saturated gradient tiles for anything you only
//  need to read. Large figures are set as a grid of dots.
//
//  The palette is deliberately narrow: white drives every control, and the four
//  chroma values are decoration only. Nothing here is amber.
//

import SwiftUI

enum SoftGlassTheme {
    // MARK: Field

    static let background = Color(red: 0.024, green: 0.022, blue: 0.031)
    static let backgroundLift = Color(red: 0.055, green: 0.050, blue: 0.068)

    // MARK: Ink

    static let ink = Color.white.opacity(0.97)
    static let inkSoft = Color.white.opacity(0.62)
    static let inkFaint = Color.white.opacity(0.36)
    static let hairline = Color.white.opacity(0.08)
    static let border = Color.white.opacity(0.14)
    static let surface = Color.white.opacity(0.05)
    static let surfaceRaised = Color.white.opacity(0.09)

    // MARK: Controls
    //
    // In this language the "accent" is simply white: a solid white capsule with
    // black ink is the only loud thing on the screen, so the colour underneath
    // stays the subject.

    static let amber = Color.white
    static let amberSoft = Color(red: 0.99, green: 0.99, blue: 1.0)
    static let amberDeep = Color(white: 0.80)
    static let amberInk = Color.black

    // MARK: Chroma

    static let pink = Color(red: 0.980, green: 0.482, blue: 0.769)     // #FA7BC4
    static let magenta = Color(red: 0.878, green: 0.337, blue: 0.678)  // #E056AD
    static let violet = Color(red: 0.573, green: 0.451, blue: 0.961)   // #9273F5
    static let blue = Color(red: 0.353, green: 0.529, blue: 0.992)     // #5A87FD
    static let mint = Color(red: 0.373, green: 0.878, blue: 0.749)     // #5FE0BF
    static let orange = Color(red: 0.965, green: 0.451, blue: 0.302)   // #F6734D
    static let lime = Color(red: 0.776, green: 0.941, blue: 0.0)       // #C6F000
    static let peach = Color(red: 1.0, green: 0.541, blue: 0.431)      // #FF8A6E

    // MARK: Shape
    //
    // Cards and controls are oversized and soft. Nothing in this language is square.

    static let cardRadius: CGFloat = 32
    static let controlRadius: CGFloat = 26
    static let tileRadius: CGFloat = 26

    // MARK: Fills

    /// The white capsule ramp. Kept almost flat on purpose: a white button with a
    /// hard gradient reads as plastic.
    static let amberGradient = LinearGradient(
        colors: [amberSoft, amber, amberDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.085),
            Color.white.opacity(0.028),
            Color.black.opacity(0.26)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let pinkGradient = LinearGradient(
        colors: [pink, magenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let magentaGradient = LinearGradient(
        colors: [peach, magenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let violetGradient = LinearGradient(
        colors: [violet, blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let blueGradient = LinearGradient(
        colors: [Color(red: 0.36, green: 0.58, blue: 1.0), violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mintGradient = LinearGradient(
        colors: [mint, blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let orangeGradient = LinearGradient(
        colors: [orange, pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let limeGradient = LinearGradient(
        colors: [lime, mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Ambient field

    /// A near-black plane with four wide colour blooms bleeding across it. Low
    /// opacity and heavy blur on purpose: they read as light in the room, never
    /// as shapes sitting on the screen.
    static func backdrop(intensity: Double = 1.0) -> some View {
        ZStack {
            background

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [magenta.opacity(0.40 * intensity), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 660, height: 660)
                .blur(radius: 40)
                .offset(x: 160, y: -300)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [violet.opacity(0.34 * intensity), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 280
                    )
                )
                .frame(width: 560, height: 560)
                .blur(radius: 44)
                .offset(x: -170, y: -60)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [blue.opacity(0.28 * intensity), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 320
                    )
                )
                .frame(width: 680, height: 680)
                .blur(radius: 52)
                .offset(x: 40, y: 360)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [mint.opacity(0.14 * intensity), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 460, height: 460)
                .blur(radius: 48)
                .offset(x: 190, y: 200)

            LinearGradient(
                colors: [background.opacity(0.55), Color.clear, background.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
