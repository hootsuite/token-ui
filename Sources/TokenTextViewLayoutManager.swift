// Copyright © 2017 Hootsuite. All rights reserved.

import Foundation
import UIKit

class TokenTextViewLayoutManager: NSLayoutManager {

    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        // FIXME: check attributes
        for i in 0..<rectCount {
            let backgroundRect = rectArray[i].insetBy(dx: -6, dy: 1)
            let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 20)
            path.fill()
            path.stroke()
        }
        color.set()
    }

}
