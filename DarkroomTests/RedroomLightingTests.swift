//
//  RedroomLightingTests.swift
//  DarkroomTests
//
//  The lighting system's own arithmetic: where the lamp is, which way an element
//  faces, how fast the light falls off, and that intensity scales the sample
//  rather than replacing it. Plus the bottle's level-to-quantity mapping.
//

import XCTest
@testable import Darkroom

final class RedroomLightingTests: XCTestCase {

    private let screen = CGSize(width: 400, height: 800)
    private let screenFrame = CGRect(x: 0, y: 0, width: 400, height: 800)

    // MARK: Direction

    /// An element below the lamp must have its gradient start above its centre
    /// and its end below it, so the highlight faces the light.
    func testSampleFacesTheLamp() {
        let frame = CGRect(x: 150, y: 600, width: 100, height: 60)
        let sample = RedroomLightSample.make(
            frame: frame,
            light: RedroomLightParameters(intensity: .normal),
            screen: screen
        )

        XCTAssertGreaterThan(sample.start.y, 0.5)
        XCTAssertLessThan(sample.end.y, 0.5)
    }

    /// An element below and to the right of the lamp leans its gradient start up
    /// and to the left.
    func testSampleLeansTowardsTheLampHorizontally() {
        let frame = CGRect(x: 320, y: 600, width: 60, height: 60)
        let sample = RedroomLightSample.make(
            frame: frame,
            light: RedroomLightParameters(intensity: .normal),
            screen: screen
        )

        XCTAssertLessThan(sample.start.x, 0.5)
    }

    /// An element at the very top of the screen is directly under the lamp, so it
    /// leans almost nowhere horizontally.
    func testElementUnderTheLampFacesStraightUp() {
        let frame = CGRect(x: 175, y: 10, width: 50, height: 40)
        let sample = RedroomLightSample.make(
            frame: frame,
            light: RedroomLightParameters(intensity: .normal),
            screen: screen
        )

        XCTAssertEqual(sample.start.x, 0.5, accuracy: 0.02)
    }

    // MARK: Falloff

    func testLightFallsOffDownTheScreen() {
        let top = RedroomLightSample.make(
            frame: CGRect(x: 100, y: 40, width: 200, height: 60),
            light: RedroomLightParameters(intensity: .normal),
            screen: screen
        )
        let middle = RedroomLightSample.make(
            frame: CGRect(x: 100, y: 380, width: 200, height: 60),
            light: RedroomLightParameters(intensity: .normal),
            screen: screen
        )
        let foot = RedroomLightSample.make(
            frame: CGRect(x: 100, y: 740, width: 200, height: 60),
            light: RedroomLightParameters(intensity: .normal),
            screen: screen
        )

        XCTAssertGreaterThan(top.strength, middle.strength)
        XCTAssertGreaterThan(middle.strength, foot.strength)
        XCTAssertGreaterThan(top.direct, middle.direct)
        XCTAssertGreaterThan(middle.direct, foot.direct)
    }

    func testStrengthIsClamped() {
        for intensity in RedroomIntensity.allCases {
            let sample = RedroomLightSample.make(
                frame: CGRect(x: 0, y: 0, width: 200, height: 60),
                light: RedroomLightParameters(intensity: intensity),
                screen: screen
            )
            XCTAssertLessThanOrEqual(sample.strength, 1)
            XCTAssertGreaterThanOrEqual(sample.strength, 0)
            XCTAssertLessThanOrEqual(sample.direct, 1)
            XCTAssertGreaterThanOrEqual(sample.bounce, 0)
        }
    }

    func testBounceIsNeverBrighterThanDirect() {
        let frame = CGRect(x: 100, y: 700, width: 200, height: 60)
        let sample = RedroomLightSample.make(
            frame: frame,
            light: RedroomLightParameters(intensity: .extreme),
            screen: screen
        )

        XCTAssertLessThanOrEqual(sample.bounce, sample.direct)
    }

    // MARK: Intensity

    /// The safelight scales glow only: at a fixed position, a brighter room
    /// returns a brighter sample.
    func testBrighterIntensityReturnsBrighterLight() {
        let frame = CGRect(x: 100, y: 300, width: 200, height: 60)

        func strength(_ intensity: RedroomIntensity) -> Double {
            RedroomLightSample.make(
                frame: frame,
                light: RedroomLightParameters(intensity: intensity),
                screen: screen
            ).strength
        }

        XCTAssertLessThan(strength(.dim), strength(.normal))
        XCTAssertLessThan(strength(.normal), strength(.bright))
        XCTAssertLessThan(strength(.bright), strength(.extreme))
    }

    /// A zero frame is what the first layout pass sees; it must not produce a
    /// sample that claims the element is lit.
    func testZeroFrameIsUnlit() {
        let sample = RedroomLightSample.make(
            frame: .zero,
            light: RedroomLightParameters(intensity: .extreme),
            screen: screen
        )

        XCTAssertEqual(sample.strength, 0)
        XCTAssertEqual(sample.direct, 0)
        XCTAssertEqual(sample.bounce, 0)
    }

    func testFullScreenFrameIsAccepted() {
        let sample = RedroomLightSample.make(
            frame: screenFrame,
            light: RedroomLightParameters(intensity: .normal),
            screen: screen
        )

        XCTAssertGreaterThan(sample.direct, 0)
        XCTAssertGreaterThanOrEqual(sample.start.x, 0)
        XCTAssertLessThanOrEqual(sample.start.x, 1)
        XCTAssertGreaterThanOrEqual(sample.start.y, 0)
        XCTAssertLessThanOrEqual(sample.start.y, 1)
    }

    // MARK: Bottle mapping

    func testBottleLevelMapsTheRemainingRolls() {
        XCTAssertEqual(
            RedroomQuantities.bottleLevel(remaining: 8, capacity: 16),
            0.5,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            RedroomQuantities.bottleLevel(remaining: 0, capacity: 16),
            0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            RedroomQuantities.bottleLevel(remaining: 16, capacity: 16),
            1,
            accuracy: 0.0001
        )
    }

    func testBottleLevelIsClampedAndSafeWithoutCapacity() {
        XCTAssertEqual(RedroomQuantities.bottleLevel(remaining: 40, capacity: 16), 1, accuracy: 0.0001)
        XCTAssertEqual(RedroomQuantities.bottleLevel(remaining: -3, capacity: 16), 0, accuracy: 0.0001)
        XCTAssertEqual(RedroomQuantities.bottleLevel(remaining: 5, capacity: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(RedroomQuantities.bottleLevel(remaining: 0, capacity: 0), 0, accuracy: 0.0001)
    }

    func testBottlePercentMatchesLevel() {
        XCTAssertEqual(RedroomQuantities.bottlePercent(remaining: 8, capacity: 16), 50)
        XCTAssertEqual(RedroomQuantities.bottlePercent(remaining: 1, capacity: 3), 33)
        XCTAssertEqual(RedroomQuantities.bottlePercent(remaining: 0, capacity: 0), 0)
    }
}
