//
//  GeneratedCodeView.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 14/09/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct GeneratedCodeView: View {
    @EnvironmentObject var viewModel: DrawingView.ViewModel
    @State var code: String

    var body: some View {
        ScrollView {
            Text(AttributedString(stringLiteral: viewModel.codeText))
                .font(.custom("Courier New", size: 13))
                .padding(10)
                .onTapGesture(count: 1) {
                    UIPasteboard.general.setValue(viewModel.codeText,
                                                  forPasteboardType: UTType.plainText.identifier)
                }
        }
    }
}

struct GeneratedCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyCode =
        """
        struct ContentView: View {
            var body: some View {
                Text("Tel")
        .font(.largeTitle)
        .scaledToFit()
        .minimumScaleFactor(0.01)
        .lineLimit(1)
        .frame(width: 105.11486381292343,
               height: 50.10718107223511)
            .border(.red)
        .position(x: 196.5827065706253, y: 227.05917358398438)
        Text("Title")
        .font(.largeTitle)
        .scaledToFit()
        .minimumScaleFactor(0.01)
        .lineLimit(1)
        .frame(width: 85.40266990661621,
               height: 44.81227099895477)
            .border(.red)
        .position(x: 196.32481157779694, y: 131.98384046554565)

            }
        }

        PlaygroundPage.current.setLiveView(ContentView())
        """

        GeneratedCodeView(code: dummyCode)
    }
}
