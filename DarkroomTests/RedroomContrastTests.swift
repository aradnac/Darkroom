//
//  RedroomContrastTests.swift
//  DarkroomTests
//
//  The contrast the theme promises, computed from the tokens rather than looked
//  at: every label the room draws, at all four safelight intensities, against
//  the darkest surface and against the brightest the glass can be made.
//

import XCTest
@testable import Darkroom

final class RedroomContrastTests: XCTestCase {

    /// Body text must hold at least 4.5:1 in every room.
    func testTextContrastPassesAtEveryIntensity() {
        for report in RedroomContrast.allReports {
            for pair in report.pairs {
                XCTAssertGreaterThanOrEqual(
                    pair.ratio,
                    pair.required,
                    "\(pair.label) at \(report.intensity.title): \(pair.ratio):1, needs \(pair.required):1"
                )
            }
        }
    }

    /// The four intensities must not change the contrast of type: they scale
    /// glow only. Because the tokens are fixed, the ratios for the room and the
    /// panels are identical across intensities; the glass's worst case may rise,
    /// which is the only figure allowed to move.
    func testPanelContrastIsIdenticalAcrossIntensities() {
        let reports = RedroomContrast.allReports
        guard let first = reports.first else { return XCTFail("No reports") }

        for report in reports.dropFirst() {
            for pair in report.pairs where pair.id != "body-glass" && pair.id != "muted-glass" && pair.id != "display-glass" {
                guard let reference = first.pairs.first(where: { $0.id == pair.id }) else {
                    XCTFail("Missing \(pair.id) in the first report")
                    continue
                }
                XCTAssertEqual(reference.ratio, pair.ratio, accuracy: 0.0001)
            }
        }
    }

    /// The glass genuinely gets brighter with the lamp, so the test is checking
    /// something real rather than a constant.
    func testGlassBrightensWithIntensity() {
        let dim = RedroomContrast.brightestGlassLuminance(intensity: .dim)
        let normal = RedroomContrast.brightestGlassLuminance(intensity: .normal)
        let bright = RedroomContrast.brightestGlassLuminance(intensity: .bright)
        let extreme = RedroomContrast.brightestGlassLuminance(intensity: .extreme)

        XCTAssertLessThan(dim, normal)
        XCTAssertLessThanOrEqual(normal, bright)
        XCTAssertLessThanOrEqual(bright, extreme)
    }

    /// The arithmetic itself: white on black is 21:1 and a colour against
    /// itself is 1:1, so the implementation matches WCAG's definition.
    func testContrastFormula() {
        XCTAssertEqual(
            RedroomContrast.ratio(foreground: 0xFFFFFF, background: 0x000000),
            21,
            accuracy: 0.01
        )
        XCTAssertEqual(
            RedroomContrast.ratio(foreground: 0xF4EAEA, background: 0xF4EAEA),
            1,
            accuracy: 0.0001
        )
    }
}
