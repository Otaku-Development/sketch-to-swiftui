//
//  PlaygroundDocument.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 08/09/2023.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Zip

struct PlaygroundDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [UTType(exportedAs: "com.apple.dt.playground")]
    }

    var text = ""

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if let fileURL = Bundle.main.url(forResource: "template", withExtension: "zip") {
            do {
                let unzipDirectory = try Zip.quickUnzipFile(fileURL)
                let fileWrappers: [String: FileWrapper] = allFiles(directoryUrl: unzipDirectory)
                return FileWrapper(directoryWithFileWrappers: fileWrappers)
            } catch {
                fatalError("File not found")
            }
        } else {
            fatalError("File not found")
        }
    }

    private func allFiles(directoryUrl: URL) -> [String: FileWrapper] {
        var fileWrappers: [String: FileWrapper] = [:]
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil)
            for fileUrl in fileURLs {
                if fileUrl.isDirectory == true {
                    let allFiles = allFiles(directoryUrl: fileUrl)
                    fileWrappers[fileUrl.lastPathComponent] = FileWrapper(directoryWithFileWrappers: allFiles)
                }
                else {
                    if fileUrl.lastPathComponent == "Contents.swift", let data = text.data(using: .utf8) {
                        let wrapper = FileWrapper(regularFileWithContents: data)
                        fileWrappers[fileUrl.lastPathComponent] = wrapper
                    }
                    else {
                        let fileData = try Data(contentsOf: fileUrl)
                        let wrapper = FileWrapper(regularFileWithContents: fileData)
                        fileWrappers[fileUrl.lastPathComponent] = wrapper
                    }
                }

            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        return fileWrappers
    }
}

extension URL {
    var isDirectory: Bool? {
        do {
            return (try resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory)
        }
        catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
}
