//
//  DevelopHomeView.swift
//  Darkroom
//
//  The Develop tab: the entry to a new session and a short guide to the stages.
//

import SwiftUI

struct DevelopHomeView: View {
    @ObservedObject private var themeStore = Theme13SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Sections settle in once the first frame is laid out, so a tab switch or a
    /// launch arrives rather than snaps.
    @State private var revealed = false

    private let steps: [(title: String, detail: String)] = [
        ("Pre-soak", "Optional soak in water before the developer."),
        ("Developer", "Timed, with agitation prompts and a tap for bubbles."),
        ("Stop", "20 to 40 seconds with constant agitation."),
        ("Fix", "Set by your film leader's clearing time, times three."),
        ("Wash", "Running water, or fill and dump."),
        ("Final rinse", "A wetting agent, without a rinse.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if themeStore.isTheme13Active {
                        paperContent
                    } else if themeStore.isSoftGlassActive {
                        softContent
                    } else {
                        hero
                        flow
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background {
                LiquidBackdrop()
            }
            .appNavigationChrome(index: "01", title: "Develop")
        }
    }

    // MARK: Print theme

    /// The poster-cover archetype: display title, cutout hero, specimen index.
    private var paperContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Theme13PosterCover(
                index: "01",
                kicker: "At the sink",
                title: "Develop",
                line: "A roll, end to end",
                caption: "Pre-soak, developer, stop, fix, wash, final rinse — timed, prompted and logged."
            )

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AmberCapsuleStyle(height: 52))

            Theme13StageList(index: "02", heading: "How a session runs", steps: steps)
        }
    }

    // MARK: Soft glass

    private var softContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            softHeading
                .softReveal(revealed, delay: 0, reduceMotion: reduceMotion)
            softSummary
                .softReveal(revealed, delay: 0.06, reduceMotion: reduceMotion)
            softMosaic
                .softReveal(revealed, delay: 0.12, reduceMotion: reduceMotion)
            softPlan
                .softReveal(revealed, delay: 0.18, reduceMotion: reduceMotion)
        }
        .task {
            guard !revealed else { return }
            try? await Task.sleep(for: .milliseconds(40))
            revealed = true
        }
    }

    private var softHeading: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                SoftGlassCaption(text: "At the sink", color: SoftGlassTheme.pink)
                Text("Ready when\nthe tank is.")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(SoftGlassTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            SoftGlassIconButton(systemImage: "slider.horizontal.3") {
                themeStore.isShowingSettings = true
            }
            .accessibilityLabel("Settings")
        }
    }

    private var softSummary: some View {
        let featured = featuredTime

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                SoftGlassCaption(text: "Suggested time")

                Spacer(minLength: 0)

                Text(featured?.pair ?? "From the library")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SoftGlassTheme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            DotMatrixDigits(text: featured?.figure ?? "--:--", dot: 7, spacing: 3)

            Text(featured?.note ?? "Add a film and a developer to the library and its published time appears here.")
                .font(.system(size: 13))
                .foregroundStyle(SoftGlassTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                SessionSetupView()
            } label: {
                SoftGlassActionLabel(title: "Start a session")
            }
            .buttonStyle(AmberCapsuleStyle(height: 58))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(radius: SoftGlassTheme.cardRadius, glowing: true)
    }

    private var softMosaic: some View {
        let films = LibraryStore.shared.films.count
        let bottles = ChemistryStore.shared.batches.count

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            SoftGlassTile(
                label: "Films",
                value: "\(films)",
                caption: "in the library",
                gradient: SoftGlassTheme.pinkGradient,
                tint: SoftGlassTheme.pink
            )
            SoftGlassTile(
                label: "At",
                value: featuredTime?.temperature ?? "—",
                caption: "published temperature",
                gradient: SoftGlassTheme.orangeGradient,
                tint: SoftGlassTheme.orange
            )
            SoftGlassTile(
                label: "Chemicals",
                value: "\(bottles)",
                caption: bottles == 1 ? "bottle at the bench" : "bottles at the bench",
                gradient: SoftGlassTheme.mintGradient,
                tint: SoftGlassTheme.mint
            )
            SoftGlassTile(
                label: "Stages",
                value: "\(steps.count)",
                caption: "pre-soak to rinse",
                gradient: SoftGlassTheme.blueGradient,
                tint: SoftGlassTheme.blue
            )
        }
    }

    private var softPlan: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SoftGlassCaption(text: "How a session runs")
                Spacer(minLength: 0)
                Text("\(steps.count) stages")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SoftGlassTheme.inkFaint)
            }

            VStack(spacing: 14) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    SoftGlassRow(title: step.title, detail: step.detail, index: index + 1)

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(SoftGlassTheme.hairline)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(radius: SoftGlassTheme.cardRadius)
    }

    // MARK: Feature

    private struct FeaturedTime {
        let figure: String
        let pair: String
        let temperature: String
        let note: String
    }

    /// The first film in the library that has a sourced development time, set as
    /// the screen's figure. Nothing is invented: with no documented time the hero
    /// says so rather than showing a plausible number.
    private var featuredTime: FeaturedTime? {
        let library = LibraryStore.shared

        for film in StarterLibrary.films {
            let entries = library.times(forFilm: film.id).filter { $0.seconds != nil }
            guard let entry = entries.first(where: { abs($0.celsius - 20) < 0.05 }) ?? entries.first,
                  let seconds = entry.seconds else { continue }

            let developerName = library.developer(key: entry.developer)?.name ?? entry.developer
            let dilution = library.dilutionLabel(developerKey: entry.developer, dilution: entry.dilution)
            let minutes = seconds / 60
            let remainder = seconds % 60
            let temperature = library.temperatureLabel(entry.celsius)

            let source = library.source(key: entry.provenance.source)?.publisher
            let note = source.map { "Published time at \(temperature), sourced from \($0)." }
                ?? "Published time at \(temperature)."

            return FeaturedTime(
                figure: String(format: "%02d:%02d", minutes, remainder),
                pair: "\(film.displayName) · \(developerName) \(dilution)",
                temperature: temperature,
                note: note
            )
        }

        return nil
    }

    // MARK: Darkroom

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "timer")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.amber)
                .frame(width: 68, height: 68)
                .glassCard(radius: 34)

            VStack(alignment: .leading, spacing: 8) {
                OverlineText(text: "Ready when the tank is", color: Theme.amber)
                Text("Develop a roll")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Timed stages, agitation prompts, a tap-anywhere start and a sound at every step.")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Label("New session", systemImage: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.amber)
            .controlSize(.large)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 30)
    }

    private var flow: some View {
        VStack(alignment: .leading, spacing: 14) {
            OverlineText(text: "How a session runs")

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.amberInk)
                        .frame(width: 26, height: 26)
                        .background {
                            Circle().fill(Theme.amber)
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(step.detail)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 30)
    }
}


// MARK: - Reveal

/// A short spring settle for a section: a little rise and scale, staggered by a
/// few tens of milliseconds per section. Collapses to a quick fade when the
/// reader has asked for reduced motion.
private struct SoftReveal: ViewModifier {
    let revealed: Bool
    let delay: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(revealed || reduceMotion ? 1 : 0)
            .offset(y: revealed || reduceMotion ? 0 : 16)
            .scaleEffect(revealed || reduceMotion ? 1 : 0.97, anchor: .top)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.20)
                    : .spring(response: 0.62, dampingFraction: 0.86).delay(delay),
                value: revealed
            )
    }
}

extension View {
    fileprivate func softReveal(_ revealed: Bool, delay: Double, reduceMotion: Bool) -> some View {
        modifier(SoftReveal(revealed: revealed, delay: delay, reduceMotion: reduceMotion))
    }
}
