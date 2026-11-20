//
//  RedroomJournalScreen.swift
//  Darkroom
//
//  The Journal bench in REDROOM. The journal itself is still to be built, so
//  this is the room's own statement of what will stand here — a plate on the wall
//  where the ledger will hang, not a borrowed one.
//

import SwiftUI

struct RedroomJournalTab: View {
    var body: some View {
        NavigationStack {
            RedroomJournalHome()
        }
    }
}

private struct RedroomJournalHome: View {
    private let bullets: [String] = [
        "Each session logged with film, developer, time and temperature",
        "Search, filter and re-run a past session",
        "Averages against the published times",
        "Totals per chemical batch"
    ]

    var body: some View {
        RedroomScreen {
            RedroomScreenHeader(kicker: "Kept on the bench", title: "Journal")
                .redroomReveal(.safelightFade)

            ledgerPlate

            RedroomNote(text: "The journal is on the roadmap as Journal and statistics. Until it arrives, this room stays empty rather than showing a ledger with nothing in it.")
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var ledgerPlate: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Redroom.textMuted)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Journal")
                        .font(Redroom.display(20, weight: .semibold))
                        .foregroundStyle(Redroom.text)
                    Text("Every development session, kept and searchable.")
                        .font(Redroom.body(12))
                        .foregroundStyle(Redroom.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            RedroomLitRule()

            ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
                HStack(alignment: .top, spacing: 10) {
                    Text(String(format: "%02d", index + 1))
                        .font(Redroom.figure(10, weight: .semibold))
                        .foregroundStyle(Redroom.textMuted)
                        .frame(width: 20, alignment: .leading)

                    Text(bullet)
                        .font(Redroom.body(13))
                        .foregroundStyle(Redroom.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .redroomGlass(variant: .optical, cornerRadius: RedroomMetrics.cardRadius)
    }
}
