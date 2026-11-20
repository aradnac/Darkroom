//
//  RedroomGlass.swift
//  Darkroom
//
//  The theme's glass. Six variants, all built from the same recipe: a dark,
//  slightly translucent interior, a specular pool where the lamp lands, and a
//  rim whose bright end always faces the safelight.
//
//  None of the measurements here are absolute: every opacity is multiplied by
//  the sample the lighting system produces for this element's position, so glass
//  at the top of a screen is visibly brighter than glass at the foot.
//

import SwiftUI

// MARK: - Variants

enum RedroomGlassVariant: String, CaseIterable, Identifiable {
    /// Deep translucent black. The default surface.
    case smoked
    /// Barely there until the lamp catches its edge.
    case transparent
    /// Thick optical glass, more body and a stronger rim.
    case optical
    /// Wet glass: a brighter sheen and a bounce along the lower edge.
    case wet
    /// Reflective black glass, almost a mirror.
    case reflective
    /// Frosted glass: the same dark body, softened by a haze.
    case frosted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smoked: return "Smoked"
        case .transparent: return "Clear"
        case .optical: return "Optical"
        case .wet: return "Wet"
        case .reflective: return "Reflective"
        case .frosted: return "Frosted"
        }
    }

    var top: UInt32 {
        switch self {
        case .smoked: return 0x0C0404
        case .transparent: return 0x0A0505
        case .optical: return 0x120606
        case .wet: return 0x0D0505
        case .reflective: return 0x150707
        case .frosted: return 0x0C0404
        }
    }

    var bottom: UInt32 {
        switch self {
        case .smoked: return 0x050202
        case .transparent: return 0x030101
        case .optical: return 0x0A0404
        case .wet: return 0x040202
        case .reflective: return 0x060101
        case .frosted: return 0x070303
        }
    }

    /// How much white sheen the lamp throws across the surface.
    var sheen: Double {
        switch self {
        case .smoked: return 0.05
        case .transparent: return 0.03
        case .optical: return 0.07
        case .wet: return 0.11
        case .reflective: return 0.09
        case .frosted: return 0.08
        }
    }

    /// Extra haze inside the glass, for the frosted variant.
    var haze: Double {
        self == .frosted ? 0.10 : 0
    }
}

// MARK: - Body

struct RedroomGlassBody: View {
    let variant: RedroomGlassVariant
    let cornerRadius: CGFloat
    let sample: RedroomLightSample

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape.fill(
                LinearGradient(
                    colors: [
                        Redroom.color(variant.top),
                        Redroom.color(variant.bottom)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // The lamp's light landing on the pane, strongest where it faces.
            shape.fill(
                LinearGradient(
                    colors: [
                        Redroom.safelight.opacity(0.20 * sample.direct),
                        Color.clear
                    ],
                    startPoint: sample.start,
                    endPoint: sample.end
                )
            )

            // The specular pool itself.
            shape.fill(
                RadialGradient(
                    colors: [
                        Redroom.safelight.opacity(0.22 * sample.direct),
                        Color.clear
                    ],
                    center: sample.glowCenter,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .blur(radius: 10)

            // A white-hot glint, not a red one: the lamp's own filament.
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(variant.sheen * sample.direct),
                        Color.clear
                    ],
                    startPoint: sample.start,
                    endPoint: .center
                )
            )
            .blendMode(.softLight)

            if variant.haze > 0 {
                shape.fill(Color.white.opacity(variant.haze * (0.4 + sample.direct)))
            }
        }
    }
}

// MARK: - Rim

struct RedroomGlassRim: View {
    let cornerRadius: CGFloat
    let sample: RedroomLightSample

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Redroom.safelight.opacity(0.62 * sample.direct + 0.05),
                        Redroom.safelight.opacity(0.06),
                        Redroom.deepRed.opacity(0.28 * sample.bounce + 0.05)
                    ],
                    startPoint: sample.start,
                    endPoint: sample.end
                ),
                lineWidth: 1
            )
            .allowsHitTesting(false)
    }
}
