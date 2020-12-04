//
//  ZSNavigationController.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/2.
//

import UIKit

class ZSNavigationController: UINavigationController {
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .darkContent
  }
  
  override var shouldAutorotate: Bool { true }
  override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationBar.titleTextAttributes = [
      .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
      .foregroundColor: UIColor.black
    ]
    navigationBar.barTintColor = UIColor.white.withAlphaComponent(245 / 255.0)
  }
  
}
