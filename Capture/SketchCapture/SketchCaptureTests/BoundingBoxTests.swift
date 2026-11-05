//
//  BoundingBoxTests.swift
//  SketchCaptureTests
//
//  Created by Daniel Leivers on 16/08/2023.
//

import XCTest
@testable import SketchCapture

final class BoundingBoxTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Bear in mind YOLO boxes are the CENTRE point and a width and height that are all relative to the full size between 0 and 1

    func testFullSize() throws {
        let relative = CGRect(x: 0.5, y: 0.5, width: 1, height: 1)
        let box = BoundingBox(displayRect: CGRect.zero, text: "test", relativeRect: relative)
        let display = box.displayRectFromRelative(for: CGSize(width: 100, height: 100))
        XCTAssertEqual(display, CGRect(x: 0, y: 0, width: 100, height: 100))
    }

//    func testFullSizeMin() throws {
//        let relative = CGRect(x: 0.0, y: 0.0, width: 1, height: 1)
//        let box = BoundingBox(displayRect: CGRect.zero, text: "test", relativeRect: relative)
//        let display = box.displayRectFromRelative(for: CGSize(width: 100, height: 100))
//        XCTAssertEqual(display, CGRect(x: 0, y: 0, width: 100, height: 100))
//    }

    func testHalfPositionHorizontalSize() throws {
        let relative = CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        let box = BoundingBox(displayRect: CGRect.zero, text: "test", relativeRect: relative)
        let display = box.displayRectFromRelative(for: CGSize(width: 100, height: 100))
        XCTAssertEqual(display, CGRect(x: 25, y: 25, width: 50, height: 50))

        let bigDisplay = box.displayRectFromRelative(for: CGSize(width: 200, height: 200))
        XCTAssertEqual(bigDisplay, CGRect(x: 50, y: 50, width: 100, height: 100))
    }

    func testTopSize() throws {
        let relative = CGRect(x: 0.5, y: 0.1, width: 1, height: 0.2)
        let box = BoundingBox(displayRect: CGRect.zero, text: "test", relativeRect: relative)
        let display = box.displayRectFromRelative(for: CGSize(width: 100, height: 100))
        XCTAssertEqual(display, CGRect(x: 0, y: 80, width: 100, height: 20))
    }

    func testBottomSize() throws {
        let relative = CGRect(x: 0.5, y: 0.8, width: 1, height: 0.2)
        let box = BoundingBox(displayRect: CGRect.zero, text: "test", relativeRect: relative)
        let display = box.displayRectFromRelative(for: CGSize(width: 100, height: 100))
        XCTAssertEqual(display, CGRect(x: 0, y: 10, width: 100, height: 20))
    }

    func testLeftSize() throws {
        let relative = CGRect(x: 0.2, y: 0.1, width: 0.2, height: 0.2)
        let box = BoundingBox(displayRect: CGRect.zero, text: "test", relativeRect: relative)
        let display = box.displayRectFromRelative(for: CGSize(width: 100, height: 100))
        XCTAssertEqual(display, CGRect(x: 10, y: 80, width: 20, height: 20))
    }

    func testReal() throws {
        let relative = CGRect(x: 0.10921971499919891, y: 0.79978683218359947, width: 0.15947014093399048, height: 0.068370230495929718)
        let box = BoundingBox(displayRect: CGRect.zero, text: "test", relativeRect: relative)
        let display = box.displayRectFromRelative(for: CGSize(width: 457, height: 930)) // 457 / 930
        XCTAssertEqual(display, CGRect(x: 47, y: 125, width: 76, height: 61))

        // Aiming for:
//        ▿ (47.0, 125.0, 76.0, 61.0)
//          ▿ origin : (47.0, 125.0)
//            - x : 47.0
//            - y : 125.0
//          ▿ size : (76.0, 61.0)
//            - width : 76.0
//            - height : 61.0

        // What we got:
//        ▿ (13.47448255121708, 154.40608888864517, 72.87785440683365, 63.58431436121464)
//          ▿ origin : (13.47448255121708, 154.40608888864517)
//            - x : 13.47448255121708
//            - y : 154.40608888864517
//          ▿ size : (72.87785440683365, 63.58431436121464)
//            - width : 72.87785440683365
//            - height : 63.58431436121464
    }
}
