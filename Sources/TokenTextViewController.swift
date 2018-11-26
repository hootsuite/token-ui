// Copyright © 2017 Hootsuite. All rights reserved.

import Foundation
import UIKit

/// The delegate used to handle user interaction and enable/disable customization to a `TokenTextViewController`.
public protocol TokenTextViewControllerDelegate: class {

    /// Called when text changes.
    func tokenTextViewDidChange(_ sender: TokenTextViewController)

    /// Whether an edit should be accepted.
    func tokenTextViewShouldChangeTextInRange(_ sender: TokenTextViewController, range: NSRange, replacementText text: String) -> Bool

    /// Called when a token was tapped.
    func tokenTextViewDidSelectToken(_ sender: TokenTextViewController, tokenRef: TokenReference, fromRect rect: CGRect)

    /// Called when a token was deleted.
    func tokenTextViewDidDeleteToken(_ sender: TokenTextViewController, tokenRef: TokenReference)

    /// Called when a token was added.
    func tokenTextViewDidAddToken(_ sender: TokenTextViewController, tokenRef: TokenReference)

    /// Called when the formatting is being updated.
    func tokenTextViewTextStorageIsUpdatingFormatting(_ sender: TokenTextViewController, text: String, searchRange: NSRange) -> [(attributes: [NSAttributedString.Key: Any], forRange: NSRange)]

    /// Allows to customize the background color for a token.
    func tokenTextViewBackgroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor?

    /// Allows to customize the foreground color for a token
    func tokenTextViewForegroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor?

    /// Whether the last edit should cancel token editing.
    func tokenTextViewShouldCancelEditingAtInsert(_ sender: TokenTextViewController, newText: String, inputText: String) -> Bool

    /// Whether content of type type can be pasted in the text view.
    /// This method is called every time some content may be pasted.
    func tokenTextView(_: TokenTextViewController, shouldAcceptContentOfType type: PasteboardItemType) -> Bool

    /// Called when media items have been pasted.
    func tokenTextView(_: TokenTextViewController, didReceive items: [PasteboardItem])

}

/// Default implementation for some `TokenTextViewControllerDelegate` methods.
public extension TokenTextViewControllerDelegate {

    /// Default value of `false`.
    func tokenTextView(_: TokenTextViewController, shouldAcceptContentOfType type: PasteboardItemType) -> Bool {
        return false
    }

    /// Empty default implementation.
    func tokenTextView(_: TokenTextViewController, didReceive items: [PasteboardItem]) {

    }

    /// Empty default implementation
    func tokenTextViewDidAddToken(_ sender: TokenTextViewController, tokenRef: TokenReference) {

    }

    /// Default color of white.
    func tokenTextViewForegroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor? {
        return .white
    }

}

/// The delegate used to handle text input in a `TokenTextViewController`.
public protocol TokenTextViewControllerInputDelegate: class {

    /// Called whenever the text is updated.
    func tokenTextViewInputTextDidChange(_ sender: TokenTextViewController, inputText: String)

    /// Called when the text is confirmed by the user.
    func tokenTextViewInputTextWasConfirmed(_ sender: TokenTextViewController)

    /// Called when teh text is cancelled by the user.
    func tokenTextViewInputTextWasCanceled(_ sender: TokenTextViewController, reason: TokenTextInputCancellationReason)

}

/// Determines different input cancellation reasons for a `TokenTextViewController`.
public enum TokenTextInputCancellationReason {

    case deleteInput
    case tapOut

}

/// A data structure to hold constants for the `TokenTextViewController`.
public struct TokenTextViewControllerConstants {

    public static let tokenAttributeName = NSAttributedString.Key(rawValue: "com.hootsuite.token")
    static let inputTextAttributeName = NSAttributedString.Key(rawValue: "com.hootsuite.input")
    static let inputTextAttributeAnchorValue = "anchor"
    static let inputTextAttributeTextValue = "text"

}

public typealias TokenReference = String

/// A data structure used to identify a `Token` inside some text.
public struct TokenInformation {

    /// The `Token` identifier.
    public var reference: TokenReference

    /// The text that contains the `Token`.
    public var text: String

    /// The range of text that contains the `Token`.
    public var range: NSRange

}

/// Used to display a `UITextView` that creates and responds to `Token`'s as the user types and taps.
open class TokenTextViewController: UIViewController, UITextViewDelegate, NSLayoutManagerDelegate, TokenTextViewTextStorageDelegate, UIGestureRecognizerDelegate {

    /// The delegate used to handle user interaction and enable/disable customization.
    open weak var delegate: TokenTextViewControllerDelegate?

    /// The delegate used to handle text input.
    open weak var inputDelegate: TokenTextViewControllerInputDelegate? {
        didSet {
            if let (inputText, _) = tokenTextStorage.inputTextAndRange() {
                inputDelegate?.tokenTextViewInputTextDidChange(self, inputText: inputText)
            }
        }
    }

    /// The font for the textView.
    open var font = UIFont.preferredFont(forTextStyle: .body) {
        didSet {
            viewAsTextView.font = font
            tokenTextStorage.font = font
        }
    }

    /// Flag for text tokenization when input field loses focus
    public var tokenizeOnLostFocus = false

    fileprivate var tokenTapRecognizer: UITapGestureRecognizer?
    fileprivate var inputModeHandler: TokenTextViewControllerInputModeHandler!
    fileprivate var textTappedHandler: ((UITapGestureRecognizer) -> Void)?
    fileprivate var inputIsSuspended = false

    /// Initializer for `self`.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Initializer for `self`.
    public init() {
        super.init(nibName: nil, bundle: nil)
        inputModeHandler = TokenTextViewControllerInputModeHandler(tokenTextViewController: self)
        textTappedHandler = normalModeTapHandler
    }

    /// Loads a `PasteMediaTextView` as the base view of `self`.
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
        textView.mediaPasteDelegate = self
        textView.isScrollEnabled = true
        tokenTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(TokenTextViewController.textTapped(_:)))
        tokenTapRecognizer!.numberOfTapsRequired = 1
        tokenTapRecognizer!.delegate = self
        textView.addGestureRecognizer(tokenTapRecognizer!)
        self.view = textView
    }

    fileprivate var viewAsTextView: UITextView! {
        return (view as! UITextView)
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
            name: UIContentSizeCategory.didChangeNotification,
            object: nil)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    @objc func preferredContentSizeChanged(_ notification: Notification) {
        tokenTextStorage.updateFormatting()
    }

    @objc func textTapped(_ recognizer: UITapGestureRecognizer) {
        textTappedHandler?(recognizer)
    }

    // MARK: UIGestureRecognizerDelegate

    /// Enables/disables some gestures to be recognized simultaneously.
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tokenTapRecognizer {
            return true
        }
        return false
    }

    // MARK: UITextView variables and functions.

    /// The text contained in the textView.
    open var text: String! {
        get {
            return viewAsTextView.text
        }

        set {
            viewAsTextView.text = newValue
        }
    }

    /// The color of the text in the textView.
    open var textColor: UIColor! {
        get {
            return viewAsTextView.textColor
        }

        set {
            viewAsTextView.textColor = newValue
        }
    }

    /// The style of the text alignment for the textView.
    open var textAlignment: NSTextAlignment {
        get {
            return viewAsTextView.textAlignment
        }

        set {
            viewAsTextView.textAlignment = newValue
        }
    }

    /// The selected range of text in the textView.
    open var selectedRange: NSRange {
        get {
            return viewAsTextView.selectedRange
        }

        set {
            viewAsTextView.selectedRange = newValue
        }
    }

    /// The type of keyboard displayed when the user interacts with the textView.
    open var keyboardType: UIKeyboardType {
        get {
            return viewAsTextView.keyboardType
        }

        set {
            viewAsTextView.keyboardType = newValue
        }
    }

    /// The edge insets of the textView.
    open var textContainerInset: UIEdgeInsets {
        get {
            return viewAsTextView.textContainerInset
        }

        set {
            viewAsTextView.textContainerInset = newValue
        }
    }

    /// Sets the scrolling enabled/disabled state of the textView.
    open var scrollEnabled: Bool {
        get {
            return viewAsTextView.isScrollEnabled
        }

        set {
            viewAsTextView.isScrollEnabled = newValue
        }
    }

    /// The line fragment padding for the textView.
    open var lineFragmentPadding: CGFloat {
        get {
            return viewAsTextView.textContainer.lineFragmentPadding
        }

        set {
            viewAsTextView.textContainer.lineFragmentPadding = newValue
        }
    }

    /// A rectangle that defines the area for drawing the caret in the textView.
    public var cursorRect: CGRect? {
        if let selectedTextRange = viewAsTextView.selectedTextRange {
            return viewAsTextView.caretRect(for: selectedTextRange.start)
        }
        return nil
    }

    /// The accessibility label string for the text view.
    override open var accessibilityLabel: String! {
        get {
            return viewAsTextView.accessibilityLabel
        }

        set {
            viewAsTextView.accessibilityLabel = newValue
        }
    }

    /// Assigns the first responder to the textView.
    override open func becomeFirstResponder() -> Bool {
        return viewAsTextView.becomeFirstResponder()
    }

    /// Resigns the first responder from the textView.
    override open func resignFirstResponder() -> Bool {
        return viewAsTextView.resignFirstResponder()
    }

    /// Resigns as first responder.
    open func suspendInput() {
        _ = resignFirstResponder()
        inputIsSuspended = true
    }

    /// The text storage object holding the text displayed in this text view.
    open var attributedString: NSAttributedString {
        return viewAsTextView.textStorage
    }

    // MARK: Text manipulation.

    /// Appends the given text to the textView and repositions the cursor at the end.
    open func appendText(_ text: String) {
        viewAsTextView.textStorage.append(NSAttributedString(string: text))
        repositionCursorAtEndOfRange()
    }

    /// Adds text to the beginning of the textView and repositions the cursor at the end.
    open func prependText(_ text: String) {
        let cursorLocation = viewAsTextView.selectedRange.location
        viewAsTextView.textStorage.insert(NSAttributedString(string: text), at: 0)
        viewAsTextView.selectedRange = NSRange(location: cursorLocation + (text as NSString).length, length: 0)
        repositionCursorAtEndOfRange()
    }

    /// Replaces the first occurrence of the given string in the textView with another string.
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

    /// Replaces the characters in the given range in the textView with the provided string.
    open func replaceCharactersInRange(_ range: NSRange, withString: String) {
        if !rangeIntersectsToken(range) {
            viewAsTextView.textStorage.replaceCharacters(in: range, with: withString)
        }
    }

    /// Inserts the given string at the provided index location of the textView.
    open func insertString(_ string: String, atIndex index: Int) {
        viewAsTextView.textStorage.insert(NSAttributedString(string: string), at: index)
    }

    // MARK: token editing

    /// Adds a token to the textView at the given index and informs the delegate.
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
        delegate?.tokenTextViewDidAddToken(self, tokenRef: tokenRef)
        return tokenInfo
    }

    /// Updates the formatting of the textView.
    open func updateTokenFormatting() {
        tokenTextStorage.updateFormatting()
    }

    fileprivate func createNewTokenAttributes() -> [NSAttributedString.Key: Any] {
        return [
            TokenTextViewControllerConstants.tokenAttributeName: UUID().uuidString as TokenReference
        ]
    }

    /// Updates the given `Token`'s text with the provided text and informs the delegate of the change.
    open func updateTokenText(_ tokenRef: TokenReference, newText: String) {
        let effectiveText = effectiveTokenDisplayText(newText)
        replaceTokenText(tokenRef, newText: effectiveText)
        repositionCursorAtEndOfRange()
        self.delegate?.tokenTextViewDidChange(self)
    }

    /// Delegates the given `Token` and informs the delegate of the change.
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

    /// An array of all the `Token`'s currently in the textView.
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

    /// Determines whether the given range intersects with a `Token` currently in the textView.
    open func rangeIntersectsToken(_ range: NSRange) -> Bool {
        return tokenTextStorage.rangeIntersectsToken(range)
    }

    /// Determines whether the given range intersects with a `Token` that is currently being input by the user.
    open func rangeIntersectsTokenInput(_ range: NSRange) -> Bool {
        return tokenTextStorage.rangeIntersectsTokenInput(range)
    }

    fileprivate func cancelEditingAndKeepText() {
        tokenTextStorage.clearEditingAttributes()
        inputDelegate?.tokenTextViewInputTextWasCanceled(self, reason: .tapOut)
    }

    // MARK: Token List editing

    // Create a token from editable text contained from atIndex to toIndex (excluded)
    fileprivate func tokenizeEditableText(at range: NSRange) {
        if range.length != 0 {
            let nsText = text as NSString
            replaceCharactersInRange(range, withString: "")
            let textSubstring = nsText.substring(with: range).trimmingCharacters(in: .whitespaces)
            if !textSubstring.isEmpty {
                addToken(range.location, text: textSubstring)
            }
        }
    }

    // Create tokens from all editable text contained in the input field
    public func tokenizeAllEditableText() {
        var nsText = text as NSString

        if tokenList.isEmpty {
            tokenizeEditableText(at: NSRange(location: 0, length: nsText.length))
            return
        }

        // ensure we use a sorted tokenlist (by location)
        let orderedTokenList: [TokenInformation] = tokenList.sorted(by: { $0.range.location < $1.range.location })

        // find text discontinuities, characters that do not belong to a token
        var discontinuities: [NSRange] = []

        // find discontinuities before token list
        guard let firstToken = orderedTokenList.first else { return }
        if firstToken.range.location != 0 {
            discontinuities.append(NSRange(location: 0, length: firstToken.range.location))
        }

        // find discontinuities within token list
        for i in 1..<orderedTokenList.count {
            let endPositionPrevious = orderedTokenList[i-1].range.length + orderedTokenList[i-1].range.location
            let startPositionCurrent = orderedTokenList[i].range.location

            if startPositionCurrent != endPositionPrevious {
                // found discontinuity
                discontinuities.append(NSRange(location: endPositionPrevious, length: (startPositionCurrent - endPositionPrevious)))
            }
        }

        // find discontinuities after token list
        guard let lastToken = orderedTokenList.last else { return }
        let lengthAfterTokenList = lastToken.range.location + lastToken.range.length - nsText.length
        if lengthAfterTokenList != 0 {
            discontinuities.append(NSRange(location: (lastToken.range.length + lastToken.range.location), length: (nsText.length - lastToken.range.length - lastToken.range.location)))
        }

        // apply tokens at discontinuities
        for i in (0..<discontinuities.count).reversed() {
            // insert all new chips
            tokenizeEditableText(at: discontinuities[i])
        }

        // move cursor to the end
        nsText = text as NSString
        selectedRange = NSRange(location: nsText.length, length: 0)
    }

    // Create editable text from exisitng token, appended to end of input field
    // This method tokenizes all current editable text prior to making token editable
    public func makeTokenEditableAndMoveToFront(tokenReference: TokenReference) {
        var clickedTokenText = ""

        guard let foundToken = tokenList.first(where: { $0.reference == tokenReference }) else { return }
        clickedTokenText = foundToken.text.trimmingCharacters(in: CharacterSet.whitespaces)
        tokenizeAllEditableText()
        deleteToken(tokenReference)
        appendText(clickedTokenText)

        let nsText = self.text as NSString
        selectedRange = NSRange(location: nsText.length, length: 0)
        _ = becomeFirstResponder()
        delegate?.tokenTextViewDidChange(self)
    }

    // MARK: Input Mode

    ///
    open func switchToInputEditingMode(_ location: Int, text: String, initialInputLength: Int = 0) {
        let attrString = NSAttributedString(string: text, attributes: [TokenTextViewControllerConstants.inputTextAttributeName: TokenTextViewControllerConstants.inputTextAttributeAnchorValue])
        tokenTextStorage.insert(attrString, at: location)
        if initialInputLength > 0 {
            let inputRange = NSRange(location: location + (text as NSString).length, length: initialInputLength)
            tokenTextStorage.addAttributes([TokenTextViewControllerConstants.inputTextAttributeName: TokenTextViewControllerConstants.inputTextAttributeTextValue], range: inputRange)
        }
        viewAsTextView.selectedRange = NSRange(location: location + (text as NSString).length + initialInputLength, length: 0)
        viewAsTextView.autocorrectionType = .no
        viewAsTextView.delegate = inputModeHandler
        textTappedHandler = inputModeTapHandler
        delegate?.tokenTextViewDidChange(self)
        tokenTextStorage.updateFormatting()
    }

    /// Sets the text tap handler with the `normalModeTapHandler` and returns the location of the cursor.
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
        if let charIndex = viewAsTextView.characterIndexAtLocation(location), charIndex < viewAsTextView.textStorage.length - 1 {
            var range = NSRange(location: 0, length: 0)
            if let tokenRef = viewAsTextView.attributedText?.attribute(TokenTextViewControllerConstants.tokenAttributeName, at: charIndex, effectiveRange: &range) as? TokenReference {
                _ = resignFirstResponder()
                let rect: CGRect = {
                    if let textRange = viewAsTextView.textRangeFromNSRange(range) {
                        return view.convert(viewAsTextView.firstRect(for: textRange), from: viewAsTextView.textInputView)
                    } else {
                        return CGRect(origin: location, size: CGSize.zero)
                    }
                }()
                delegate?.tokenTextViewDidSelectToken(self, tokenRef: tokenRef, fromRect: rect)
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

    /// Determines whether the text in the given range should be replaced by the provided string.
    /// Deleting one character, if it is part of a token, should delete the full token.
    /// If the editing range intersects tokens, make sure tokens are fully deleted and delegate called.
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

    public func textViewDidEndEditing(_ textView: UITextView) {
        if tokenizeOnLostFocus {
            tokenizeAllEditableText()
        }
    }


    // MARK: NSLayoutManagerDelegate

    open func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
        var effectiveRange = NSRange(location: 0, length: 0)
        if (view as! UITextView).attributedText?.attribute(TokenTextViewControllerConstants.tokenAttributeName, at: charIndex, effectiveRange: &effectiveRange) is TokenReference {
            return false
        }
        return true
    }

    // MARK: TokenTextViewTextStorageDelegate

    func textStorageIsUpdatingFormatting(_ sender: TokenTextViewTextStorage, text: String, searchRange: NSRange) -> [(attributes: [NSAttributedString.Key: Any], forRange: NSRange)]? {
        return delegate?.tokenTextViewTextStorageIsUpdatingFormatting(self, text: text, searchRange: searchRange)
    }

    func textStorageBackgroundColourForTokenRef(_ sender: TokenTextViewTextStorage, tokenRef: TokenReference) -> UIColor? {
        return delegate?.tokenTextViewBackgroundColourForTokenRef(self, tokenRef: tokenRef)
    }

    func textStorageForegroundColourForTokenRef(_ sender: TokenTextViewTextStorage, tokenRef: TokenReference) -> UIColor? {
        return delegate?.tokenTextViewForegroundColourForTokenRef(self, tokenRef: tokenRef)
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
            _ = tokenTextViewController.resignFirstResponder()
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
        let attrString = NSAttributedString(string: newText, attributes: [TokenTextViewControllerConstants.inputTextAttributeName: TokenTextViewControllerConstants.inputTextAttributeTextValue])
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
