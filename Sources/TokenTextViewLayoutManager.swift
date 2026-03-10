// Copyright © 2017 Hootsuite. All rights reserved.

import Foundation
import UIKit

class TokenTextViewLayoutManager: NSLayoutManager {

    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        UIColor.red.set()  // Testing: force red background
        for i in 0..<rectCount {
            let backgroundRect = rectArray[i]
            let path = UIBezierPath(rect: backgroundRect)
            path.fill()
        }
    }

}
