// Copyright © 2017 Hootsuite. All rights reserved.

@testable import TokenUI
import XCTest

class TokenTextViewTextStorageTests: XCTestCase {

    func testGetString() {
        let mentionText = createMentionText()
        XCTAssertEqual(mentionText.string, "Hello @davidby how are you")
    }

    func testReplaceCharacters() {
        let mentionText = createMentionText()
        mentionText.replaceCharacters(in: NSRange(location: 6, length: 8), with: "@kenbritton")
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
            XCTFail("Expected a token info, got nil")
        }
    }

    func testRangeNotIntersectingTokens() {
        let mentionText = createMentionText()
        let intersection = mentionText.rangeIntersectsToken(NSRange(location: 0, length: 3))
        XCTAssertFalse(intersection)
    }

    func testRangeIntersectingTokens() {
        let mentionText = createMentionText()
        let intersection = mentionText.rangeIntersectsToken(NSRange(location: 3, length: 5))
        XCTAssertTrue(intersection)
    }

    func testRangeNotIntersectingTokensRefs() {
        let mentionText = createMentionText()
        let intersection = mentionText.tokensIntersectingRange(NSRange(location: 0, length: 3))
        XCTAssertTrue(intersection.isEmpty)
    }

    func testRangeIntersectingTokensRefs() {
        let mentionText = createMentionText()
        let intersection = mentionText.tokensIntersectingRange(NSRange(location: 3, length: 5))
        XCTAssertTrue(intersection.count == 1)
        if let ref = intersection.first {
            XCTAssertEqual(ref, "token-reference")
        } else {
            XCTFail("Expected an intersecting token, got nil")
        }
    }

    func testValidEditingRangeNoIntersection() {
        let mentionText = createMentionText()
        XCTAssertTrue(mentionText.isValidEditingRange(NSRange(location: 0, length: 3)))
    }

    func testValidEditingRangeEncloseMention() {
        let mentionText = createMentionText()
        XCTAssertTrue(mentionText.isValidEditingRange(NSRange(location: 4, length: 12)))
    }

    func testInvalidEditingRangeOverlapBefore() {
        let mentionText = createMentionText()
        XCTAssertFalse(mentionText.isValidEditingRange(NSRange(location: 5, length: 4)))
    }

    func testInvalidEditingRangeOverlapAfter() {
        let mentionText = createMentionText()
        XCTAssertFalse(mentionText.isValidEditingRange(NSRange(location: 10, length: 8)))
    }

    func testInvalidEditingRangeWithinToken() {
        let mentionText = createMentionText()
        XCTAssertFalse(mentionText.isValidEditingRange(NSRange(location: 8, length: 4)))
    }

    fileprivate func createMentionText() -> TokenTextViewTextStorage {
        let textStorage = TokenTextViewTextStorage()
        let originalText = NSAttributedString(string: "Hello  how are you")
        textStorage.insert(originalText, at: 0)
        let mentionText = NSAttributedString(string: "@davidby", attributes: [TokenTextViewControllerConstants.tokenAttributeName: "token-reference"])
        textStorage.insert(mentionText, at: 6)
        return textStorage
    }

}
