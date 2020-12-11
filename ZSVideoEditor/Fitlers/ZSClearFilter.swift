//
//  ZSClearFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/11.
//

import MetalKit

final class ZSClearFilter {
  private(set) lazy var clearCps: MTLComputePipelineState = {
    guard
      let library = MetalInstance.sharedDevice.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "zs_view_clear"),
      let cps = try? MetalInstance.sharedDevice.makeComputePipelineState(function: kernel)
    else { fatalError("UNKNOWN") }
    return cps
  }()
  
  func render(_ inTexture: MTLTexture) {
    guard
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else { fatalError() }
    commandEncoder.setComputePipelineState(clearCps)
    commandEncoder.setTexture(inTexture, index: 0)
    commandEncoder.dispatchThreadgroups(inTexture)
    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}
