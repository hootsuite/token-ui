//
// Created by David Bonnefoy on 15-07-16.
// Copyright (c) 2015 Hootsuite Media Inc. All rights reserved.
//

import Foundation
import UIKit

/// TokenTextViewController delegate
public protocol TokenTextViewControllerDelegate: class {
    /// Called when text changes
    func tokenTextViewDidChange(_ sender: TokenTextViewController) -> ()
    /// Whether an edit should be accepted
    func tokenTextViewShouldChangeTextInRange(_ sender: TokenTextViewController, range: NSRange, replacementText text: String) -> Bool
    /// Called when a token was tapped
    func tokenTextViewDidSelectToken(_ sender: TokenTextViewController, tokenRef: TokenReference, fromRect rect: CGRect) -> ()
    /// Called when a token was deleted
    func tokenTextViewDidDeleteToken(_ sender: TokenTextViewController, tokenRef: TokenReference) -> ()
    /// Called when the formatting is being updated
    func tokenTextViewTextStorageIsUpdatingFormatting(_ sender: TokenTextViewController, text: String, searchRange: NSRange) -> [(attributes: [String:AnyObject], forRange: NSRange)]
    /// Allows to customize the background color for a token
    func tokenTextViewBackgroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor?
    /// Whether the last edit should cancel token editing
    func tokenTextViewShouldCancelEditingAtInsert(_ sender: TokenTextViewController, newText: String, inputText: String) -> Bool
    /// Whether content of type type can be pasted in the text view.
    /// This method is called every time some content may be pasted.
    func tokenTextView(_: TokenTextViewController, shouldAcceptContentOfType type: PasteboardItemType) -> Bool
    /// Called when media items have been pasted.
    func tokenTextView(_: TokenTextViewController, didReceive items: [PasteboardItem])
}

/// Default implementation of some delegate methods
public extension TokenTextViewControllerDelegate {
    func tokenTextView(_: TokenTextViewController, shouldAcceptContentOfType type: PasteboardItemType) -> Bool {
        return false
    }

    func tokenTextView(_: TokenTextViewController, didReceive items: [PasteboardItem]) {
        // Empty default implementation
    }
}

public protocol TokenTextViewControllerInputDelegate: class {
    func tokenTextViewInputTextDidChange(_ sender: TokenTextViewController, inputText: String)
    func tokenTextViewInputTextWasConfirmed(_ sender: TokenTextViewController)
    func tokenTextViewInputTextWasCanceled(_ sender: TokenTextViewController, reason: TokenTextInputCancellationReason)
}

public enum TokenTextInputCancellationReason {
    case deleteInput
    case tapOut
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

open class TokenTextViewController: UIViewController, UITextViewDelegate, NSLayoutManagerDelegate, TokenTextViewTextStorageDelegate, UIGestureRecognizerDelegate {

    open weak var delegate: TokenTextViewControllerDelegate?
    open weak var inputDelegate: TokenTextViewControllerInputDelegate? {
        didSet {
            if let (inputText, _) = tokenTextStorage.inputTextAndRange() {
                inputDelegate?.tokenTextViewInputTextDidChange(self, inputText: inputText)
            }
        }
    }

    open var font = UIFont.preferredFont(forTextStyle: .body) {
        didSet {
            viewAsTextView.font = font
        }
    }

    fileprivate var tokenTapRecognizer: UITapGestureRecognizer?
    fileprivate var inputModeHandler: TokenTextViewControllerInputModeHandler!
    fileprivate var textTappedHandler: ((UITapGestureRecognizer) -> Void)?
    fileprivate var inputIsSuspended = false

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init() {
        super.init(nibName: nil, bundle: nil)
        inputModeHandler = TokenTextViewControllerInputModeHandler(tokenTextViewController: self)
        textTappedHandler = normalModeTapHandler
    }

    override open func loadView() {
        let textStorage = TokenTextViewTextStorage()
        textStorage.formattingDelegate = self
        let layoutManager = TokenTextViewLayoutManager()
        layoutManager.delegate = self
        let container = NSTextContainer(size: CGSize.zero)
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)
        let textView = PasteMediaTextView(frame: CGRect.zero, textContainer: container)
        textView.delegate = self
        textView.pasteDelegate = self
        textView.isScrollEnabled = true
        tokenTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(TokenTextViewController.textTapped(_:)))
        tokenTapRecognizer!.numberOfTapsRequired = 1
        tokenTapRecognizer!.delegate = self
        textView.addGestureRecognizer(tokenTapRecognizer!)
        self.view = textView
    }

    fileprivate var viewAsTextView: UITextView! {
        return view as! UITextView
    }

    fileprivate var tokenTextStorage: TokenTextViewTextStorage {
        return viewAsTextView.textStorage as! TokenTextViewTextStorage
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewAsTextView.font = font
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(TokenTextViewController.preferredContentSizeChanged(_:)),
            name: NSNotification.Name.UIContentSizeCategoryDidChange,
            object: nil)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }

    func preferredContentSizeChanged(_ notification: Notification) {
        tokenTextStorage.updateFormatting()
    }

    func textTapped(_ recognizer: UITapGestureRecognizer) {
        textTappedHandler?(recognizer)
    }

    // MARK: UIGestureRecognizerDelegate

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tokenTapRecognizer {
            return true
        }
        return false
    }

    // MARK: UITextView vars and funcs

    open var text: String! {
        get {
            return viewAsTextView.text
        }

        set {
            viewAsTextView.text = newValue
        }
    }

    open var textColor: UIColor! {
        get {
            return viewAsTextView.textColor
        }

        set {
            viewAsTextView.textColor = newValue
        }
    }

    open var textAlignment: NSTextAlignment {
        get {
            return viewAsTextView.textAlignment
        }

        set {
            viewAsTextView.textAlignment = newValue
        }
    }

    open var selectedRange: NSRange {
        get {
            return viewAsTextView.selectedRange
        }

        set {
            viewAsTextView.selectedRange = newValue
        }
    }

    open var keyboardType: UIKeyboardType {
        get {
            return viewAsTextView.keyboardType
        }

        set {
            viewAsTextView.keyboardType = newValue
        }
    }

    open var textContainerInset: UIEdgeInsets {
        get {
            return viewAsTextView.textContainerInset
        }

        set {
            viewAsTextView.textContainerInset = newValue
        }
    }

    open var scrollEnabled: Bool {
        get {
            return viewAsTextView.isScrollEnabled
        }

        set {
            viewAsTextView.isScrollEnabled = newValue
        }
    }

    open var lineFragmentPadding: CGFloat {
        get {
            return viewAsTextView.textContainer.lineFragmentPadding
        }

        set {
            viewAsTextView.textContainer.lineFragmentPadding = newValue
        }
    }

    public var cursorRect: CGRect? {
        if let selectedTextRange = viewAsTextView.selectedTextRange {
            return viewAsTextView.caretRect(for: selectedTextRange.start)
        }
        return nil
    }

    override open var accessibilityLabel: String! {
        get {
            return viewAsTextView.accessibilityLabel
        }

        set {
            viewAsTextView.accessibilityLabel = newValue
        }
    }

    override open func becomeFirstResponder() -> Bool {
        return viewAsTextView.becomeFirstResponder()
    }

    override open func resignFirstResponder() -> Bool {
        return viewAsTextView.resignFirstResponder()
    }

    open func suspendInput() {
        let _ = resignFirstResponder()
        inputIsSuspended = true
    }

    open var attributedString: NSAttributedString {
        return viewAsTextView.textStorage
    }

    // MARK: text manipulation

    open func appendText(_ text: String) {
        viewAsTextView.textStorage.append(NSAttributedString(string: text))
        repositionCursorAtEndOfRange()
    }

    open func prependText(_ text: String) {
        let cursorLocation = viewAsTextView.selectedRange.location
        viewAsTextView.textStorage.insert(NSAttributedString(string: text), at: 0)
        viewAsTextView.selectedRange = NSRange(location: cursorLocation + (text as NSString).length, length: 0)
        repositionCursorAtEndOfRange()
    }

    open func replaceFirstOccurrenceOfString(_ string: String, withString replacement: String) {
        let cursorLocation = viewAsTextView.selectedRange.location
        let searchRange = viewAsTextView.textStorage.mutableString.range(of: string)
        if searchRange.length > 0 {
            viewAsTextView.textStorage.mutableString.replaceCharacters(in: searchRange, with: replacement)
            if cursorLocation > searchRange.location {
                viewAsTextView.selectedRange = NSRange(location: min(cursorLocation + (replacement as NSString).length - (string as NSString).length, (text as NSString).length), length: 0)
                repositionCursorAtEndOfRange()
            }
        }
    }

    open func replaceCharactersInRange(_ range: NSRange, withString: String) {
        if !rangeIntersectsToken(range) {
            viewAsTextView.textStorage.replaceCharacters(in: range, with: withString)
        }
    }

    open func insertString(_ string: String, atIndex index: Int) {
        viewAsTextView.textStorage.insert(NSAttributedString(string: string), at: index)
    }

    // MARK: token editing

    @discardableResult
    open func addToken(_ startIndex: Int, text: String) -> TokenInformation {
        let effectiveText = effectiveTokenDisplayText(text)
        let attrs = createNewTokenAttributes()
        let attrString = NSAttributedString(string: effectiveText, attributes: attrs)
        viewAsTextView.textStorage.insert(attrString, at: startIndex)
        repositionCursorAtEndOfRange()
        let tokenRange = tokenAtLocation(startIndex)!.range
        let tokenRef = attrs[TokenTextViewControllerConstants.tokenAttributeName] as! TokenReference
        let tokenInfo = TokenInformation(reference: tokenRef, text: effectiveText, range: tokenRange)
        delegate?.tokenTextViewDidChange(self)
        return tokenInfo
    }

    open func updateTokenFormatting() {
        tokenTextStorage.updateFormatting()
    }

    fileprivate func createNewTokenAttributes() -> [String: Any] {
        return [TokenTextViewControllerConstants.tokenAttributeName: UUID().uuidString as TokenReference as AnyObject]
    }

    open func updateTokenText(_ tokenRef: TokenReference, newText: String) {
        let effectiveText = effectiveTokenDisplayText(newText)
        replaceTokenText(tokenRef, newText: effectiveText)
        repositionCursorAtEndOfRange()
        self.delegate?.tokenTextViewDidChange(self)
    }

    open func deleteToken(_ tokenRef: TokenReference) {
        replaceTokenText(tokenRef, newText: "")
        viewAsTextView.selectedRange = NSRange(location: viewAsTextView.selectedRange.location, length: 0)
        self.delegate?.tokenTextViewDidChange(self)
        delegate?.tokenTextViewDidDeleteToken(self, tokenRef: tokenRef)
    }

    fileprivate func replaceTokenText(_ tokenToReplaceRef: TokenReference, newText: String) {
        tokenTextStorage.enumerateTokens { (tokenRef, tokenRange) -> ObjCBool in
            if tokenRef == tokenToReplaceRef {
                self.viewAsTextView.textStorage.replaceCharacters(in: tokenRange, with: newText)
                return true
            }
            return false
        }
    }

    fileprivate func repositionCursorAtEndOfRange() {
        let cursorLocation = viewAsTextView.selectedRange.location
        if let tokenInfo = tokenAtLocation(cursorLocation) {
            viewAsTextView.selectedRange = NSRange(location: tokenInfo.range.location + tokenInfo.range.length, length: 0)
        }
    }

    open var tokenList: [TokenInformation] {
        return tokenTextStorage.tokenList
    }

    fileprivate func tokenAtLocation(_ location: Int) -> TokenInformation? {
        for tokenInfo in tokenList {
            if location >= tokenInfo.range.location && location < tokenInfo.range.location + tokenInfo.range.length {
                return tokenInfo
            }
        }
        return nil
    }

    open func rangeIntersectsToken(_ range: NSRange) -> Bool {
        return tokenTextStorage.rangeIntersectsToken(range)
    }

    open func rangeIntersectsTokenInput(_ range: NSRange) -> Bool {
        return tokenTextStorage.rangeIntersectsTokenInput(range)
    }

    fileprivate func cancelEditingAndKeepText() {
        tokenTextStorage.clearEditingAttributes()
        inputDelegate?.tokenTextViewInputTextWasCanceled(self, reason: .tapOut)
    }

    // MARK: Token List editing
    
    // creates a token out of editable text contained in the input field
    fileprivate func tokenizeEditableText(atIndex: Int, toIndex: Int) {
        let startIndex = text.index(text.startIndex, offsetBy: atIndex)
        let endIndex = text.index(text.startIndex, offsetBy: toIndex)
        let newRange = startIndex..<endIndex
        let newString = text.substring(with: newRange)
        
        let nsNewRange = NSRange(location: atIndex, length: (toIndex-atIndex))
        replaceCharactersInRange(nsNewRange, withString: "")
        
        addToken(atIndex, text: newString)
    }
    
    // creates a token out of all editable text contained in the input field
    // aka: chipifyAll
    open func tokenizeAllEditableText(_ moveCursor: Bool) {
        switch tokenList.count {
        case 0:
            tokenizeEditableText(atIndex: 0, toIndex: text.characters.count)
        default:
            // find text discontinuities
            var discontinuityLength: [Int] = []
            var discontinuityIndex: [Int] = []
            
            // find text discontinuities before token list
            if tokenList.first?.range.location != 0 {
                discontinuityLength.append((tokenList.first?.range.location)!)
                discontinuityIndex.append(0)
            }

            // find text discontinuities within token list
            for i in 1..<tokenList.count {
                let endPositionPrevious = tokenList[i-1].range.length + tokenList[i-1].range.location
                let startPositionCurrent = tokenList[i].range.location
                
                if startPositionCurrent != endPositionPrevious {
                    // found discontinuity
                    discontinuityLength.append(startPositionCurrent - endPositionPrevious)
                    discontinuityIndex.append(endPositionPrevious)
                }
            }

            // find discontinuities after token list
            let lastToken = tokenList.last!
            let lengthAfterTokenList = lastToken.range.location + lastToken.range.length - text.characters.count
            if lengthAfterTokenList != 0 {
                let lastToken = tokenList.last!
                discontinuityLength.append(text.characters.count-lastToken.range.length - lastToken.range.location)
                discontinuityIndex.append(lastToken.range.length + lastToken.range.location)
            }
            
            // apply tokens to discontinuities
            for i in (0..<discontinuityLength.count).reversed() {
                // insert all new chips
                tokenizeEditableText(atIndex: discontinuityIndex[i], toIndex: discontinuityIndex[i]+discontinuityLength[i])
            }
            // move cursor to the end
            if moveCursor {
                selectedRange = NSRange(location: text.characters.count, length: 0)
            }
        }
    }
    
    // MARK: Input Mode

    open func switchToInputEditingMode(_ location: Int, text: String, initialInputLength: Int = 0) {
        let attrString = NSAttributedString(string: text, attributes: [TokenTextViewControllerConstants.inputTextAttributeName : TokenTextViewControllerConstants.inputTextAttributeAnchorValue])
        tokenTextStorage.insert(attrString, at: location)
        if initialInputLength > 0 {
            let inputRange = NSRange(location: location + (text as NSString).length, length: initialInputLength)
            tokenTextStorage.addAttributes([TokenTextViewControllerConstants.inputTextAttributeName : TokenTextViewControllerConstants.inputTextAttributeTextValue], range: inputRange)
        }
        viewAsTextView.selectedRange = NSRange(location: location + (text as NSString).length + initialInputLength, length: 0)
        viewAsTextView.autocorrectionType = .no
        viewAsTextView.delegate = inputModeHandler
        textTappedHandler = inputModeTapHandler
        delegate?.tokenTextViewDidChange(self)
        tokenTextStorage.updateFormatting()
    }

    open func switchToNormalEditingMode() -> Int {
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
        viewAsTextView.autocorrectionType = .default
        return location
    }

    fileprivate var normalModeTapHandler: ((UITapGestureRecognizer) -> Void) {
        return { [weak self] recognizer in
            self?.normalModeTap(recognizer: recognizer)
        }
    }

    fileprivate var inputModeTapHandler: ((UITapGestureRecognizer) -> Void) {
        return { [weak self] recognizer in
            self?.inputModeTap(recognizer: recognizer)
        }
    }

    fileprivate func normalModeTap(recognizer: UITapGestureRecognizer) {
        viewAsTextView.becomeFirstResponder()
        let location: CGPoint = recognizer.location(in: viewAsTextView)
        var charIndex = viewAsTextView.characterIndexAtLocation(location)
        if charIndex != nil && charIndex! < viewAsTextView.textStorage.length - 1 {
            var range = NSRange(location: 0, length: 0)
            if let tokenRef = viewAsTextView.attributedText?.attribute(TokenTextViewControllerConstants.tokenAttributeName, at: charIndex!, effectiveRange: &range) as? TokenReference {
                let _ = resignFirstResponder()
                let rect: CGRect = {
                    if let textRange = viewAsTextView.textRangeFromNSRange(range) {
                        return view.convert(viewAsTextView.firstRect(for: textRange), from: viewAsTextView.textInputView)
                    } else {
                        return CGRect(origin: location, size: CGSize.zero)
                    }
                }()
                delegate?.tokenTextViewDidSelectToken(self, tokenRef: tokenRef, fromRect: rect)
            } else {
                if charIndex == viewAsTextView.textStorage.length - 1 {
                    // Allow placing the cursor at the end of the text
                    charIndex = viewAsTextView.textStorage.length
                }
                viewAsTextView.selectedRange = NSRange(location: charIndex!, length: 0)
            }
        }
    }

    fileprivate func inputModeTap(recognizer: UITapGestureRecognizer) {
        guard !inputIsSuspended else {
            inputIsSuspended = false
            return
        }
        let location: CGPoint = recognizer.location(in: viewAsTextView)

        if
            let charIndex = viewAsTextView.characterIndexAtLocation(location),
            let (_, inputRange) = tokenTextStorage.inputTextAndRange(),
            let (_, anchorRange) = tokenTextStorage.anchorTextAndRange(),
            charIndex < anchorRange.location || charIndex >= inputRange.location + inputRange.length - 1
        {
            cancelEditingAndKeepText()
        }
    }

    // MARK: UITextViewDelegate

    open func textViewDidChange(_ textView: UITextView) {
        self.delegate?.tokenTextViewDidChange(self)
    }

    open func textViewDidChangeSelection(_ textView: UITextView) {
        if viewAsTextView.selectedRange.length == 0 {
            // The cursor is being repositioned
            let cursorLocation = textView.selectedRange.location
            let newCursorLocation = clampCursorLocationToToken(cursorLocation)
            if newCursorLocation != cursorLocation {
                viewAsTextView.selectedRange = NSRange(location: newCursorLocation, length: 0)
            }
        } else {
            // A selection range is being modified
            let adjustedSelectionStart = clampCursorLocationToToken(textView.selectedRange.location)
            let adjustedSelectionLength = max(adjustedSelectionStart, clampCursorLocationToToken(textView.selectedRange.location + textView.selectedRange.length)) - adjustedSelectionStart
            if (adjustedSelectionStart != textView.selectedRange.location) || (adjustedSelectionLength != textView.selectedRange.length) {
                viewAsTextView.selectedRange = NSRange(location: adjustedSelectionStart, length: adjustedSelectionLength)
            }
        }
    }

    fileprivate func clampCursorLocationToToken(_ cursorLocation: Int) -> Int {
        if let tokenInfo = tokenAtLocation(cursorLocation) {
            let range = tokenInfo.range
            return (cursorLocation > range.location + range.length / 2) ? (range.location + range.length) : range.location
        }
        return cursorLocation
    }

    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText: String) -> Bool {
        if range.length == 1 && (replacementText as NSString).length == 0 {
            // Deleting one character, if it is part of a token the full token should be deleted
            if let tokenInfo = tokenAtLocation(range.location) {
                deleteToken(tokenInfo.reference)
                viewAsTextView.selectedRange = NSRange(location: tokenInfo.range.location, length: 0)
                return false
            }
        } else if range.length > 0 {
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

    fileprivate func replaceRangeAndIntersectingTokens(_ range: NSRange, intersectingTokenReferences: [TokenReference], replacementText: String) {
        viewAsTextView.textStorage.replaceCharacters(in: range, with: replacementText)
        tokenTextStorage.enumerateTokens { (tokenRef, tokenRange) -> ObjCBool in
            if intersectingTokenReferences.contains(tokenRef) {
                self.viewAsTextView.textStorage.replaceCharacters(in: tokenRange, with: "")
            }
            return false
        }
        viewAsTextView.selectedRange = NSRange(location: viewAsTextView.selectedRange.location, length: 0)
        for tokenRef in intersectingTokenReferences {
            delegate?.tokenTextViewDidDeleteToken(self, tokenRef: tokenRef)
        }
    }


    // MARK: NSLayoutManagerDelegate

    open func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
        var effectiveRange = NSRange(location: 0, length: 0)
        if let _ = (view as! UITextView).attributedText?.attribute(TokenTextViewControllerConstants.tokenAttributeName, at: charIndex, effectiveRange: &effectiveRange) as? TokenReference {
            return false
        }
        return true
    }

    // MARK: TokenTextViewTextStorageDelegate

    func textStorageIsUpdatingFormatting(_ sender: TokenTextViewTextStorage, text: String, searchRange: NSRange) -> [(attributes: [String:AnyObject], forRange: NSRange)]? {
        return delegate?.tokenTextViewTextStorageIsUpdatingFormatting(self, text: text, searchRange: searchRange)
    }

    func textStorageBackgroundColourForTokenRef(_ sender: TokenTextViewTextStorage, tokenRef: TokenReference) -> UIColor? {
        return delegate?.tokenTextViewBackgroundColourForTokenRef(self, tokenRef: tokenRef)
    }

    // MARK: Token text management

    fileprivate func effectiveTokenDisplayText(_ originalText: String) -> String {
        return tokenTextStorage.effectiveTokenDisplayText(originalText)
    }

}

class TokenTextViewControllerInputModeHandler: NSObject, UITextViewDelegate {

    fileprivate weak var tokenTextViewController: TokenTextViewController!

    init(tokenTextViewController: TokenTextViewController) {
        self.tokenTextViewController = tokenTextViewController
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if let (_, inputRange) = tokenTextViewController.tokenTextStorage.inputTextAndRange() {
            let cursorLocation = textView.selectedRange.location + textView.selectedRange.length
            let adjustedLocation = clampCursorLocationToInputRange(cursorLocation, inputRange: inputRange)
            if adjustedLocation != cursorLocation || textView.selectedRange.length > 0 {
                tokenTextViewController.viewAsTextView.selectedRange = NSRange(location: adjustedLocation, length: 0)
            }
        } else if let (_, anchorRange) = tokenTextViewController.tokenTextStorage.anchorTextAndRange() {
            let adjustedLocation = anchorRange.location + 1
            if textView.selectedRange.location != adjustedLocation {
                tokenTextViewController.viewAsTextView.selectedRange = NSRange(location: adjustedLocation, length: 0)
            }
        } else {
            let _ = tokenTextViewController.resignFirstResponder()
        }
    }

    fileprivate func clampCursorLocationToInputRange(_ cursorLocation: Int, inputRange: NSRange) -> Int {
        if cursorLocation < inputRange.location {
            return inputRange.location
        }
        if cursorLocation > inputRange.location + inputRange.length {
            return inputRange.location + inputRange.length
        }
        return cursorLocation
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText newText: String) -> Bool {
        if range.length == 0 {
            handleInsertion(range, newText: newText)
        } else if range.length == 1 && newText.isEmpty {
            handleCharacterDeletion(range)
        }
        return false
    }

    fileprivate func handleInsertion(_ range: NSRange, newText: String) {
        if newText == "\n" {
            // Do not insert return, inform delegate
            tokenTextViewController.inputDelegate?.tokenTextViewInputTextWasConfirmed(tokenTextViewController)
            return
        }
        // Insert new text with token attribute
        let attrString = NSAttributedString(string: newText, attributes: [TokenTextViewControllerConstants.inputTextAttributeName : TokenTextViewControllerConstants.inputTextAttributeTextValue])
        tokenTextViewController.viewAsTextView.textStorage.insert(attrString, at: range.location)
        tokenTextViewController.viewAsTextView.selectedRange = NSRange(location: range.location + (newText as NSString).length, length: 0)
        if let (inputText, _) = tokenTextViewController.tokenTextStorage.inputTextAndRange() {
            tokenTextViewController.inputDelegate?.tokenTextViewInputTextDidChange(tokenTextViewController, inputText: inputText)
            if let delegate = tokenTextViewController.delegate, delegate.tokenTextViewShouldCancelEditingAtInsert(tokenTextViewController, newText: newText, inputText: inputText) {
                tokenTextViewController.cancelEditingAndKeepText()
            }
        }
    }

    fileprivate func handleCharacterDeletion(_ range: NSRange) {
        if let (_, inputRange) = tokenTextViewController.tokenTextStorage.inputTextAndRange(), let (_, anchorRange) = tokenTextViewController.tokenTextStorage.anchorTextAndRange() {
            if range.location >= anchorRange.location && range.location < anchorRange.location + anchorRange.length {
                // The anchor ("@") is deleted, input is cancelled
                tokenTextViewController.inputDelegate?.tokenTextViewInputTextWasCanceled(tokenTextViewController, reason: .deleteInput)
            } else if range.location >= inputRange.location && range.location < inputRange.location + inputRange.length {
                // Do deletion
                tokenTextViewController.viewAsTextView.textStorage.replaceCharacters(in: range, with: "")
                tokenTextViewController.viewAsTextView.selectedRange = NSRange(location: range.location, length: 0)
                if let (inputText, _) = tokenTextViewController.tokenTextStorage.inputTextAndRange() {
                    tokenTextViewController.inputDelegate?.tokenTextViewInputTextDidChange(tokenTextViewController, inputText: inputText)
                }
            }
        } else {
            // Input fully deleted, input is cancelled
            tokenTextViewController.inputDelegate?.tokenTextViewInputTextWasCanceled(tokenTextViewController, reason: .deleteInput)
        }
    }
}

extension UITextView {
    func characterIndexAtLocation(_ location: CGPoint) -> Int? {
        var point = location
        point.x -= self.textContainerInset.left
        point.y -= self.textContainerInset.top
        return self.textContainer.layoutManager?.characterIndex(for: point, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

extension UITextView {
    func textRangeFromNSRange(_ range: NSRange) -> UITextRange? {
        let beginning = self.beginningOfDocument
        if let start = self.position(from: beginning, offset: range.location),
            let end = self.position(from: start, offset: range.length),
            let textRange = self.textRange(from: start, to: end) {
            return textRange
        } else {
            return nil
        }
    }
}

extension TokenTextViewController: PasteMediaTextViewPasteDelegate {
    func pasteMediaTextView(_: PasteMediaTextView, shouldAcceptContentOfType type: PasteboardItemType) -> Bool {
        return delegate?.tokenTextView(self, shouldAcceptContentOfType: type) ?? false
    }

    func pasteMediaTextView(_: PasteMediaTextView, didReceive items: [PasteboardItem]) {
        delegate?.tokenTextView(self, didReceive: items)
    }
}
