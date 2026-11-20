//
//  RedroomRootView.swift
//  Darkroom
//
//  The root of the third design language. In Phase 1 it is the foundations
//  room: the safelight, the intensity setting and every glass variant, so the
//  lighting can be judged before a single screen is built on it. Later phases
//  replace this body with the five tabs; nothing outside this file changes.
//
//  Reached only from the debug preview row until the theme is complete.
//

import SwiftUI

struct RedroomRootView: View {
    @AppStorage("redroom.intensity") private var intensityRaw = RedroomIntensity.normal.rawValue

    private var intensity: RedroomIntensity {
        RedroomIntensity(rawValue: intensityRaw) ?? .normal
    }

    var body: some View {
        ZStack {
            RedroomSafelight()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    intensityCard
                    glassGallery
                    lightTest
                }
                .padding(RedroomMetrics.screenPadding)
                .padding(.bottom, 40)
            }
        }
        .environment(
            \.redroomLight,
            RedroomLightParameters(intensity: intensity)
        )
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            RedroomLabel("Theme 3 · foundations")
            Text("REDROOM")
                .font(Redroom.display(34, weight: .bold))
                .foregroundStyle(Redroom.text)
                .tracking(2)

            Text("One safelight, and every surface answers it. This room is the theme's own, reached only from the debug preview until the screens are complete.")
                .font(Redroom.body(13))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private var intensityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RedroomSectionHeader(title: "Safelight")

            Text("Scales the glow, the reflections and the highlights. Type colour never changes, so every reading keeps its contrast in every room.")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Safelight intensity", selection: $intensityRaw) {
                ForEach(RedroomIntensity.allCases) { level in
                    Text(level.title).tag(level.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .tint(Redroom.safelight)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .smoked)
    }

    private var glassGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            RedroomSectionHeader(title: "Glass")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(RedroomGlassVariant.allCases) { variant in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(variant.title)
                            .font(Redroom.body(13, weight: .medium))
                            .foregroundStyle(Redroom.text)
                        Text("Sample")
                            .font(Redroom.label(9))
                            .foregroundStyle(Redroom.textMuted)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
                    .redroomGlass(variant: variant, cornerRadius: 18)
                }
            }
        }
    }

    /// The lighting check: the same glass at the top, the middle and the foot of
    /// the room. The top one must be brightest, and every rim must face the lamp.
    private var lightTest: some View {
        VStack(alignment: .leading, spacing: 12) {
            RedroomSectionHeader(title: "Light test")

            lightRow("Top")
            lightRow("Middle")
            lightRow("Foot")

            Text("Highlights face the lamp and dim with distance. Nothing here is hard-coded to an angle.")
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func lightRow(_ title: String) -> some View {
        HStack(spacing: 12) {
            RedroomIndicator()
            Text(title)
                .font(Redroom.body(14, weight: .medium))
                .foregroundStyle(Redroom.text)
            Spacer(minLength: 0)
            Text("38:00")
                .font(Redroom.figure(15, weight: .semibold))
                .foregroundStyle(Redroom.textMuted)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .frame(maxWidth: .infinity)
        .redroomGlass(variant: .optical, cornerRadius: 18)
    }
}
