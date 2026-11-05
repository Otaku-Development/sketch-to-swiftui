//
//  GeneratedComponentsView.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 25/08/2023.
//

import SwiftUI

struct GeneratedComponentsView: View {
    @EnvironmentObject var viewModel: GeneratedViewViewModel
    @State private var showingAlert = false
    let actualFrameSize: CGSize

    @State private var textFieldBinding: String = ""
    @State private var favoriteColor = 0
    @State private var showGreeting = true

    let placeholderText = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """

    var body: some View {
        ForEach(0..<viewModel.detectedBoundingBoxes.count, id: \.self) { index in
            let box = viewModel.detectedBoundingBoxes[index]
            if box.classification == .navigationBar {
                navigationBarForElement(boundingBox: box, size: actualFrameSize)
            }
            if box.classification == .button {
                buttonForElement(boundingBox: box, size: actualFrameSize)
            }
            if box.classification == .label {
                labelForElement(boundingBox: box, size: actualFrameSize)
            }
            if box.classification == .tabBar {
                tabBarForElement(boundingBox: box, size: actualFrameSize)
            }
            if box.classification == .image {
                imageForElement(boundingBox: box, size: actualFrameSize)
            }
            if box.classification == .segmentedControl {
                segmentedControlForElement(boundingBox: box, size: actualFrameSize)
            }
            if box.classification == .textField {
                textFieldForElement(boundingBox: box, size: actualFrameSize)
            }
            if box.classification == .switchButton {
                switchForElement(boundingBox: box, size: actualFrameSize)
            }

// 'segmentedControl', 'textField', 'switchButton'

        }
    }
    
    @ViewBuilder
    func navigationBarForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)

        if let navBoundingBox = boundingBox as? NavigationBarBoundingBox {
            NavigationBar(title: boundingBox.displayText ?? "Title", showLeftButton: navBoundingBox.hasLeftButton, showRightButton: navBoundingBox.hasRightButton)
                .frame(width: actualRect.width,
                       height: actualRect.height)
                .position(x: actualRect.midX, y: actualRect.midY)
        }
        else {
            NavigationBar(title: boundingBox.displayText ?? "Title")
                .frame(width: actualRect.width,
                       height: actualRect.height)
                .position(x: actualRect.midX, y: actualRect.midY)
        }
    }

    @ViewBuilder
    func buttonForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
        Button(action: {
            showingAlert = true
        }) {
            Text(boundingBox.displayText ?? "Button").frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert("Button pressed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .buttonStyle(.borderedProminent)
        .frame(width: actualRect.width,
               height: actualRect.height)
        .position(x: actualRect.midX, y: actualRect.midY)
    }

    @ViewBuilder
    func labelForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        if let text = boundingBox.displayText {
            let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
            Text(text)
                .font(.largeTitle)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .lineLimit(1)
                .frame(width: actualRect.width,
                       height: actualRect.height)
                    .border(.red)
                .position(x: actualRect.midX, y: actualRect.midY)
        }
        else {
            let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
            Text(placeholderText)
//                .font(.largeTitle)
//                .scaledToFit()
//                .minimumScaleFactor(0.01)
//                .lineLimit(1)
                .frame(width: actualRect.width,
                       height: actualRect.height)
                    .border(.red)
                .position(x: actualRect.midX, y: actualRect.midY)
        }
    }

    @ViewBuilder
    func tabBarForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
        TabBar(numberOfBarItems: 4)
            .frame(width: actualRect.width,
                   height: actualRect.height)
            .background(.yellow.opacity(0.2))
//            .border(.blue, width: 2)
            .position(x: actualRect.midX, y: actualRect.midY)
    }

    @ViewBuilder
    func imageForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
        Image("image_ux")
        .resizable(resizingMode: .stretch)
        .frame(width: actualRect.width,
               height: actualRect.height)
        .border(.red)
        .position(x: actualRect.midX, y: actualRect.midY)
    }

    @ViewBuilder
    func textFieldForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
        TextField("", text: $textFieldBinding)
//        .resizable(resizingMode: .stretch)
        .frame(width: actualRect.width,
               height: actualRect.height)
        .cornerRadius(5)
        .border(.black)
        .position(x: actualRect.midX, y: actualRect.midY)
    }

    @ViewBuilder
    func segmentedControlForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
        Picker("", selection: $favoriteColor) {
                        Text("Red").tag(0)
                        Text("Green").tag(1)
                        Text("Blue").tag(2)
                    }
                    .pickerStyle(.segmented)
        .frame(width: actualRect.width,
               height: actualRect.height)
        .border(.black)
        .position(x: actualRect.midX, y: actualRect.midY)
        .cornerRadius(5)
    }

    @ViewBuilder
    func switchForElement(boundingBox: BoundingBox, size: CGSize) -> some View {
        let actualRect = boundingBox.displayCentreRectFromRelative(for: size)
        Toggle("", isOn: $showGreeting)
        .frame(width: actualRect.width,
               height: actualRect.height)
        .border(.black)
        .position(x: actualRect.midX, y: actualRect.midY)
        .cornerRadius(5)
    }

}

struct GeneratedComponentsView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geo in
            let viewModel = GeneratedViewViewModel(boxesString: GeneratedView.boundingBoxesString)
            GeneratedComponentsView(actualFrameSize: geo.size).environmentObject(viewModel)
//                .position(x: 500, y: -500)
//                .frame(height: .infinity)
        }
    }
}
