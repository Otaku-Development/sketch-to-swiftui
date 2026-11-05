//
//  CGRectTests.swift
//  SketchCaptureTests
//
//  Created by Daniel Leivers on 22/09/2023.
//

import XCTest
@testable import SketchCapture

final class CGRectTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let relativeRect = 
    }

}

extension CGRect {
    static func createWithCentrePoint(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
