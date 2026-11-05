//
//  SketchCaptureApp.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 26/04/2023.
//

import SwiftUI

@main
struct SketchCaptureApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            IntroductionView(viewModel: IntroductionView.ViewModel())
        }
    }
}
