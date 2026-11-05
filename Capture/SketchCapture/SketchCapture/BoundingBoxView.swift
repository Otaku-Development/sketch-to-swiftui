//
//  BoundingBoxView.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 08/05/2023.
//

import SwiftUI

protocol BoundingBoxViewDelegate: NSObject {
    func splitBox(boundingBox: BoundingBox)
    func ignore(boundingBox: BoundingBox)
}

struct BoundingBoxView: View {

    let boundingBox: BoundingBox
    weak var delegate: BoundingBoxViewDelegate?

    @State private var showingConfirmation = false
    @State private var backgroundColor = Color.red

    private var color: Color {
        boundingBox.classification == .unknown ? .red : .green
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(0.25))
                .border(color)
            if boundingBox.text == nil {
                Text(boundingBox.classification.rawValue).bold().padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5 )).foregroundColor(.white)
            }
            if let title = boundingBox.text {
                Text(title).bold().foregroundColor(.blue)
            }
        }
        .frame(width: boundingBox.displayRect.width,
               height: boundingBox.displayRect.height)
        .position(x: boundingBox.displayRect.midX,
                  y: boundingBox.displayRect.midY)
        .onTapGesture {
            showingConfirmation = true
        }
        .confirmationDialog("Change background", isPresented: $showingConfirmation) {
            VStack() {
                ForEach(0..<ElementClassification.allCases.count, id: \.self) { index in
                    Button(String(ElementClassification.allCases[index].rawValue)) {
                        boundingBox.classification = ElementClassification.allCases[index]
                    }
                }
                Button("Split", role: .destructive) {
                    delegate?.splitBox(boundingBox: boundingBox)
                }
                Button("Ignore", role: .destructive) {
                    delegate?.ignore(boundingBox: boundingBox)
                }
                Button("Cancel", role: .destructive) {
                    print("Cancel!")
                    showingConfirmation = false
                }
            }
        } message: {
            Text("Select the UI element")
        }
    }
}

struct BoundingBoxView_Previews: PreviewProvider {
    static var previews: some View {
        BoundingBoxView(boundingBox: BoundingBox(strokes: [], displayRect: CGRect(x: 10, y: 10, width: 200, height: 100)))
    }
}
