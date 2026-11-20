//
//  CrossProcessProfileTests.swift
//  DarkroomTests
//
//  The cross-processing profile: the fields it carries, the rule that an unsafe
//  combination is never presented as merely experimental, and the CSV route into
//  the same library.
//

import XCTest
@testable import Darkroom

final class CrossProcessProfileTests: XCTestCase {

    // MARK: Model

    private func entry(
        classification: CrossProcessClass,
        colourShifts: String? = "Cyan shadows",
        limitations: String? = "Times vary between kits",
        provenance: LibraryProvenance = LibraryProvenance(kind: .community, source: "massive-dev-chart", note: nil)
    ) -> LibraryCrossProcess {
        LibraryCrossProcess(
            film: "film-a",
            fromProcess: .colourReversal,
            toProcess: .colourNegative,
            classification: classification,
            summary: "A cross process.",
            provenance: provenance,
            colourShifts: colourShifts,
            contrastChange: "Higher",
            grainChange: "Finer",
            exposureNotes: "Rate at EI 32",
            expectedResult: "Dense and saturated",
            limitations: limitations,
            examples: ["Music photography"],
            references: ["Massive Dev Chart — https://www.digitaltruth.com/devchart.php"]
        )
    }

    func testFullProfileDecodes() throws {
        let json = """
        {
          "film": "film-a",
          "fromProcess": "colourReversal",
          "toProcess": "colourNegative",
          "classification": "documentedAndTested",
          "summary": "The classic cross process.",
          "provenance": { "kind": "community", "source": "massive-dev-chart" },
          "colourShifts": "Cyan shadows.",
          "contrastChange": "Higher.",
          "grainChange": "Finer.",
          "exposureNotes": "Rate at EI 32.",
          "expectedResult": "Dense and saturated.",
          "limitations": "Times vary between kits.",
          "examples": ["Music photography"],
          "references": ["Massive Dev Chart — https://www.digitaltruth.com/devchart.php"]
        }
        """

        let decoded = try JSONDecoder().decode(LibraryCrossProcess.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.colourShifts, "Cyan shadows.")
        XCTAssertEqual(decoded.contrastChange, "Higher.")
        XCTAssertEqual(decoded.grainChange, "Finer.")
        XCTAssertEqual(decoded.exposureNotes, "Rate at EI 32.")
        XCTAssertEqual(decoded.expectedResult, "Dense and saturated.")
        XCTAssertEqual(decoded.examples, ["Music photography"])
        XCTAssertEqual(decoded.references?.count, 1)
        XCTAssertFalse(decoded.isUnsafe)
        XCTAssertEqual(decoded.classification.safetyTitle, "Documented and tested")
    }

    func testProfileFieldsOnlyIncludeWhatIsDocumented() {
        let sparse = LibraryCrossProcess(
            film: "film-b",
            fromProcess: .colourNegative,
            toProcess: .colourReversal,
            classification: .experimental,
            summary: "Thin.",
            provenance: .unverified
        )

        XCTAssertTrue(sparse.profileFields.isEmpty)
    }

    func testProfileFieldsAreOrderedAndFlagLimitationsWhenUnsafe() {
        let unsafe = entry(classification: .incompatible)
        let fields = unsafe.profileFields

        XCTAssertEqual(fields.map { $0.label }, [
            "Colour shifts", "Contrast", "Grain", "Exposure", "Expected result", "Limitations"
        ])
        XCTAssertEqual(fields.last?.isWarning, true)
        XCTAssertTrue(fields.dropLast().allSatisfy { !$0.isWarning })
    }

    // MARK: Safety

    func testUnsafeIsNeverPresentedAsExperimental() {
        let unsafe = entry(classification: .incompatible)

        XCTAssertTrue(unsafe.isUnsafe)
        XCTAssertFalse(CrossProcessClass.incompatible.isSafe)
        XCTAssertTrue(unsafe.classification.safetyTitle.contains("Unsafe"))
        XCTAssertFalse(unsafe.classification.safetyTitle.lowercased().contains("experimental"))
    }

    func testOnlyIncompatibleIsUnsafe() {
        for item in CrossProcessClass.allCases {
            XCTAssertEqual(item.isSafe, item != .incompatible, "\(item.rawValue)")
        }
    }

    func testSortedPutsUnsafeLast() {
        let entries = [
            entry(classification: .incompatible),
            entry(classification: .experimental),
            entry(classification: .documentedAndTested),
            entry(classification: .notRecommended),
            entry(classification: .communityTested)
        ]

        XCTAssertEqual(
            LibraryCrossProcess.sorted(entries).map(\.classification),
            [.documentedAndTested, .communityTested, .experimental, .notRecommended, .incompatible]
        )
    }

    // MARK: Import

    func testCSVImportsCrossProcessProfiles() throws {
        let csv = """
        kind,film,fromprocess,toprocess,classification,summary,colourshifts,contrastchange,grainchange,exposurenotes,expectedresult,limitations,examples,references,provenance,source
        crossprocess,film-a,colourReversal,colourNegative,communityTested,A classic cross process,Cyan shadows,Higher,Finer,Rate at EI 32,Dense and saturated,Sample variance,Example one|Example two,Chart|Second chart,community,massive-dev-chart
        crossprocess,film-b,cinemaNegative,colourReversal,unsafe,Rem-jet in E-6 leaves the kit contaminated,,,,No usable result,Ruinous and unsafe,Second example,,datasheet,kodak-ecn2
        """

        let document = try LibraryImporter.document(fromCSV: csv)

        XCTAssertEqual(document.crossProcess.count, 2)

        let first = try XCTUnwrap(document.crossProcess.first { $0.film == "film-a" })
        XCTAssertEqual(first.fromProcess, .colourReversal)
        XCTAssertEqual(first.toProcess, .colourNegative)
        XCTAssertEqual(first.classification, .communityTested)
        XCTAssertEqual(first.colourShifts, "Cyan shadows")
        XCTAssertEqual(first.contrastChange, "Higher")
        XCTAssertEqual(first.grainChange, "Finer")
        XCTAssertEqual(first.exposureNotes, "Rate at EI 32")
        XCTAssertEqual(first.expectedResult, "Dense and saturated")
        XCTAssertEqual(first.limitations, "Sample variance")
        XCTAssertEqual(first.examples, ["Example one", "Example two"])
        XCTAssertEqual(first.references, ["Chart", "Second chart"])
        XCTAssertEqual(first.provenance.source, "massive-dev-chart")
        XCTAssertFalse(first.isUnsafe)

        let second = try XCTUnwrap(document.crossProcess.first { $0.film == "film-b" })
        XCTAssertEqual(second.toProcess, .colourReversal)
        XCTAssertTrue(second.isUnsafe)
        XCTAssertEqual(second.classification, .incompatible)
    }

    func testCSVSkipsACrossProcessRowWithNoClassification() throws {
        let csv = """
        kind,film,fromprocess,toprocess,classification,summary,provenance
        crossprocess,film-a,colourReversal,colourNegative,,Missing class,community
        crossprocess,film-b,colourNegative,colourReversal,experimental,Thin,unverified
        """

        let document = try LibraryImporter.document(fromCSV: csv)

        XCTAssertEqual(document.crossProcess.count, 1)
        XCTAssertEqual(document.crossProcess.first?.film, "film-b")
        XCTAssertEqual(document.crossProcess.first?.classification, .experimental)
    }

    func testCSVToleratesSpokenProcessNames() throws {
        let csv = """
        kind,film,fromprocess,toprocess,classification,summary,provenance
        crossprocess,film-a,C-41,E-6,communityTested,Cast,community
        """

        let document = try LibraryImporter.document(fromCSV: csv)

        XCTAssertEqual(document.crossProcess.first?.fromProcess, .colourNegative)
        XCTAssertEqual(document.crossProcess.first?.toProcess, .colourReversal)
    }

    func testImportSummaryCountsCrossProcessRecords() {
        let csv = """
        kind,film,fromprocess,toprocess,classification,summary,provenance
        crossprocess,film-a,colourReversal,colourNegative,experimental,Thin,unverified
        """

        guard let document = try? LibraryImporter.document(fromCSV: csv) else {
            return XCTFail("Import failed")
        }

        XCTAssertTrue(LibraryImporter.summary(of: document).contains("cross-process"))
    }
}
