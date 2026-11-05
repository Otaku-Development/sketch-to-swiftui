//
//  NavigationBarBoundingBox.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 15/09/2023.
//

import Foundation

class NavigationBarBoundingBox: BoundingBox {
    let leftBoundingBox: BoundingBox?
    let rightBoundingBox: BoundingBox?

    var hasLeftButton: Bool {
        get {
            return leftBoundingBox != nil
        }
    }

    var hasRightButton: Bool {
        get {
            return rightBoundingBox != nil
        }
    }

    init(from boundingBox: BoundingBox, left: BoundingBox?, right: BoundingBox?) {
        self.leftBoundingBox = left
        self.rightBoundingBox = right
        super.init(displayRect: boundingBox.displayRect, text: boundingBox.text ?? "NavigationBar", classification: boundingBox.classification, relativeRect: boundingBox.relativeRect, detectionConfidence: boundingBox.detectionConfidence)
        self.displayText = boundingBox.displayText
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

}
