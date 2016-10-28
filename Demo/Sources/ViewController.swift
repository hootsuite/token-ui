//
//  ViewController.swift
//  TokenTextApp
//
//  Created by David Bonnefoy on 2016-05-27.
//  Copyright © 2016 Hootsuite. All rights reserved.
//

import Foundation
import UIKit
import TokenUI

class ViewController: UIViewController {

    @IBOutlet weak var textInputContainer: UIView!
    fileprivate var tokenTextVC: TokenTextViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        tokenTextVC = TokenTextViewController()
        tokenTextVC.delegate = self
        addChildViewController(tokenTextVC)
        textInputContainer.addSubview(tokenTextVC.view)
        tokenTextVC.view.frame = textInputContainer.bounds
        tokenTextVC.didMove(toParentViewController: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tokenTextVC.text = "Hello "
        tokenTextVC.addToken(6, text: "Team")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let _ = tokenTextVC.becomeFirstResponder()
    }

}

extension ViewController: TokenTextViewControllerDelegate {

    func tokenTextViewDidChange(_ sender: TokenTextViewController) -> () {
    }

    func tokenTextViewShouldChangeTextInRange(_ sender: TokenTextViewController, range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sender.tokenizeAllEditableText()
            return false
        } else {
            return true
        }
    }

    func tokenTextViewDidSelectToken(_ sender: TokenTextViewController, tokenRef: TokenReference, fromRect rect: CGRect) -> () {
        let alert = UIAlertController(title: "Token Selected", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }

    func tokenTextViewDidDeleteToken(_ sender: TokenTextViewController, tokenRef: TokenReference) -> () {
        let alert = UIAlertController(title: "Token Deleted", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
            })
        present(alert, animated: true, completion: nil)
    }

    func tokenTextViewTextStorageIsUpdatingFormatting(_ sender: TokenTextViewController, text: String, searchRange: NSRange) -> [(attributes: [String:AnyObject], forRange: NSRange)] {
        return []
    }

    func tokenTextViewBackgroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor? {
        return UIColor.blue
    }

    func tokenTextViewShouldCancelEditingAtInsert(_ sender: TokenTextViewController, newText: String, inputText: String) -> Bool {
        return true
    }
}
