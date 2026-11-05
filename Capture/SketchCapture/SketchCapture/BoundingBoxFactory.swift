//
//  BoundingBoxFactory.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 03/05/2023.
//

import Foundation
import PencilKit

class BoundingBoxFactory {

    func boundingBoxes(for strokes: [PKStroke]) -> [BoundingBox] {
        var results: [BoundingBox] = []

        for stroke in strokes {
            let boundingBox = BoundingBox(strokes: [stroke], displayRect: stroke.renderBounds)
            results.append(boundingBox)
        }

        var containsOverlaps = true
        while containsOverlaps {
            containsOverlaps = false
            var interimResults: [BoundingBox] = []

            for i in 0..<results.count {
                guard i < results.count else { continue }
                var thisBox = results[i]
                let resultsCopy = results
                for otherBox in resultsCopy {
                    guard thisBox.displayRect != otherBox.displayRect else { continue }

                    if thisBox.displayRect.intersects(otherBox.displayRect) {
                        containsOverlaps = true
                        thisBox = BoundingBox(strokes: otherBox.strokes + thisBox.strokes, displayRect: thisBox.displayRect.union(otherBox.displayRect))
                        if let index = results.firstIndex(of: otherBox) {
                            results.remove(at: index)
                        }
                    }

                }

                interimResults.append(thisBox)
            }

            results = interimResults
        }

        return results
    }
}
