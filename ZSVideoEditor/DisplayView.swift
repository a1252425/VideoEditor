//
//  DisplayView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import MetalKit

final class DisplayView: MTKView {
  
  private lazy var cps: MTLComputePipelineState = {
    guard
      let device = device,
      let library = device.makeDefaultLibrary(),
      let kernel = library.makeFunction(name: "icon")
    else { fatalError("UNKNOWN") }
    do {
      return try MetalInstance.sharedDevice.makeComputePipelineState(function: kernel)
    }
    catch {
      fatalError(error.localizedDescription)
    }
  }()
  
  private lazy var textureLoader: MTKTextureLoader = {
    return MTKTextureLoader(device: MetalInstance.sharedDevice)
  }()
  
  private lazy var bgTexture: MTLTexture = {
    guard
      let filePath = Bundle.main.path(forResource: "icon_bg", ofType: "png")
    else { fatalError("file not found") }
    let fileURL = URL(fileURLWithPath: filePath)
    do {
      return try textureLoader.newTexture(URL: fileURL, options: nil)
    } catch {
      fatalError("make texture failed")
    }
  }()
  
  private lazy var upperBgTexture: MTLTexture = {
    guard
      let filePath = Bundle.main.path(forResource: "icon_upper_bg", ofType: "png")
    else { fatalError("file not found") }
    let fileURL = URL(fileURLWithPath: filePath)
    do {
      return try textureLoader.newTexture(URL: fileURL, options: nil)
    } catch {
      fatalError("make texture failed")
    }
  }()
  
  private lazy var footballTexture: MTLTexture = {
    guard
      let filePath = Bundle.main.path(forResource: "icon_football", ofType: "png")
    else { fatalError("file not found") }
    let fileURL = URL(fileURLWithPath: filePath)
    do {
      return try textureLoader.newTexture(URL: fileURL, options: nil)
    } catch {
      fatalError("make texture failed")
    }
  }()
  
  private lazy var displayTexture: MTLTexture = {
    guard
      let filePath = Bundle.main.path(forResource: "icon_display", ofType: "png")
    else { fatalError("file not found") }
    let fileURL = URL(fileURLWithPath: filePath)
    do {
      return try textureLoader.newTexture(URL: fileURL, options: nil)
    } catch {
      fatalError("make texture failed")
    }
  }()
  
  private lazy var starTexture: MTLTexture = {
    guard
      let filePath = Bundle.main.path(forResource: "icon_star", ofType: "png")
    else { fatalError("file not found") }
    let fileURL = URL(fileURLWithPath: filePath)
    do {
      return try textureLoader.newTexture(URL: fileURL, options: nil)
    } catch {
      fatalError("make texture failed")
    }
  }()
  
  private lazy var titleTexture: MTLTexture = {
    guard
      let filePath = Bundle.main.path(forResource: "icon_title", ofType: "png")
    else { fatalError("file not found") }
    let fileURL = URL(fileURLWithPath: filePath)
    do {
      return try textureLoader.newTexture(URL: fileURL, options: nil)
    } catch {
      fatalError("make texture failed")
    }
  }()
  
  override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    framebufferOnly = false
    backgroundColor = .clear
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func update() {
    
  }
  
  override func draw(_ rect: CGRect) {
    guard
      let drawable = currentDrawable,
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer()
    else { return }
    guard
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else { return }
    commandEncoder.setComputePipelineState(cps)
    commandEncoder.setTexture(drawable.texture, index: 0)
    commandEncoder.setTexture(bgTexture, index: 1)
    commandEncoder.setTexture(upperBgTexture, index: 2)
    commandEncoder.setTexture(displayTexture, index: 3)
    commandEncoder.setTexture(starTexture, index: 4)
    commandEncoder.setTexture(footballTexture, index: 5)
    commandEncoder.setTexture(titleTexture, index: 6)
    commandEncoder.dispatchThreadgroups(drawable.texture)
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
  }
}
