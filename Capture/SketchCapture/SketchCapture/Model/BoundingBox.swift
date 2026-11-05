//
//  BoundingBox.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 03/05/2023.
//

import Foundation
import PencilKit
import Vision

class BoundingBox: Hashable, Codable, Comparable {
    let strokes: [PKStroke]

    private(set) var displayRect: CGRect
    private(set) var relativeRect: CGRect
    @Published var classification: ElementClassification = .unknown
    let text: String?
    var displayText: String?
    var detectedClassification: ElementClassification = .unknown
    let detectionConfidence: VNConfidence

    private enum CodingKeys: String, CodingKey {
        case displayRect
        case relativeRect
        case classification
        case text
    }

    init(strokes: [PKStroke], displayRect: CGRect,  classification: ElementClassification = .unknown) {
        self.strokes = strokes
        self.displayRect = displayRect
        self.classification = classification
        self.text = nil
        self.relativeRect = displayRect
        self.detectionConfidence = 0
    }

    init(displayRect: CGRect, text: String, classification: ElementClassification = .unknown, strokes: [PKStroke] = [], relativeRect: CGRect, detectionConfidence: VNConfidence = 0) {
        self.strokes = strokes
        self.displayRect = displayRect
        self.classification = classification
        self.text = text
        self.relativeRect = relativeRect
        self.detectionConfidence = detectionConfidence
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        displayRect = try values.decode(CGRect.self, forKey: .displayRect)
        relativeRect = try values.decode(CGRect.self, forKey: .relativeRect)
        let classificationString = try values.decode(String.self, forKey: .classification)
        classification = ElementClassification(rawValue: classificationString) ?? .unknown
        text = try values.decode(String.self, forKey: .text)
        strokes = []
//                locationInText = try values.decode(Int.self, forKey: .locationInText)
        detectionConfidence = 0
    }

    func makeFullWidth() {
        relativeRect = CGRect(x: 0.5, y: relativeRect.origin.y, width: 1, height: relativeRect.size.height)
    }

    func updateRelativeRect(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil, desiredDisplayRect: CGRect? = nil) {
        relativeRect = CGRect(x: x ?? relativeRect.origin.x,
                              y: y ?? relativeRect.origin.y,
                              width: width ?? relativeRect.size.width,
                              height: height ?? relativeRect.size.height)
        if let desiredDisplayRect {
            displayRect = desiredDisplayRect
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(displayRect.width)
        hasher.combine(displayRect.height)
        hasher.combine(displayRect.origin.x)
        hasher.combine(displayRect.origin.y)
        hasher.combine(relativeRect.width)
        hasher.combine(relativeRect.height)
        hasher.combine(relativeRect.origin.x)
        hasher.combine(relativeRect.origin.y)
        hasher.combine(strokes.count)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayRect, forKey: .displayRect)
        try container.encode(relativeRect, forKey: .relativeRect)
        try container.encode(text, forKey: .text)
        try container.encode(classification.rawValue, forKey: .classification)
                // Handle encoding strokes manually, modify as needed
//                let strokesData = strokes.map { $0.dataRepresentation() }
//                try container.encode(strokesData, forKey: .strokes)
    }

    static func == (lhs: BoundingBox, rhs: BoundingBox) -> Bool {
        return lhs.displayRect.equalTo(rhs.displayRect) && lhs.relativeRect.equalTo(rhs.relativeRect) && lhs.strokes.count == rhs.strokes.count
    }

    static func combineBoxes(_ boxes: [BoundingBox], text: String, classification: ElementClassification, detectionConfidence: VNConfidence) -> BoundingBox {
        let strokes: [PKStroke] = boxes.reduce([]) { partialResult, box in
            partialResult + box.strokes
        }

        var rect = boxes.first?.displayRect ?? CGRect.zero
        var relativeRect = boxes.first?.relativeRect ?? CGRect.zero
        boxes.forEach { box in
            rect = rect.union(box.displayRect)
            relativeRect = relativeRect.union(box.relativeRect)
        }

        return BoundingBox(displayRect: rect, text: text, classification: classification, strokes: strokes, relativeRect: relativeRect, detectionConfidence: detectionConfidence)
    }

    func displayRectFromRelative(for size: CGSize) -> CGRect {
        return Self.displayRectFromRelative(for: size, relativeRect: relativeRect)
    }

    static func displayRectFromRelative(for size: CGSize, relativeRect: CGRect) -> CGRect {
        let width = size.width
        let height = size.height
        return CGRect(x: max(0, (relativeRect.origin.x - (relativeRect.size.width / 2.0)) * width),
                      y: max(0, (1.0 - relativeRect.origin.y - (relativeRect.size.height / 2.0)) * height),
                       width: relativeRect.size.width * width,
                       height: relativeRect.size.height * height)
//        return CGRect(x: ((relativeRect.origin.x - relativeRect.size.width) / 2.0) * width,
//                      y: (1.0 - (relativeRect.origin.y - relativeRect.size.height) / 2.0) * height,
//                       width: relativeRect.size.width * width,
//                       height: relativeRect.size.height * height)

    }

    func displayCentreRectFromRelative(for size: CGSize) -> CGRect {
        return Self.displayCentreRectFromRelative(for: size, relativeRect: relativeRect)
    }

    static func displayCentreRectFromRelative(for size: CGSize, relativeRect: CGRect) -> CGRect {
        let width = size.width
        let height = size.height
        return CGRect(x: (relativeRect.origin.x) * width,
                      y: (1.0 - relativeRect.origin.y - relativeRect.size.height) * height,
                       width: relativeRect.size.width * width,
                       height: relativeRect.size.height * height)
//        return CGRect(x: ((relativeRect.origin.x - relativeRect.size.width) / 2.0) * width,
//                      y: (1.0 - (relativeRect.origin.y - relativeRect.size.height) / 2.0) * height,
//                       width: relativeRect.size.width * width,
//                       height: relativeRect.size.height * height)

    }

    func contains(_ otherBoundingBox: BoundingBox) -> Bool {

        // TODO: Can we write a "contains" that uses the YOLO bounding box instead?

        return displayRect.contains(CGPoint(x: otherBoundingBox.displayRect.midX, y: otherBoundingBox.displayRect.midY))
    }

//    func overlaps(_ otherBoundingBox: BoundingBox) -> Bool {
//        return displayRect.intersects(CGPoint(x: otherBoundingBox.displayRect.midX, y: otherBoundingBox.displayRect.midY))
//    }

    static func < (lhs: BoundingBox, rhs: BoundingBox) -> Bool {
        return lhs.detectionConfidence < rhs.detectionConfidence
    }
}

