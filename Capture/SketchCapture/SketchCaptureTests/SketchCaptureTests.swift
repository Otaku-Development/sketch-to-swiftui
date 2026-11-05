//
//  SketchCaptureTests.swift
//  SketchCaptureTests
//
//  Created by Daniel Leivers on 09/08/2023.
//

import XCTest
import SwiftUI
@testable import SketchCapture

final class SketchCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

        let boundingBoxesString = "[{\"classification\":\"unknown\",\"text\":\"tabBar: 0.742608\",\"displayRect\":[[-3.669327437877655,832.06132885068655],[308.74816137552261,101.77421696484089]]},{\"classification\":\"unknown\",\"text\":\"button: 0.595413\",\"displayRect\":[[396.24838467128575,86.926448419690132],[22.568267431110144,24.625295251607895]]},{\"classification\":\"unknown\",\"text\":\"tabBar: 0.480837\",\"displayRect\":[[205.42025810480118,830.28066951781511],[247.26364398002625,104.89385090768337]]},{\"classification\":\"unknown\",\"text\":\"button: 0.340275\",\"displayRect\":[[34.529695838689804,317.31002166867256],[319.25510358810425,405.18162578344345]]},{\"classification\":\"unknown\",\"text\":\"navigationBar: 0.298619\",\"displayRect\":[[167.71511098742485,1.0443587601184845],[285.64567464590073,134.95448604226112]]}]"

//        let ouputBoundingBoxes: [BoundingBox]
        // Convert the JSON string to Data
        if let jsonData = boundingBoxesString.data(using: .utf8) {
            // Create a JSONDecoder instance
            let jsonDecoder = JSONDecoder()

            // Decode the JSON data to an array of BoundingBox objects
            do {
                let boundingBoxes = try jsonDecoder.decode([BoundingBox].self, from: jsonData)
                // You now have an array of BoundingBox objects
                for box in boundingBoxes {
                    print(box.displayRect) // Prints the displayRect of each bounding box
                }
//                let ouputBoundingBoxes = boundingBoxes
                XCTAssertEqual(boundingBoxes.count, 5)

                // TODO: Now try and turn this in to a SwiftUI view hierarchy...
                // i.e. make the magic happen!
                processDetectedElements(boundingBoxes: boundingBoxes)

            } catch {
                print("Error decoding BoundingBox array: \(error.localizedDescription)")
                XCTFail("Failed to decode JSON")
            }
        } else {
            print("Error converting JSON string to data")
            XCTFail("Failed to convert String to JSON")
        }
    }

    func processDetectedElements(boundingBoxes: [BoundingBox]) {
        let processedBoundingBoxes = preprocessBoundingBoxes(boundingBoxes: boundingBoxes)
        // TODO: Now generate the code

        let mainElements = processedBoundingBoxes.filter { $0.text?.hasPrefix("tabBar") == false && $0.text?.hasPrefix("navigationBar") == false }

        var views: [any View] = []
        for element in mainElements {
            switch element.text {
            case "button":
                let view = buttonForElement(boundingBox: element)
                views.append(view)
            default:
                continue
            }
        }

    }

    func buttonForElement(boundingBox: BoundingBox) -> some View {
        Button("Button") {
            print("Pressed button")
        }
            .position(x: boundingBox.displayRect.origin.x, y: boundingBox.displayRect.origin.y)
            .frame(width: boundingBox.displayRect.size.width, height: boundingBox.displayRect.size.height)
    }

    func preprocessBoundingBoxes(boundingBoxes: [BoundingBox]) -> [BoundingBox] {
        var processedBoundingBoxes: [BoundingBox] = []
        var remainingBoundingBoxes = boundingBoxes

        // 1. Deal with special cases
        // 1.1. Tab bar
        let tabBars = boundingBoxes.filter { $0.text?.hasPrefix("tabBar") == true }
        if tabBars.count > 1 {
            // A screen can only have 1 tabbar so we need to make this a single thing...
            let tabBar = BoundingBox.combineBoxes(tabBars, text: "tabBar", classification: .tabBar)
            processedBoundingBoxes.append(tabBar)
        }
        else if let tabBar = tabBars.first {
            processedBoundingBoxes.append(tabBar)
        }
        remainingBoundingBoxes.removeAll(where: { $0.text?.hasPrefix("tabBar") == true })

        // 1.2. Nav bar
        let navBars = boundingBoxes.filter { $0.text?.hasPrefix("navigationBar") == true }
        if navBars.count > 1 {
            // A screen can only have 1 tabbar so we need to make this a single thing...
            let navBar = BoundingBox.combineBoxes(navBars, text: "navigationBar", classification: .navigationBar)
            processedBoundingBoxes.append(navBar)
        }
        else if let navBar = navBars.first {
            processedBoundingBoxes.append(navBar)
        }
        remainingBoundingBoxes.removeAll(where: { $0.text?.hasPrefix("navigationBar") == true })

        // We could try and find any elements inside the nav bar
        // We could try and find any elements inside the tab bar
        // TODO: Process the other elements

        processedBoundingBoxes.append(contentsOf: remainingBoundingBoxes)

        return processedBoundingBoxes
    }

}
