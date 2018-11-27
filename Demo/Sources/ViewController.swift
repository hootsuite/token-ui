// Copyright © 2017 Hootsuite. All rights reserved.

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
        addChild(tokenTextVC)
        textInputContainer.addSubview(tokenTextVC.view)
        tokenTextVC.view.frame = textInputContainer.bounds
        tokenTextVC.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tokenTextVC.font = UIFont(name: "HelveticaNeue", size: 19)!
        tokenTextVC.text = "Hello "
        tokenTextVC.addToken(6, text: "Team")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = tokenTextVC.becomeFirstResponder()
    }

}

extension ViewController: TokenTextViewControllerDelegate {

    func tokenTextViewDidChange(_ sender: TokenTextViewController) {
    }

    func tokenTextViewShouldChangeTextInRange(_ sender: TokenTextViewController, range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sender.tokenizeAllEditableText()
            return false
        } else {
            return true
        }
    }

    func tokenTextViewDidSelectToken(_ sender: TokenTextViewController, tokenRef: TokenReference, fromRect rect: CGRect) {
        let alert = UIAlertController(title: "Token Selected", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }

    func tokenTextViewDidDeleteToken(_ sender: TokenTextViewController, tokenRef: TokenReference) {
        let alert = UIAlertController(title: "Token Deleted", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }

    func tokenTextViewTextStorageIsUpdatingFormatting(_ sender: TokenTextViewController, text: String, searchRange: NSRange) -> [(attributes: [NSAttributedString.Key: Any], forRange: NSRange)] {
        return []
    }

    func tokenTextViewBackgroundColourForTokenRef(_ sender: TokenTextViewController, tokenRef: TokenReference) -> UIColor? {
        return UIColor.blue
    }

    func tokenTextViewShouldCancelEditingAtInsert(_ sender: TokenTextViewController, newText: String, inputText: String) -> Bool {
        return true
    }
}
