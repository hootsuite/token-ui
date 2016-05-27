//
//  TokenTextViewTextStorageTests.swift
//  OwlTokenTextView
//
//  Created by David Bonnefoy on 2016-05-27.
//  Copyright © 2016 Hootsuite. All rights reserved.
//

@testable import OwlTokenTextView
import XCTest

class TokenTextViewTextStorageTests: XCTestCase {

    func testGetString() {
        let mentionText = createMentionText()
        XCTAssertEqual(mentionText.string, "Hello @davidby how are you")
    }

    func testReplaceCharacters() {
        let mentionText = createMentionText()
        mentionText.replaceCharactersInRange(NSMakeRange(6, 8), withString: "@kenbritton")
        XCTAssertEqual(mentionText.string, "Hello @kenbritton how are you")
    }

    func testTokenList() {
        let mentionText = createMentionText()
        let tokenList = mentionText.tokenList
        if let tokenInfo = tokenList.first {
            XCTAssertEqual(tokenInfo.reference, "token-reference")
            XCTAssertEqual(tokenInfo.text, "@davidby")
            XCTAssertEqual(tokenInfo.range.location, 6)
            XCTAssertEqual(tokenInfo.range.length, 8)
        } else {
            XCTFail()
        }
    }

    func testRangeNotIntersectingTokens() {
        let mentionText = createMentionText()
        let intersection = mentionText.rangeIntersectsToken(NSMakeRange(0, 3))
        XCTAssertFalse(intersection)
    }

    func testRangeIntersectingTokens() {
        let mentionText = createMentionText()
        let intersection = mentionText.rangeIntersectsToken(NSMakeRange(3, 5))
        XCTAssertTrue(intersection)
    }

    func testRangeNotIntersectingTokensRefs() {
        let mentionText = createMentionText()
        let intersection = mentionText.tokensIntersectingRange(NSMakeRange(0, 3))
        XCTAssertTrue(intersection.isEmpty)
    }

    func testRangeIntersectingTokensRefs() {
        let mentionText = createMentionText()
        let intersection = mentionText.tokensIntersectingRange(NSMakeRange(3, 5))
        XCTAssertTrue(intersection.count == 1)
        if let ref = intersection.first {
            XCTAssertEqual(ref, "token-reference")
        } else {
            XCTFail()
        }
    }

    func testValidEditingRangeNoIntersection() {
        let mentionText = createMentionText()
        XCTAssertTrue(mentionText.isValidEditingRange(NSMakeRange(0, 3)))
    }

    func testValidEditingRangeEncloseMention() {
        let mentionText = createMentionText()
        XCTAssertTrue(mentionText.isValidEditingRange(NSMakeRange(4, 12)))
    }

    func testInvalidEditingRangeOverlapBefore() {
        let mentionText = createMentionText()
        XCTAssertFalse(mentionText.isValidEditingRange(NSMakeRange(5, 4)))
    }

    func testInvalidEditingRangeOverlapAfter() {
        let mentionText = createMentionText()
        XCTAssertFalse(mentionText.isValidEditingRange(NSMakeRange(10, 8)))
    }

    func testInvalidEditingRangeWithinToken() {
        let mentionText = createMentionText()
        XCTAssertFalse(mentionText.isValidEditingRange(NSMakeRange(8, 4)))
    }

    private func createMentionText() -> TokenTextViewTextStorage {
        let textStorage = TokenTextViewTextStorage()
        let originalText = NSAttributedString(string: "Hello  how are you")
        textStorage.insertAttributedString(originalText, atIndex: 0)
        let mentionText = NSAttributedString(string: "@davidby", attributes: [TokenTextViewControllerConstants.tokenAttributeName: "token-reference"])
        textStorage.insertAttributedString(mentionText, atIndex: 6)
        return textStorage
    }

}
