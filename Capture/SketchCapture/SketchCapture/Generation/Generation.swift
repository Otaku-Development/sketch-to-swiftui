//
//  Generation.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 11/08/2023.
//

import Foundation
import SwiftUI
import Vision

class Generation {
    private let detectionBoxes: [BoundingBox]
    private let drawingBoxes: [BoundingBox]
    private let inputImage: UIImage?
    private(set) var boxes: [BoundingBox] = []
    private let playgroundSize: CGSize

    init(detectionBoxes: [BoundingBox], drawingBoxes: [BoundingBox], image: UIImage?, playgroundSize: CGSize = CGSize(width: 400, height: 600)) {
        self.detectionBoxes = detectionBoxes
        self.drawingBoxes = drawingBoxes
        inputImage = image
        self.playgroundSize = playgroundSize
        //        boxes = processDetectedElements(boundingBoxes: boundingBoxes)
    }

    func process() async throws -> [BoundingBox] {
        return try await processDetectedElements(boundingBoxes: detectionBoxes)
    }

    func processString() async throws -> String {
        let processedBoxes = try await processDetectedElements(boundingBoxes: detectionBoxes)
        return generateCode(boundingBoxes: processedBoxes)
    }

    func processAll() async throws -> ([BoundingBox], String) {
        let processedBoxes = try await processDetectedElements(boundingBoxes: detectionBoxes)
        return (processedBoxes, generateCode(boundingBoxes: processedBoxes))
    }

    private func processDetectedElements(boundingBoxes: [BoundingBox], displaySize: CGSize? = nil) async throws -> [BoundingBox] {
        let preprocessedBoxes = preprocessBoundingBoxes(boundingBoxes: boundingBoxes)
        let processedBoundingBoxes = try await processBoundingBoxes(boundingBoxes: preprocessedBoxes)
        let detectedBoxes = processedBoundingBoxes
        return detectedBoxes
    }

    private func preprocessBoundingBoxes(boundingBoxes: [BoundingBox]) -> [BoundingBox] {
        // find which elements overlap each other and see if we can filter them out
        guard let size = inputImage?.size else { return boundingBoxes }

        /// 0 only run this on non-container type views
        let boxes = boundingBoxes.filter {
            $0.classification != .navigationBar && $0.classification != .tabBar
        }

        var groupedOverlaps: [Set<BoundingBox>] = []
        /// 1 Find all overlaps
        for box in boxes {

            //            let referenceRect = box.displayCentreRectFromRelative(for: size)
            let referenceRect = box.displayRect
            var overlappingRects: Set<BoundingBox> = []

            for otherBox in boxes {
                guard box != otherBox else { continue }
                //                let otherRect = otherBox.displayCentreRectFromRelative(for: size)
                let otherRect = otherBox.displayRect
                guard referenceRect.intersects(otherRect) else { continue }
                overlappingRects.insert(box)
                overlappingRects.insert(otherBox)
            }

            guard overlappingRects.count > 0 else { continue }
            groupedOverlaps.append(overlappingRects)
        }

        /// 2 Process the overlaps to decide which element should take precedent
        var excludedBoxes: Set<BoundingBox> = []
        var newBoxes: [BoundingBox] = []
        for overlap in groupedOverlaps {
            guard overlap.count > 0 else { continue }
            // For now just pick the biggest box
            // TODO: Should we do anything with confidence values here?
            let biggestBox = overlap.max { $0.detectionConfidence < $1.detectionConfidence }
//            let biggestBox = overlap.max { ($0.relativeRect.width * $0.relativeRect.height) < ($1.relativeRect.width * $1.relativeRect.height) }
            guard let biggestBox else { continue }

            var remainingBoxes = overlap.subtracting([biggestBox])
            remainingBoxes = remainingBoxes.filter {
                let intersection = biggestBox.displayRect.intersection($0.displayRect)
                // is the intersection any bigger than this second box?
                let horizontalIntersectionScale = intersection.width / $0.displayRect.width
                return horizontalIntersectionScale < 0.85
                //                let areaOfIntersection = (intersection.width * intersection.height) / ($0.displayRect.width * $0.displayRect.height)
                //                return areaOfIntersection < 0.7 // 50% or more of the box is outside of the overlap
                //                biggestBox.contains($0)
            }

            if remainingBoxes.count > 0 {
                // We need to make our biggestBox bigger!
                var engorgedBox = biggestBox.displayRect
                var engorgedRelativeBox = biggestBox.relativeRect
                remainingBoxes.forEach {
                    engorgedBox = engorgedBox.union($0.displayRect)
                    engorgedRelativeBox = combineRelativeRectangles(engorgedRelativeBox, $0.relativeRect)
                }
                //                biggestBox.displayRect.union($0.displayRect)
                // Calculate relative rect
                //                let combinedRelativeRect

                let newBox = BoundingBox(displayRect: engorgedBox,
                                         text: biggestBox.text!,
                                         classification: biggestBox.classification,
                                         relativeRect: engorgedRelativeBox,
                                         detectionConfidence: biggestBox.detectionConfidence)
                excludedBoxes.formUnion(overlap)
                newBoxes.append(newBox)
            }
            else {
                let boxesToExclude = overlap.subtracting([biggestBox])
                excludedBoxes.formUnion(boxesToExclude)
            }

        }
        
        var boxesToKeep = boundingBoxes.filter { !excludedBoxes.contains($0) }
        boxesToKeep.append(contentsOf: newBoxes)

        return boxesToKeep
    }

    func combineRelativeRectangles(_ rect1: CGRect, _ rect2: CGRect) -> CGRect {
        let minX = min(rect1.origin.x, rect2.origin.x)
        let minY = min(rect1.origin.y, rect2.origin.y)
        let maxX = max(rect1.origin.x + rect1.width, rect2.origin.x + rect2.width)
        let maxY = max(rect1.origin.y + rect1.height, rect2.origin.y + rect2.height)

        let combinedWidth = maxX - minX
        let combinedHeight = maxY - minY

        let centerX = minX + combinedWidth / 2.0
        let centerY = minY + combinedHeight / 2.0

        return CGRect(x: centerX - combinedWidth / 2.0, y: centerY - combinedHeight / 2.0, width: combinedWidth, height: combinedHeight)
    }

    private func processBoundingBoxes(boundingBoxes: [BoundingBox]) async throws -> [BoundingBox] {
        let displaySize = inputImage?.size
        var processedBoundingBoxes: [BoundingBox] = []
        var remainingBoundingBoxes = boundingBoxes

        // 1. Deal with special cases
        // 1.1. Tab bar
        //        let tabBars = boundingBoxes.filter { $0.text?.hasPrefix("tabBar") == true }
        let tabBars = remainingBoundingBoxes.filter { $0.classification == .tabBar }
        if tabBars.count > 0 {
            let tabBar: BoundingBox
            if tabBars.count > 1 {
                // A screen can only have 1 tabbar so we need to make this a single thing...
                let confidence = tabBars.max(by: { $0.detectionConfidence < $1.detectionConfidence })?.detectionConfidence
                tabBar = BoundingBox.combineBoxes(tabBars, text: "tabBar", classification: .tabBar, detectionConfidence: confidence ?? 0)
            }
            else {
                tabBar = tabBars.first!
            }
            tabBar.updateRelativeRect(x: 0, width: 1) // We want it full width and at the bottom!
            processedBoundingBoxes.append(tabBar)

            var tabBarItems: Set<BoundingBox> = []
            for box in remainingBoundingBoxes {
                //                guard box.text?.hasPrefix("tabBar") == false else { continue }
                guard box.classification != .tabBar else { continue }
                guard tabBar.contains(box) else { continue }
                print("Found in tab bar: \(box)")
                tabBarItems.insert(box)
            }

            print("What tab bar items we got? \(tabBarItems)")

            remainingBoundingBoxes.removeAll { tabBarItems.contains($0) }

            // TODO: process tabBarItems and add them in (i.e. are there 2? 3? 4? Only icons?)
        }

        //        remainingBoundingBoxes.removeAll(where: { $0.text?.hasPrefix("tabBar") == true })
        remainingBoundingBoxes.removeAll(where: { $0.classification == .tabBar })

        // 1.2. Nav bar
        let navBars = remainingBoundingBoxes.filter { $0.classification == .navigationBar }
        if navBars.count > 0 {
            let navBar: BoundingBox
            if navBars.count > 1 {
                // A screen can only have 1 tabbar so we need to make this a single thing...
                let confidence = navBars.max(by: { $0.detectionConfidence < $1.detectionConfidence })?.detectionConfidence
                navBar = BoundingBox.combineBoxes(navBars, text: "navigationBar", classification: .navigationBar, detectionConfidence: confidence ?? 0)
            }
            else {
                navBar = navBars.first!
            }

            // Check our confidence
            if navBar.detectionConfidence > 0.3 && navBar.displayRect.origin.y < 50 {
                if let displaySize {
                    navBar.updateRelativeRect(x: 0, y: 1 - (navBar.relativeRect.size.height), width: 1, desiredDisplayRect: CGRect(x: 0, y: 0, width: displaySize.width, height: navBar.relativeRect.size.height * displaySize.height)) // We want it full width and at the top!
                }
                else {
                    navBar.updateRelativeRect(x: 0, y: 1 - (navBar.relativeRect.size.height), width: 1) // We want it full width and at the top!
                }

                var navBarItems: Set<BoundingBox> = []
                for box in boundingBoxes {
                    guard box.classification != .navigationBar else { continue }
                    guard navBar.contains(box) else { continue }
                    navBarItems.insert(box)
                }
                remainingBoundingBoxes.removeAll { navBarItems.contains($0) }
                // TODO: process navBarItems and add them in (i.e. are there 2? 3? 4? Only icons?)

                // Find the left/right-most item...
                var leftMostItem: BoundingBox? = nil
                var rightMostItem: BoundingBox? = nil
                var centreMostItem: BoundingBox? = nil
                for item in navBarItems {
                    guard
                        let left = leftMostItem,
                        let right = rightMostItem,
                        let centre = centreMostItem
                    else {
                        leftMostItem = item
                        rightMostItem = item
                        centreMostItem = item
                        continue
                    }

                    if item.displayRect.minX < left.displayRect.minX {
                        leftMostItem = item
                    }

                    if item.displayRect.maxX > right.displayRect.maxX {
                        rightMostItem = item
                    }

                    if abs(item.displayRect.midX - navBar.displayRect.midX) <
                        abs(centre.displayRect.midX - navBar.displayRect.midX) &&
                        item.classification == .label {
                        centreMostItem = item
                    }
                }

                if leftMostItem == centreMostItem, let centre = centreMostItem {
                    let widthToCentre = navBar.displayRect.width / 2
                    let leftDistance = centre.displayRect.midX - 0
                    let rightDistance = widthToCentre - centre.displayRect.midX
                    if leftDistance < rightDistance {
                        centreMostItem = nil
                    }
                    else {
                        leftMostItem = nil
                    }
                }

                if rightMostItem == centreMostItem, let centre = centreMostItem {
                    let leftDistance = centre.displayRect.midX - navBar.displayRect.midX
                    let rightDistance = navBar.displayRect.width - centre.displayRect.midX
                    if leftDistance < rightDistance {
                        rightMostItem = nil
                    }
                    else {
                        centreMostItem = nil
                    }
                }

                if let left = leftMostItem, leftMostItem?.classification == .label {
                    let detectedText = try await detectTextIn(box: left)
                    left.displayText = detectedText
                }

                if let centre = centreMostItem, centreMostItem?.classification == .label {
                    let detectedText = try await detectTextIn(box: centre)
                    centre.displayText = detectedText
                    navBar.displayText = detectedText
                }

                if let right = rightMostItem, rightMostItem?.classification == .label {
                    let detectedText = try await detectTextIn(box: right)
                    right.displayText = detectedText
                }

                let navigationBar = NavigationBarBoundingBox(from: navBar, left: leftMostItem, right: rightMostItem)
                processedBoundingBoxes.append(navigationBar)
            }
            else {
                print("We found a navBar but with odd confidence or position: \(navBar.detectionConfidence), \(navBar.displayRect)")
            }
        }
        remainingBoundingBoxes.removeAll(where: { $0.classification == .navigationBar })

        // 1.3 Labels
        //        let labels = boundingBoxes.filter { $0.text?.hasPrefix("label") == true }
        let labels = remainingBoundingBoxes.filter { $0.classification == .label }
        if labels.count > 0 {
            for label in labels {
                guard let detectedText = try await detectTextIn(box: label) else { continue }
                label.displayText = detectedText
            }

            var duplicates: Set<BoundingBox> = []
            for label in labels {
                guard !duplicates.contains(label) else { continue }
                var potentialDuplicates = labels.filter { $0 != label && $0.displayText == label.displayText && $0.displayRect.intersects(label.displayRect) }
                let bestDuplicate = potentialDuplicates.max()

                if let bestDuplicate, bestDuplicate.detectionConfidence > label.detectionConfidence {
                    potentialDuplicates = labels.filter { $0 != bestDuplicate }
                    potentialDuplicates.append(label)
                    processedBoundingBoxes.append(bestDuplicate)
                }
                else {
                    processedBoundingBoxes.append(label)
                }

                duplicates.formUnion(potentialDuplicates)
            }

            remainingBoundingBoxes.removeAll(where: { $0.classification == .label })
        }

        // 1.4 Buttons
        //        let buttons = boundingBoxes.filter { $0.text?.hasPrefix("button") == true }
        let buttons = remainingBoundingBoxes.filter { $0.classification == .button }
        if buttons.count > 0 {
            for button in buttons {
                guard let detectedText = try await detectTextIn(box: button) else { continue }
                button.displayText = detectedText
            }

            var duplicates: Set<BoundingBox> = []
            for button in buttons {
                guard !duplicates.contains(button) else { continue }
                var potentialDuplicates = buttons.filter { $0 != button && $0.displayText == button.displayText && $0.displayRect.intersects(button.displayRect) }
                let bestDuplicate = potentialDuplicates.max()

                if let bestDuplicate, bestDuplicate.detectionConfidence > button.detectionConfidence {
                    potentialDuplicates = buttons.filter { $0 != bestDuplicate }
                    potentialDuplicates.append(button)
                    processedBoundingBoxes.append(bestDuplicate)
                }
                else {
                    processedBoundingBoxes.append(button)
                }

                duplicates.formUnion(potentialDuplicates)
            }

            remainingBoundingBoxes.removeAll(where: { $0.classification == .button })
        }

        // We could try and find any elements inside the nav bar
        // We could try and find any elements inside the tab bar
        // TODO: Process the other elements

        let textFields = remainingBoundingBoxes.filter { $0.classification == .textField }
        if textFields.count > 0 {
            var duplicates: Set<BoundingBox> = []
            for textField in textFields {
                guard !duplicates.contains(textField) else { continue }
                var potentialDuplicates = textFields.filter { $0 != textField && $0.displayRect.intersects(textField.displayRect) }
                let bestDuplicate = potentialDuplicates.max()

                if let bestDuplicate, bestDuplicate.detectionConfidence > textField.detectionConfidence {
                    potentialDuplicates = textFields.filter { $0 != bestDuplicate }
                    potentialDuplicates.append(textField)
                    processedBoundingBoxes.append(bestDuplicate)
                }
                else {
                    processedBoundingBoxes.append(textField)
                }

                duplicates.formUnion(potentialDuplicates)
            }

            remainingBoundingBoxes.removeAll(where: { $0.classification == .textField })
        }

        let switchButtons = remainingBoundingBoxes.filter { $0.classification == .switchButton }
        if switchButtons.count > 0 {
            var duplicates: Set<BoundingBox> = []
            for switchButton in switchButtons {
                guard !duplicates.contains(switchButton) else { continue }
                var potentialDuplicates = switchButtons.filter { $0 != switchButton && $0.displayRect.intersects(switchButton.displayRect) }
                let bestDuplicate = potentialDuplicates.max()

                if let bestDuplicate, bestDuplicate.detectionConfidence > switchButton.detectionConfidence {
                    potentialDuplicates = switchButtons.filter { $0 != bestDuplicate }
                    potentialDuplicates.append(switchButton)
                    processedBoundingBoxes.append(bestDuplicate)
                }
                else {
                    processedBoundingBoxes.append(switchButton)
                }

                duplicates.formUnion(potentialDuplicates)
            }

            remainingBoundingBoxes.removeAll(where: { $0.classification == .switchButton })
        }

        let segmentedControls = remainingBoundingBoxes.filter { $0.classification == .segmentedControl }
        if segmentedControls.count > 0 {
            var duplicates: Set<BoundingBox> = []
            for segmentedControl in segmentedControls {
                guard !duplicates.contains(segmentedControl) else { continue }
                var potentialDuplicates = segmentedControls.filter { $0 != segmentedControl && $0.displayRect.intersects(segmentedControl.displayRect) }
                let bestDuplicate = potentialDuplicates.max()

                if let bestDuplicate, bestDuplicate.detectionConfidence > segmentedControl.detectionConfidence {
                    potentialDuplicates = segmentedControls.filter { $0 != bestDuplicate }
                    potentialDuplicates.append(segmentedControl)
                    processedBoundingBoxes.append(bestDuplicate)
                }
                else {
                    processedBoundingBoxes.append(segmentedControl)
                }

                duplicates.formUnion(potentialDuplicates)
            }

            remainingBoundingBoxes.removeAll(where: { $0.classification == .segmentedControl })
        }

        // Size processing...


        processedBoundingBoxes.append(contentsOf: remainingBoundingBoxes)

        return processedBoundingBoxes
    }

    private func detectTextIn(box: BoundingBox) async throws -> String? {
        guard let originalImage = inputImage else { return nil }
        guard let croppedImage = cropBoxFromImage(box: box, image: originalImage) else { return nil }
        let text = try await detectText(image: croppedImage)
        return text
    }

    private func cropBoxFromImage(box: BoundingBox, image: UIImage) -> UIImage? {
        let targetRect2 = box.displayCentreRectFromRelative(for: image.size)
        let testImage2 = image.cropToRect(rect: targetRect2)
        return testImage2
    }

    //    private func findElementsInsideNavigationBar(navBar: BoundingBox, elements: )

    private func detectText(image: UIImage) async throws -> String? {
        return try await withCheckedThrowingContinuation({ continuation in
            let request = VNRecognizeTextRequest { recognizeTextRequest, error in
                print("What we got? \(recognizeTextRequest), \(error)")
                guard let observations =
                        recognizeTextRequest.results as? [VNRecognizedTextObservation] else {
                    return
                }
                let recognizedStrings = observations.map { observation in
                    // Return the string of the top VNRecognizedText instance.
                    print("Top candidate: \(observation.topCandidates(1).first?.string)")
                    return observation.topCandidates(1).first?.string
                }.compactMap { $0 }

                continuation.resume(returning: recognizedStrings.first)
                //            recognizedStrings.first
            }

            let requests = [request]

            DispatchQueue.global(qos: .userInitiated).async {
                guard let img = image.cgImage else {
                    continuation.resume(returning: nil)
                    return
                }

                let handler = VNImageRequestHandler(cgImage: img, options: [:])
                try? handler.perform(requests)
            }
        })

        //        func recognizeTextHandler(request: VNRequest, error: Error?) {
    }

    //    private func uploadImage(storageRef: StorageReference, image: UIImage, metadata: StorageMetadata?) async throws -> URL {
    //        return try await withCheckedThrowingContinuation({ continuation in
    //            uploadImage(storageRef: storageRef, image: image, metadata: metadata) { result in
    //                continuation.resume(with: result)
    //            }
    //        })
    //    }

    private let tabBarCode =
        """
        struct TabContainerView: View {
            var body: some View {
                TabView {
                    %@
                    .tabItem {
                        Label("Menu", systemImage: "list.dash")
                    }

                    %@
                    .tabItem {
                        Label("Order", systemImage: "square.and.pencil")
                    }

                    %@
                    .tabItem {
                        Label("Order", systemImage: "person")
                    }
                }
            }
        }
        """

    private let navigationBarLeftButton =
        """
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                print("Custom Action")
            } label: {
                HStack {
                    Image(systemName: "chevron.backward")
                    Text("Back")
                }
            }
            .tint(.white)
        }
        """

    private let navigationBarRightButton =
        """
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                print("Custom Action")
            } label: {
                HStack {
                    Text("Done")
                }
            }
            .tint(.white)
        }
        """

    private let navigationBarCode =
        """
        struct NavigationView: View {
            var body: some View {
                NavigationStack {
                    ContentView()
                    .navigationTitle("%@")
                    %@
                    .toolbarBackground(
                        Color.cyan,
                        for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        """

    let contentViewCode =
    """
    struct ContentView: View {
        @State private var showingAlert = false
        @State private var textFieldBinding: String = ""

        var body: some View {
            ZStack {
                %@
            }
        }
    }
    """

    let playgroundLivePreview = "PlaygroundPage.current.setLiveView(%@)"

    let imports =
    """
    import SwiftUI
    import PlaygroundSupport
    """

    private func generateCode(boundingBoxes: [BoundingBox]) -> String {
        let actualFrameSize = playgroundSize
        var contentsOfView = ""
        var hasTabBar = false
        var filledNavigationBar: String?

        for box in boundingBoxes {
            if box.classification == .navigationBar, let navBox = box as? NavigationBarBoundingBox {
                // Construct tool bar
                var toolBarString =
                """
                .toolbar {
                    %@
                }
                """
                if navBox.hasLeftButton && navBox.hasRightButton {
                    toolBarString = String(format: toolBarString, navigationBarLeftButton + "\n" + navigationBarRightButton)
                }
                else if navBox.hasLeftButton {
                    toolBarString = String(format: toolBarString, navigationBarLeftButton)
                }
                else if navBox.hasRightButton {
                    toolBarString = String(format: toolBarString, navigationBarRightButton)
                }
                else {
                    toolBarString = ""
                }

                filledNavigationBar = String(format: navigationBarCode, box.displayText ?? "Title", toolBarString)
            }
            if box.classification == .button {
                let button = buttonForElement(boundingBox: box, size: actualFrameSize)
                contentsOfView.append(button)
                contentsOfView.append("\n")
            }
            if box.classification == .label {
                let label = labelForElement(boundingBox: box, size: actualFrameSize)
                contentsOfView.append(label)
                contentsOfView.append("\n")
            }
            if box.classification == .tabBar {
                hasTabBar = true
            }
            if box.classification == .image {
                let image = imageForElement(boundingBox: box, size: actualFrameSize)
                contentsOfView.append(image)
                contentsOfView.append("\n")
            }
            if box.classification == .textField {
                let textField = textFieldForElement(boundingBox: box, size: actualFrameSize)
                contentsOfView.append(textField)
                contentsOfView.append("\n")
            }
        }

        let sizeSpecification = ".frame(width: \(playgroundSize.width), height: \(playgroundSize.height))"
        let contentView = String(format: contentViewCode, contentsOfView)
        let playgroundPreview: String
        if hasTabBar, let filledNavigationBar {
            playgroundPreview = String(format: playgroundLivePreview, "TabContainerView()\(sizeSpecification)")
            let tabBar = String(format: tabBarCode, "NavigationView()", "NavigationView()", "NavigationView()")
            return imports + "\n\n" + tabBar + "\n\n" + filledNavigationBar + "\n\n" + contentView + "\n\n" + playgroundPreview
        }
        else if hasTabBar {
            playgroundPreview = String(format: playgroundLivePreview, "TabContainerView()\(sizeSpecification)")
            let tabBar = String(format: tabBarCode, "ContentView()", "ContentView()", "ContentView()")
            return imports + "\n\n" + tabBar + "\n\n" + contentView + "\n\n" + playgroundPreview
        }
        else if let filledNavigationBar {
            playgroundPreview = String(format: playgroundLivePreview, "NavigationView()\(sizeSpecification)")
            return imports + "\n\n" + filledNavigationBar + "\n\n" + contentView + "\n\n" + playgroundPreview
        }
        else {
            playgroundPreview = String(format: playgroundLivePreview, "ContentView()\(sizeSpecification)")
            return imports + "\n\n" + contentView + "\n\n" + playgroundPreview
        }
    }

    func buttonForElement(boundingBox: BoundingBox, size: CGSize) -> String {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
        return """
        Button(action: {
            showingAlert = true
        }) {
            Text("\(boundingBox.displayText ?? "Button")").frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert("Button pressed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .buttonStyle(.borderedProminent)
        .frame(width: \(actualRect.width),
               height: \(actualRect.height))
        .position(x: \(actualRect.midX), y: \(actualRect.midY))
        """
    }

    func labelForElement(boundingBox: BoundingBox, size: CGSize) -> String {
        if let text = boundingBox.displayText {
            let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
            return
                """
                Text("\(text)")
                .font(.largeTitle)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .lineLimit(1)
                .frame(width: \(actualRect.width),
                       height: \(actualRect.height))
                    .border(.red)
                .position(x: \(actualRect.midX), y: \(actualRect.midY))
                """
        }
        else {
            let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
            let placeholderText = """
                Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
                """

            return """
            Text("\(placeholderText)")
            .frame(width: \(actualRect.width),
                   height: \(actualRect.height))
            .border(.red)
            .position(x: \(actualRect.midX), y: \(actualRect.midY))
            """
        }
    }

    func imageForElement(boundingBox: BoundingBox, size: CGSize) -> String {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)

        let imageString = """
        Image(uiImage: UIImage(named: "image_ux")!)
        .resizable(resizingMode: .stretch)
        .frame(width: \(actualRect.width),
               height: \(actualRect.height))
        .position(x: \(actualRect.midX), y: \(actualRect.midY))
        """
        return imageString
    }

    func textFieldForElement(boundingBox: BoundingBox, size: CGSize) -> String {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)

        let imageString = """
        TextField("", text: $textFieldBinding)
        .frame(width: \(actualRect.width),
               height: \(actualRect.height))
        .border(.black)
        .position(x: \(actualRect.midX), y: \(actualRect.midY))
        """
        return imageString
    }

//    @ViewBuilder
//    func textFieldForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
//        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
//        TextField("", text: $textFieldBinding)
////        .resizable(resizingMode: .stretch)
//        .frame(width: actualRect.width,
//               height: actualRect.height)
//        .border(.black)
//        .position(x: actualRect.midX, y: actualRect.midY)
//        .cornerRadius(5)
//    }

    static func createFromJSON(_ json: String) -> Generation? {
        guard let jsonData = json.data(using: .utf8) else { return nil }
        let jsonDecoder = JSONDecoder()
        do {
            let boundingBoxes = try jsonDecoder.decode([BoundingBox].self, from: jsonData)
            return Generation(detectionBoxes:boundingBoxes, drawingBoxes: [], image: nil)
        } catch {
            print("Error decoding BoundingBox array: \(error.localizedDescription)")
            return  nil
        }
    }

}

extension UIImage {

    func cropToRect(rect: CGRect!) -> UIImage? {

        let scaledRect = CGRect(x: rect.origin.x * self.scale, y: rect.origin.y * self.scale, width: rect.size.width * self.scale, height: rect.size.height * self.scale);


        guard let imageRef: CGImage = self.cgImage?.cropping(to:scaledRect)
        else {
            return nil
        }

        let croppedImage: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return croppedImage
    }
}
