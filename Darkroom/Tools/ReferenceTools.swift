//
//  ReferenceTools.swift
//  Darkroom
//
//  Source-linked practical references for the darkroom bench.
//

import SwiftUI

struct ToolSourceLink: View {
    let title: String
    let detail: String
    let url: String

    var body: some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.amber)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(detail)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(radius: 18)
            }
            .buttonStyle(HapticButtonStyle())
        }
    }
}

private enum LeaderRetrieverModel: String, CaseIterable, Identifiable {
    case promaster = "ProMaster 98855"
    case kaiser = "Kaiser 204132"

    var id: String { rawValue }
}

struct FilmLeaderGuideView: View {
    @State private var selectedModel: LeaderRetrieverModel = .promaster

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 8) {
                    OverlineText(text: "35 mm canister", color: Theme.amber)
                    Text("Retrieve the leader.")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("Choose the retriever you own. These procedures are transcribed from the linked, model-specific instructions; do not combine steps from different tools.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Picker("Retriever model", selection: $selectedModel) {
                    ForEach(LeaderRetrieverModel.allCases) { model in
                        Text(model.rawValue).tag(model)
                    }
                }
                .pickerStyle(.segmented)

                if selectedModel == .promaster {
                    VStack(alignment: .leading, spacing: 13) {
                        OverlineText(text: "ProMaster · daylight use", color: Theme.amber)
                        GuideStep(number: "01", title: "Tighten the roll", detail: "Turn the cartridge spindle counter-clockwise a few times.")
                        GuideStep(number: "02", title: "Insert both sheets", detail: "Move sliders A and B fully right. Insert the tips of both sliding sheets into the cartridge.")
                        GuideStep(number: "03", title: "Advance slider A", detail: "Hold the cartridge against the tool and move slider A fully left, keeping slider B fully right. If it does not slide smoothly, do not force it; turn the spindle counter-clockwise several times and try again.")
                        GuideStep(number: "04", title: "Listen for the click", detail: "Slowly turn the spindle counter-clockwise until you hear a click, then stop immediately.")
                        GuideStep(number: "05", title: "Catch and withdraw", detail: "Move slider B left until it meets slider A, then slowly pull the cartridge away from the retriever. The leader should be extracted.")
                        Text("If there is no click, start over. If the sheets cannot be inserted after several attempts, stop and use the manual's darkroom or dark-bag alternative.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .glassCard(radius: 24)
                } else {
                    VStack(alignment: .leading, spacing: 13) {
                        OverlineText(text: "Kaiser · avoid direct bright light", color: Theme.amber)
                        GuideStep(number: "01", title: "Tighten the roll", detail: "Turn the cartridge spindle three or four times counter-clockwise.")
                        GuideStep(number: "02", title: "Set position A", detail: "Push the retriever button into position A. Insert tongue 3 completely into the cartridge slot; the tip of tongue 4 must also disappear inside.")
                        GuideStep(number: "03", title: "Find the catch", detail: "Slowly turn the cartridge spindle counter-clockwise until you hear a quiet click.")
                        GuideStep(number: "04", title: "Set position B", detail: "Hold the cartridge and spindle firmly while pushing the button into position B.")
                        GuideStep(number: "05", title: "Extract", detail: "Turn the spindle about one turn clockwise until you feel slight resistance. Pull the retriever out of the cartridge without holding the cartridge by its spindle.")
                        Text("If the leader is not extracted, repeat the complete operation. Follow the manual's instruction to avoid direct sun or bright light while using this retriever.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .glassCard(radius: 24)
                }

                VStack(alignment: .leading, spacing: 9) {
                    Label("Keep the film protected", systemImage: "checkmark.shield")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                    Text("Once recovered, load the film onto a reel in complete darkness or in a changing bag. Retriever controls differ by model; stop rather than forcing a slider, tongue, or film.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(17)
                .glassCard(radius: 22, tint: Theme.amber)

                ToolSourceLink(
                    title: "ProMaster Film Retriever · instruction book",
                    detail: "Manufacturer manual for model 98855; includes the daylight-use extraction procedure.",
                    url: "https://manuals.promaster.com/prodfiles/98855/Instruction%20Book/98855_FilmRetriever.pdf"
                )
                ToolSourceLink(
                    title: "Kaiser 35 mm Film Retriever · instructions",
                    detail: "Model 204132 manual; includes its bright-light caution and complete extraction sequence.",
                    url: "https://www.freestylephoto.com/static/pdf/product_pdf/kaiser/204132_Kaiser-35mm-Film-Retriever_INSTRUCTIONS.pdf"
                )
            }
            .padding(20)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Leader retrieval")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GuideStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Text(number)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.amber)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct TankReferenceRow: Identifiable {
    let id: String
    let tank: String
    let filmLoad: String
    let solutionVolume: String
    let note: String
}

struct TankCapacityReferenceView: View {
    private let rows = [
        TankReferenceRow(
            id: "paterson-single",
            tank: "Paterson System 4 · 35 mm tank",
            filmLoad: "1 × 35 mm reel",
            solutionVolume: "290 mL",
            note: "Manufacturer tank instructions identify the single-reel 35 mm tank; check the fill mark on your exact model."
        ),
        TankReferenceRow(
            id: "paterson-universal",
            tank: "Paterson System 4 · Universal tank",
            filmLoad: "2 × 35 mm reels or 1 × 120 reel",
            solutionVolume: "500 mL",
            note: "Common inversion-processing reference volume. Actual minimums vary with the tank and loaded reels; confirm the molded mark."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    OverlineText(text: "Tank reference", color: Theme.amber)
                    Text("Check the fill mark.")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("These are reference figures, not a substitute for the minimum volume printed for your tank and reel combination.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 13) {
                        Text(row.tank)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FILM LOAD")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.3)
                                    .foregroundStyle(Theme.inkFaint)
                                Text(row.filmLoad)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer(minLength: 10)
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("REFERENCE VOLUME")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.1)
                                    .foregroundStyle(Theme.inkFaint)
                                Text(row.solutionVolume)
                                    .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                                    .foregroundStyle(Theme.amber)
                            }
                        }
                        Text(row.note)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(17)
                    .glassCard(radius: 22)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Tank markings take priority", systemImage: "ruler")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                    Text("A listed film-load capacity is not automatically a safe working volume. Confirm the minimum liquid level for inversion with your tank's own instructions before mixing chemistry.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(17)
                .glassCard(radius: 22, tint: Theme.amber)

                ToolSourceLink(
                    title: "Paterson Super System 4 · tank instructions",
                    detail: "Manufacturer guide covering film formats and reel capacity. Verify fill volumes against your tank's markings.",
                    url: "https://patersonphotographic.com/wp-content/uploads/2025/05/Tanks.pdf"
                )
            }
            .padding(20)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Tank capacities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChemicalSafetyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    OverlineText(text: "Before you mix", color: Color(red: 0.95, green: 0.58, blue: 0.45))
                    Text("Treat every bottle as chemistry.")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("Product formulations differ. The label and current safety data sheet (SDS) for the exact product take precedence over this general checklist.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SafetySection(
                    icon: "hand.raised.fill",
                    title: "Protect skin and eyes",
                    points: [
                        "Wear chemical-resistant gloves specified by the product SDS; use eye protection when measuring or mixing concentrates.",
                        "Avoid splashes, skin contact, and breathing powder or mist. Wash hands after handling and keep food and drink away from the work area."
                    ]
                )
                SafetySection(
                    icon: "wind",
                    title: "Ventilate the room",
                    points: [
                        "Work with good general ventilation and keep containers closed when not in use.",
                        "If fumes or irritation occur, stop, move to fresh air, and follow the SDS emergency guidance. Do not use a respirator as a substitute for required ventilation."
                    ]
                )
                SafetySection(
                    icon: "xmark.octagon.fill",
                    title: "Never mix these",
                    warning: true,
                    points: [
                        "Never mix household chlorine bleach with acids or ammonia-containing cleaners; toxic chlorine or chloramine gases can result.",
                        "Do not combine photographic baths, concentrates, or leftover waste with one another unless the product instructions explicitly direct it. Keep stop, developer, and fixer in separate, labeled containers.",
                        "Do not pour an unknown chemical into a drain or another waste container. Mixing incompatible leftovers can cause dangerous reactions."
                    ]
                )
                SafetySection(
                    icon: "shippingbox.fill",
                    title: "Store and dispose carefully",
                    points: [
                        "Keep products in their original, labeled containers and follow their storage and disposal instructions.",
                        "Do not assume spent fixer or other photographic chemistry is drain-safe. Check the product SDS and local sewer or hazardous-waste rules; use a local collection program when required."
                    ]
                )

                ToolSourceLink(
                    title: "U.S. EPA · Household Hazardous Waste",
                    detail: "Do not mix leftover hazardous products; follow labels and contact local agencies for disposal rules.",
                    url: "https://www.epa.gov/hw/household-hazardous-waste-hhw"
                )
                ToolSourceLink(
                    title: "CDC · Chlorine chemical fact sheet",
                    detail: "Chlorine exposure and the hazards of mixing household bleach with other cleaners.",
                    url: "https://www.cdc.gov/chemical-emergencies/chemical-fact-sheets/chlorine.html"
                )
            }
            .padding(20)
        }
        .background { LiquidBackdrop() }
        .navigationTitle("Chemical safety")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SafetySection: View {
    let icon: String
    let title: String
    var warning = false
    let points: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(warning ? Color(red: 1.0, green: 0.55, blue: 0.42) : Theme.amber)
            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(warning ? Color(red: 1.0, green: 0.55, blue: 0.42) : Theme.amber)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                    Text(point)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(17)
        .glassCard(radius: 22, tint: warning ? Color(red: 1.0, green: 0.35, blue: 0.22) : nil)
    }
}
