//
//  DrawingView.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 27/04/2023.
//

import SwiftUI
import PencilKit
import FirebaseStorage
import FirebaseDatabase
import Vision
import UniformTypeIdentifiers

class FirebaseError: Error {
    
}

struct DrawingView: View {
    enum Preview {
        case none
        case generated
        case generatedCode
    }

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ViewModel

    @State private var saving = false
    @State private var showSaveFailedAlert = false
    @State private var showCloseAlert = false
    @State private var combineElements = false
    @State private var showCombineElementsAlert = false
    @State private var showElementValidation = false
    @State private var showMLVision = false
    @State private var canvasView = PKCanvasView()

    @State private var selectedBoxes: [BoundingBox] = []

    @State private var showingPreview: Preview = .none
//    @State private var showingGeneratedCode = false

    @State private var showingExporter = false


    private var image: UIImage {
        guard let imagePath = viewModel.imageUrl?.relativePath,
              let image = UIImage(contentsOfFile: imagePath) else {
            return UIImage(named: "test-screenshot")!
        }
        return image
    }

    var body: some View {
        LoadingView(isShowing: $saving) {
            ZStack {
                NavigationView {
                    HStack {
                        drawingStack.frame(maxWidth: .infinity)
                        if showingPreview == .none && viewModel.isCapture {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .mask({
                                    RoundedRectangle(cornerRadius: 20)
                                })
                                .overlay(
                                    GeometryReader { geo in
                                        Image("iphone-mockup")
                                            .resizable(resizingMode: .stretch)
                                            .foregroundColor(.clear)
                                            .frame(width: geo.size.width + 40, height: geo.size.height + 40)
                                            .offset(x: -20, y: -20)

                                    }
                                )
                                .padding(20)
                                .background(Color.gray.opacity(0.5))
                        }
                        else if showingPreview == .generated {
//                            GeneratedView(viewModel: GeneratedViewViewModel(rawVisionBoxes: viewModel.visionBoundingBoxes, drawingBoxes: viewModel.boundingBoxes, inputImage: viewModel.lastDetectionImage))
                            GeneratedView(viewModel: GeneratedViewViewModel(detectedBoundingBoxes: viewModel.processedBoxes))
                        }
                        else if showingPreview == .generatedCode {
//                            Text(AttributedString("Code shows here"))
                            GeneratedCodeView(code: viewModel.codeText)
                                .frame(maxWidth: 456, maxHeight: .infinity)
                                .border(.blue, width: 4)
                                .environmentObject(viewModel)
                        }
                    }
                    .navigationBarTitle(Text("Sketch Capture"), displayMode: .inline)
                    .navigationBarItems(
                        leading: HStack {
                            Button {
                                self.showCloseAlert = true
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .alert("Choose one of the following actions.",
                                   isPresented: $showCloseAlert) {
                                Button("Save it ✅") {
                                    saveDrawing() {
                                        dismiss()
                                    }
                                }
                                Button(role: .destructive) {
                                    dismiss()
                                } label: {
                                    Text("Delete it! 🗑️")
                                }
                            }
                            Button(action: toggleElementValidation) {
                                Image(systemName: "questionmark.square.dashed")
                            }
                            if viewModel.boundingBoxes.count > 0 && showElementValidation {
                                Button() {
                                    self.combineElements = !self.combineElements
                                } label: {
                                    Image(systemName: "lasso.and.sparkles")
                                }
                            }

                            Button(action: toggleMLVision) {
                                if showMLVision {
                                    Image(systemName: "eye.fill")
                                }
                                else {
                                    Image(systemName: "eye")
                                }
                            }

                            Button(action: togglePreview) {
                                if showingPreview == .generated {
                                    Image(systemName: "doc.richtext.fill")
                                }
                                else {
                                    Image(systemName: "doc.richtext")
                                }
                            }

                            Button(action: toggleCodePreview) {
                                if showingPreview == .generatedCode {
                                    Image(systemName: "doc.append.fill")
                                }
                                else {
                                    Image(systemName: "doc.append")
                                }
                            }
                        },
                        trailing: HStack {
                            Button(action: shareDrawing) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Button("Export") {
                                showingExporter = true
                            }
                            .fileExporter(isPresented: $showingExporter, document: viewModel.document, contentType: UTType(exportedAs: "com.apple.dt.playground")) { result in
                                switch result {
                                case .success(let url):
                                    print("Saved to \(url)")
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }
                            }
                            Link("Playgrounds", destination: URL(string: "x-com-apple-playgrounds://")!)
                        })
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.large)
            }
            .alert("Save failed, please try again", isPresented: $showSaveFailedAlert) {
                Button("OK", role: .cancel) {
                    showSaveFailedAlert = false
                }
            }

        }
    }

    @State var dragViewState = CGRect.zero

    var drawingStack: some View {
        ZStack {
            Image("iphone-mockup")
                .resizable()
                .scaledToFit()
                .allowsHitTesting(false)
                .overlay {
                    GeometryReader { geo in
                        ZStack {
                            CanvasView(canvasView: $canvasView, onChanged: drawingChanged).disabled(showElementValidation)
                            if viewModel.boundingBoxes.count > 0 && showElementValidation {
                                BoundingBoxesView(boxes: viewModel.boundingBoxes, delegate: viewModel)
                            }
                            if viewModel.visionBoundingBoxes.count > 0 && showMLVision {
                                BoundingBoxesView(boxes: viewModel.visionBoundingBoxes, delegate: viewModel).border(.blue, width: 5)
                            }
                            if self.combineElements {
                                Rectangle().fill(.white.opacity(0.4)).frame(width: geo.size.width, height: geo.size.height).border(.indigo).gesture(
                                                                            DragGesture()
                                                                                .onChanged { gesture in
                                                                                    let width = max(gesture.startLocation.x, gesture.location.x) - min(gesture.startLocation.x, gesture.location.x)
                                                                                    let height = max(gesture.startLocation.y, gesture.location.y) - min(gesture.startLocation.y, gesture.location.y)
                                                                                    let x = gesture.location.x + ((gesture.startLocation.x - gesture.location.x) / 2.0)
                                                                                    let y = gesture.location.y + ((gesture.startLocation.y - gesture.location.y) / 2.0)

                                                                                    dragViewState = CGRect(x: x, y: y, width: width, height: height)
                                                                                    combineDragging(draggedRect: dragViewState)
                                                                                }
                                                                                .onEnded { _ in
                                                                                    self.combineElements = false
                                                                                    combineDragEnded(draggedRect: dragViewState)
                                                                                    dragViewState = .zero
                                                                                }
                                                                        )
                                Rectangle().fill(.clear).border(.gray).frame(width: dragViewState.width, height: dragViewState.height).position(x: dragViewState.origin.x, y: dragViewState.origin.y)
                                ForEach(selectedBoxes, id: \.self) { selectedBox in
                                    Rectangle().fill(.blue).frame(width: selectedBox.displayRect.width,
                                                                  height: selectedBox.displayRect.height).position(x: selectedBox.displayRect.midX, y: selectedBox.displayRect.midY)
                                }

                            }
                            Image("iphone-mockup")
                                .resizable()
                                .scaledToFit()
                                .allowsHitTesting(false)
//                                .backgroundStyle(.blue)
                        }.alert("Combine?", isPresented: $showCombineElementsAlert) {
                            Button("Combine") {
                                viewModel.combineBoxes(selectedBoxes)
                                selectedBoxes = []
                            }
                            Button("Cancel") {
                                selectedBoxes = []
                            }
                        }
                    }
                }
        }
    }
}

struct DrawingView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingView(viewModel: DrawingView.ViewModel(startingSketch: StartingSketch(localImage: nil), userStatement: UserStatement(name: nil, hasAgreedToTerms: true, hasRequestedDebrief: false, hasAgreedToEvaluation: false)))
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}

// MARK: - Private Methods
private extension DrawingView {

    func combineDragging(draggedRect: CGRect) {
        selectedBoxes = []
        findSelectedBoxes(draggedRect: draggedRect)
    }

    func combineDragEnded(draggedRect: CGRect) {
        findSelectedBoxes(draggedRect: draggedRect)

        if selectedBoxes.count > 1 {
            self.showCombineElementsAlert = true
        }
    }

    private func findSelectedBoxes(draggedRect: CGRect) {
        let correctedRect = CGRect(x: draggedRect.origin.x - draggedRect.width / 2.0, y: draggedRect.origin.y - draggedRect.height / 2.0, width: draggedRect.width, height: draggedRect.height)
        for box in viewModel.boundingBoxes {
            if box.classification == .unknown && box.displayRect.intersects(correctedRect) {
                selectedBoxes.append(box)
            }
        }
    }

    func drawingChanged() {
//        viewModel.updateBoundingBoxes(canvasView.drawing)
        viewModel.queueRecognition(canvasView: canvasView)
    }

    func saveDrawing(completion: @escaping ()->()) {
        saving = true
        Task {
            defer {
                saving = false
            }

            do {
                try await viewModel.save(canvasView)
                completion()
            }
            catch {
                // TODO: Show error and ask to try again!
                print("Save failed \(error)")
                showSaveFailedAlert = true
            }
        }
    }

    func shareDrawing() {
        let scale = UIScreen.screens.first?.scale ?? 1.0
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: scale).withBackground(color: .white)

        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let vc = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if UIDevice.current.userInterfaceIdiom == .pad {
            // otherwise iPad crashes
            let activeScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            let rootViewController = (activeScene?.windows ?? []).first(where: { $0.isKeyWindow })?.rootViewController
            vc.popoverPresentationController?.sourceView = rootViewController?.view
            vc.popoverPresentationController?.sourceRect = .zero
        }

        windowScene?.keyWindow?.rootViewController?.present(vc, animated: true, completion: nil)
    }

    func shareDrawing2() {
            Task {
                let scale = UIScreen.screens.first?.scale ?? 1.0
                let image = canvasView.drawing.image(from: canvasView.bounds, scale: scale).withBackground(color: .white)

//                if let screenshot = await takeScreenshot() {
                    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        // otherwise iPad crashes
                        let thisViewVC = UIHostingController(rootView: self)
                        activityVC.popoverPresentationController?.sourceView = thisViewVC.view
                    }

                    UIApplication.shared.connectedScenes.flatMap {($0 as? UIWindowScene)?.windows ?? []}.first {$0.isKeyWindow}?.rootViewController?.present(activityVC, animated: true, completion: nil)
//                }
            }
        }

    func toggleElementValidation() {
        showElementValidation = !showElementValidation
        viewModel.updateBoundingBoxes(canvasView.drawing)
//        viewModel.findAndCombineUnprocessedBoxes(canvasView.drawing)
    }

    func toggleMLVision() {
        showMLVision = !showMLVision
        if showMLVision {
            viewModel.recognizeUsingModel(canvasView: canvasView)
        }
    }

    func togglePreview() {
        if showingPreview == .generated {
            showingPreview = .none
        }
        else {
            showingPreview = .generated
        }
    }

    func toggleCodePreview() {
        if showingPreview == .generatedCode {
            showingPreview = .none
        }
        else {
            showingPreview = .generatedCode
        }
    }
}

extension DrawingView {
    class ViewModel: NSObject, ObservableObject, BoundingBoxViewDelegate {
        @Published var codeText: String = ""
        @Published private(set) var boundingBoxes: [BoundingBox] = []
        @Published private(set) var visionBoundingBoxes: [BoundingBox] = []
        private(set) var ignoredBoundingBoxes: [BoundingBox] = []

        @Published private(set) var processedBoxes: [BoundingBox] = []

        private let startingSketch: StartingSketch
        private let userStatement: UserStatement
        private let detection = Detection()

        private let dataStore = DataStore()

        private var currentDetectionWorkItem: DispatchWorkItem?
        private var startDetectionTime: Date?

        private(set) var lastDetectionImage: UIImage?

        let isCapture: Bool

        var imageUrl: URL? {
            startingSketch.localImage
        }
//        private var document = PlaygroundDocument(text: "")
        var document: PlaygroundDocument {
            get {
                PlaygroundDocument(text: codeText)
            }
        }

        init(startingSketch: StartingSketch, userStatement: UserStatement, isCapture: Bool = true) {
            self.startingSketch = startingSketch
            self.userStatement = userStatement
            self.isCapture = isCapture
            if !isCapture {
//                prev
            }
        }

        func updateBoundingBoxes(_ drawing: PKDrawing) {
            if boundingBoxes.count == 0 {
                boundingBoxes = BoundingBoxFactory().boundingBoxes(for: drawing.strokes)
            }
            else {
                findUnprocessedStrokes(drawing)
            }
        }

        func combineBoxes(_ boxes: [BoundingBox]) {
            for box in boxes {
                guard let index = boundingBoxes.firstIndex(of: box) else { continue }
                boundingBoxes.remove(at: index)
            }

            let strokes: [PKStroke] = boxes.reduce([]) { partialResult, box in
                partialResult + box.strokes
            }

            var rect = boxes.first?.displayRect ?? CGRect.zero
            boxes.forEach { box in
                rect = rect.union(box.displayRect)
            }
            let newBox = BoundingBox(strokes: strokes, displayRect: rect)
            boundingBoxes.append(newBox)
        }

        func findUnprocessedStrokes(_ drawing: PKDrawing) {
            var newStrokes: [PKStroke] = []
            for stroke in drawing.strokes {
                let existingStrokes = boundingBoxes.flatMap { $0.strokes }
                guard existingStrokes.filter({ $0.renderBounds.equalTo(stroke.renderBounds) }).isEmpty else { continue }
                print("Found a new stroke!")
                newStrokes.append(stroke)
            }

            let newBoxes = BoundingBoxFactory().boundingBoxes(for: newStrokes)
            boundingBoxes.append(contentsOf: newBoxes)
        }

        func findAndCombineUnprocessedBoxes(_ drawing: PKDrawing) {
            var newStrokes: [PKStroke] = []
            for stroke in drawing.strokes {
                let existingStrokes = boundingBoxes.flatMap { $0.strokes }
                guard existingStrokes.filter({ $0.renderBounds.equalTo(stroke.renderBounds) }).isEmpty else { continue }
                print("Found a new stroke!")
                newStrokes.append(stroke)
            }


            let unclassifiedBoxes = boundingBoxes.filter { $0.classification ==  .unknown }
            boundingBoxes.removeAll { $0.classification == .unknown }
            let unclassifiedStrokes = unclassifiedBoxes.flatMap { $0.strokes }
            newStrokes.append(contentsOf: unclassifiedStrokes)

            let newBoxes = BoundingBoxFactory().boundingBoxes(for: newStrokes)
            boundingBoxes.append(contentsOf: newBoxes)
        }

        func splitBox(boundingBox: BoundingBox) {
            guard let index = boundingBoxes.firstIndex(of: boundingBox) else { return }
            boundingBoxes.remove(at: index)
            for stroke in boundingBox.strokes {
                let boundingBox = BoundingBox(strokes: [stroke], displayRect: stroke.renderBounds)
                boundingBoxes.append(boundingBox)
            }
        }

        func ignore(boundingBox: BoundingBox) {
            guard let index = boundingBoxes.firstIndex(of: boundingBox) else { return }
            boundingBoxes.remove(at: index)
            ignoredBoundingBoxes.append(boundingBox)
        }

        func save(_ canvasView: PKCanvasView) async throws {
            try await dataStore.save(canvasView, boundingBoxes: boundingBoxes, userStatement: userStatement)
        }

        func queueRecognition(canvasView: PKCanvasView) {
            currentDetectionWorkItem?.cancel()
            startDetectionTime = Date()
            let newWorkItem = recognizeWithWorkItem(canvasView: canvasView)
            currentDetectionWorkItem = newWorkItem
            DispatchQueue.global().async(execute: newWorkItem)
        }

        func recognizeWithWorkItem(canvasView: PKCanvasView) -> DispatchWorkItem {
//            canvasView.drawing
//            var newStrokes: [PKStroke] = []
//            for stroke in drawing.strokes {
//                let existingStrokes = boundingBoxes.flatMap { $0.strokes }
//                guard existingStrokes.filter({ $0.renderBounds.equalTo(stroke.renderBounds) }).isEmpty else { continue }
//                print("Found a new stroke!")
//                newStrokes.append(stroke)
//            }

            let currentStrokes = canvasView.drawing.strokes
//            let newBoxes = BoundingBoxFactory().boundingBoxes(for: canvasView.drawing.strokes)
//            boundingBoxes.append(contentsOf: newBoxes)

            let scale = UIScreen.screens.first?.scale ?? 1.0
            let image = canvasView.drawing.image(from: canvasView.bounds, scale: scale).withBackground(color: .white)
            let size = image.size
            let workItem = detection.classifyImageWorkItem(image) { [weak self] observations in
                guard let self else { return }
                let drawingBoundingBoxes = BoundingBoxFactory().boundingBoxes(for: currentStrokes)
                self.processMLModelResults(observations: observations, size: size, drawnBoxes: drawingBoundingBoxes, detectionImage: image)
            }
            return workItem
        }

        func recognizeUsingModel(canvasView: PKCanvasView) {
            /*let scale = UIScreen.screens.first?.scale ?? 1.0
            let image = canvasView.drawing.image(from: canvasView.bounds, scale: scale).withBackground(color: .white)
//            let width = image.size.width
//            let height = image.size.height
            let size = image.size
            detection.classifyImage(image) { [weak self] observations in
                guard let self else { return }
                self.processMLModelResults(observations: observations, size: size)
            }*/

            // Create a JSONEncoder instance
            let jsonEncoder = JSONEncoder()
//            jsonEncoder.outputFormatting = .prettyPrinted // Optional: Makes the JSON output more human-readable

            // Encode the boundingBox object to JSON data
            do {
                let jsonData = try jsonEncoder.encode(self.visionBoundingBoxes)

                // Convert the JSON data to a String
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString) // Prints the JSON representation of the boundingBox object
                }
            } catch {
                print("Error encoding BoundingBox: \(error.localizedDescription)")
            }
        }

        func processMLModelResults(observations: [VNRecognizedObjectObservation], size: CGSize, drawnBoxes: [BoundingBox], detectionImage: UIImage) {
            var newBoundingBoxes: [BoundingBox] = []
            for observation in observations {
                let label = observation.labels.first?.identifier ?? ""
                let confidence = observation.confidence.formatted() ?? "0"
                let box = observation.boundingBox
                let displayRect = BoundingBox.displayCentreRectFromRelative(for: size, relativeRect: box)
                let finalBox = BoundingBox(displayRect: displayRect, text: "\(label): \(confidence)", classification: ElementClassification(rawValue: label) ?? .unknown, relativeRect: box, detectionConfidence: observation.confidence)
                newBoundingBoxes.append(finalBox)
            }
            print("Detection and classification took: \(Date().timeIntervalSince(self.startDetectionTime!))")

            let generation = Generation(detectionBoxes: newBoundingBoxes, drawingBoxes: drawnBoxes, image: detectionImage)
            let size = detectionImage.size
            Task {
                do {
                    let results = try await generation.processAll()
                    let processedBoxes = results.0
                    let codeText = results.1
                    DispatchQueue.main.async {
                        self.codeText = codeText
                        self.processedBoxes = processedBoxes
                        let finishTime = Date()
                        guard let startTime = self.startDetectionTime else { return }
                        let duration = finishTime.timeIntervalSince(startTime)
                        print("Generation took: \(duration)")
                    }
                } catch {
                    print("What happened? \(error)")
                }
            }

            DispatchQueue.main.async {
                self.visionBoundingBoxes.removeAll()
                self.visionBoundingBoxes.append(contentsOf: newBoundingBoxes)
                self.lastDetectionImage = detectionImage
            }
        }
    }
}

extension UIImage {
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: rect)

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}


//struct CanvasModel: Transferable {
//    let getImage: () async -> UIImage?
//
//    static var transferRepresentation: some TransferRepresentation {
//        DataRepresentation(exportedContentType: .jpeg) { item in
//            try await { () -> Data in
//                if let img = await item.getImage(), let jpeg = img.jpegData(compressionQuality: 0.6) {
//                    return jpeg
//                } else {
//                    throw ExportImageError.noImageFound
//                }
//            }()
//        }
//    }
//}
