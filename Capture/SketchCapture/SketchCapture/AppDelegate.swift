//
//  AppDelegate.swift
//  SketchCapture
//
//  Created by Daniel Leivers on 27/04/2023.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseStorage

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
//        Detection().attemptToDetect()
        return true
    }
}
