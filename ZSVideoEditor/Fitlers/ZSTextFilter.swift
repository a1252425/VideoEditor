//
//  ZSTextFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/11.
//

import MetalKit

final class ZSTextFilter {
  let texture: MTLTexture
  
  init(_ attributeString: NSAttributedString) {
    do {
      texture = try MetalInstance
        .shared
        .textureLoader
        .newTexture(data: UIGraphicsImageRenderer(size: attributeString.size())
                      .pngData { _ in attributeString.draw(at: .zero) },
                    options: nil)
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  func makeTexture(_ time: Float) -> MTLTexture {
    let attributeString = NSAttributedString(string: "\(Int(time * 10))KM/H", attributes: [
      .font: UIFont.systemFont(ofSize: 30, weight: .semibold),
      .foregroundColor: UIColor.red
    ])
    do {
      return try MetalInstance
        .shared
        .textureLoader
        .newTexture(data: UIGraphicsImageRenderer(size: attributeString.size())
                      .pngData { _ in attributeString.draw(at: .zero) },
                    options: nil)
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  var animations = [ZSFilterAnimation]()
  func add(_ animation: ZSFilterAnimation) {
    animations.append(animation)
  }
  
  private lazy var cps: MTLComputePipelineState = {
    guard
      let library = MetalInstance.sharedDevice.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "zs_view"),
      let cps = try? MetalInstance.sharedDevice.makeComputePipelineState(function: kernel)
    else { fatalError("UNKNOWN") }
    return cps
  }()
  func render(_ inTexture: MTLTexture, frame: CGRect, time: Float, mask: MTLTexture? = nil) {
    let texture = makeTexture(time)
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
    commandEncoder.setTexture(inTexture, index: 1)
    commandEncoder.setTexture(texture, index: 2)
    commandEncoder.setBytes(&frame, length: MemoryLayout<vector_float4>.stride, index: 0)
    commandEncoder.setBytes(&transform, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
    commandEncoder.dispatchThreadgroups(inTexture)
    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}
