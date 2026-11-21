//
//  FilmTroubleshooterView.swift
//  Darkroom
//
//  Read the negatives, pick the closest fault, and get the probable causes
//  ranked by confidence — each tied to the step that produces it, with the
//  correction to make next time.
//

import SwiftUI

// MARK: - Model

/// The step of the process a fault can come from.
enum TroubleshooterStep: String, CaseIterable {
    case exposure
    case development
    case agitation
    case chemistry
    case wash
    case drying
    case storage

    var label: String { rawValue.capitalized }
}

/// How sure the diagnosis is. Three dots is the cause a faulty roll most
/// often traces back to; one dot is the rarer explanation.
enum TroubleshooterConfidence: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: TroubleshooterConfidence, rhs: TroubleshooterConfidence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

struct TroubleshooterCause: Hashable {
    let title: String
    let step: TroubleshooterStep
    let fix: String
    let confidence: TroubleshooterConfidence
}

struct TroubleshooterSymptom: Identifiable, Hashable {
    let id: String
    let title: String
    let resultTitle: String
    let causes: [TroubleshooterCause]
}

enum Troubleshooter {
    /// Ranked most probable first; the panel shows the top three until the
    /// full checklist is opened.
    static let symptoms: [TroubleshooterSymptom] = [
        TroubleshooterSymptom(
            id: "thin",
            title: "Thin / clear",
            resultTitle: "Thin / clear negatives",
            causes: [
                TroubleshooterCause(
                    title: "Underexposure",
                    step: .exposure,
                    fix: "Confirm the camera's ISO setting and meter for the shadows; open up or slow the shutter.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Under-development",
                    step: .development,
                    fix: "Recheck time, temperature and dilution against the chart, and time every stage with a timer.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Exhausted or over-diluted developer",
                    step: .chemistry,
                    fix: "Log rolls against the batch's capacity and mix fresh developer at the stated dilution.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Unfired shutter or lens cap",
                    step: .exposure,
                    fix: "If whole frames are clear, test the shutter and confirm the lens cap is off.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "dense",
            title: "Dense / dark",
            resultTitle: "Dense / dark negatives",
            causes: [
                TroubleshooterCause(
                    title: "Overexposure",
                    step: .exposure,
                    fix: "Meter for the highlights you want to hold, and check for a stuck aperture or wrong ISO.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Over-development",
                    step: .development,
                    fix: "Match the chart's time and temperature exactly; extend only where a push is documented.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Developer temperature too high",
                    step: .chemistry,
                    fix: "Bring every bath to the chart's temperature before pouring, or compensate the time.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Developer too concentrated",
                    step: .chemistry,
                    fix: "Measure stock and water precisely; a stronger mix acts like extra development.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "uneven",
            title: "Uneven",
            resultTitle: "Uneven development",
            causes: [
                TroubleshooterCause(
                    title: "Insufficient agitation in the first 30 seconds",
                    step: .agitation,
                    fix: "Agitate continuously for the first 30 s.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Reels loaded touching",
                    step: .agitation,
                    fix: "Ensure there's space between reels.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Developer too cold for the dilution",
                    step: .chemistry,
                    fix: "Check temperature and adjust dilution.",
                    confidence: .low
                ),
                TroubleshooterCause(
                    title: "Slow pour or an underfilled tank",
                    step: .development,
                    fix: "Pour the developer in one quick, continuous motion and use enough volume to submerge every reel.",
                    confidence: .medium
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "water-marks",
            title: "Water marks",
            resultTitle: "Water marks",
            causes: [
                TroubleshooterCause(
                    title: "Minerals in the final rinse",
                    step: .wash,
                    fix: "Use distilled water for the final rinse and mix the wetting agent fresh.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Drops dried on the film",
                    step: .drying,
                    fix: "Hang the roll straight from a weighted clip and let it drip-dry in still air; never squeegee with fingers.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Wetting agent dosed too strong",
                    step: .wash,
                    fix: "Dilute the wetting agent per its instructions; stronger is not safer.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "A stale or reused rinse bath",
                    step: .wash,
                    fix: "Mix fresh wetting-agent solution once it looks cloudy or has served several rolls.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "bromide-drag",
            title: "Bromide drag",
            resultTitle: "Bromide drag",
            causes: [
                TroubleshooterCause(
                    title: "Irregular agitation",
                    step: .agitation,
                    fix: "Keep the interval steady: invert, rotate a quarter-turn and repeat, so fresh developer sweeps every frame.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Agitation gaps too long",
                    step: .agitation,
                    fix: "Agitate gently once or twice a minute rather than in long gaps.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Developer near capacity",
                    step: .chemistry,
                    fix: "Log rolls against the batch's capacity and retire it before the chemistry weakens.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "reticulation",
            title: "Reticulation",
            resultTitle: "Reticulation",
            causes: [
                TroubleshooterCause(
                    title: "Temperature shock between baths",
                    step: .chemistry,
                    fix: "Keep developer, stop, fixer and wash within a couple of degrees of each other.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Stop bath far too strong or too cold",
                    step: .chemistry,
                    fix: "Dilute the stop bath as documented and match its temperature to the developer.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Hot wash after a cold developer",
                    step: .wash,
                    fix: "Raise the wash temperature gradually rather than shocking the emulsion.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "grain",
            title: "Excessive grain",
            resultTitle: "Excessive grain",
            causes: [
                TroubleshooterCause(
                    title: "Over-development",
                    step: .development,
                    fix: "Develop to the documented time at the right temperature instead of extending for density.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Underexposure pushed in the developer",
                    step: .exposure,
                    fix: "Rate the film where it holds shadow detail and give the exposure at the camera, not in the tank.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Vigorous, constant agitation",
                    step: .agitation,
                    fix: "Use the documented agitation scheme; extra agitation raises contrast and coarsens grain.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Force-drying with heat",
                    step: .drying,
                    fix: "Air-dry at room temperature; heat swells the emulsion and sets the grain.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "fogging",
            title: "Fogging",
            resultTitle: "Fogging",
            causes: [
                TroubleshooterCause(
                    title: "Film past date or stored warm",
                    step: .storage,
                    fix: "Check the expiry, store sealed and cool, and develop expired stock promptly.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Light leak in the tank, bag or darkroom",
                    step: .development,
                    fix: "Test the changing bag and tank lid with a loaded sacrifice roll before trusting a real one.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Developer too hot or too concentrated",
                    step: .chemistry,
                    fix: "Match the chart's temperature and dilution; heat and strength both raise base fog.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "X-ray or radiation exposure",
                    step: .storage,
                    fix: "Ask for hand inspection at airports and keep film away from radiation sources.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "colour-cast",
            title: "Colour cast",
            resultTitle: "Colour cast",
            causes: [
                TroubleshooterCause(
                    title: "Residual fixer or an incomplete wash",
                    step: .wash,
                    fix: "Extend the wash and confirm the clearing test passes before the final rinse.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Exhausted or contaminated fixer",
                    step: .chemistry,
                    fix: "Compare clearing time against fresh fixer and replace the batch when it lengthens or nears capacity.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Tinted or stale final rinse",
                    step: .wash,
                    fix: "Mix the wetting-agent rinse fresh in clean, distilled water.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Colour film in black-and-white chemistry",
                    step: .chemistry,
                    fix: "C-41 emulsions keep an orange mask; expect a base tint when cross-developing.",
                    confidence: .low
                )
            ]
        ),
        TroubleshooterSymptom(
            id: "scratches",
            title: "Scratches",
            resultTitle: "Scratches",
            causes: [
                TroubleshooterCause(
                    title: "Dirt in the camera's film gate",
                    step: .exposure,
                    fix: "Clean the gate and pressure plate with a blower before loading.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Grit picked up while drying",
                    step: .drying,
                    fix: "Dry in a dust-free corner and never touch the wet emulsion.",
                    confidence: .high
                ),
                TroubleshooterCause(
                    title: "Damaged reel or rough loading",
                    step: .development,
                    fix: "Inspect the reel for burrs and load slowly; never force the film.",
                    confidence: .medium
                ),
                TroubleshooterCause(
                    title: "Grit in the storage sleeves",
                    step: .storage,
                    fix: "Wipe sleeves inside and out before refiling a processed roll.",
                    confidence: .low
                )
            ]
        )
    ]
}

// MARK: - Screen

struct FilmTroubleshooterView: View {
    @ObservedObject private var library = LibraryStore.shared

    @State private var filmKey: String?
    @State private var selection: TroubleshooterSymptom.ID?
    @State private var checklistExpanded = false

    private var selectedFilm: LibraryFilm? {
        if let filmKey, let film = library.film(key: filmKey) { return film }
        return library.films.first { $0.name.localizedCaseInsensitiveContains("HP5") }
            ?? library.films.first
    }

    private var selectedSymptom: TroubleshooterSymptom? {
        selection.flatMap { id in Troubleshooter.symptoms.first { $0.id == id } }
    }

    private func displayFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                filmPill
                symptomGrid
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Troubleshooter")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let symptom = selectedSymptom {
                TroubleshooterResultPanel(symptom: symptom, isExpanded: $checklistExpanded)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: selection)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("What do your negatives show?")
                .font(displayFont(21))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Tap the closest match.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var filmPill: some View {
        Menu {
            ForEach(library.films, id: \.key) { film in
                Button {
                    filmKey = film.key
                } label: {
                    if film.key == selectedFilm?.key {
                        Label(film.name, systemImage: "checkmark")
                    } else {
                        Text(film.name)
                    }
                }
            }
        } label: {
            Text((selectedFilm?.name ?? "Select a film").uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(Theme.ink.opacity(0.92))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background {
                    Capsule().fill(Theme.surfaceRaised)
                }
                .overlay {
                    Capsule().strokeBorder(Theme.border, lineWidth: 1)
                }
        }
        .accessibilityLabel("Film: \(selectedFilm?.name ?? "none selected")")
    }

    private var symptomGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(Troubleshooter.symptoms) { symptom in
                TroubleshooterCard(
                    symptom: symptom,
                    isSelected: selection == symptom.id
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        if selection == symptom.id {
                            selection = nil
                            checklistExpanded = false
                        } else {
                            selection = symptom.id
                            checklistExpanded = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Card

private struct TroubleshooterCard: View {
    let symptom: TroubleshooterSymptom
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                TroubleshooterStripView(symptom: symptom)
                    .frame(width: 92, height: 62)
                    .frame(maxWidth: .infinity)

                Text(symptom.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.amber : Theme.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surfaceRaised)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Theme.amber : Theme.border, lineWidth: isSelected ? 1.6 : 1)
            }
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityHint("Shows ranked probable causes")
    }
}

// MARK: - Film strip thumbnail

/// A little 35 mm strip whose frame shows the fault itself: thin, dense,
/// streaked, crackled, and so on. Drawn procedurally with a seeded generator
/// so every render of a symptom looks the same.
private struct TroubleshooterStripView: View {
    let symptom: TroubleshooterSymptom

    var body: some View {
        Canvas { context, size in
            var rng = TroubleshooterRNG(seed: Self.stableSeed(symptom.id))

            // Strip body
            let strip = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 5)
            context.fill(strip, with: .color(Color(white: 0.09)))

            // The frame
            let holeHeight = size.height * 0.17
            let frameRect = CGRect(
                x: size.width * 0.07,
                y: holeHeight + 1.5,
                width: size.width * 0.86,
                height: size.height - holeHeight * 2 - 3
            )
            drawScene(in: frameRect, into: context, using: &rng)
            drawFault(in: frameRect, into: context, using: &rng)

            // Sprocket holes, top and bottom
            let holeWidth = size.width * 0.085
            let holeAdvance = holeWidth * 2.3
            let holeRadius: CGFloat = 1.8
            for rowCenter in [holeHeight / 2, size.height - holeHeight / 2] {
                var x = size.width * 0.08
                while x + holeWidth <= size.width * 0.94 {
                    let hole = Path(
                        roundedRect: CGRect(x: x, y: rowCenter - holeHeight / 2, width: holeWidth, height: holeHeight),
                        cornerRadius: holeRadius
                    )
                    context.fill(hole, with: .color(Color(white: 0.78).opacity(0.88)))
                    x += holeAdvance
                }
            }
        }
        .accessibilityHidden(true)
    }

    private static func stableSeed(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for scalar in string.unicodeScalars {
            hash = (hash &* 33) &+ UInt64(scalar.value)
        }
        return hash
    }

    /// A quiet grey scene — sky, ground, a tree — every fault is drawn over.
    private func drawScene(in rect: CGRect, into context: GraphicsContext, using rng: inout TroubleshooterRNG) {
        context.fill(Path(rect), with: .color(Color(white: 0.70)))

        let horizonY = rect.minY + rect.height * 0.52
        var ground = Path()
        ground.addRect(CGRect(x: rect.minX, y: horizonY, width: rect.width, height: rect.maxY - horizonY))
        context.fill(ground, with: .color(Color(white: 0.42)))

        // Distant block on the horizon
        var building = Path()
        building.addRect(CGRect(
            x: rect.minX + rect.width * 0.68,
            y: horizonY - rect.height * 0.22,
            width: rect.width * 0.22,
            height: rect.height * 0.22
        ))
        context.fill(building, with: .color(Color(white: 0.30)))

        // Tree
        let trunkRect = CGRect(
            x: rect.minX + rect.width * 0.34,
            y: horizonY - rect.height * 0.16,
            width: rect.width * 0.035,
            height: rect.height * 0.34
        )
        context.fill(Path(trunkRect), with: .color(Color(white: 0.14)))
        let canopyCenter = CGPoint(x: trunkRect.midX, y: horizonY - rect.height * 0.28)
        for offset in [(0.0, 0.0), (-0.09, 0.05), (0.09, 0.04)] {
            let radius = rect.height * 0.20
            let circle = Path(ellipseIn: CGRect(
                x: canopyCenter.x + rect.width * offset.0 - radius,
                y: canopyCenter.y + rect.height * offset.1 - radius * 0.85,
                width: radius * 2,
                height: radius * 1.7
            ))
            context.fill(circle, with: .color(Color(white: 0.16)))
        }
    }

    private func drawFault(in rect: CGRect, into context: GraphicsContext, using rng: inout TroubleshooterRNG) {
        switch symptom.id {
        case "thin":
            context.fill(Path(rect), with: .color(Color(white: 1).opacity(0.58)))

        case "dense":
            context.fill(Path(rect), with: .color(Color(white: 0.02).opacity(0.74)))

        case "uneven":
            let splitX = rect.minX + rect.width * 0.44
            var left = Path()
            left.addRect(CGRect(x: rect.minX, y: rect.minY, width: splitX - rect.minX, height: rect.height))
            context.fill(left, with: .color(Color(white: 0.04).opacity(0.88)))
            var band = Path()
            band.addRect(CGRect(x: splitX, y: rect.minY, width: rect.width * 0.14, height: rect.height))
            context.fill(band, with: .linearGradient(
                Gradient(colors: [Color(white: 0.04).opacity(0.88), .clear]),
                startPoint: CGPoint(x: splitX, y: rect.midY),
                endPoint: CGPoint(x: splitX + rect.width * 0.14, y: rect.midY)
            ))

        case "water-marks":
            context.fill(Path(rect), with: .color(Color(white: 0.92).opacity(0.16)))
            for _ in 0..<13 {
                let cx = rect.minX + Double.random(in: 0.14...0.86, using: &rng) * rect.width
                let cy = rect.minY + Double.random(in: 0.10...0.90, using: &rng) * rect.height
                let r = Double.random(in: 2.4...6.4, using: &rng) * (rect.width / 92)
                let blob = Path(ellipseIn: CGRect(x: cx - r, y: cy - r * 0.8, width: r * 2, height: r * 1.6))
                if Double.random(in: 0...1, using: &rng) < 0.4 {
                    context.fill(blob, with: .color(Color(white: 1).opacity(0.30)))
                } else {
                    context.stroke(blob, with: .color(Color(white: 1).opacity(0.75)), lineWidth: 1)
                }
            }

        case "bromide-drag":
            var y = rect.minY
            while y < rect.maxY {
                let h = Double.random(in: 1.4...4.2, using: &rng) * (rect.height / 48)
                var streak = Path()
                streak.addRect(CGRect(x: rect.minX, y: y, width: rect.width, height: h))
                let dark = Double.random(in: 0...1, using: &rng) < 0.5
                context.fill(streak, with: .color(
                    dark ? Color(white: 0.08).opacity(0.38) : Color(white: 1).opacity(0.30)
                ))
                y += h + Double.random(in: 0.8...2.6, using: &rng) * (rect.height / 48)
            }

        case "reticulation":
            let ink = Color(white: 0.05).opacity(0.62)
            let columns = 6
            let rows = 4
            for column in 1..<columns {
                var path = Path()
                let baseX = rect.minX + rect.width * CGFloat(column) / CGFloat(columns)
                let steps = 5
                for step in 0...steps {
                    let y = rect.minY + rect.height * CGFloat(step) / CGFloat(steps)
                    let jitter = Double.random(in: -0.9...0.9, using: &rng) * (rect.width / 60)
                    let point = CGPoint(x: baseX + jitter, y: y)
                    if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.stroke(path, with: .color(ink), lineWidth: 0.9)
            }
            for row in 1..<rows {
                var path = Path()
                let baseY = rect.minY + rect.height * CGFloat(row) / CGFloat(rows)
                let steps = 8
                for step in 0...steps {
                    let x = rect.minX + rect.width * CGFloat(step) / CGFloat(steps)
                    let jitter = Double.random(in: -0.9...0.9, using: &rng) * (rect.height / 40)
                    let point = CGPoint(x: x, y: baseY + jitter)
                    if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.stroke(path, with: .color(ink), lineWidth: 0.9)
            }

        case "grain":
            context.fill(Path(rect), with: .color(Color(white: 0.5).opacity(0.14)))
            for _ in 0..<360 {
                let cx = rect.minX + Double.random(in: 0...1, using: &rng) * rect.width
                let cy = rect.minY + Double.random(in: 0...1, using: &rng) * rect.height
                let r = Double.random(in: 0.35...1.15, using: &rng) * (rect.width / 92)
                let dot = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
                let light = Double.random(in: 0...1, using: &rng) < 0.5
                context.fill(dot, with: .color(light ? Color(white: 1).opacity(0.4) : Color(white: 0).opacity(0.4)))
            }

        case "fogging":
            context.fill(Path(rect), with: .color(Color(white: 0.55).opacity(0.42)))
            let leak = Path(ellipseIn: CGRect(
                x: rect.maxX - rect.height * 1.1,
                y: rect.minY - rect.height * 0.55,
                width: rect.height * 1.5,
                height: rect.height * 1.5
            ))
            context.fill(leak, with: .color(Color(white: 1).opacity(0.45)))

        case "colour-cast":
            context.fill(Path(rect), with: .color(Color(red: 0.80, green: 0.60, blue: 0.34).opacity(0.46)))

        case "scratches":
            for _ in 0..<4 {
                let startX = rect.minX + Double.random(in: 0.1...0.9, using: &rng) * rect.width
                let angle = Double.random(in: -0.45...0.45, using: &rng) + .pi / 2
                let length = rect.height * 1.5
                let start = CGPoint(x: startX, y: rect.minY - rect.height * 0.2)
                let end = CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length)
                var line = Path()
                line.move(to: start)
                line.addLine(to: end)
                let bright = Double.random(in: 0...1, using: &rng) < 0.75
                context.stroke(line, with: .color(
                    bright ? Color(white: 1).opacity(0.85) : Color(white: 0.1).opacity(0.6)
                ), lineWidth: 0.7)
            }

        default:
            break
        }
    }
}

// MARK: - Results panel

private struct TroubleshooterResultPanel: View {
    let symptom: TroubleshooterSymptom
    @Binding var isExpanded: Bool

    private let collapsedCauses = 3

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.inkFaint)
                .frame(width: 38, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 12) {
                Text(symptom.resultTitle)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                OverlineText(text: isExpanded ? "Full checklist" : "Likely causes")

                if isExpanded {
                    ScrollView {
                        causeList(symptom.causes)
                    }
                    .frame(height: 330)
                } else {
                    causeList(Array(symptom.causes.prefix(collapsedCauses)))
                }
            }
            .padding(.horizontal, 20)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "doc.plaintext")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isExpanded ? "Hide full checklist" : "Show full checklist")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(GlassCapsuleStyle(height: 44))
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background { surface }
        .overlay(alignment: .top) { topEdge }
        .shadow(color: .black.opacity(0.34), radius: 22, x: 0, y: -10)
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Likely causes for \(symptom.resultTitle)")
    }

    @ViewBuilder
    private func causeList(_ causes: [TroubleshooterCause]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(causes.enumerated()), id: \.element) { index, cause in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                }
                causeRow(index: index + 1, cause: cause)
                    .padding(.vertical, 11)
            }
        }
    }

    private func causeRow(index: Int, cause: TroubleshooterCause) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(index)")
                .font(.figures(14, weight: .semibold))
                .foregroundStyle(Theme.ink.opacity(0.9))
                .frame(width: 30, height: 30)
                .background {
                    Circle().fill(Theme.surfaceRaised)
                }
                .overlay {
                    Circle().strokeBorder(Theme.hairline, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(cause.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Fix: \(cause.fix)")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(cause.step.label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.inkFaint)
            }

            Spacer(minLength: 8)

            ConfidenceDots(level: cause.confidence)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(index). \(cause.title). Step: \(cause.step.label). Confidence \(cause.confidence.label). Fix: \(cause.fix)")
    }

    private var surface: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
            .fill(Theme.panelGradient)
        }
    }

    private var topEdge: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 30,
            topTrailingRadius: 30,
            style: .continuous
        )
        .strokeBorder(Theme.border, lineWidth: 1)
    }
}

// MARK: - Confidence dots

private struct ConfidenceDots: View {
    let level: TroubleshooterConfidence

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...3, id: \.self) { dot in
                Circle()
                    .fill(dot <= level.rawValue ? Theme.amber : Color.clear)
                    .frame(width: 9, height: 9)
                    .overlay {
                        Circle().strokeBorder(
                            dot <= level.rawValue ? Color.clear : Theme.inkFaint,
                            lineWidth: 1
                        )
                    }
            }
        }
        .accessibilityLabel("Confidence: \(level.label)")
    }
}

// MARK: - Seeded generator

/// Deterministic randomness for the procedural thumbnails, so a symptom's
/// strip never redraws differently between renders.
struct TroubleshooterRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
