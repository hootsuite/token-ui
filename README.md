# TokenUI

[![GitHub license](https://img.shields.io/badge/license-Apache%202-lightgrey.svg)](https://raw.githubusercontent.com/Carthage/Carthage/master/LICENSE.md)
[![GitHub release](https://img.shields.io/github/release/carthage/carthage.svg)](https://github.com/Carthage/Carthage/releases)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/Alamofire.svg)](https://img.shields.io/cocoapods/v/Alamofire.svg)

TokenUI is a swift Framework for creating and managing a text input component that allows to add 'tokens' rendered as pills.

TokenUI has been developed for use in the Hootsuite iOS app.

## Features

- TokenUI provides a layer on top of a `UITextView` that creates and responds to Tokens as the user types and taps.
- It keeps the same functionalities as a regular `UITextView` so the user can insert, delete and manipulate text even without any added tokens.

![TokenUI Demo](https://github.com/hootsuite/token-ui/blob/master/Demo/Resources/TokenUIDemo.gif?raw=true)

## Requirements

- iOS 11.0+
- Xcode 10.0+

## Demo Projects

See the demo project provided for example usage of the TokenUI framework.


## Installation

TokenUI can be installed using either [Carthage](https://github.com/Carthage/Carthage) or [CocoaPods](https://cocoapods.org/).

### Carthage

To integrate TokenUI into your Xcode project using Carthage, specify it in your Cartfile:

```
git "git@github.com:hootsuite/token-ui.git"
```

### CocoaPods

First, add the following line to your Podfile:

```
pod 'TokenUI'
```

Second, install TokenUI into your project:

```
pod install
```


## Initialization

A TokenUI component is handled by its own controller called `TokenTextViewController` . In order to use it create an instance of `TokenTextViewController`

```swift
let tokenTextViewController = TokenTextViewController()
```

If needed set the initial properties such as font type, initial text, etc...

```swift
tokenTextViewController.scrollEnabled = true
tokenTextViewController.keyboardType = .default
tokenTextViewController.text = "initialText"

```

Next step is to add it as a child of your own viewController and add the `TokenTextViewController` view to the container view. That is the view that is going to display the TokenText UI component.

```swift
addChildViewController(tokenTextViewController)
view.addSubview(tokenTextViewController.view)
tokenTextViewController.didMove(toParentViewController: self)

```


## Usage

A token information is represented using the `TokenInformation` struct.

```swift
public struct TokenInformation {

/// The `Token` identifier.
public var reference: TokenReference

/// The text that contains the `Token`.
public var text: String

/// The range of text that contains the `Token`.
public var range: NSRange

}
```

### Add/Delete/Update tokens

You can easily add/update/delete tokens to your TokenUIViewController using the following API methods:

```swift
open func addToken(_ startIndex: Int, text: String) -> TokenInformation
open func updateTokenText(_ tokenRef: TokenReference, newText: String)
open func deleteToken(_ tokenRef: TokenReference)

```

Example of usage:

```swift
tokenTextViewController.addToken(6, text: "Team")
```


You can access a list of all the tokens in the view using the property:

```swift
var tokenList: [TokenInformation]
```


### Delegate


As many other UI components, TokenUI uses the delegate pattern to notify changes to the view controller. Conform to `TokenTextViewControllerDelegate` to access these methods and set the delegate.

```swift
extension MessageEditorViewController: TokenTextViewControllerDelegate
...

tokenTextViewController.delegate = self
```

### Interacting with text and tokens

TokenTextViewControllerDelegate provides a set of methods to detect changes on the text in a similar way as `UITextViewDelegate`. Also provides methods to detect user interaction with the tokens.

```swift
func tokenTextViewDidChange(_ sender: TokenTextViewController)
func textViewDidChangeSelection(_ textView: UITextView)
func tokenTextViewDidSelectToken(_ sender: TokenTextViewController, tokenRef: TokenReference, fromRect rect: CGRect)
func tokenTextViewDidDeleteToken(_ sender: TokenTextViewController, tokenRef: TokenReference)

```

### Customize tokens

Tokens can easily be customize using TokenTextViewControllerDelegate methods.

```swift
func tokenTextViewBackgroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor?
func tokenTextViewForegroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor?
```

For example, if we want to have blue color for the pill around the tokens:

```swift
func tokenTextViewBackgroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor? {
	return UIColor.blue
}
```

### Text Manipulation

You can manipulate text in a TokenUI view the same way you may do it with a UITextView. The API provides several methods for adding text, replacing characters, etc.

```swift
func appendText(_ text: String)
func prependText(_ text: String)
func replaceFirstOccurrenceOfString(_ string: String, withString replacement: String)
func replaceCharactersInRange(_ range: NSRange, withString: String)
```

### Detect changes on Tokens

To get notified for changes on the Token Text, we use `TokenTextViewControllerInputDelegate`

```swift
func tokenTextViewInputTextDidChange(_ sender: TokenTextViewController, inputText: String)
func tokenTextViewInputTextWasConfirmed(_ sender: TokenTextViewController)
func tokenTextViewInputTextWasCanceled(_ sender: TokenTextViewController, reason: TokenTextInputCancellationReason)
```


### Objective-C

TokenUI makes use of Swift features such as Swift-style enums and enum protocols which are not supported by Objective-C. Due to this, the framework cannot be used in Objective-C only projects, but can be used in mixed Objective-C and Swift projects.


## License

TokenUI is released under the Apache License, Version 2.0. See [LICENSE.md](LICENSE.md) for details.

