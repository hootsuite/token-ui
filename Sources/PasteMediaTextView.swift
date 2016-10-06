//
//  Copyright © 2016 Hootsuite. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

protocol PasteMediaTextViewPasteDelegate: class {
    func pasteMediaTextView(_: PasteMediaTextView, shouldAcceptContentOfType type: PasteboardItemType) -> Bool
    func pasteMediaTextView(_: PasteMediaTextView, didReceive items: [PasteboardItem])
}


public enum PasteboardItemType: String {
    case imageJpeg = "public.jpeg"
    case imagePng = "public.png"
    case imageGif = "com.compuserve.gif"

    static let allValues = [imageJpeg, imagePng, imageGif]
}

public struct PasteboardItem {
    public let type: PasteboardItemType
    public let data: Data
}

public class PasteMediaTextView: UITextView {

    weak var pasteDelegate: PasteMediaTextViewPasteDelegate?

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action ==  #selector(paste(_:)), pasteDelegate != nil, let acceptedTypes = acceptedTypes {
            if UIPasteboard.general.contains(pasteboardTypes: acceptedTypes.map { $0.rawValue }, inItemSet: nil) {
                return true
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }

    override public func paste(_ sender: Any?) {
        super.paste(sender)
        if let pasteDelegate = pasteDelegate, let acceptedTypes = acceptedTypes {
            var results: [PasteboardItem] = []
            for (index, item) in UIPasteboard.general.items.enumerated() {
                if let type = acceptedTypes.filter({ item[$0.rawValue] != nil }).first,
                    let data = UIPasteboard.general.data(forPasteboardType: type.rawValue, inItemSet: IndexSet([index]))?.first as? Data {
                    results.append(PasteboardItem(type: type, data: data))
                }
            }
            if !results.isEmpty {
                pasteDelegate.pasteMediaTextView(self, didReceive: results)
            }
        }
    }

    fileprivate var acceptedTypes: [PasteboardItemType]? {
        if let pasteDelegate = pasteDelegate {
            return PasteboardItemType.allValues.filter { pasteDelegate.pasteMediaTextView(self, shouldAcceptContentOfType: $0) }
        }
        return nil
    }

}
