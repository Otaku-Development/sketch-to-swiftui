//
//  Detection.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 21/07/2023.
//

import Foundation
import CoreML
import Vision
import UIKit

class Detection {
//https://betterprogramming.pub/how-to-build-a-yolov5-object-detection-app-on-ios-39c8c77dfe58
//    private lazy var classificationRequest: VNCoreMLRequest = {
//        do {
//            // 2
//            let config = MLModelConfiguration()
//            config.computeUnits = .all
////          config.
//            let model = try VNCoreMLModel(for: DetectComponents2(configuration: config).model)
//            model.inputImageFeatureName = "image"
//            // 3
//            let request = VNCoreMLRequest(model: model) { response, _ in
//                if let classifications = response.results as? [VNClassificationObservation] {
//                    print("Classification results: \(classifications)")
//                }
//                else if let observations = response.results as? [VNRecognizedObjectObservation] {
//                    print("Object results: \(observations)")
//                }
//                else {
//                    print("It's something else!!")
//                }
//            }
//        // 4
////        request.imageCropAndScaleOption = .centerCrop
//            request.imageCropAndScaleOption = .scaleFill
//            return request
//      } catch {
//        // 5
//        fatalError("Failed to load Vision ML model: \(error)")
//      }
//    }()


    func createClassificationRequest(completion: @escaping ([VNRecognizedObjectObservation])->()) -> VNCoreMLRequest {
        do {
            // 2
            let config = MLModelConfiguration()
            config.computeUnits = .all
//          config.
            let model = try VNCoreMLModel(for: DetectComponents8(configuration: config).model)
            model.inputImageFeatureName = "image"
            // 3
            let request = VNCoreMLRequest(model: model) { response, _ in
                if let classifications = response.results as? [VNClassificationObservation] {
                    print("Classification results: \(classifications)")
                    completion([])
                }
                else if let observations = response.results as? [VNRecognizedObjectObservation] {
                    print("Object results: \(observations)")
                    completion(observations)
                }
                else {
                    print("It's something else!!")
                    completion([])
                }
            }

//        request.imageCropAndScaleOption = .centerCrop
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            // 5
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }

//    func attemptToDetect() {
////        ComponentDetector(configuration: MLModelConfiguration).model
////        Components().model
//        guard let image = UIImage(named: "liam.jpg") else { return }
//        classifyImage(image)
//    }
//
//    func attemptToDetectImage(_ image: UIImage) {
////        ComponentDetector(configuration: MLModelConfiguration).model
////        Components().model
////        guard let image = UIImage(named: "liam.jpg") else { return }
//        classifyImage(image)
//    }

    func classifyImage(_ image: UIImage, completion: @escaping ([VNRecognizedObjectObservation])->()) {
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
            return
        }
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
        }

        let request = createClassificationRequest(completion: completion)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do {
            guard let self else { return }
            try handler.perform([request])
        } catch {
            print("Failed to perform classification.\n\(error.localizedDescription)")
            completion([])
        }
      }
    }

    func classifyImageWorkItem(_ image: UIImage, completion: @escaping ([VNRecognizedObjectObservation])->()) -> DispatchWorkItem {
        let newWorkItem = DispatchWorkItem(qos: .userInitiated) { [weak self] in
            guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
                completion([])
                return
            }
            guard let ciImage = CIImage(image: image) else {
                fatalError("Unable to create \(CIImage.self) from \(image).")
            }
            guard let self else { completion([]); return }

            let request = self.createClassificationRequest(completion: completion)
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
                completion([])
            }
        }
        return newWorkItem
    }
}
