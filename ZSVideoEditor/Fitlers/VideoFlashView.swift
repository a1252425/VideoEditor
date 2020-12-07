//
//  VideoFlashView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/7.
//

import UIKit
import MetalKit

struct FlashUniforms {
  let color1: vector_float4
  let color2: vector_float4
  let interval: Float
  let duration: Float
  let count: Int
}

final class VideoFlashView: MTKView {
  private let commandQueue: MTLCommandQueue
  private let cps: MTLComputePipelineState
  private lazy var uniformBuffer: MTLBuffer = {
    device!.makeBuffer(length: MemoryLayout<FlashUniforms>.size, options: [])!
  }()
  private var timer: Float = 0
  init() {
    guard
      let device = MTLCreateSystemDefaultDevice()
    else { fatalError("Device not suppert") }
    guard
      let library = device.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "flash"),
      let cps = try? device.makeComputePipelineState(function: kernel)
    else { fatalError("Compute pipline state create failed") }
    self.cps = cps
    guard
      let commandQueue = device.makeCommandQueue()
    else { fatalError("Command queue init failed") }
    self.commandQueue = commandQueue
    super.init(frame: .zero, device: device)
    framebufferOnly = false
    var uniform = FlashUniforms(color1: [0, 0, 0, 1],
                                color2: [Float(142/255.0), Float(212/255.0), Float(65/255.0), 1],
                                interval: 0.1,
                                duration: 0.37,
                                count: 8)
    let uniformPointer = uniformBuffer.contents()
    memcpy(uniformPointer, &uniform, MemoryLayout<FlashUniforms>.size)
    backgroundColor = .clear
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func update() {
    timer += 0.01
    if timer > 4 { timer = 0 }
  }
  
  override func draw(_ rect: CGRect) {
    update()
    guard let drawable = currentDrawable else { return }
    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
      return
    }
    guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
      return commandBuffer.commit()
    }
    commandEncoder.setComputePipelineState(cps)
    commandEncoder.setTexture(drawable.texture, index: 0)
    commandEncoder.setBuffer(uniformBuffer, offset: 0, index: 0)
    commandEncoder.setBytes(&timer, length: MemoryLayout<Float>.size, index: 1)
    let threadGroupCount = MTLSizeMake(8, 8, 1)
    let threadGroups = MTLSizeMake((drawable.texture.width + threadGroupCount.width - 1) / threadGroupCount.width,
                                   (drawable.texture.height + threadGroupCount.height - 1) / threadGroupCount.height,
                                   1)
    commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
