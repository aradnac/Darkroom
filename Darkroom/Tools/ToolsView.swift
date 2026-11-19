//
//  ToolsView.swift
//  Darkroom
//
//  The sink-side utility hub.
//

import SwiftUI

struct ToolsView: View {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    introduction

                    VStack(spacing: 10) {
                        ToolLaunchCard(
                            title: "Temperature",
                            subtitle: "Convert °C and °F",
                            systemImage: "thermometer.medium",
                            accent: Theme.amber,
                            destination: TemperatureConverterView()
                        )
                        ToolLaunchCard(
                            title: "Stopwatch",
                            subtitle: "Elapsed time with lap splits",
                            systemImage: "stopwatch",
                            accent: Color(red: 0.72, green: 0.77, blue: 0.95),
                            destination: StopwatchToolView()
                        )
                        ToolLaunchCard(
                            title: "Interval timer",
                            subtitle: "Set work, rest, and rounds",
                            systemImage: "repeat",
                            accent: Color(red: 0.70, green: 0.83, blue: 0.75),
                            destination: IntervalTimerView()
                        )
                        ToolLaunchCard(
                            title: "Wash & final rinse",
                            subtitle: "Fill-and-dump guide and timers",
                            systemImage: "drop",
                            accent: Color(red: 0.53, green: 0.76, blue: 0.91),
                            destination: WashRinseTimerView()
                        )
                        ToolLaunchCard(
                            title: "Tank visualizer",
                            subtitle: "See how far a pour reaches",
                            systemImage: "cylinder.fill",
                            accent: Color(red: 0.98, green: 0.66, blue: 0.18),
                            destination: TankVisualizerView()
                        )
                    }

                    OverlineText(text: "Reference", color: Theme.amber)
                        .padding(.top, 2)

                    VStack(spacing: 10) {
                        ToolLaunchCard(
                            title: "Film leader retrieval",
                            subtitle: "A documented 35 mm retriever method",
                            systemImage: "film",
                            accent: Color(red: 0.90, green: 0.69, blue: 0.48),
                            destination: FilmLeaderGuideView()
                        )
                        ToolLaunchCard(
                            title: "Tank capacities",
                            subtitle: "Film load and reference volumes",
                            systemImage: "cylinder.split.1x2",
                            accent: Color(red: 0.63, green: 0.79, blue: 0.75),
                            destination: TankCapacityReferenceView()
                        )
                        ToolLaunchCard(
                            title: "Chemical safety",
                            subtitle: "Handling, ventilation, and disposal",
                            systemImage: "hand.raised",
                            accent: Color(red: 0.94, green: 0.59, blue: 0.45),
                            destination: ChemicalSafetyView()
                        )
                    }

                    Button {
                        themeStore.isShowingSettings = true
                    } label: {
                        ToolCardBody(
                            title: "Settings",
                            subtitle: "Appearance, motion and themes",
                            systemImage: "slider.horizontal.3",
                            accent: Theme.amber
                        )
                    }
                    .buttonStyle(HapticButtonStyle())
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background {
                LiquidBackdrop()
            }
            .appNavigationChrome(index: "05", title: "Tools")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 9) {
            OverlineText(text: "At the sink", color: Theme.amber)
            Text("Small tools.\nSteady hands.")
                .font(
                    themeStore.isTheme13Active
                        ? Theme13Type.headline(30)
                        : .system(size: 30, weight: .semibold, design: .rounded)
                )
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Quick conversions, dependable timing, and references for the work in front of you.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

private struct ToolLaunchCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            ToolCardBody(title: title, subtitle: subtitle, systemImage: systemImage, accent: accent)
        }
        .buttonStyle(HapticButtonStyle())
    }
}

private struct ToolCardBody: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    @ObservedObject private var themeStore = Theme13SettingsStore.shared

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: themeStore.isTheme13Active ? 0 : 15, style: .continuous)
                    .fill(accent.opacity(0.13))
                    .frame(width: 48, height: 48)
                RoundedRectangle(cornerRadius: themeStore.isTheme13Active ? 0 : 15, style: .continuous)
                    .strokeBorder(accent.opacity(0.22), lineWidth: 1)
                    .frame(width: 48, height: 48)
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 21, tint: accent)
        .contentShape(Rectangle())
    }
}
