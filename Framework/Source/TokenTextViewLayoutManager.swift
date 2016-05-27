//
// Created by David Bonnefoy on 15-07-16.
// Copyright (c) 2015 Hootsuite Media Inc. All rights reserved.
//

import Foundation
import UIKit

class TokenTextViewLayoutManager: NSLayoutManager {

    override func fillBackgroundRectArray(rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        // FIXME: check attributes
        for i in 0..<rectCount {
            let backgroundRect = CGRectInset(rectArray[i], -6, 1)
            let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 20)
            path.fill()
            path.stroke()
        }
        color.set()
    }
}
