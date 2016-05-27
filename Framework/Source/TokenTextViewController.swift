//
// Created by David Bonnefoy on 15-07-16.
// Copyright (c) 2015 Hootsuite Media Inc. All rights reserved.
//

import Foundation
import UIKit
import HootUIKit

public protocol TokenTextViewControllerDelegate: class {
    func tokenTextViewDidChange(sender: TokenTextViewController) -> ()
    func tokenTextViewShouldChangeTextInRange(sender: TokenTextViewController, range: NSRange, replacementText text: String) -> Bool
    func tokenTextViewDidSelectToken(sender: TokenTextViewController, tokenRef: TokenReference, fromRect rect: CGRect) -> ()
    func tokenTextViewDidDeleteToken(sender: TokenTextViewController, tokenRef: TokenReference) -> ()
    func tokenTextViewTextStorageIsUpdatingFormatting(sender: TokenTextViewController, text: String, searchRange: NSRange) -> [(attributes: [String:AnyObject], forRange: NSRange)]
    func tokenTextViewBackgroundColourForTokenRef(sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor?
    func tokenTextViewShouldCancelEditingAtInsert(sender: TokenTextViewController, newText: String, inputText: String) -> Bool
}

public protocol TokenTextViewControllerInputDelegate: class {
    func tokenTextViewInputTextDidChange(sender: TokenTextViewController, inputText: String)
    func tokenTextViewInputTextWasConfirmed(sender: TokenTextViewController)
    func tokenTextViewInputTextWasCanceled(sender: TokenTextViewController, reason: CancellationReason)
}

public enum CancellationReason {
    case DeleteInput
    case TapOut
    case Other
}

public struct TokenTextViewControllerConstants {
    public static let tokenAttributeName = "com.hootsuite.token"
    static let inputTextAttributeName = "com.hootsuite.input"
    static let inputTextAttributeAnchorValue = "anchor"
    static let inputTextAttributeTextValue = "text"
}

public typealias TokenReference = String

public struct TokenInformation {
    public var reference: TokenReference
    public var text: String
    public var range: NSRange
}

public class TokenTextViewController: UIViewController, UITextViewDelegate, NSLayoutManagerDelegate, TokenTextViewTextStorageDelegate, UIGestureRecognizerDelegate {

    public weak var delegate: TokenTextViewControllerDelegate?
    public weak var inputDelegate: TokenTextViewControllerInputDelegate? {
        didSet {
            if let (inputText, _) = tokenTextStorage.inputTextAndRange() {
                inputDelegate?.tokenTextViewInputTextDidChange(self, inputText: inputText)
            }
        }
    }

    private var currentFont = TextStyle.Messageline.font
    private var tokenTapRecognizer: UITapGestureRecognizer?
    private var inputModeHandler: TokenTextViewControllerInputModeHandler!
    private var textTappedHandler: ((UITapGestureRecognizer) -> Void)?
    private var inputIsSuspended = false

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init() {
        super.init(nibName: nil, bundle: nil)
        inputModeHandler = TokenTextViewControllerInputModeHandler(tokenTextViewController: self)
        textTappedHandler = normalModeTapHandler
    }

    override public func loadView() {
        let textStorage = TokenTextViewTextStorage()
        textStorage.formattingDelegate = self
        let layoutManager = TokenTextViewLayoutManager()
        layoutManager.delegate = self
        let container = NSTextContainer(size: CGSize.zero)
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)
        let textView = UITextView(frame: CGRect.zero, textContainer: container)
        textView.delegate = self
        textView.scrollEnabled = true
        tokenTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(TokenTextViewController.textTapped(_:)))
        tokenTapRecognizer!.numberOfTapsRequired = 1
        tokenTapRecognizer!.delegate = self
        textView.addGestureRecognizer(tokenTapRecognizer!)
        self.view = textView
    }

    private var viewAsTextView: UITextView! {
        return view as! UITextView
    }

    private var tokenTextStorage: TokenTextViewTextStorage {
        return viewAsTextView.textStorage as! TokenTextViewTextStorage
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewAsTextView.font = currentFont
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(TokenTextViewController.preferredContentSizeChanged(_:)),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)
    }

    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    func preferredContentSizeChanged(notification: NSNotification) {
        tokenTextStorage.updateFormatting()
    }

    func textTapped(recognizer: UITapGestureRecognizer) {
        textTappedHandler?(recognizer)
    }

    // MARK: UIGestureRecognizerDelegate

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tokenTapRecognizer {
            return true
        }
        return false
    }

    // MARK: UITextView vars and funcs

    public var text: String! {
        get {
            return viewAsTextView.text
        }

        set {
            viewAsTextView.text = newValue
        }
    }

    public var font: UIFont! {
        get {
            return viewAsTextView.font
        }

        set {
            viewAsTextView.font = newValue
            currentFont = newValue
        }
    }

    public var textColor: UIColor! {
        get {
            return viewAsTextView.textColor
        }

        set {
            viewAsTextView.textColor = newValue
        }
    }

    public var textAlignment: NSTextAlignment {
        get {
            return viewAsTextView.textAlignment
        }

        set {
            viewAsTextView.textAlignment = newValue
        }
    }

    public var selectedRange: NSRange {
        get {
            return viewAsTextView.selectedRange
        }

        set {
            viewAsTextView.selectedRange = newValue
        }
    }

    public var keyboardType: UIKeyboardType {
        get {
            return viewAsTextView.keyboardType
        }

        set {
            viewAsTextView.keyboardType = newValue
        }
    }

    public var textContainerInset: UIEdgeInsets {
        get {
            return viewAsTextView.textContainerInset
        }

        set {
            viewAsTextView.textContainerInset = newValue
        }
    }

    public var lineFragmentPadding: CGFloat {
        get {
            return viewAsTextView.textContainer.lineFragmentPadding
        }

        set {
            viewAsTextView.textContainer.lineFragmentPadding = newValue
        }
    }

    override public var accessibilityLabel: String! {
        get {
            return viewAsTextView.accessibilityLabel
        }

        set {
            viewAsTextView.accessibilityLabel = newValue
        }
    }

    override public func becomeFirstResponder() -> Bool {
        return viewAsTextView.becomeFirstResponder()
    }

    override public func resignFirstResponder() -> Bool {
        return viewAsTextView.resignFirstResponder()
    }

    public func suspendInput() {
        resignFirstResponder()
        inputIsSuspended = true
    }

    public var attributedString: NSAttributedString {
        return viewAsTextView.textStorage
    }

    // MARK: text manipulation

    public func appendText(text: String) {
        viewAsTextView.textStorage.appendAttributedString(NSAttributedString(string: text))
        repositionCursorAtEndOfRange()
    }

    public func prependText(text: String) {
        let cursorLocation = viewAsTextView.selectedRange.location
        viewAsTextView.textStorage.insertAttributedString(NSAttributedString(string: text), atIndex: 0)
        viewAsTextView.selectedRange = NSMakeRange(cursorLocation + (text as NSString).length, 0)
        repositionCursorAtEndOfRange()
    }

    public func replaceFirstOccurrenceOfString(string: String, withString replacement: String) {
        let cursorLocation = viewAsTextView.selectedRange.location
        let searchRange = viewAsTextView.textStorage.mutableString.rangeOfString(string)
        if searchRange.length > 0 {
            viewAsTextView.textStorage.mutableString.replaceCharactersInRange(searchRange, withString: replacement)
            if cursorLocation > searchRange.location {
                viewAsTextView.selectedRange = NSMakeRange(min(cursorLocation + (replacement as NSString).length - (string as NSString).length, (text as NSString).length), 0)
                repositionCursorAtEndOfRange()
            }
        }
    }

    public func replaceCharactersInRange(range: NSRange, withString: String) {
        if !rangeIntersectsToken(range) {
            viewAsTextView.textStorage.replaceCharactersInRange(range, withString: withString)
        }
    }

    public func insertString(string: String, atIndex index: Int) {
        viewAsTextView.textStorage.insertAttributedString(NSAttributedString(string: string), atIndex: index)
    }

    // MARK: token editing

    public func addToken(startIndex: Int, text: String) -> TokenInformation {
        let effectiveText = effectiveTokenDisplayText(text)
        let attrs = createNewTokenAttributes()
        let attrString = NSAttributedString(string: effectiveText, attributes: attrs)
        viewAsTextView.textStorage.insertAttributedString(attrString, atIndex: startIndex)
        repositionCursorAtEndOfRange()
        let tokenRange = tokenAtLocation(startIndex)!.range
        let tokenRef = attrs[TokenTextViewControllerConstants.tokenAttributeName] as! TokenReference
        let tokenInfo = TokenInformation(reference: tokenRef, text: effectiveText, range: tokenRange)
        delegate?.tokenTextViewDidChange(self)
        return tokenInfo
    }

    public func updateTokenFormatting() {
        tokenTextStorage.updateFormatting()
    }

    private func createNewTokenAttributes() -> [String: AnyObject] {
        return [TokenTextViewControllerConstants.tokenAttributeName: NSUUID().UUIDString as TokenReference]
    }

    public func updateTokenText(tokenRef: TokenReference, newText: String) {
        let effectiveText = effectiveTokenDisplayText(newText)
        replaceTokenText(tokenRef, newText: effectiveText)
        repositionCursorAtEndOfRange()
        self.delegate?.tokenTextViewDidChange(self)
    }

    public func deleteToken(tokenRef: TokenReference) {
        replaceTokenText(tokenRef, newText: "")
        viewAsTextView.selectedRange = NSMakeRange(viewAsTextView.selectedRange.location, 0)
        self.delegate?.tokenTextViewDidChange(self)
        delegate?.tokenTextViewDidDeleteToken(self, tokenRef: tokenRef)
    }

    private func replaceTokenText(tokenToReplaceRef: TokenReference, newText: String) {
        tokenTextStorage.enumerateTokens { (tokenRef, tokenRange) -> ObjCBool in
            if tokenRef == tokenToReplaceRef {
                self.viewAsTextView.textStorage.replaceCharactersInRange(tokenRange, withString: newText)
                return true
            }
            return false
        }
    }

    private func repositionCursorAtEndOfRange() {
        let cursorLocation = viewAsTextView.selectedRange.location
        if let tokenInfo = tokenAtLocation(cursorLocation) {
            viewAsTextView.selectedRange = NSMakeRange(tokenInfo.range.location + tokenInfo.range.length, 0)
        }
    }

    public var tokenList: [TokenInformation] {
        return tokenTextStorage.tokenList
    }

    private func tokenAtLocation(location: Int) -> TokenInformation? {
        for tokenInfo in tokenList {
            if location >= tokenInfo.range.location && location < tokenInfo.range.location + tokenInfo.range.length {
                return tokenInfo
            }
        }
        return nil
    }

    public func rangeIntersectsToken(range: NSRange) -> Bool {
        return tokenTextStorage.rangeIntersectsToken(range)
    }

    public func rangeIntersectsTokenInput(range: NSRange) -> Bool {
        return tokenTextStorage.rangeIntersectsTokenInput(range)
    }

    private func cancelEditingAndKeepText() {
        tokenTextStorage.clearEditingAttributes()
        inputDelegate?.tokenTextViewInputTextWasCanceled(self, reason: .TapOut)
    }

    // MARK: Input Mode

    public func switchToInputEditingMode(location: Int, text: String, initialInputLength: Int = 0) {
        let attrString = NSAttributedString(string: text, attributes: [TokenTextViewControllerConstants.inputTextAttributeName : TokenTextViewControllerConstants.inputTextAttributeAnchorValue])
        tokenTextStorage.insertAttributedString(attrString, atIndex: location)
        if initialInputLength > 0 {
            let inputRange = NSRange(location: location + (text as NSString).length, length: initialInputLength)
            tokenTextStorage.addAttributes([TokenTextViewControllerConstants.inputTextAttributeName : TokenTextViewControllerConstants.inputTextAttributeTextValue], range: inputRange)
        }
        viewAsTextView.selectedRange = NSMakeRange(location + (text as NSString).length + initialInputLength, 0)
        viewAsTextView.autocorrectionType = .No
        viewAsTextView.delegate = inputModeHandler
        textTappedHandler = inputModeTapHandler
        delegate?.tokenTextViewDidChange(self)
        tokenTextStorage.updateFormatting()
    }

    public func switchToNormalEditingMode() -> Int {
        var location = selectedRange.location
        if let (_, anchorRange) = tokenTextStorage.anchorTextAndRange() {
            location = anchorRange.location
            replaceCharactersInRange(anchorRange, withString: "")
        }
        if let (_, inputRange) = tokenTextStorage.inputTextAndRange() {
            replaceCharactersInRange(inputRange, withString: "")
        }
        viewAsTextView.delegate = self
        textTappedHandler = normalModeTapHandler
        viewAsTextView.autocorrectionType = .Default
        return location
    }

    var normalModeTapHandler: ((UITapGestureRecognizer) -> Void) {
        return { [unowned self] (recognizer: UITapGestureRecognizer) in
            self.viewAsTextView.becomeFirstResponder()
            let location: CGPoint = recognizer.locationInView(self.viewAsTextView)
            var charIndex = self.viewAsTextView.characterIndexAtLocation(location)
            if charIndex < self.viewAsTextView.textStorage.length - 1 {
                var range = NSRange(location: 0, length: 0)
                if let tokenRef = self.viewAsTextView.attributedText?.attribute(TokenTextViewControllerConstants.tokenAttributeName, atIndex: charIndex!, effectiveRange: &range) as? TokenReference {
                    self.resignFirstResponder()
                    let rect: CGRect = {
                        if let textRange = self.viewAsTextView.textRangeFromNSRange(range) {
                            return self.view.convertRect(self.viewAsTextView.firstRectForRange(textRange), fromView: self.viewAsTextView.textInputView)
                        } else {
                            return CGRectMake(location.x, location.y, 0, 0)
                        }
                    }()
                    self.delegate?.tokenTextViewDidSelectToken(self, tokenRef: tokenRef, fromRect: rect)
                } else {
                    if charIndex == self.viewAsTextView.textStorage.length - 1 {
                        // Allow placing the cursor at the end of the text
                        charIndex = self.viewAsTextView.textStorage.length
                    }
                    self.viewAsTextView.selectedRange = NSMakeRange(charIndex!, 0)
                }
            }
        }
    }

    var inputModeTapHandler: ((UITapGestureRecognizer) -> Void) {
        return { [unowned self] (recognizer: UITapGestureRecognizer) in
            guard !self.inputIsSuspended else {
                self.inputIsSuspended = false
                return
            }
            let location: CGPoint = recognizer.locationInView(self.viewAsTextView)
            let charIndex = self.viewAsTextView.characterIndexAtLocation(location)
            if let (_, inputRange) = self.tokenTextStorage.inputTextAndRange(), (_, anchorRange) = self.tokenTextStorage.anchorTextAndRange()
                where charIndex < anchorRange.location || charIndex >= inputRange.location + inputRange.length - 1 {
                    self.cancelEditingAndKeepText()
            }
        }
    }

    // MARK: UITextViewDelegate

    public func textViewDidChange(textView: UITextView) {
        self.delegate?.tokenTextViewDidChange(self)
    }

    public func textViewDidChangeSelection(textView: UITextView) {
        if viewAsTextView.selectedRange.length == 0 {
            // The cursor is being repositioned
            let cursorLocation = textView.selectedRange.location
            let newCursorLocation = clampCursorLocationToToken(cursorLocation)
            if newCursorLocation != cursorLocation {
                viewAsTextView.selectedRange = NSMakeRange(newCursorLocation, 0)
            }
        } else {
            // A selection range is being modified
            let adjustedSelectionStart = clampCursorLocationToToken(textView.selectedRange.location)
            let adjustedSelectionLength = max(adjustedSelectionStart, clampCursorLocationToToken(textView.selectedRange.location + textView.selectedRange.length)) - adjustedSelectionStart
            if (adjustedSelectionStart != textView.selectedRange.location) || (adjustedSelectionLength != textView.selectedRange.length) {
                viewAsTextView.selectedRange = NSMakeRange(adjustedSelectionStart, adjustedSelectionLength)
            }
        }
    }

    private func clampCursorLocationToToken(cursorLocation: Int) -> Int {
        if let tokenInfo = tokenAtLocation(cursorLocation) {
            let range = tokenInfo.range
            return (cursorLocation > range.location + range.length / 2) ? (range.location + range.length) : range.location
        }
        return cursorLocation
    }

    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText: String) -> Bool {
        if (range.length == 1 && (replacementText as NSString).length == 0) {
            // Deleting one character, if it is part of a token the full token should be deleted
            if let tokenInfo = tokenAtLocation(range.location) {
                deleteToken(tokenInfo.reference)
                viewAsTextView.selectedRange = NSMakeRange(tokenInfo.range.location, 0)
                return false
            }
        } else if (range.length > 0) {
            // Check if partial overlap or editing range contained in a token, reject edit
            if !tokenTextStorage.isValidEditingRange(range) {
                return false
            }
            // If the editing range intersects tokens, make sure tokens are fully deleted and delegate called
            let intersectingTokenReferences = tokenTextStorage.tokensIntersectingRange(range)
            if !intersectingTokenReferences.isEmpty {
                replaceRangeAndIntersectingTokens(range, intersectingTokenReferences: intersectingTokenReferences, replacementText: replacementText)
                self.delegate?.tokenTextViewDidChange(self)
                return false
            }
        }
        return delegate?.tokenTextViewShouldChangeTextInRange(self, range: range, replacementText: replacementText) ?? true
    }

    private func replaceRangeAndIntersectingTokens(range: NSRange, intersectingTokenReferences: [TokenReference], replacementText: String) {
        viewAsTextView.textStorage.replaceCharactersInRange(range, withString: replacementText)
        tokenTextStorage.enumerateTokens { (tokenRef, tokenRange) -> ObjCBool in
            if intersectingTokenReferences.contains(tokenRef) {
                self.viewAsTextView.textStorage.replaceCharactersInRange(tokenRange, withString: "")
            }
            return false
        }
        viewAsTextView.selectedRange = NSMakeRange(viewAsTextView.selectedRange.location, 0)
        for tokenRef in intersectingTokenReferences {
            delegate?.tokenTextViewDidDeleteToken(self, tokenRef: tokenRef)
        }
    }


    // MARK: NSLayoutManagerDelegate

    public func layoutManager(layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAtIndex charIndex: Int) -> Bool {
        var effectiveRange = NSRange(location: 0, length: 0)
        if let _ = (view as! UITextView).attributedText?.attribute(TokenTextViewControllerConstants.tokenAttributeName, atIndex: charIndex, effectiveRange: &effectiveRange) as? TokenReference {
            return false
        }
        return true
    }

    // MARK: TokenTextViewTextStorageDelegate

    func textStorageIsUpdatingFormatting(sender: TokenTextViewTextStorage, text: String, searchRange: NSRange) -> [(attributes: [String:AnyObject], forRange: NSRange)]? {
        return delegate?.tokenTextViewTextStorageIsUpdatingFormatting(self, text: text, searchRange: searchRange)
    }

    func textStorageBackgroundColourForTokenRef(sender: TokenTextViewTextStorage, tokenRef: TokenReference) -> UIColor? {
        return delegate?.tokenTextViewBackgroundColourForTokenRef(self, tokenRef: tokenRef)
    }

    // MARK: Token text management

    private func effectiveTokenDisplayText(originalText: String) -> String {
        return tokenTextStorage.effectiveTokenDisplayText(originalText)
    }

}

class TokenTextViewControllerInputModeHandler: NSObject, UITextViewDelegate {

    private weak var tokenTextViewController: TokenTextViewController!

    init(tokenTextViewController: TokenTextViewController) {
        self.tokenTextViewController = tokenTextViewController
    }

    func textViewDidChangeSelection(textView: UITextView) {
        if let (_, inputRange) = tokenTextViewController.tokenTextStorage.inputTextAndRange() {
            let cursorLocation = textView.selectedRange.location + textView.selectedRange.length
            let adjustedLocation = clampCursorLocationToInputRange(cursorLocation, inputRange: inputRange)
            if adjustedLocation != cursorLocation || textView.selectedRange.length > 0 {
                tokenTextViewController.viewAsTextView.selectedRange = NSMakeRange(adjustedLocation, 0)
            }
        } else if let (_, anchorRange) = tokenTextViewController.tokenTextStorage.anchorTextAndRange() {
            let adjustedLocation = anchorRange.location + 1
            if textView.selectedRange.location != adjustedLocation {
                tokenTextViewController.viewAsTextView.selectedRange = NSMakeRange(adjustedLocation, 0)
            }
        } else {
            tokenTextViewController.resignFirstResponder()
        }
    }

    private func clampCursorLocationToInputRange(cursorLocation: Int, inputRange: NSRange) -> Int {
        if cursorLocation < inputRange.location {
            return inputRange.location
        }
        if cursorLocation > inputRange.location + inputRange.length {
            return inputRange.location + inputRange.length
        }
        return cursorLocation
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText newText: String) -> Bool {
        if range.length == 0 {
            handleInsertion(range, newText: newText)
        } else if range.length == 1 && newText.isEmpty {
            handleCharacterDeletion(range)
        }
        return false
    }

    private func handleInsertion(range: NSRange, newText: String) {
        if newText == "\n" {
            // Do not insert return, inform delegate
            tokenTextViewController.inputDelegate?.tokenTextViewInputTextWasConfirmed(tokenTextViewController)
            return
        }
        // Insert new text with token attribute
        let attrString = NSAttributedString(string: newText, attributes: [TokenTextViewControllerConstants.inputTextAttributeName : TokenTextViewControllerConstants.inputTextAttributeTextValue])
        tokenTextViewController.viewAsTextView.textStorage.insertAttributedString(attrString, atIndex: range.location)
        tokenTextViewController.viewAsTextView.selectedRange = NSMakeRange(range.location + (newText as NSString).length, 0)
        if let (inputText, _) = tokenTextViewController.tokenTextStorage.inputTextAndRange() {
            tokenTextViewController.inputDelegate?.tokenTextViewInputTextDidChange(tokenTextViewController, inputText: inputText)
            if let delegate = tokenTextViewController.delegate where delegate.tokenTextViewShouldCancelEditingAtInsert(tokenTextViewController, newText: newText, inputText: inputText) {
                tokenTextViewController.cancelEditingAndKeepText()
            }
        }
    }

    private func handleCharacterDeletion(range: NSRange) {
        if let (_, inputRange) = tokenTextViewController.tokenTextStorage.inputTextAndRange(), (_, anchorRange) = tokenTextViewController.tokenTextStorage.anchorTextAndRange() {
            if range.location >= anchorRange.location && range.location < anchorRange.location + anchorRange.length {
                // The anchor ("@") is deleted, input is cancelled
                tokenTextViewController.inputDelegate?.tokenTextViewInputTextWasCanceled(tokenTextViewController, reason: .DeleteInput)
            } else if range.location >= inputRange.location && range.location < inputRange.location + inputRange.length {
                // Do deletion
                tokenTextViewController.viewAsTextView.textStorage.replaceCharactersInRange(range, withString: "")
                tokenTextViewController.viewAsTextView.selectedRange = NSMakeRange(range.location, 0)
                if let (inputText, _) = tokenTextViewController.tokenTextStorage.inputTextAndRange() {
                    tokenTextViewController.inputDelegate?.tokenTextViewInputTextDidChange(tokenTextViewController, inputText: inputText)
                }
            }
        } else {
            // Input fully deleted, input is cancelled
            tokenTextViewController.inputDelegate?.tokenTextViewInputTextWasCanceled(tokenTextViewController, reason: .DeleteInput)
        }
    }
}

extension UITextView {
    func characterIndexAtLocation(location: CGPoint) -> Int? {
        var point = location
        point.x -= self.textContainerInset.left
        point.y -= self.textContainerInset.top
        return self.textContainer.layoutManager?.characterIndexForPoint(point, inTextContainer: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

extension UITextView {
    func textRangeFromNSRange(range: NSRange) -> UITextRange? {
        let beginning = self.beginningOfDocument
        if let start = self.positionFromPosition(beginning, offset: range.location),
            let end = self.positionFromPosition(start, offset: range.length),
            let textRange = self.textRangeFromPosition(start, toPosition: end) {
            return textRange
        } else {
            return nil
        }
    }
}
