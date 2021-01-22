//
//  ICBViewController.swift
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/19.
//

import UIKit
import MetalKit

class ICBViewController: UIViewController {

  private lazy var mtkView = MTKView(frame: view.bounds,
                                     device: MTLCreateSystemDefaultDevice())
  private lazy var renderer = ICBRenderer(mtkView)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(mtkView)
    mtkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    mtkView.delegate = renderer
  }
}
