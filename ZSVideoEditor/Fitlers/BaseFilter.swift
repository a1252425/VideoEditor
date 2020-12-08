//
//  BaseFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import Metal

protocol FilterProtocol: AnyObject {
  func taskComplete(_ filter: BaseFilter)
}

class BaseFilter {
  weak var delegate: FilterProtocol?
  let device = MetalInstance.shared.device
  func render(_ texture: MTLTexture, commandBuffer: MTLCommandBuffer) {
    
  }
  
  func taskComplete() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.delegate?.taskComplete(self)
    }
  }
}
