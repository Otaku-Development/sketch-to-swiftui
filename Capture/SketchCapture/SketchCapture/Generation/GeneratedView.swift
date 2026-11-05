//
//  GeneratedView.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 11/08/2023.
//

import SwiftUI

struct GeneratedView: View {
    let viewModel: GeneratedViewViewModel

    let iphoneImageSize = UIImage(named: "iphone-mockup")!.size

    var body: some View {
        ZStack {
            Image("iphone-mockup")
                .resizable()
                .scaledToFit()
                .allowsHitTesting(false)
                .overlay {
                    GeometryReader { geo in
                        ZStack {
                            let horizontalPadding = geo.size.height / iphoneImageSize.height * 21
                            let verticalPadding = geo.size.height / iphoneImageSize.height * 19
                            let generatedFrame = CGRect(x: 0, y: 0, width: geo.size.width - (horizontalPadding * 2), height: geo.size.height - (verticalPadding * 2))

                            GeneratedComponentsView(actualFrameSize: generatedFrame.size)
                                .padding(EdgeInsets(top: verticalPadding, leading: horizontalPadding, bottom: verticalPadding, trailing: horizontalPadding))
                                .cornerRadius(100)
                                .clipped()
                            Image("iphone-mockup")
                                .resizable()
                                .scaledToFit()
                                .allowsHitTesting(false)
                        }
                        //.background(.red.opacity(0.1))
                    }
                }

        }.environmentObject(viewModel)
    }

    static let otherBoundingBoxesString = "[{\"relativeRect\":[[0.03990599513053894,0.84667593240737915],[0.65604209899902344,0.1570202112197876]],\"displayRect\":[[18.237039774656296,-3.4374135732650757],[299.81123924255371,146.02879643440247]],\"classification\":\"navigationBar\",\"text\":\"navigationBar: 0.880625\"},{\"relativeRect\":[[0.098709031939506531,0.87081402912735939],[0.066462665796279907,0.042111076414585114]],\"displayRect\":[[45.110027596354485,80.979651845991611],[30.373438268899918,39.163301065564156]],\"classification\":\"button\",\"text\":\"button: 0.878595\"},{\"relativeRect\":[[0.79485601931810379,0.88194252084940672],[0.15306733548641205,0.029733294621109962]],\"displayRect\":[[363.24920082837343,82.141491612419486],[69.951772317290306,27.651963997632265]],\"classification\":\"label\",\"text\":\"label: 0.782762\"},{\"relativeRect\":[[0.38603115081787109,0.87827846966683865],[0.24141490459442139,0.034009832888841629]],\"displayRect\":[[176.41623592376709,81.571878623217344],[110.32661139965057,31.629144586622715]],\"classification\":\"label\",\"text\":\"label: 0.644715\"},{\"relativeRect\":[[0.33327183127403259,0.85052129626274109],[0.64529377222061157,0.14813917875289917]],\"displayRect\":[[152.30522689223289,1.2457582354545593],[294.89925390481949,137.76943624019623]],\"classification\":\"navigationBar\",\"text\":\"navigationBar: 0.389465\"},{\"relativeRect\":[[0.33066915720701218,0.87671716883778572],[0.12591643631458282,0.032719619572162628]],\"displayRect\":[[151.11580484360456,84.223786778748035],[57.543811395764351,30.429246202111244]],\"classification\":\"label\",\"text\":\"label: 0.300377\"},{\"relativeRect\":[[0.32183390855789185,0.8465427802875638],[0.5905768871307373,0.020139208063483238]],\"displayRect\":[[147.07809621095657,123.98575083352625],[269.89363741874695,18.729463499039412]],\"classification\":\"image\",\"text\":\"image: 0.321925\"}]"

    static let boundingBoxesString = "[{\"relativeRect\":[[0.24020901322364807,0.54670798778533936],[0.53688997030258179,0.31213879585266113]],\"displayRect\":[[-12.90383917093277,276.41703128814697],[245.35871642827988,290.28908014297485]],\"classification\":\"image\",\"text\":\"image: 0.981076\"},{\"relativeRect\":[[0.25985759496688843,0.4457395151257515],[0.25794178247451782,0.045459374785423279]],\"displayRect\":[[59.815223604440689,494.32364165782928],[117.87939459085464,42.277218550443649]],\"classification\":\"label\",\"text\":\"label: 0.77504\"},{\"relativeRect\":[[0.12436592578887939,0.11998862773180008],[0.59045475721359253,0.080738767981529236]],\"displayRect\":[[-78.08368393778801,780.86704909801483],[269.83782404661179,75.087054222822189]],\"classification\":\"button\",\"text\":\"button: 0.641714\"}]"

}

struct GeneratedView_Previews: PreviewProvider {
    static var previews: some View {

        let viewModel = GeneratedViewViewModel(boxesString: GeneratedView.otherBoundingBoxesString)
        GeneratedView(viewModel: viewModel)
    }
}

class GeneratedViewViewModel: ObservableObject {

    @Published var detectedBoundingBoxes: [BoundingBox] = []

    private let generation: Generation?

    init(boxesString: String) {
        generation = Generation.createFromJSON(boxesString)!
        Task {
            do {
                detectedBoundingBoxes = try await generation!.process()
            } catch {
                print("What happened? \(error)")
            }
        }
    }

    init(rawVisionBoxes: [BoundingBox], drawingBoxes: [BoundingBox], inputImage: UIImage?) {
        generation = Generation(detectionBoxes: rawVisionBoxes, drawingBoxes: drawingBoxes, image: inputImage)

        Task {
            do {
                detectedBoundingBoxes = try await generation!.process()
            } catch {
                print("What happened? \(error)")
            }
        }
    }

    init(detectedBoundingBoxes: [BoundingBox]) {
        self.detectedBoundingBoxes = detectedBoundingBoxes
        self.generation = nil
    }
}
