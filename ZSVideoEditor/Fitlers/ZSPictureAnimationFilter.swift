//
//  ZSPictureAnimationFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/10.
//

import MetalKit

final class ZSPictureAnimationFilter {
  let texture: MTLTexture
  init(content: MTLTexture) {
    self.texture = content
  }
  
  var animations = [ZSFilterAnimation]()
  func add(_ animation: ZSFilterAnimation) {
    animations.append(animation)
  }
  
  private lazy var cps: MTLComputePipelineState = {
    guard
      let library = MetalInstance.sharedDevice.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "zs_picture_animation"),
      let cps = try? MetalInstance.sharedDevice.makeComputePipelineState(function: kernel)
    else { fatalError("UNKNOWN") }
    return cps
  }()
  func render(_ inTexture: MTLTexture, frame: CGRect, time: Float, mask: MTLTexture? = nil) {
    guard
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else { fatalError() }
    var frame = vector_float4(Float(frame.origin.x),
                              Float(frame.origin.y),
                              Float(frame.width),
                              Float(frame.height))
    var transform = animations.transform(time)
    commandEncoder.setComputePipelineState(cps)
    commandEncoder.setTexture(inTexture, index: 0)
    commandEncoder.setTexture(texture, index: 1)
    commandEncoder.setBytes(&frame, length: MemoryLayout<vector_float4>.stride, index: 0)
    commandEncoder.setBytes(&transform, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
    commandEncoder.dispatchThreadgroups(inTexture)
    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}
