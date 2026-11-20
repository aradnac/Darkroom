//
//  VoiceCommandTests.swift
//  DarkroomTests
//
//  What the recogniser's transcript has to turn into. "go" heard before the
//  result settles is the case that made voice commands look broken.
//

import XCTest
@testable import Darkroom

final class VoiceCommandTests: XCTestCase {

    func testGoIsHeardFromAPartialTranscript() {
        XCTAssertEqual(VoiceCommand.parse("go", isFinal: false), .go)
        XCTAssertEqual(VoiceCommand.parse("Go.", isFinal: false), .go)
        XCTAssertEqual(VoiceCommand.parse("ok go", isFinal: false), .go)
        XCTAssertEqual(VoiceCommand.parse("let's go", isFinal: false), .go)
        XCTAssertEqual(VoiceCommand.parse("go", isFinal: true), .go)
        XCTAssertEqual(VoiceCommand.parse("start now", isFinal: true), .go)
    }

    func testGoDoesNotSwallowLongerCommands() {
        XCTAssertEqual(VoiceCommand.parse("start fixer", isFinal: false), .startFixer)
        XCTAssertEqual(VoiceCommand.parse("start the fixer", isFinal: true), .startFixer)
        XCTAssertEqual(VoiceCommand.parse("next stage", isFinal: false), .nextStage)
        XCTAssertEqual(VoiceCommand.parse("skip stage", isFinal: true), .nextStage)
    }

    func testSpokenNumbers() {
        XCTAssertEqual(VoiceCommand.parse("add thirty seconds", isFinal: false), .addSeconds(30))
        XCTAssertEqual(VoiceCommand.parse("add 30 seconds", isFinal: false), .addSeconds(30))
        XCTAssertEqual(VoiceCommand.parse("add forty-five seconds", isFinal: false), .addSeconds(45))
        XCTAssertEqual(VoiceCommand.parse("add one and a half minutes", isFinal: false), .addSeconds(90))
        XCTAssertEqual(VoiceCommand.parse("add a minute", isFinal: false), .addSeconds(60))
        XCTAssertEqual(VoiceCommand.parse("add half a minute", isFinal: false), .addSeconds(30))
        XCTAssertEqual(VoiceCommand.parse("add twenty seconds please", isFinal: false), .addSeconds(20))
        XCTAssertEqual(VoiceCommand.parse("thirty seconds more", isFinal: false), .addSeconds(30))
    }

    func testRollCount() {
        XCTAssertEqual(VoiceCommand.parse("how many rolls", isFinal: false), .rollCount)
        XCTAssertEqual(
            VoiceCommand.parse("how many rolls have I developed with this d 76", isFinal: false),
            .rollCount
        )
    }

    func testUnrelatedSpeechDoesNothing() {
        XCTAssertNil(VoiceCommand.parse("", isFinal: false))
        XCTAssertNil(VoiceCommand.parse("hello there", isFinal: false))
        XCTAssertNil(VoiceCommand.parse("add", isFinal: false))
        XCTAssertNil(VoiceCommand.parse("add eleven minutes", isFinal: false))
    }

    /// "start" opening a longer sentence must not start the stage.
    func testBareStartNeedsToBeTheWholePhrase() {
        XCTAssertNil(VoiceCommand.parse("start the developer please", isFinal: false))
        XCTAssertEqual(VoiceCommand.parse("start", isFinal: false), .go)
    }
}
