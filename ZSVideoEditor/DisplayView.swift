//
//  DisplayView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import MetalKit

final class DisplayView: MTKView {
  private lazy var filters = [BaseFilter]()
  
  override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    framebufferOnly = false
    backgroundColor = .clear
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func play() {
  }
  
  func stop() {
  }
  
  private func update() {
    
  }
  
  override func draw(_ rect: CGRect) {
    guard
      let drawable = currentDrawable,
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer()
    else { return }
    filters.forEach { $0.render(drawable.texture, commandBuffer: commandBuffer) }
    commandBuffer.present(drawable)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}

extension DisplayView: FilterProtocol {
  func taskComplete(_ filter: BaseFilter) {
    if let index = filters.firstIndex(where: { $0 === filter }) {
      filters.remove(at: index)
    }
  }
}
