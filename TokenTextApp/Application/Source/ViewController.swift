//
//  ViewController.swift
//  TokenTextApp
//
//  Created by David Bonnefoy on 2016-05-27.
//  Copyright © 2016 Hootsuite. All rights reserved.
//

import Foundation
import UIKit
import OwlTokenTextView

class ViewController: UIViewController {

    @IBOutlet weak var textInputContainer: UIView!
    private var tokenTextVC: TokenTextViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        tokenTextVC = TokenTextViewController()
        tokenTextVC.delegate = self
        addChildViewController(tokenTextVC)
        textInputContainer.addSubview(tokenTextVC.view)
        tokenTextVC.view.frame = textInputContainer.bounds
        tokenTextVC.didMoveToParentViewController(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tokenTextVC.text = "Hello "
        tokenTextVC.addToken(6, text: "Team")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tokenTextVC.becomeFirstResponder()
    }

}

extension ViewController: TokenTextViewControllerDelegate {

    func tokenTextViewDidChange(sender: TokenTextViewController) -> () {
    }

    func tokenTextViewShouldChangeTextInRange(sender: TokenTextViewController, range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    func tokenTextViewDidSelectToken(sender: TokenTextViewController, tokenRef: TokenReference, fromRect rect: CGRect) -> () {
        let alert = UIAlertController(title: "Token Selected", message: nil, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default) { _ in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        presentViewController(alert, animated: true, completion: nil)
    }

    func tokenTextViewDidDeleteToken(sender: TokenTextViewController, tokenRef: TokenReference) -> () {
        let alert = UIAlertController(title: "Token Deleted", message: nil, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default) { _ in
            self.dismissViewControllerAnimated(true, completion: nil)
            })
        presentViewController(alert, animated: true, completion: nil)
    }

    func tokenTextViewTextStorageIsUpdatingFormatting(sender: TokenTextViewController, text: String, searchRange: NSRange) -> [(attributes: [String:AnyObject], forRange: NSRange)] {
        return []
    }

    func tokenTextViewBackgroundColourForTokenRef(sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor? {
        return UIColor.blueColor()
    }

    func tokenTextViewShouldCancelEditingAtInsert(sender: TokenTextViewController, newText: String, inputText: String) -> Bool {
        return true
    }
}
