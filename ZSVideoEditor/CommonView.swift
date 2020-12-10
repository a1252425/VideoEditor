//
//  CommonView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

import MetalKit

final class CommonView: MTKView {
  private var cps: MTLComputePipelineState?
  
  private var bgTexture: MTLTexture?
  private var upperBgTexture: MTLTexture?
  private var footballTexture: MTLTexture?
  private var displayTexture: MTLTexture?
  private var starTexture: MTLTexture?
  private var titleTexture: MTLTexture?
  
  private var uniforms = [ZSUniform]()
  private var uniformsBuffer: MTLBuffer?
  
  private var timer: Float = 0
  
  override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    framebufferOnly = false
    backgroundColor = .clear
    createCPSs()
    createTextures()
    createBuffers()
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
    guard
      let cps = cps,
      let drawable = currentDrawable,
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeComputeCommandEncoder()
    else { return }
    var count = uniforms.count
    encoder.setComputePipelineState(cps)
    encoder.setTexture(drawable.texture, index: 0)
    encoder.setTexture(drawable.texture, index: 1)
    encoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
    encoder.setBytes(&count, length: MemoryLayout<Int>.size, index: 1)
    encoder.dispatchThreadgroups(drawable.texture)
    encoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

extension CommonView {
  private func createCPSs() {
    guard
      let device = device,
      let library = device.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "zs_compute")
    else { fatalError("UNKNOWN") }
    cps = try? device.makeComputePipelineState(function: kernel)
  }
  
  private func createTextures() {
    guard let device = device else { return }
    let textureLoader = MTKTextureLoader(device: device)
    let urls: [URL] = [
      "icon_bg",
      "icon_upper_bg",
      "icon_football",
      "icon_display",
      "icon_star",
      "icon_title"
    ]
    .map { Bundle.main.path(forResource: $0, ofType: "png")! }
    .map { URL(fileURLWithPath: $0) }
    let textures = textureLoader.newTextures(URLs: urls, options: nil, error: nil)
    bgTexture = textures[0]
    upperBgTexture = textures[1]
    footballTexture = textures[2]
    displayTexture = textures[3]
    starTexture = textures[4]
    titleTexture = textures[5]
  }
  
  private func createBuffers() {
    guard
      let device = device
    else { fatalError() }
    
    let scale = Float(UIScreen.main.scale)
    let transform = matrix_float4x4.identity.xy_2d
    
    if let texture = bgTexture {
      let frame = vector_float4(40 * scale, 40 * scale, 256 * scale, 256 * scale)
      let uniform = ZSUniform(frame: vector_int4(frame), transform: transform, texture: texture)
      uniforms.append(uniform)
    }
    
    if let texture = displayTexture {
      let frame = vector_float4(40 * scale, 40 * scale, 256 * scale, 256 * scale)
      let uniform = ZSUniform(frame: vector_int4(frame), transform: transform, texture: texture)
      uniforms.append(uniform)
    }
//    
//    if let texture = titleTexture {
//      let frame = vector_float4(40 * scale, 40 * scale, 256 * scale, 256 * scale)
//      let uniform = ZSUniform(frame: vector_int4(frame), transform: transform, texture: texture)
//      uniforms.append(uniform)
//    }
    
    let length = MemoryLayout<ZSUniform>.stride * uniforms.count
    guard
      let buffer = device.makeBuffer(length: length, options: [])
    else { fatalError() }
    memcpy(buffer.contents(), &uniforms, length)
    uniformsBuffer = buffer
  }
}
