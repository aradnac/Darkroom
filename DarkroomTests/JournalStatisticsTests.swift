//
//  JournalStatisticsTests.swift
//  DarkroomTests
//
//  The journal's arithmetic: the tallies, the deviation from the published time,
//  and the way a bottle is credited with the sessions that name its developer.
//

import XCTest
@testable import Darkroom

final class JournalStatisticsTests: XCTestCase {

    private func record(
        date: Date,
        film: String = "Ilford HP5 Plus 400",
        filmID: String = "hp5",
        developer: String = "Kodak D-76",
        developerID: String = "d76",
        dilution: String = "1+1",
        seconds: TimeInterval = 600,
        published: TimeInterval? = 600,
        rolls: Int = 1
    ) -> SessionRecord {
        SessionRecord(
            date: date,
            filmID: filmID,
            filmName: film,
            developerID: developerID,
            developerName: developer,
            dilutionID: dilution,
            dilutionLabel: dilution,
            temperature: 20,
            developmentSeconds: seconds,
            publishedSeconds: published,
            exposureIndex: 400,
            pushStops: 0,
            reuseCount: 1,
            rolls: rolls,
            agitationLabel: "Normal",
            washLabel: "Running water"
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: Totals

    func testTotalsAndTallies() {
        let records = [
            record(date: date(2026, 11, 2), rolls: 2),
            record(date: date(2026, 10, 9), film: "Kodak Tri-X 400", filmID: "trix"),
            record(date: date(2026, 10, 20), developer: "Ilford ID-11", developerID: "id11")
        ]

        let stats = JournalStatistics(records: records)

        XCTAssertEqual(stats.sessions, 3)
        XCTAssertEqual(stats.rolls, 4)
        XCTAssertEqual(stats.totalTime, 1800, accuracy: 0.001)

        let byFilm = Dictionary(uniqueKeysWithValues: stats.byFilm.map { ($0.name, $0) })
        XCTAssertEqual(byFilm["Ilford HP5 Plus 400"]?.rolls, 3)
        XCTAssertEqual(byFilm["Ilford HP5 Plus 400"]?.sessions, 2)
        XCTAssertEqual(byFilm["Kodak Tri-X 400"]?.rolls, 1)

        let byDeveloper = Dictionary(uniqueKeysWithValues: stats.byDeveloper.map { ($0.name, $0) })
        XCTAssertEqual(byDeveloper["Kodak D-76"]?.sessions, 2)
        XCTAssertEqual(byDeveloper["Ilford ID-11"]?.sessions, 1)

        // Newest month first.
        XCTAssertEqual(stats.byMonth.first?.id, "2026-11")
        XCTAssertEqual(stats.byMonth.map(\.id), ["2026-11", "2026-10"])
    }

    // MARK: Deviation

    func testDeviationAveragesOnlyWhereThereIsAPublishedTime() {
        let records = [
            record(date: date(2026, 11, 1), seconds: 630, published: 600),   // +30
            record(date: date(2026, 11, 2), seconds: 570, published: 600),   // −30
            record(date: date(2026, 11, 3), seconds: 900, published: nil)    // ignored
        ]

        let stats = JournalStatistics(records: records)
        let deviation = try? XCTUnwrap(stats.deviation)

        XCTAssertEqual(deviation?.count, 2)
        XCTAssertEqual(deviation?.average ?? 0, 0, accuracy: 0.001)
        XCTAssertEqual(deviation?.averagePercent ?? 1, 0, accuracy: 0.001)
    }

    func testDeviationReportsWhenNothingHasAPublishedTime() {
        let records = [record(date: date(2026, 11, 1), seconds: 900, published: nil)]
        XCTAssertNil(JournalStatistics(records: records).deviation)
    }

    func testRecordDeviationAndPercent() {
        let entry = record(date: date(2026, 11, 1), seconds: 660, published: 600)
        XCTAssertEqual(entry.deviation ?? 0, 60, accuracy: 0.001)
        XCTAssertEqual(entry.deviationPercent ?? 0, 10, accuracy: 0.001)
    }

    // MARK: Chemicals

    func testChemicalTotalsSeparateDilutionsAndCreditBatches() {
        let records = [
            record(date: date(2026, 11, 1), dilution: "1+1", rolls: 2),
            record(date: date(2026, 11, 2), dilution: "1+3", rolls: 1),
            record(date: date(2026, 11, 3), developer: "Ilford ID-11", developerID: "id11", dilution: "1+1")
        ]

        let batch = ChemicalBatch(
            name: "D-76 stock, 1 L",
            developer: "Kodak D-76",
            litres: 1,
            mixedOn: date(2026, 10, 1),
            shelfLifeMonths: 6,
            capacityRolls: 16,
            isReusable: true,
            notes: ""
        )
        let other = ChemicalBatch(
            name: "Rodinal",
            developer: "Agfa Rodinal",
            litres: 0.5,
            mixedOn: date(2026, 10, 1),
            shelfLifeMonths: nil,
            capacityRolls: 50,
            isReusable: false,
            notes: ""
        )

        let stats = JournalStatistics(records: records, batches: [batch, other])
        let chemicals = Dictionary(uniqueKeysWithValues: stats.chemicals.map { ($0.name, $0) })

        XCTAssertEqual(chemicals.count, 3)
        XCTAssertEqual(chemicals["Kodak D-76 1+1"]?.rolls, 2)
        XCTAssertEqual(chemicals["Kodak D-76 1+3"]?.rolls, 1)

        let d76 = chemicals["Kodak D-76 1+1"]
        XCTAssertEqual(d76?.batches.count, 1)
        XCTAssertEqual(d76?.batches.first?.name, "D-76 stock, 1 L")
        XCTAssertEqual(d76?.batches.first?.sessions, 2)

        // The Rodinal bottle names a developer no session used.
        XCTAssertTrue(chemicals.values.allSatisfy { chemical in
            chemical.batches.allSatisfy { $0.name != "Rodinal" }
        })
    }

    // MARK: Months

    func testMonthLabel() {
        XCTAssertEqual(JournalStatistics.monthLabel("2026-11"), "November 2026")
        XCTAssertEqual(JournalStatistics.monthLabel("2025-01"), "January 2025")
        XCTAssertEqual(JournalStatistics.monthLabel("nonsense"), "nonsense")
    }
}
