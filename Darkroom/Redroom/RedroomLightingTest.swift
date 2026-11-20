//
//  RedroomLightingTest.swift
//  Darkroom
//
//  DEBUG ONLY. The room's test bench: the same pane of glass at nine places on
//  the display, the four safelight intensities side by side, the contrast audit
//  computed from the tokens, and a live read-out of what the lighting sample
//  says about a probe the reader can drag.
//
//  Nothing here is in a release build.
//

#if DEBUG
import SwiftUI

struct RedroomLightingTest: View {
    @AppStorage("redroom.intensity") private var intensityRaw = RedroomIntensity.normal.rawValue

    @State private var probeFrame: CGRect = .zero

    private var intensity: RedroomIntensity {
        RedroomIntensity(rawValue: intensityRaw) ?? .normal
    }

    private let report = RedroomContrast.allReports

    var body: some View {
        RedroomScreen {
            RedroomScreenHeader(kicker: "Debug", title: "Lighting test")
                .redroomReveal(.safelightFade)

            RedroomNote(text: "Not compiled into a release build. Use it to check that every surface answers the same lamp, that the four intensities scale only glow, and that text keeps its contrast in every room.")

            intensityPicker

            positionGrid

            probeCard

            contrastTable

            notes
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            RedroomDetailHeader(kicker: "Settings", title: "Lighting")
                .background(Redroom.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.redroomLight, RedroomLightParameters(intensity: intensity))
    }

    // MARK: Intensity

    private var intensityPicker: some View {
        RedroomPanel(title: "Safelight") {
            RedroomSegmented(
                items: RedroomIntensity.allCases,
                selection: Binding(
                    get: { intensity },
                    set: { intensityRaw = $0.rawValue }
                ),
                title: { $0.title }
            )

            RedroomValueRow(
                label: "Glow factor",
                value: String(format: "×%.2f", intensity.lightFactor)
            )
        }
    }

    // MARK: Positions

    private var positionGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            RedroomSectionHeader(title: "Nine places under one lamp")

            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { column in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(positionName(row: row, column: column))
                                .font(Redroom.label(8))
                                .foregroundStyle(Redroom.textMuted)
                            Text("38:00")
                                .font(Redroom.figure(14, weight: .semibold))
                                .foregroundStyle(Redroom.text)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .redroomGlass(
                            variant: .optical,
                            cornerRadius: 14
                        )
                    }
                }
            }
        }
    }

    private func positionName(row: Int, column: Int) -> String {
        let rows = ["Top", "Middle", "Foot"]
        let columns = ["Left", "Centre", "Right"]
        return "\(rows[row]) \(columns[column])".uppercased()
    }

    // MARK: Probe

    private var probeCard: some View {
        let sample = RedroomLightSample.make(frame: probeFrame, light: RedroomLightParameters(intensity: intensity))

        return RedroomPanel(title: "Live sample", detail: "What the lamp reports for the glass below it.") {
            HStack(spacing: 8) {
                Image(systemName: "light.max")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Redroom.text)
                Text("Probe")
                    .font(Redroom.body(13))
                    .foregroundStyle(Redroom.text)
                Spacer(minLength: 4)
                Text(String(format: "%.2f", sample.direct))
                    .font(Redroom.figure(14, weight: .semibold))
                    .foregroundStyle(Redroom.text)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .redroomGlass(variant: .wet, cornerRadius: 14)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { value in
                probeFrame = value
            }

            RedroomValueRow(label: "Strength", value: String(format: "%.3f", sample.strength))
            RedroomValueRow(label: "Direct", value: String(format: "%.3f", sample.direct))
            RedroomValueRow(label: "Bounce", value: String(format: "%.3f", sample.bounce))
            RedroomValueRow(
                label: "Gradient start",
                value: String(format: "%.2f, %.2f", sample.start.x, sample.start.y)
            )
            RedroomValueRow(
                label: "Gradient end",
                value: String(format: "%.2f, %.2f", sample.end.x, sample.end.y)
            )

            let mid = RedroomLightSample.make(
                frame: CGRect(x: 0, y: 0, width: 120, height: 60),
                light: RedroomLightParameters(intensity: intensity),
                screen: CGSize(width: 400, height: 800)
            )
            RedroomValueRow(
                label: "Top of screen faces lamp",
                value: mid.start.y > 0.5 ? "yes" : "check"
            )
        }
    }

    // MARK: Contrast

    private var contrastTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            RedroomSectionHeader(title: "Contrast audit · computed")

            ForEach(report) { entry in
                RedroomPanel(
                    title: "\(entry.intensity.title) safelight",
                    detail: String(
                        format: "Required %.1f:1 for body text. Lowest pair %.1f:1.",
                        RedroomContrast.minimumTextRatio,
                        entry.lowest?.ratio ?? 0
                    ),
                    variant: entry.passes ? .smoked : .wet
                ) {
                    ForEach(entry.pairs) { pair in
                        HStack(spacing: 8) {
                            Text(pair.label)
                                .font(Redroom.body(11))
                                .foregroundStyle(Redroom.textMuted)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 4)

                            Text(String(format: "%.2f:1", pair.ratio))
                                .font(Redroom.figure(11, weight: .semibold))
                                .foregroundStyle(Redroom.text)

                            Image(systemName: pair.passes ? "checkmark" : "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Redroom.text)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(pair.label): \(String(format: "%.2f", pair.ratio)) to 1, required \(pair.required), \(pair.passes ? "passes" : "fails")"
                        )
                    }
                }
            }
        }
    }

    // MARK: Notes

    private var notes: some View {
        RedroomPanel(title: "What to check by hand") {
            bullet("Reduce Motion: the glow stops breathing, and every highlight stays where the lamp puts it.")
            bullet("Text: the figure on each pane is the same near-white at every intensity.")
            bullet("Position: the top-left pane is the brightest, the foot-right the dimmest.")
            bullet("Pressed controls: a press adds light; it never replaces the safelight.")
            bullet("Nothing over the liquid: dragging across a tray must still move its controls.")
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·")
                .font(Redroom.body(12, weight: .bold))
                .foregroundStyle(Redroom.textMuted)
            Text(text)
                .font(Redroom.body(12))
                .foregroundStyle(Redroom.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
