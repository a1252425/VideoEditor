//
//  ZSMetalViewController.swift
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/22.
//

import MetalKit

class ZSMetalViewController: UIViewController {
  
  private lazy var mtkView = MTKView(frame: view.bounds,
                                     device: MTLCreateSystemDefaultDevice())
  private lazy var renderer = ICBRenderer(mtkView)
//  private lazy var renderer = CGSRenderer(mtkView)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    
    view.addSubview(mtkView)
    mtkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    mtkView.delegate = renderer
  }

}
