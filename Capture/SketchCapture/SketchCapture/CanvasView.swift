//
//  CanvasView.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 27/04/2023.
//

import SwiftUI
import PencilKit

struct CanvasView: View {
    @Binding var canvasView: PKCanvasView

    let onChanged: () -> Void

    @State var toolPicker = PKToolPicker()
}

extension CanvasView: UIViewRepresentable {
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.delegate = context.coordinator
        #if targetEnvironment(simulator)
        canvasView.drawingPolicy = .anyInput
        #endif

        showToolPicker()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        print("Update UIView")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasView: $canvasView, onChanged: onChanged)
    }
}

private extension CanvasView {
    func showToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
}

class Coordinator: NSObject {
    var canvasView: Binding<PKCanvasView>
    let onChanged: () -> Void

    init(canvasView: Binding<PKCanvasView>, onChanged: @escaping () -> Void) {
        self.canvasView = canvasView
        self.onChanged = onChanged
    }
}

extension Coordinator: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if !canvasView.drawing.bounds.isEmpty {
            onChanged()
        }
    }
}
