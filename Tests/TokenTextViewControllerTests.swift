// Copyright © 2017 Hootsuite. All rights reserved.

@testable import TokenUI
import XCTest

class TokenTextViewControllerTests: XCTestCase {

    func testSetGetText() {
        let tokenVC = TokenTextViewController()
        let text = "This is not a text."
        tokenVC.text = text
        XCTAssertEqual(tokenVC.text, text, "Text should be as set")
    }

    func testSetGetFont() {
        let tokenVC = TokenTextViewController()
        let font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        tokenVC.font = font
        XCTAssertEqual(tokenVC.font, font, "Font should be as set")
    }

    func testSetGetTextColor() {
        let tokenVC = TokenTextViewController()
        let color = UIColor.purple
        tokenVC.textColor = color
        XCTAssertEqual(tokenVC.textColor, color, "Color should be as set")
    }

    func testSetGetTextAlignment() {
        let tokenVC = TokenTextViewController()
        let alignment = NSTextAlignment.left
        tokenVC.textAlignment = alignment
        XCTAssertEqual(tokenVC.textAlignment, alignment, "Alignment should be as set")
    }

    func testSetGetSelectedRange() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "This is not a text."
        let range = NSRange(location: 2, length: 3)
        tokenVC.selectedRange = range
        XCTAssertEqual(tokenVC.selectedRange.location, range.location, "Selected range should be as set")
        XCTAssertEqual(tokenVC.selectedRange.length, range.length, "Selected range should be as set")
    }

    func testSetGetKeyboardType() {
        let tokenVC = TokenTextViewController()
        tokenVC.keyboardType = UIKeyboardType.twitter
        XCTAssertEqual(tokenVC.keyboardType, UIKeyboardType.twitter, "Keyboard type should be as set")
    }

    func testSetGetTextContainerInset() {
        let tokenVC = TokenTextViewController()
        let inset = UIEdgeInsets(top: 2, left: 3, bottom: 4, right: 5)
        tokenVC.textContainerInset = inset
        XCTAssertEqual(tokenVC.textContainerInset.top, inset.top, "Insets should be as set")
        XCTAssertEqual(tokenVC.textContainerInset.left, inset.left, "Insets should be as set")
        XCTAssertEqual(tokenVC.textContainerInset.right, inset.right, "Insets should be as set")
        XCTAssertEqual(tokenVC.textContainerInset.bottom, inset.bottom, "Insets should be as set")
    }

    func testSetGetLineFragmentPadding() {
        let tokenVC = TokenTextViewController()
        let padding = 5.0 as CGFloat
        tokenVC.lineFragmentPadding = padding
        XCTAssertEqual(tokenVC.lineFragmentPadding, padding, "Padding should be as set")
    }

    func testSetGetAccessibilityLabel() {
        let tokenVC = TokenTextViewController()
        let label = "Token view"
        tokenVC.accessibilityLabel = label
        XCTAssertEqual(tokenVC.accessibilityLabel, label, "Accessibility label should be as set")
    }

    func testPrependTextToMessage() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "test text"
        let prependText = "Prepend"
        tokenVC.prependText(prependText)
        XCTAssertTrue(tokenVC.text.hasPrefix(prependText), "Prefix should be as set")
    }

    func testReplaceStringInText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Replace this text here"
        tokenVC.replaceFirstOccurrenceOfString("here", withString: "there")
        XCTAssertEqual(tokenVC.text, "Replace this text there", "Replaced text should be as requested")
    }

    func testReplaceStringInTextStringNotFound() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Replace this text here"
        tokenVC.replaceFirstOccurrenceOfString("not here", withString: "there")
        XCTAssertEqual(tokenVC.text, "Replace this text here", "Text should not change when original string not found")
    }

    func testReplaceStringInTextMultipleStringsFound() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Replace this text here and here"
        tokenVC.replaceFirstOccurrenceOfString("here", withString: "there")
        XCTAssertEqual(tokenVC.text, "Replace this text there and here", "Only one string should be replaced")
    }

    func testReplaceStringInTextEmptyString() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Replace this text here and here"
        tokenVC.replaceFirstOccurrenceOfString("", withString: "there")
        XCTAssertEqual(tokenVC.text, "Replace this text here and here", "Text should not change when replaced string is empty")
    }

    func testReplaceStringInTextEmptyText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = ""
        tokenVC.replaceFirstOccurrenceOfString("here", withString: "there")
        XCTAssertEqual(tokenVC.text, "", "Text should not change when message is empty")
    }

    func testCursorLocationForPrependTextToMessage() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "test text"
        let range = NSRange(location: 1, length: 0)
        tokenVC.selectedRange = range
        let prependText = "Prepend"
        tokenVC.prependText(prependText)
        XCTAssertEqual(tokenVC.selectedRange.location, range.location + (prependText as NSString).length, "Cursor should be set according to added text")
    }

    func testCursorLocationForReplaceStringInTextCursorAfterText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Replace this text here, really"
        tokenVC.selectedRange = NSRange(location: 24, length: 0) // Cursor before 'really'
        tokenVC.replaceFirstOccurrenceOfString("here", withString: "there")
        XCTAssertEqual(tokenVC.selectedRange.location, 25, "Cursor should be set according to added text")
    }

    func testCursorLocationForReplaceStringInTextCursorBeforeText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Replace this text here, really"
        tokenVC.selectedRange = NSRange(location: 8, length: 0) // Cursor before 'this'
        tokenVC.replaceFirstOccurrenceOfString("here", withString: "there")
        XCTAssertEqual(tokenVC.selectedRange.location, 8, "Cursor should be set according to added text")
    }

    func testCanAddToken() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "I talk to, hello"
        _ = tokenVC.addToken(9, text: "davidby")
        let tokenList = tokenVC.tokenList
        XCTAssertEqual(tokenList.count, 1, "Token should be added")
        XCTAssertEqual(tokenList[0].text, " davidby ", "Token should be added with right text")
    }

    func testAddedTokenHasRightReference() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "I talk to, hello"
        let tokenRef = tokenVC.addToken(9, text: "davidby").reference
        let tokenList = tokenVC.tokenList
        XCTAssertEqual(tokenList[0].reference, tokenRef, "Token should be added with right text")
    }

    func testAddedTokenAtRequestedLocation() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "I talk to, hello"
        tokenVC.addToken(9, text: "davidby")
        let tokenList = tokenVC.tokenList
        XCTAssertEqual(tokenList[0].range.location, 9, "Token should be added where requested")
    }

    func testCanModifyToken() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "I talk to, hello"
        let tokenRef = tokenVC.addToken(9, text: "davidby").reference
        tokenVC.updateTokenText(tokenRef, newText: "db")
        let tokenList = tokenVC.tokenList
        XCTAssertEqual(tokenList[0].text, " db ", "Token should be updated with right text")
    }

    func testIntersectToken() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "I talk to, hello"
        _ = tokenVC.addToken(9, text: "davidby").reference
        XCTAssertTrue(tokenVC.rangeIntersectsToken(NSRange(location: 5, length: 5)), "Range does intersect token")
        XCTAssertFalse(tokenVC.rangeIntersectsToken(NSRange(location: 0, length: 5)), "Range does not intersect token")
    }

    func testReplaceDoubleQuotes() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Hello \"friend\" how are you"
        XCTAssertEqual(tokenVC.text, "Hello “friend” how are you", "Dumb quotes should have been replaced by smart quotes")
    }

    func testReplaceSingleQuotes() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Hello 'friend' how are you"
        XCTAssertEqual(tokenVC.text, "Hello ‘friend’ how are you", "Dumb quotes should have been replaced by smart quotes")
    }

    func testTokenizeAllEditableTextEmpty() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = ""
        tokenVC.tokenizeAllEditableText()
        XCTAssertTrue(tokenVC.tokenList.isEmpty, "Tokenize all editable text should handle empty text field")
    }

    func testTokenizeAllEditableTextWithText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "This is awesome"
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList[0].text, " This is awesome ", "Tokenize all editable text should handle text")
    }

    func testTokenizeAllEditableTextWithTextToken() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "This"
        tokenVC.addToken(4, text: "is awesome")
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 2)
        XCTAssertEqual(tokenVC.tokenList[0].text, " This ")
        XCTAssertEqual(tokenVC.tokenList[1].text, " is awesome ", "Tokenize all editable text should handle text-token")
    }

    func testTokenizeAllEditableTextWithTextTokenText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "This"
        tokenVC.addToken(4, text: "is")
        tokenVC.appendText("awesome")
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 3)
        XCTAssertEqual(tokenVC.tokenList[0].text, " This ")
        XCTAssertEqual(tokenVC.tokenList[1].text, " is ")
        XCTAssertEqual(tokenVC.tokenList[2].text, " awesome ", "Tokenize all editable text should handle text-token-text")
    }

    func testTokenizeAllEditableTextWithTextTokenToken() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "This"
        tokenVC.addToken(4, text: "is")
        tokenVC.addToken(8, text: "awesome")
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 3)
        XCTAssertEqual(tokenVC.tokenList[0].text, " This ")
        XCTAssertEqual(tokenVC.tokenList[1].text, " is ")
        XCTAssertEqual(tokenVC.tokenList[2].text, " awesome ", "Tokenize all editable text should handle text-token-token")
    }

    func testTokenizeAllEditableTextWithToken() {
        let tokenVC = TokenTextViewController()
        tokenVC.addToken(0, text: "This is awesome")
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 1)
        XCTAssertEqual(tokenVC.tokenList[0].text, " This is awesome ", "Tokenize all editable text should handle token")
    }

    func testTokenizeAllEditableTextWithTokenText() {
        let tokenVC = TokenTextViewController()
        tokenVC.addToken(0, text: "This")
        tokenVC.appendText("is awesome")
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 2)
        XCTAssertEqual(tokenVC.tokenList[0].text, " This ", "Tokenize all editable text should handle token-text first token")
        XCTAssertEqual(tokenVC.tokenList[1].text, " is awesome ", "Tokenize all editable text should handle token-text second token")
    }

    func testTokenizeAllEditableTextWithTokenTextToken() {
        let tokenVC = TokenTextViewController()
        tokenVC.addToken(0, text: "This")
        tokenVC.appendText("is")
        tokenVC.addToken(8, text: "awesome")
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 3)
        XCTAssertEqual(tokenVC.tokenList[0].text, " This ", "Tokenize all editable text should handle token-text-token first token")
        XCTAssertEqual(tokenVC.tokenList[1].text, " is ", "Tokenize all editable text should handle token-text-token second token")
        XCTAssertEqual(tokenVC.tokenList[2].text, " awesome ", "Tokenize all editable text should handle token-text-token third token")
    }

    func testTokenizeAllEditableTextWith50Tokens() {
        let tokenQuantity = 25
        let tokenVC = TokenTextViewController()
        for _ in 0..<tokenQuantity {
            tokenVC.insertString("plus some more", atIndex: 0)
            tokenVC.addToken(0, text: "some text")
        }
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 2 * tokenQuantity, "Tokenize all editable text should handle 50 tokens")
    }

    func testTokenizeAllEditableTextWithEmojiText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "😀"
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 1, "Tokenize all editable text should handle emoji text, token count")
        XCTAssertEqual(tokenVC.text, " 😀 ", "Tokenize all editable text should handle emoji text, text")
        XCTAssertEqual(tokenVC.tokenList[0].text, " 😀 ", "Tokenize all editable text should handle emoji text, token text")
    }

    func testTokenizeAllEditableTextWithModEmojiText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "👍🏾"
        tokenVC.tokenizeAllEditableText()
        XCTAssertEqual(tokenVC.tokenList.count, 1, "Tokenize all editable text should handle modified emoji text, token count")
        XCTAssertEqual(tokenVC.text, " 👍🏾 ", "Tokenize all editable text should handle modified emoji text, text")
        XCTAssertEqual(tokenVC.tokenList[0].text, " 👍🏾 ", "Tokenize all editable text should handle modified emoji text, token text")
    }

    func testMakeTokenEditableAndMoveToFrontToken() {
        let tokenVC = TokenTextViewController()
        let addedToken = tokenVC.addToken(0, text: "How are you?")
        tokenVC.makeTokenEditableAndMoveToFront(tokenReference: addedToken.reference)
        XCTAssertEqual(tokenVC.tokenList.count, 0, "Make token editable with one token, token list count")
        XCTAssertEqual(tokenVC.text, "How are you?", "Make token editable with one token, text")
    }

    func testMakeTokenEditableAndMoveToFrontTokenText() {
        let tokenVC = TokenTextViewController()
        let addedToken = tokenVC.addToken(0, text: "Blue")
        tokenVC.appendText("Red")
        tokenVC.makeTokenEditableAndMoveToFront(tokenReference: addedToken.reference)
        XCTAssertEqual(tokenVC.tokenList.count, 1, "Make token editable with token-text, token list count")
        XCTAssertNotEqual(tokenVC.tokenList[0].reference, addedToken.reference, "Make token editable with token-text, first token")
        XCTAssertEqual(tokenVC.tokenList[0].text, " Red ", "Make token editable with token-text, first token text")
        XCTAssertTrue(tokenVC.text.hasSuffix("Blue"), "Make token editable with token-text, text")
    }

    func testMakeTokenEditableAndMoveToFrontTokenTokenText() {
        let tokenVC = TokenTextViewController()
        let firstToken = tokenVC.addToken(0, text: "Blue")
        let secondToken = tokenVC.addToken(6, text: "Red")
        tokenVC.appendText("Green")
        tokenVC.makeTokenEditableAndMoveToFront(tokenReference: secondToken.reference)
        XCTAssertEqual(tokenVC.tokenList.count, 2, "Make token editable with token-token-text, token list count")
        XCTAssertEqual(tokenVC.tokenList[0].reference, firstToken.reference, "Make token editable with token-token-text, first token")
        XCTAssertNotEqual(tokenVC.tokenList[1].reference, secondToken.reference, "Make token editable with token-token-text, second token")
        XCTAssertEqual(tokenVC.tokenList[1].text, " Green ", "Make token editable with token-token-text, second token text")
        XCTAssertTrue(tokenVC.text.hasSuffix("Red"), "Make token editable with token-token-text, text")
    }

    func testMakeTokenEditableAndMoveToFrontTokenTextToken() {
        let tokenVC = TokenTextViewController()
        let firstToken = tokenVC.addToken(0, text: "Blue")
        tokenVC.appendText("Green")
        let secondToken = tokenVC.addToken(11, text: "Red")
        tokenVC.makeTokenEditableAndMoveToFront(tokenReference: firstToken.reference)
        XCTAssertEqual(tokenVC.tokenList.count, 2, "Make token editable with token-text-token, token list count")
        XCTAssertEqual(tokenVC.tokenList[1].reference, secondToken.reference, "Make token editable with token-text-token, second token")
        XCTAssertNotEqual(tokenVC.tokenList[0].reference, firstToken.reference, "Make token editable with token-text-token, first token")
        XCTAssertEqual(tokenVC.tokenList[0].text, " Green ", "Make token editable with token-text-token, first token text")
        XCTAssertTrue(tokenVC.text.hasSuffix("Blue"), "Make token editable with token-text-token, text")
    }

    func testMakeTokenEditableAndMoveToFrontTextTokenText() {
        let tokenVC = TokenTextViewController()
        tokenVC.text = "Blue"
        let firstToken = tokenVC.addToken(4, text: "Red")
        tokenVC.appendText("Green")
        tokenVC.makeTokenEditableAndMoveToFront(tokenReference: firstToken.reference)
        XCTAssertEqual(tokenVC.tokenList.count, 2, "Make token editable with text-token-text, token list count")
        XCTAssertEqual(tokenVC.tokenList[0].text, " Blue ", "Make token editable with text-token-text, first token")
        XCTAssertEqual(tokenVC.tokenList[1].text, " Green ", "Make token editable with text-token-text, second token")
        XCTAssertTrue(tokenVC.text.hasSuffix("Red"), "Make token editable with text-token-text, text")
    }

    func testMakeTokenEditableAndMoveToFrontWithEmojiText() {
        let tokenVC = TokenTextViewController()
        let emoji = "😀"
        let firstToken = tokenVC.addToken(0, text: emoji)
        tokenVC.makeTokenEditableAndMoveToFront(tokenReference: firstToken.reference)
        XCTAssertEqual(tokenVC.tokenList.count, 0, "Make token editable with emoji, token list count")
        XCTAssertEqual(tokenVC.text, emoji, "Make token editable with emoji, text")
    }

    func testMakeTokenEditableAndMoveToFrontWithModEmojiText() {
        let tokenVC = TokenTextViewController()
        let emoji = "👍🏾"
        let firstToken = tokenVC.addToken(0, text: emoji)
        tokenVC.makeTokenEditableAndMoveToFront(tokenReference: firstToken.reference)
        XCTAssertEqual(tokenVC.tokenList.count, 0, "Make token editable with modified emoji, token list count")
        XCTAssertEqual(tokenVC.text, emoji, "Make token editable with modified emoji, text")
    }
}
