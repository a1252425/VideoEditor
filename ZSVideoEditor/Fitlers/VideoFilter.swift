//
//  VideoFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import MetalKit
import AVFoundation

struct FlashUniforms {
  let color1: vector_float4
  let color2: vector_float4
  let interval: Float
  let duration: Float
  let count: Int
  
  static func common() -> Self {
    return FlashUniforms(color1: [0, 0, 0, 1],
                         color2: [Float(142/255.0), Float(212/255.0), Float(65/255.0), 1],
                         interval: 0.1,
                         duration: 0.4,
                         count: 8)
  }
}

final class VideoFilter: BaseFilter {
  private let cps: MTLComputePipelineState
  private var videoTexture: MTLTexture?
  private var drawTexture: MTLTexture?
  private lazy var uniformBuffer: MTLBuffer = {
    device.makeBuffer(length: MemoryLayout<FlashUniforms>.size, options: [])!
  }()
  private var timer: Float = 0
  private var maxTime: Float = 0
  
  init(_ uniforms: FlashUniforms = FlashUniforms.common()) {
    guard
      let library = MetalInstance.sharedDevice.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "flash"),
      let cps = try? MetalInstance.sharedDevice.makeComputePipelineState(function: kernel)
    else { fatalError("Compute pipline state create failed") }
    self.cps = cps
    super.init()
    var uniform = uniforms
    let uniformPointer = uniformBuffer.contents()
    memcpy(uniformPointer, &uniform, MemoryLayout<FlashUniforms>.size)
    maxTime = uniforms.interval * Float(uniforms.count - 1) + uniforms.duration
  }
  
  func setTime(_ time: TimeInterval) {
    timer = Float(time)
  }
  
  func render() -> MTLTexture? {
    guard
      let videoTexture = videoTexture,
      let drawTexture = drawTexture,
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else { return nil }
    commandEncoder.setComputePipelineState(cps)
    commandEncoder.setTexture(videoTexture, index: 0)
    commandEncoder.setTexture(drawTexture, index: 1)
    commandEncoder.setBuffer(uniformBuffer, offset: 0, index: 0)
    commandEncoder.setBytes(&timer, length: MemoryLayout<Float>.size, index: 1)
    commandEncoder.dispatchThreadgroups(videoTexture)
    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    return drawTexture
  }
}

extension VideoFilter {
  func proccess(pixelBuffer: CVPixelBuffer,
                adopter: AVAssetWriterInputPixelBufferAdaptor,
                atTime: inout TimeInterval) {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    
    //  Init texture
    var tmpTextureCache: CVMetalTextureCache?
    CVMetalTextureCacheCreate(nil, nil, device, nil, &tmpTextureCache)
    guard let textureCache = tmpTextureCache else { return }
    var tmpTexture: CVMetalTexture?
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              textureCache,
                                              pixelBuffer,
                                              nil,
                                              .bgra8Unorm,
                                              width,
                                              height,
                                              0,
                                              &tmpTexture)
    guard let metalTexture = tmpTexture else { return }
    videoTexture = CVMetalTextureGetTexture(metalTexture)
    drawTexture = MetalInstance.makeTexture(width: width,
                                            height: height,
                                            format: .bgra8Unorm)
    
    var flashTime: TimeInterval = 0
    let endTime: TimeInterval = TimeInterval(maxTime)
    while adopter.assetWriterInput.isReadyForMoreMediaData {
      defer { flashTime += 0.04 }
      if flashTime > endTime { break }
      setTime(flashTime)
      let time = CMTime(seconds: flashTime + atTime, preferredTimescale: 600)
      guard
        let texture = render(),
        let buffer = CVPixelBufferGetBaseAddress(pixelBuffer)
        else { return }
      let region = MTLRegionMake2D(0, 0, width, height)
      texture.getBytes(buffer,
                       bytesPerRow: width * 4,
                       from: region,
                       mipmapLevel: 0)
      adopter.append(pixelBuffer, withPresentationTime: time)
    }
    atTime = flashTime
  }
}
