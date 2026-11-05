//
//  DataStore.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 07/06/2023.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase
import UIKit
import PencilKit

class DataStore {
    func countSketches(completion: @escaping (Int?) -> ()) {
        let ref = Database.database().reference()

        ref.child(statsFolder()).child("count").observeSingleEvent(of: DataEventType.value) { snapshot in
            completion(snapshot.value as? Int)
        }
    }

    func countSketches() async throws -> Int? {
        return try await withCheckedThrowingContinuation({ continuation in
            countSketches { count in
                guard let count else { continuation.resume(with: .failure(NSError())); return }
                continuation.resume(with: .success(count))
            }
        })
    }

    private func countChildren(reference: DatabaseReference, completion: (Int?) -> ()) {
        reference.observe(DataEventType.value, with: { (snapshot) in
            print(snapshot.childrenCount)
        })
    }


    private func dateFolder() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMYY"
        let date = Date()
        return dateFormatter.string(from: date)
    }

    private func uniqueNameFolder() -> String {
        return UUID().uuidString
    }

    private func uniqueImageName() -> String {
        return UUID().uuidString + ".png"
    }

    private func mainFolderName() -> String {
        return dateFolder() + "/" + uniqueNameFolder()
    }

    private func statsFolder() -> String {
        return "stats"
    }

    private func uploadImage(storageRef: StorageReference, image: UIImage, metadata: StorageMetadata?, completion: @escaping (Result<URL, Error>)->Void) {
        // Upload the file to the path "images/rivers.jpg"
        guard let imageData = image.pngData() else {
            completion(.failure(FirebaseError()))
            return
        }
        let _ = storageRef.putData(imageData, metadata: metadata) { (uploadedMetadata, error) in
            // You can also access to download URL after upload.
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    completion(.failure(FirebaseError()))
                    return
                }

                completion(.success(downloadURL))
            }
        }
    }

    private func uploadImage(storageRef: StorageReference, image: UIImage, metadata: StorageMetadata?) async throws -> URL {
        return try await withCheckedThrowingContinuation({ continuation in
            uploadImage(storageRef: storageRef, image: image, metadata: metadata) { result in
                continuation.resume(with: result)
            }
        })
    }

    private func rectForScale(_ rect: CGRect, scale: CGFloat) -> String {
        let scaleRect = CGRect(x: rect.origin.x * scale,
                               y: rect.origin.y * scale,
                               width: rect.width * scale,
                               height: rect.height * scale)
        return NSCoder.string(for: scaleRect)
    }

    func save(_ canvasView: PKCanvasView, boundingBoxes: [BoundingBox], userStatement: UserStatement) async throws {
        var ref = Database.database().reference()

        let mainFolderName = mainFolderName()

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let rootRef = storageRef.child(mainFolderName)

        let scale = await UIScreen.screens.first?.scale ?? 1.0
        let image = await canvasView.drawing.image(from: canvasView.bounds, scale: scale)
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        let mainImageUrl = try await uploadImage(storageRef: rootRef.child(uniqueImageName()), image: image, metadata: metadata)

        var elementUrls: [[String: String]] = []
        let elementsRef = rootRef.child("elements")

        for box in boundingBoxes {
            let elementImage = await canvasView.drawing.image(from: box.displayRect, scale: scale)
            print("Image: \(elementImage)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/png"
            let boxString = rectForScale(box.displayRect, scale: scale)
            let boxMetadata: [String: String] = ["type": box.classification.rawValue,
                                                 "box": boxString]
            metadata.customMetadata = boxMetadata
            let elementUrl = try await uploadImage(storageRef: elementsRef.child(uniqueImageName()), image: elementImage, metadata: metadata)
            let thisData: [String: String] = ["type": box.classification.rawValue,
                                           "box": boxString,
                                           "url": elementUrl.absoluteString]
            elementUrls.append(thisData)
        }

        let user: [String: String] = ["name": userStatement.name ?? "Anonymous",
                                      "Accepted terms": "\(userStatement.hasAgreedToTerms)",
                                      "Requested debrief": "\(userStatement.hasRequestedDebrief)",
                                      "Volunteered to evaluation": "\(userStatement.hasAgreedToEvaluation)"]

        let data: [String: Any] = ["user": user, "image": mainImageUrl.absoluteString, "elements": elementUrls]
        try await ref.child(mainFolderName).setValue(data)
        if let sketchCount = try await countSketches() {

            try await ref.child(statsFolder()).child("count").setValue(sketchCount + 1)
        }

    }
}
