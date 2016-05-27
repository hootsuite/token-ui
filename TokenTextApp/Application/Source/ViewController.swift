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

    override func viewDidLoad() {
        super.viewDidLoad()
        let tokenTextVC = TokenTextViewController()
        addChildViewController(tokenTextVC)
        view.addSubview(tokenTextVC.view)
        tokenTextVC.view.frame = self.view.bounds
        tokenTextVC.didMoveToParentViewController(self)
    }

}
