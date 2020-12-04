//
//  AppDelegate.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/2.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = ZSNavigationController(rootViewController: HomeViewController())
    window.makeKeyAndVisible()
    self.window = window
    return true
  }

}

