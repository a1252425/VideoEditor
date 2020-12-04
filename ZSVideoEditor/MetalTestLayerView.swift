//
//  MetalTestLayerView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/4.
//

import UIKit

class MetalTestLayerView: UIView {
  
  var metalLayer: CAMetalLayer {
    return layer as! CAMetalLayer
  }

  override class var layerClass: AnyClass {
    return CAMetalLayer.self
  }

  private func render() {
    let device = MTLCreateSystemDefaultDevice()
    metalLayer.device = device
    
  }
}
