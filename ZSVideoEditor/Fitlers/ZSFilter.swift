//
//  ZSFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import MetalKit

class ZSFilter {
  private(set) var frame: vector_float4
  init(_ frame: CGRect) {
    self.frame = vector_float4(Float(frame.origin.x),
                               Float(frame.origin.y),
                               Float(frame.width),
                               Float(frame.height))
  }
  
  private var content: MTLTexture?
  func set(content texture: MTLTexture) {
    self.content = texture
  }
  
  private(set) var mask: MTLTexture?
  func set(mask texture: MTLTexture) {
    self.mask = texture
  }
  
  private(set) var animations = [ZSFilterAnimation]()
  func add(_ animation: ZSFilterAnimation) {
    animations.append(animation)
  }
  
  private(set) lazy var cps: MTLComputePipelineState = {
    guard
      let library = MetalInstance.sharedDevice.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "zs_view"),
      let cps = try? MetalInstance.sharedDevice.makeComputePipelineState(function: kernel)
    else { fatalError("UNKNOWN") }
    return cps
  }()
  func render(_ inTexture: MTLTexture, time: Float) {
    guard
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else { fatalError() }
    var frame = self.frame
    var transform = animations.transform(time)
    commandEncoder.setComputePipelineState(cps)
    commandEncoder.setTexture(inTexture, index: 0)
    commandEncoder.setTexture(inTexture, index: 1)
    commandEncoder.setTexture(content, index: 2)
    commandEncoder.setBytes(&frame, length: MemoryLayout<vector_float4>.stride, index: 0)
    commandEncoder.setBytes(&transform, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
    commandEncoder.dispatchThreadgroups(inTexture)
    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
  
}
