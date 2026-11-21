//
//  DesignLanguageScreens.swift
//  Darkroom
//
//  The front door of every design language. Each one is a different department
//  laying out the same information: the published time the bench is ready with,
//  what is in the library and on the shelf, the stages of a session, and the way
//  into one.
//
//  The data is the app's own — the same library, the same bottles, the same
//  journal — read through the same stores every other screen reads. Only the
//  arrangement is new.
//

import SwiftUI

// MARK: - Develop

struct DLDevelopScreen: View {
    @Environment(\.dlStyle) private var style

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
                VStack(alignment: .leading, spacing: style.geometry.sectionSpacing) {
                    layout
                }
                .padding(.horizontal, style.geometry.pagePadding)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                if style.language == .material3 {
                    materialFab
                        .padding(.trailing, style.geometry.pagePadding)
                        .padding(.bottom, 18)
                }
            }
        }
    }

    /// Material's floating action button: the screen's one action, out of the
    /// way of the content and inside the thumb's reach.
    private var materialFab: some View {
        NavigationLink {
            SessionSetupView()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                Text("Start")
                    .font(style.body(15, weight: .semibold))
            }
            .foregroundStyle(style.palette.accentInk)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background {
                Capsule().fill(style.palette.accent)
            }
            .shadow(color: style.palette.accent.opacity(0.45), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Start a session")
    }

    // MARK: Layouts

    @ViewBuilder
    private var layout: some View {
        switch style.language {
        case .darkroom, .softLight:
            glassLayout
        case .appleClean:
            cleanLayout
        case .fluent:
            fluentLayout
        case .material3:
            materialLayout
        case .swiss:
            swissLayout
        case .brutalist:
            brutalLayout
        case .neumorphic:
            neumorphicLayout
        case .cyberpunk:
            cyberLayout
        case .retroAnalog:
            retrolLayout
        case .editorial:
            editorialLayout
        case .skeuomorphic:
            skeuomorphicLayout
        case .terminal:
            terminalLayout
        case .recorder:
            recorderLayout
        }
    }

    // MARK: 01 Liquid Glass (the app's own interface; kept for previews)

    private var glassLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: style.geometry.sectionSpacing) {
            headerRow(kicker: "At the sink", title: "Develop")

            VStack(alignment: .leading, spacing: 10) {
                DLLabel(text: "Published time")
                DLFigure(
                    value: featured?.figure ?? "--:--",
                    unit: "min",
                    caption: featured?.pair ?? "Add a film and a developer to the library.",
                    size: 44
                )
                DLRule()
                DLNote(text: featured?.note ?? "A published time appears here as soon as the library holds one for a film and developer pair.")
            }
            .padding(18)
            .dlPanel(role: .primary)
            .overlay(alignment: .topTrailing) {
                DLSignatureMark(spec: style.spec, palette: p, size: 16)
                    .padding(14)
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            statGrid(columns: 2)
            stagesSection
        }
    }

    // MARK: 02 Apple Clean

    private var cleanLayout: some View {
        VStack(alignment: .leading, spacing: 34) {
            headerRow(kicker: "At the sink", title: "Develop a roll")

            VStack(alignment: .leading, spacing: 8) {
                DLLabel(text: "Featured published time")
                DLFigure(
                    value: featured?.figure ?? "--:--",
                    unit: "min",
                    caption: featured?.pair,
                    size: 46
                )
                Text(featured?.temperature ?? "—")
                    .font(style.body(14))
                    .foregroundStyle(style.palette.inkSoft)
                DLNote(text: featured?.note ?? "A published time appears here as soon as the library holds one for a film and developer pair.")
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(stat.label)
                            .font(style.body(14))
                            .foregroundStyle(style.palette.inkSoft)
                        Spacer(minLength: 6)
                        Text(stat.value)
                            .font(style.figure(16, weight: .semibold))
                            .foregroundStyle(style.palette.ink)
                    }
                    .padding(.vertical, 14)

                    if index < stats.count - 1 {
                        DLRule()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                DLLabel(text: "How a session runs")
                    .padding(.bottom, 6)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(12, weight: .medium))
                            .foregroundStyle(style.palette.accent)
                            .frame(width: 22, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.title)
                                .font(style.body(16, weight: .semibold))
                                .foregroundStyle(style.palette.ink)
                            Text(step.detail)
                                .font(style.body(14))
                                .foregroundStyle(style.palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 12)

                    if index < steps.count - 1 {
                        DLRule()
                    }
                }
            }
        }
    }

    // MARK: 03 Microsoft Fluent

    private var fluentLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(kicker: "Develop", title: "Ready when the tank is")

            VStack(alignment: .leading, spacing: 8) {
                DLLabel(text: "Published time")
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(featured?.figure ?? "--:--")
                        .font(style.figure(36, weight: .semibold))
                        .foregroundStyle(style.palette.ink)
                    Text(featured?.temperature ?? "—")
                        .font(style.body(13))
                        .foregroundStyle(style.palette.accent)
                }
                Text(featured?.pair ?? "No sourced time yet")
                    .font(style.body(12))
                    .foregroundStyle(style.palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(radius: 8)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    VStack(alignment: .leading, spacing: 4) {
                        DLLabel(text: stat.label)
                        Text(stat.value)
                            .font(style.figure(22, weight: .semibold))
                            .foregroundStyle(style.palette.ink)
                        Text(stat.unit)
                            .font(style.body(11))
                            .foregroundStyle(style.palette.inkFaint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .dlPanel(radius: 8)
                }
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                DLSectionHeader(title: "How a session runs", note: "Six stages, from the pre-soak to the final rinse.")
                stagesCardBody
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(radius: 8)
        }
    }

    // MARK: 04 Material 3

    private var materialLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow(kicker: "Develop", title: "Ready when the tank is")

            VStack(alignment: .leading, spacing: 10) {
                DLLabel(text: "Published time")
                DLFigure(
                    value: featured?.figure ?? "--:--",
                    unit: "min",
                    caption: featured?.pair,
                    size: 44
                )
                Capsule()
                    .fill(style.palette.accent.opacity(0.22))
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(style.palette.accent)
                            .frame(width: fractionWidth(featured?.seconds), height: 6)
                    }
                    .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(radius: 26, role: .primary)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(style.palette.surfaceAlt)
                    .padding(.vertical, 4)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    VStack(alignment: .leading, spacing: 4) {
                        DLLabel(text: stat.label)
                        Text(stat.value)
                            .font(style.figure(22, weight: .semibold))
                            .foregroundStyle(style.palette.ink)
                        Text(stat.unit)
                            .font(style.body(11))
                            .foregroundStyle(style.palette.inkFaint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .dlPanel(radius: 18)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                DLSectionHeader(title: "How a session runs")
                stagesCardBody
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(radius: 26)
        }
    }

    // MARK: 05 Swiss

    private var swissLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                DLLabel(text: "01 / Develop")
                Spacer(minLength: 8)
                gearButton
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Develop")
                        .font(style.display(44))
                        .foregroundStyle(p.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(p.lineStrong)
                        .frame(height: 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Text("A roll, end to end")
                        .font(style.body(13, weight: .semibold))
                        .foregroundStyle(p.ink)
                    Text("Pre-soak, developer, stop, fix, wash and final rinse, timed and prompted.")
                        .font(style.body(12))
                        .foregroundStyle(p.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    DLSpecialityRule()
                }
                .frame(width: 132, alignment: .leading)
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    DLLabel(text: "Published time")
                    Text(featured?.figure ?? "--:--")
                        .font(style.figure(48, weight: .bold))
                        .foregroundStyle(p.ink)
                    Text(featured?.pair ?? "No sourced time yet")
                        .font(style.body(13))
                        .foregroundStyle(p.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(featured?.temperature ?? "—")
                        .font(style.figure(13))
                        .foregroundStyle(p.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                        HStack(alignment: .firstTextBaseline) {
                            Text(stat.label.uppercased())
                                .font(style.label())
                                .foregroundStyle(p.inkSoft)
                            Spacer(minLength: 6)
                            Text(stat.value)
                                .font(style.figure(14, weight: .semibold))
                                .foregroundStyle(p.ink)
                        }
                        Rectangle().fill(p.line).frame(height: 1)
                    }
                }
                .frame(width: 132, alignment: .leading)
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 10) {
                DLSectionHeader(title: "How a session runs", index: "06")

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(11, weight: .bold))
                            .foregroundStyle(p.accent)
                            .frame(width: 24, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(style.body(14, weight: .semibold))
                                .foregroundStyle(p.ink)
                            Text(step.detail)
                                .font(style.body(12))
                                .foregroundStyle(p.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    Rectangle().fill(p.line).frame(height: 1)
                }
            }
        }
    }

    // MARK: 06 Brutalist

    private var brutalLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DEVELOP")
                        .font(style.display(38))
                        .foregroundStyle(p.ink)
                    Rectangle().fill(p.accent).frame(width: 88, height: 9)
                }
                Spacer(minLength: 6)
                gearButton
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("PUBLISHED TIME")
                    .font(style.label())
                    .foregroundStyle(p.accentInk.opacity(0.75))
                Text(featured?.figure ?? "--:--")
                    .font(style.figure(52, weight: .black))
                    .foregroundStyle(p.accentInk)
                Text(featured?.pair ?? "NO SOURCED TIME YET")
                    .font(style.body(13, weight: .semibold))
                    .foregroundStyle(p.accentInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topLeading) {
                Rectangle().fill(p.ink).offset(x: 7, y: 7)
            }
            .background(Rectangle().fill(p.accent))
            .overlay(Rectangle().strokeBorder(p.ink, lineWidth: 3))

            HStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stat.label.uppercased())
                            .font(style.label())
                            .foregroundStyle(p.inkSoft)
                        Text(stat.value)
                            .font(style.figure(24, weight: .black))
                            .foregroundStyle(p.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .overlay(alignment: .leading) {
                        if index > 0 {
                            Rectangle().fill(p.lineStrong).frame(width: 3)
                        }
                    }
                }
            }
            .padding(1)
            .background(Rectangle().fill(p.surface))
            .overlay(Rectangle().strokeBorder(p.ink, lineWidth: 3))

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 0) {
                Text("HOW A SESSION RUNS")
                    .font(style.label())
                    .foregroundStyle(p.ink)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(p.accent)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(12, weight: .black))
                            .foregroundStyle(p.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title.uppercased())
                                .font(style.body(13, weight: .heavy))
                                .foregroundStyle(p.ink)
                            Text(step.detail)
                                .font(style.body(11))
                                .foregroundStyle(p.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(p.lineStrong).frame(height: 2)
                    }
                }
            }
            .background(p.surface)
            .overlay(Rectangle().strokeBorder(p.ink, lineWidth: 3))
        }
    }

    // MARK: 07 Neumorphic

    private var neumorphicLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    DLLabel(text: "At the sink", color: p.accent)
                    Text("Develop")
                        .font(style.display())
                        .foregroundStyle(p.ink)
                }
                Spacer(minLength: 6)
                gearButton
            }

            VStack(alignment: .leading, spacing: 10) {
                DLLabel(text: "Published time")
                HStack(alignment: .bottom, spacing: 12) {
                    DLFigure(
                        value: featured?.figure ?? "--:--",
                        unit: "min",
                        caption: featured?.pair,
                        size: 40
                    )
                    Spacer(minLength: 0)
                    DLMeter(caption: "of 40 min", fraction: (featured?.seconds ?? 0) / (40 * 60))
                        .frame(width: 92)
                }
                DLNote(text: featured?.note ?? "A published time appears here as soon as the library holds one for a film and developer pair.")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(radius: 26, role: .primary)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    VStack(alignment: .leading, spacing: 4) {
                        DLLabel(text: stat.label)
                        Text(stat.value)
                            .font(style.figure(22, weight: .semibold))
                            .foregroundStyle(p.ink)
                        Text(stat.unit)
                            .font(style.body(11))
                            .foregroundStyle(p.inkFaint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .dlPanel(radius: 20)
                }
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 12) {
                DLSectionHeader(title: "How a session runs")
                stagesCardBody
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(radius: 24)
        }
    }

    // MARK: 08 Cyberpunk

    private var cyberLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("SYS::DARKROOM")
                    .font(style.label())
                    .foregroundStyle(p.accent)
                Rectangle().fill(p.line).frame(height: 1)
                Text("\(filmCount) STOCKS")
                    .font(style.label())
                    .foregroundStyle(p.inkFaint)
            }

            headerRow(kicker: "unit 01", title: "DEVELOP")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("T_MIN")
                        .font(style.label())
                        .foregroundStyle(p.accent)
                    Spacer(minLength: 4)
                    Text(featured?.temperature ?? "—")
                        .font(style.label())
                        .foregroundStyle(p.inkSoft)
                }

                Text(featured?.figure ?? "--:--")
                    .font(style.figure(50, weight: .bold))
                    .foregroundStyle(p.accent)
                    .shadow(color: p.accent.opacity(0.6), radius: 12, x: 0, y: 0)

                Text(featured?.pair ?? "NO SOURCED TIME")
                    .font(style.body(11, weight: .semibold))
                    .foregroundStyle(p.ink)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    ForEach(0..<18, id: \.self) { tick in
                        Rectangle()
                            .fill(Double(tick) / 18 <= (featured?.seconds ?? 0) / (40 * 60) ? p.accent : p.line)
                            .frame(height: 9)
                    }
                }
                .padding(.top, 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(role: .primary)

            HStack(spacing: 8) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.label.uppercased())
                            .font(style.label())
                            .foregroundStyle(p.inkFaint)
                        Text(stat.value)
                            .font(style.figure(18, weight: .bold))
                            .foregroundStyle(p.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .overlay(Rectangle().strokeBorder(p.line.opacity(0.6), lineWidth: 1))
                }
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 0) {
                DLSectionHeader(title: "stage sequence", index: "06")
                    .padding(.bottom, 6)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text(">")
                            .font(style.label())
                            .foregroundStyle(p.accent)
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(10, weight: .bold))
                            .foregroundStyle(p.inkFaint)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(step.title.uppercased())
                                .font(style.body(11, weight: .bold))
                                .foregroundStyle(p.ink)
                            Text(step.detail)
                                .font(style.body(10))
                                .foregroundStyle(p.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 5)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(p.line.opacity(0.4)).frame(height: 1)
                    }
                }
            }
        }
    }

    // MARK: 09 Retro Analog

    private var retrolLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 0) {
                DLSprocketStrip(colour: p.accent.opacity(0.55), holes: 26)

                HStack(alignment: .firstTextBaseline) {
                    Text("DARKROOM · 35MM")
                        .font(style.label())
                        .tracking(1.4)
                        .foregroundStyle(p.inkSoft)
                    Spacer(minLength: 4)
                    Text("FRAME 01")
                        .font(style.label())
                        .tracking(1.4)
                        .foregroundStyle(p.accent)
                    gearButton
                        .padding(.leading, 6)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                DLSprocketStrip(colour: p.accent.opacity(0.55), holes: 26)
            }
            .background(p.surface)
            .overlay(Rectangle().strokeBorder(p.line, lineWidth: 1))

            HStack(alignment: .bottom, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PUBLISHED")
                        .font(style.label())
                        .tracking(1.6)
                        .foregroundStyle(p.accent)
                    Text(featured?.figure ?? "--:--")
                        .font(style.figure(46, weight: .semibold))
                        .foregroundStyle(p.ink)
                    Text(featured?.pair ?? "No sourced time yet")
                        .font(style.body(12))
                        .foregroundStyle(p.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                DLMeter(caption: "exposure", fraction: (featured?.seconds ?? 0) / (40 * 60))
                    .frame(width: 96)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(role: .primary)

            HStack(spacing: 8) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    VStack(spacing: 2) {
                        DLSprocketStrip(colour: p.line, holes: 6, height: 6)
                        Text(stat.value)
                            .font(style.figure(18, weight: .semibold))
                            .foregroundStyle(p.ink)
                        Text(stat.label.uppercased())
                            .font(style.label())
                            .foregroundStyle(p.inkFaint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(p.surfaceAlt)
                    .overlay(Rectangle().strokeBorder(p.line, lineWidth: 1))
                }
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 8) {
                DLSectionHeader(title: "Process order", index: "06")

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(11, weight: .semibold))
                            .foregroundStyle(p.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(style.body(13, weight: .semibold))
                                .foregroundStyle(p.ink)
                            Text(step.detail)
                                .font(style.body(11))
                                .foregroundStyle(p.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel()
        }
    }

    // MARK: 10 Editorial

    private var editorialLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("The bench")
                    .font(style.label())
                    .tracking(style.spec.type.labelTracking)
                    .foregroundStyle(p.accent)

                Text("Develop")
                    .font(style.display())
                    .foregroundStyle(p.ink)

                Text("A roll, from the pre-soak to the final rinse, kept honest about where every number came from.")
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(p.inkSoft)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Rectangle().fill(p.lineStrong).frame(height: 2)
                    .padding(.top, 4)
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured time")
                        .font(.system(size: 15, design: .serif))
                        .italic()
                        .foregroundStyle(p.inkSoft)
                    Text(featured?.figure ?? "--:--")
                        .font(style.figure(44, weight: .regular))
                        .foregroundStyle(p.ink)
                    Text(featured?.pair ?? "No sourced time yet")
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(p.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(featured?.temperature ?? "—")
                        .font(style.figure(12))
                        .foregroundStyle(p.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle().fill(p.line).frame(width: 1)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(stat.value)
                                .font(style.figure(18, weight: .regular))
                                .foregroundStyle(p.ink)
                            Text(stat.label.uppercased())
                                .font(style.label())
                                .foregroundStyle(p.inkFaint)
                        }
                    }
                }
                .frame(width: 104, alignment: .leading)
            }

            Text("“Timed stages, agitation prompts, and a sound at every step.”")
                .font(.system(size: 20, design: .serif))
                .italic()
                .foregroundStyle(p.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle().fill(p.accent).frame(width: 3)
                }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 10) {
                DLSectionHeader(title: "How a session runs", index: "Folio 02")

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(11, weight: .regular))
                            .foregroundStyle(p.accent)
                            .frame(width: 24, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.system(size: 16, design: .serif))
                                .foregroundStyle(p.ink)
                            Text(step.detail)
                                .font(.system(size: 13, design: .serif))
                                .foregroundStyle(p.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    Rectangle().fill(p.line).frame(height: 1)
                }
            }
        }
    }

    // MARK: 11 Skeuomorphic

    private var skeuomorphicLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("DEVELOP")
                            .font(style.display(20))
                            .tracking(1.6)
                            .foregroundStyle(p.ink)
                        Spacer(minLength: 6)
                    }

                    HStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            DLLabel(text: "Published", color: p.accent)
                            Text(featured?.figure ?? "--:--")
                                .font(style.figure(38, weight: .bold))
                                .foregroundStyle(p.ink)
                            Text(featured?.pair ?? "No sourced time yet")
                                .font(style.body(12))
                                .foregroundStyle(p.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        DLDial(
                            label: "exposure",
                            value: featured?.temperature ?? "—",
                            fraction: (featured?.seconds ?? 0) / (40 * 60),
                            tint: p.accent
                        )
                    }

                    Rectangle().fill(p.lineStrong.opacity(0.5)).frame(height: 1)

                    Text(featured?.note ?? "A published time appears here as soon as the library holds one for a film and developer pair.")
                        .font(style.body(11))
                        .foregroundStyle(p.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dlPanel(radius: 16, role: .primary)

                DLScrews()
                    .padding(6)
            }

            HStack(spacing: 10) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    VStack(spacing: 3) {
                        Text(stat.value)
                            .font(style.figure(18, weight: .bold))
                            .foregroundStyle(p.ink)
                        Text(stat.label.uppercased())
                            .font(style.label())
                            .foregroundStyle(p.inkFaint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .dlPanel(radius: 10)
                }
            }

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("Start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 10) {
                DLSectionHeader(title: "Process order")

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(11, weight: .bold))
                            .foregroundStyle(p.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(style.body(13, weight: .semibold))
                                .foregroundStyle(p.ink)
                            Text(step.detail)
                                .font(style.body(11))
                                .foregroundStyle(p.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel()
        }
    }

    // MARK: 12 Terminal

    private var terminalLayout: some View {
        let p = style.palette

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Text("$")
                    .font(style.body(12, weight: .bold))
                    .foregroundStyle(p.accent)
                Text("darkroom develop --roll")
                    .font(style.body(12))
                    .foregroundStyle(p.ink)
                Spacer(minLength: 4)
                gearButton
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("// published time")
                    .font(style.body(10))
                    .foregroundStyle(p.inkFaint)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("time=")
                        .font(style.body(12))
                        .foregroundStyle(p.accent)
                    Text(featured?.figure ?? "--:--")
                        .font(style.figure(34, weight: .bold))
                        .foregroundStyle(p.ink)
                    Text("min")
                        .font(style.body(11))
                        .foregroundStyle(p.inkSoft)
                }
                Text("pair=\(featured?.pair ?? "—")")
                    .font(style.body(11))
                    .foregroundStyle(p.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("temp=\(featured?.temperature ?? "—")")
                    .font(style.body(11))
                    .foregroundStyle(p.inkSoft)
                Text("source=\(featuredNoteShort)")
                    .font(style.body(10))
                    .foregroundStyle(p.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel(role: .primary)

            VStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    HStack(spacing: 8) {
                        Text(stat.label.lowercased())
                            .font(style.body(11))
                            .foregroundStyle(p.inkSoft)
                        Text(String(repeating: ".", count: max(1, 14 - stat.label.count)))
                            .font(style.body(11))
                            .foregroundStyle(p.inkFaint)
                            .lineLimit(1)
                        Text(stat.value)
                            .font(style.figure(11, weight: .semibold))
                            .foregroundStyle(p.ink)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 3)
                }
            }
            .padding(10)
            .dlPanel()

            NavigationLink {
                SessionSetupView()
            } label: {
                Text("start a session")
            }
            .buttonStyle(DLButtonStyle(role: .primary))

            VStack(alignment: .leading, spacing: 4) {
                Text("// stage sequence")
                    .font(style.body(10))
                    .foregroundStyle(p.inkFaint)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(step.title.lowercased())
                            .font(style.body(11, weight: .semibold))
                            .foregroundStyle(p.ink)
                            .frame(width: 78, alignment: .leading)
                        Text(step.detail)
                            .font(style.body(10))
                            .foregroundStyle(p.inkSoft)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%02d", index + 1))
                            .font(style.figure(10))
                            .foregroundStyle(p.accent)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dlPanel()
        }
    }

    // MARK: 13 Recorder

    /// The deck: a bold title with its menu, the dot disc, the time readout and a
    /// two-by-two of knobs. Everything sits straight on the flat field; the only
    /// surfaces are the black knobs and the tint of their tiles.
    private var recorderLayout: some View {
        VStack(alignment: .leading, spacing: style.geometry.sectionSpacing) {
            recorderTitle
            recorderPair
            recorderDisc
            recorderReadout
            recorderDeck
            recorderStart
            recorderNote
        }
    }

    private var recorderTitle: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("Develop")
                .font(style.display(38))
                .foregroundStyle(style.palette.ink)
                .lineSpacing(-4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            recorderMenu
        }
    }

    @ViewBuilder
    private var recorderPair: some View {
        if let pair = featured?.pair {
            Text(pair)
                .font(style.body(13, weight: .medium))
                .foregroundStyle(style.palette.inkSoft)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var recorderDisc: some View {
        // A published time is drawn against a 40-minute span, the way the
        // library's longest documented times sit at the top of the dial.
        let fraction: Double = Double(fractionWidth(featured?.seconds))

        return DLDotDisc(fraction: fraction, size: 190)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }

    private var recorderReadout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(style.palette.lineStrong)
                .frame(height: 1)

            recorderTime(featured)
        }
    }

    /// The readout: a faint unit at the leading edge, the time at full size, and
    /// the temperature it was measured at set quietly at the trailing edge.
    private func recorderTime(_ featured: Featured?) -> some View {
        let p = style.palette
        let figure: String = featured?.figure ?? "00:00"
        let temperature: String = featured?.temperature ?? "—"

        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("min")
                .font(style.label())
                .foregroundStyle(p.inkFaint)

            Text(figure)
                .font(style.figure(46, weight: .bold))
                .foregroundStyle(p.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 8)

            Text(temperature)
                .font(style.figure(16, weight: .medium))
                .foregroundStyle(p.ink.opacity(0.38))
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(featured.map { "Published time \($0.figure) minutes at \($0.temperature)" }
            ?? "No published time yet")
    }

    /// One dial on the deck: a knob, a label and the figure it reads.
    private struct RecorderDial: Identifiable {
        let id: String
        let label: String
        let value: String
        let fraction: Double
    }

    /// The four knobs. Every figure is the app's own; nothing is invented to fill
    /// a dial.
    private var recorderDials: [RecorderDial] {
        let films = filmCount
        let bottles = ChemistryStore.shared.batches.count
        let sessions = JournalStore.shared.records.count

        return [
            RecorderDial(
                id: "films",
                label: "Films",
                value: "\(films)",
                fraction: min(1, Double(films) / 300)
            ),
            RecorderDial(
                id: "bottles",
                label: "Bottles",
                value: "\(bottles)",
                fraction: min(1, Double(bottles) / 8)
            ),
            RecorderDial(
                id: "sessions",
                label: "Sessions",
                value: "\(sessions)",
                fraction: min(1, Double(sessions) / 40)
            ),
            RecorderDial(
                id: "stages",
                label: "Stages",
                value: "\(steps.count)",
                fraction: 1
            )
        ]
    }

    private var recorderDeck: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(recorderDials) { dial in
                recorderDial(dial)
            }
        }
    }

    private func recorderDial(_ dial: RecorderDial) -> some View {
        let p = style.palette

        return VStack(spacing: 10) {
            DLKnob(fraction: dial.fraction, size: 84)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(dial.label)
                    .font(style.label())
                    .foregroundStyle(p.inkSoft)
                Spacer(minLength: 4)
                Text(dial.value)
                    .font(style.figure(13, weight: .bold))
                    .foregroundStyle(p.ink)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.06))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dial.label), \(dial.value)")
    }

    private var recorderStart: some View {
        NavigationLink {
            SessionSetupView()
        } label: {
            Text("Start a session")
        }
        .buttonStyle(DLButtonStyle(role: .primary))
    }

    @ViewBuilder
    private var recorderNote: some View {
        if let note = featured?.note {
            Text(note)
                .font(style.body(10))
                .foregroundStyle(style.palette.ink.opacity(0.45))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The deck's menu, drawn as the small chevron the reference puts at the top
    /// right. It opens the Appearance section.
    private var recorderMenu: some View {
        Button {
            ThemeLanguageStore.shared.presentAppearance()
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(style.palette.ink)
                .frame(width: 34, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Appearance")
    }

    // MARK: Shared pieces

    private var filmCount: Int { LibraryStore.shared.films.count }

    private var stats: [(label: String, value: String, unit: String)] {
        [
            ("Films", "\(LibraryStore.shared.films.count)", "in the library"),
            ("Bottles", "\(ChemistryStore.shared.batches.count)", "mixed"),
            ("Sessions", "\(JournalStore.shared.records.count)", "logged")
        ]
    }

    private struct Featured {
        let figure: String
        let pair: String
        let temperature: String
        let note: String
        let seconds: TimeInterval
    }

    /// The first film in the library with a sourced development time. Nothing is
    /// invented: with no documented time the screen says so.
    private var featured: Featured? {
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

            return Featured(
                figure: String(format: "%02d:%02d", minutes, remainder),
                pair: "\(film.displayName) · \(developerName) \(dilution)",
                temperature: temperature,
                note: note,
                seconds: TimeInterval(seconds)
            )
        }

        return nil
    }

    private var featuredNoteShort: String {
        guard let note = featured?.note else { return "—" }
        return note.replacingOccurrences(of: "Published time at ", with: "")
    }

    private func fractionWidth(_ seconds: TimeInterval?) -> CGFloat {
        guard let seconds, seconds > 0 else { return 0 }
        return CGFloat(min(1, seconds / (40 * 60)))
    }

    private func headerRow(kicker: String, title: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            DLHeader(kicker: kicker, title: title, detail: detailLine)
            gearButton
        }
    }

    private var detailLine: String? {
        switch style.language {
        case .appleClean, .editorial:
            return nil
        case .terminal, .cyberpunk, .recorder:
            return nil
        default:
            return "Timed stages, agitation prompts, and a sound at every step."
        }
    }

    private var stagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "How a session runs")
            stagesCardBody
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dlPanel()
    }

    private var stagesCardBody: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                DLRow(
                    title: step.title,
                    detail: step.detail,
                    value: String(format: "%02d", index + 1)
                )
                if index < steps.count - 1 {
                    DLRule()
                }
            }
        }
    }

    private var gearButton: some View {
        Button {
            ThemeLanguageStore.shared.presentAppearance()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(style.palette.accent)
                .frame(width: 34, height: 34)
                .dlPanel(radius: 10)
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel("Appearance")
    }

    private func statGrid(columns: Int) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns),
            spacing: 10
        ) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                DLStatTile(label: stat.label, value: stat.value, unit: stat.unit)
            }
        }
    }

    private func gearInk(_ colour: Color) -> Color { colour }
}

// MARK: - Small furniture

/// The Swiss cross-hair rule: two rules and a registered cross.
private struct DLSpecialityRule: View {
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        ZStack(alignment: .topLeading) {
            Rectangle().fill(p.lineStrong).frame(height: 1)
            Rectangle().fill(p.lineStrong).frame(width: 1)
                .frame(height: 22)
                .offset(x: 0)
        }
        .frame(height: 22)
    }
}

/// The four screws that hold a skeuomorphic panel to the case.
struct DLScrews: View {
    @Environment(\.dlStyle) private var style

    var body: some View {
        let p = style.palette

        VStack {
            HStack {
                screw(p)
                Spacer(minLength: 0)
                screw(p)
            }
            Spacer(minLength: 0)
            HStack {
                screw(p)
                Spacer(minLength: 0)
                screw(p)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func screw(_ p: DLPalette) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [p.surfaceAlt, p.fieldAlt],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 5
                )
            )
            .frame(width: 7, height: 7)
            .overlay {
                Rectangle()
                    .fill(p.lineStrong.opacity(0.7))
                    .frame(width: 4, height: 0.8)
            }
            .overlay {
                Circle().strokeBorder(p.lineStrong.opacity(0.6), lineWidth: 0.6)
            }
    }
}
