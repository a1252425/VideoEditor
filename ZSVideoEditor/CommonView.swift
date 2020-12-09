//
//  CommonView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

import MetalKit

struct CommonUniforms {
  let frame: vector_float4
  let transform: matrix_float2x2
}

final class CommonView: MTKView {
  private var cps: MTLComputePipelineState?
  
  private var bgTexture: MTLTexture?
  private var upperBgTexture: MTLTexture?
  private var footballTexture: MTLTexture?
  private var displayTexture: MTLTexture?
  private var starTexture: MTLTexture?
  private var titleTexture: MTLTexture?
  
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
  
  override func layoutSubviews() {
    super.layoutSubviews()
    print(bounds)
  }
  
  private func update() {
    timer += 0.01
    if timer > 4 { timer = 0 }
  }
  
  override func draw(_ rect: CGRect) {
    update()
    guard
      let drawable = currentDrawable,
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer()
    else { return }
    
    if let encoder = commandBuffer.makeComputeCommandEncoder(), let cps = cps {
      encoder.setComputePipelineState(cps)
      encoder.setTexture(drawable.texture, index: 0)
      encoder.setTexture(drawable.texture, index: 1)
      encoder.setTexture(bgTexture, index: 2)
      encoder.setBuffer(uniformsBuffer, offset: 0, index: 0)
      encoder.dispatchThreadgroups(drawable.texture)
      encoder.endEncoding()
    }

    commandBuffer.present(drawable)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
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
      let device = device,
      let buffer = device.makeBuffer(length: MemoryLayout<CommonUniforms>.size, options: [])
    else { fatalError() }
    let scale = Float(UIScreen.main.scale)
    let frame = vector_float4(40 * scale, 40 * scale, 240 * scale, 240 * scale)
    let transform = matrix_float4x4.identity.xy_2d
    var uniforms = CommonUniforms(frame: frame,
                                  transform: transform)
    memcpy(buffer.contents(), &uniforms, MemoryLayout<CommonUniforms>.size)
    uniformsBuffer = buffer
  }
}
