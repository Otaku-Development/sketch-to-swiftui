//
//  BoundingBoxes.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 27/04/2023.
//

import SwiftUI
import PencilKit

struct BoundingBoxesView: View {
    let boxes: [BoundingBox]
    weak var delegate: BoundingBoxViewDelegate?

    var body: some View {
        ForEach(0..<boxes.count, id: \.self) { index in
            BoundingBoxView(boundingBox: boxes[index], delegate: delegate).zIndex(boxes[index].classification == .unknown ? 1: 0)
        }
    }
}

struct BoundingBoxes_Previews: PreviewProvider {
    static var previews: some View {
        BoundingBoxesView(boxes: [])
    }
}
