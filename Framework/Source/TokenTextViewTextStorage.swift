//
// Created by David Bonnefoy on 15-07-16.
// Copyright (c) 2015 Hootsuite Media Inc. All rights reserved.
//

import Foundation
import UIKit
import HootUIKit

protocol TokenTextViewTextStorageDelegate: class {
    func textStorageIsUpdatingFormatting(sender: TokenTextViewTextStorage, text: String, searchRange: NSRange) -> [(attributes: [String:AnyObject], forRange: NSRange)]?
    func textStorageBackgroundColourForTokenRef(sender: TokenTextViewTextStorage, tokenRef: TokenReference) -> UIColor?
}

class TokenTextViewTextStorage: NSTextStorage {

    // FIXME: These constants should be replaced by calls to HootUIKit when available
    private struct Constants {
        static let PrimaryLinkColor = UIColor(red: 0.0, green: 174.0/255.0, blue: 239.0/255.0, alpha: 1.0)
        static let PrimaryTextColor = UIColor(white: 36.0/255.0, alpha: 1.0)
    }

    private let backingStore = NSMutableAttributedString()
    private var dynamicTextNeedsUpdate = false

    weak var formattingDelegate: TokenTextViewTextStorageDelegate?

    // MARK: Reading Text

    override var string: String {
        return backingStore.string
    }

    override func attributesAtIndex(index: Int, effectiveRange range: NSRangePointer) -> [String:AnyObject] {
        return backingStore.attributesAtIndex(index, effectiveRange: range)
    }

    // MARK: Text Editing

    override func replaceCharactersInRange(range: NSRange, withString str: String) {
        beginEditing()
        backingStore.replaceCharactersInRange(range, withString: str)
        edited([.EditedCharacters, .EditedAttributes], range: range, changeInLength: (str as NSString).length - range.length)
        dynamicTextNeedsUpdate = true
        endEditing()
    }

    override func setAttributes(attrs: [String:AnyObject]!, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func processEditing() {

        fixDumQuotes()

        if (dynamicTextNeedsUpdate) {
            dynamicTextNeedsUpdate = false
            performReplacementsForCharacterChangeInRange(editedRange)
        }

        super.processEditing()
    }

    private func performReplacementsForCharacterChangeInRange(changedRange: NSRange) {
        let lineRange = (backingStore.string as NSString).lineRangeForRange(NSMakeRange(NSMaxRange(changedRange), 0))
        let extendedRange = NSUnionRange(changedRange, lineRange)
        applyFormattingAttributesToRange(extendedRange)
    }

    func updateFormatting() {
        // Dummy edit to trigger updating all attributes
        self.beginEditing()
        self.edited(.EditedAttributes, range: NSRange(location: 0, length: 0), changeInLength: 0)
        self.dynamicTextNeedsUpdate = true
        self.endEditing()
    }

    private func applyFormattingAttributesToRange(searchRange: NSRange) {

        // Set default attributes of edited range
        addAttribute(NSForegroundColorAttributeName, value: Constants.PrimaryTextColor, range: searchRange)
        addAttribute(NSFontAttributeName, value: TextStyle.Messageline.font, range: searchRange)
        addAttribute(NSKernAttributeName, value: 0.0, range: searchRange)

        if let (_, range) = inputTextAndRange() {
            addAttribute(NSForegroundColorAttributeName, value:Constants.PrimaryLinkColor, range: range)
        }
        if let (_, range) = anchorTextAndRange() {
            addAttribute(NSForegroundColorAttributeName, value:Constants.PrimaryLinkColor, range: range)
        }

        enumerateTokens(inRange: searchRange) { (tokenRef, tokenRange) -> ObjCBool in
            var tokenFormattingAttributes = [String:AnyObject]()
            if let backgroundColor = self.formattingDelegate?.textStorageBackgroundColourForTokenRef(self, tokenRef: tokenRef) {
                tokenFormattingAttributes[NSForegroundColorAttributeName] = UIColor.whiteColor()
                tokenFormattingAttributes[NSBackgroundColorAttributeName] = backgroundColor
            }
            let formattingRange = self.displayRangeFromTokenRange(tokenRange)
            self.addAttributes(tokenFormattingAttributes, range: formattingRange)

            // Add kerning to the leading and trailing space to prevent overlap
            self.addAttributes([NSKernAttributeName:3.0], range: NSRange(location: tokenRange.location, length: 1))
            self.addAttributes([NSKernAttributeName:3.0], range: NSRange(location: tokenRange.location + tokenRange.length - 1, length: 1))
            return false
        }

        if let additionalFormats = formattingDelegate?.textStorageIsUpdatingFormatting(self, text: backingStore.string, searchRange: searchRange) where !additionalFormats.isEmpty {
            for (formatDict, range) in additionalFormats {
                if !rangeIntersectsToken(range) {
                    addAttributes(formatDict, range: range)
                }
            }
        }
    }

    // TODO: Currently a duplicate from HSTwitterTextColoringTextStorage
    // That class will be deleted when the Unified Mention feature is deployed
    private func fixDumQuotes() {
        let nsText = backingStore.string as NSString
        nsText.enumerateSubstringsInRange(NSMakeRange(0, nsText.length),
                options: NSStringEnumerationOptions.ByComposedCharacterSequences,
                usingBlock: {
                    (substring: String?, substringRange: NSRange, _, _) -> () in
                    if substring == "\"" {
                        if (substringRange.location == 0) {
                            self.backingStore.replaceCharactersInRange(substringRange, withString: "“")
                        } else {
                            let previousCharacter = nsText.substringWithRange(NSMakeRange(substringRange.location - 1, 1))
                            if previousCharacter == " " || previousCharacter == "\n" {
                                self.backingStore.replaceCharactersInRange(substringRange, withString: "“")
                            } else {
                                self.backingStore.replaceCharactersInRange(substringRange, withString: "”")
                            }
                        }
                    } else if substring == "'" {
                        if (substringRange.location == 0) {
                            self.backingStore.replaceCharactersInRange(substringRange, withString: "‘")
                        } else {
                            let previousCharacter = nsText.substringWithRange(NSMakeRange(substringRange.location - 1, 1))
                            if previousCharacter == " " || previousCharacter == "\n" {
                                self.backingStore.replaceCharactersInRange(substringRange, withString: "‘")
                            } else {
                                self.backingStore.replaceCharactersInRange(substringRange, withString: "’")
                            }
                        }
                    }
                })
    }

    // MARK: Token utilities

    var tokenList: [TokenInformation] {
        var tokenArray: [TokenInformation] = []
        enumerateTokens { (tokenRef, tokenRange) -> ObjCBool in
            let tokenText = self.attributedSubstringFromRange(tokenRange).string
            let tokenInfo = TokenInformation(reference: tokenRef, text: tokenText, range: tokenRange)
            tokenArray.append(tokenInfo)
            return false
        }
        return tokenArray
    }

    func enumerateTokens(inRange range: NSRange? = nil, withAction action:(tokenRef: TokenReference, tokenRange: NSRange) -> ObjCBool) {
        let searchRange = range ?? NSMakeRange(0, length)
        enumerateAttribute(TokenTextViewControllerConstants.tokenAttributeName,
            inRange:searchRange,
            options:NSAttributedStringEnumerationOptions(rawValue: 0),
            usingBlock: {
                (value: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                if let tokenRef = value as? TokenReference {
                    let shouldStop = action(tokenRef: tokenRef, tokenRange: range)
                    stop.memory = shouldStop
                }
        })
    }

    func tokensIntersectingRange(range: NSRange) -> [TokenReference] {
        return tokenList.filter {
            NSIntersectionRange(range, $0.range).length > 0
        }.map {
            $0.reference
        }
    }

    func rangeIntersectsToken(range: NSRange) -> Bool {
        for tokenInfo in tokenList {
            if NSIntersectionRange(range, tokenInfo.range).length > 0 {
                return true
            }
        }
        return false
    }

    func rangeIntersectsTokenInput(range: NSRange) -> Bool {
        if let (_, anchorRange) = anchorTextAndRange() where NSIntersectionRange(range, anchorRange).length > 0 {
            return true
        }
        if let (_, inputRange) = inputTextAndRange() where NSIntersectionRange(range, inputRange).length > 0 {
            return true
        }
        return false
    }

    func isValidEditingRange(range: NSRange) -> Bool {
        // We don't allow editing parts of tokens (ranges that partially overlap a token or are contained within a token)
        if range.length == 0 {
            return true
        }
        let editingRangeStart = range.location
        let editingRangeEnd = range.location + range.length - 1
        for tokenInfo in tokenList {
            let tokenRangeStart = tokenInfo.range.location
            let tokenRangeEnd = tokenInfo.range.location + tokenInfo.range.length - 1
            if editingRangeStart > tokenRangeStart && editingRangeStart <  tokenRangeEnd ||
                editingRangeEnd > tokenRangeStart && editingRangeEnd <  tokenRangeEnd {
                    return false
            }
        }
        return true
    }

    func effectiveTokenDisplayText(originalText: String) -> String {
        return " \(originalText) "
    }

    private func displayRangeFromTokenRange(tokenRange: NSRange) -> NSRange {
        return NSMakeRange(tokenRange.location + 1, tokenRange.length - 2)
    }

    // MARK: Input mode

    func anchorTextAndRange() -> (String, NSRange)? {
        return attributeTextAndRange(TokenTextViewControllerConstants.inputTextAttributeName, attributeValue: TokenTextViewControllerConstants.inputTextAttributeAnchorValue)
    }

    func inputTextAndRange() -> (String, NSRange)? {
        return attributeTextAndRange(TokenTextViewControllerConstants.inputTextAttributeName, attributeValue: TokenTextViewControllerConstants.inputTextAttributeTextValue)
    }

    private func attributeTextAndRange(attributeName: String, attributeValue: String) -> (String, NSRange)? {
        var result: (String, NSRange)? = nil
        enumerateAttribute(attributeName,
            inRange:NSMakeRange(0, length),
            options:NSAttributedStringEnumerationOptions(rawValue: 0),
            usingBlock: {
                (value: AnyObject?, range: NSRange, stop) in
                if let value = value as? String where value == attributeValue {
                    result = (self.attributedSubstringFromRange(range).string, range)
                    stop.memory = true
                }
        })
        return result
    }

    func clearEditingAttributes() {
        removeAttribute(TokenTextViewControllerConstants.inputTextAttributeName, range: NSMakeRange(0, length))
        updateFormatting()
    }

}
