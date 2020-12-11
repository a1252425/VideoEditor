//
//  CommonView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

import MetalKit

final class CommonView: MTKView {
  private var textures = [MTLTexture]()
  
  private lazy var clearFilter = ZSClearFilter()
  private lazy var bgFilter = ZSFilter(CGRect(x: 60, y: 30, width: 210, height: 210))
  private lazy var filterGroup = ZSShootFilterGroup()
//  private lazy var textFilter: ZSTextFilter = {
//    let textFilter = ZSTextFilter(CGRect(x: 400, y: 50, width: 300, height: 120))
//    textFilter.set(speed: 120, duration: 1.2)
//    return textFilter
//  }()
  
  private var timer: Float = 0
  
  override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    framebufferOnly = false
    backgroundColor = .clear
    createTextures()
    bgFilter.set(content: textures[0])
    addAnimations()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func update() {
    timer += 0.01
    if timer > 8 { timer = 0 }
  }
  
  override func draw(_ rect: CGRect) {
    update()
    guard let drawable = currentDrawable else { return }
    
    clearFilter.render(drawable.texture)
    bgFilter.render(drawable.texture, time: timer)
    filterGroup.render(drawable.texture, timer: timer)
//    textFilter.render(drawable.texture, time: timer)
    
    guard
      let commandBuffer = MetalInstance.sharedCommandQueue.makeCommandBuffer()
    else { return }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

extension CommonView {
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
    textures = textureLoader.newTextures(URLs: urls, options: nil, error: nil)
  }
}

extension CommonView {
  private func addAnimations() {
    let animations: [ZSFilterAnimation] = [
      ZSFilterAnimation(startTime: 1.5, endTime: 2.5, type: .scale(from: 1, to: 0)),
      ZSFilterAnimation(startTime: 2.5, endTime: 3.5, type: .scale(from: 0, to: 1)),
      ZSFilterAnimation(startTime: 3.9, endTime: 4.5, type: .rotate(from: 0, to: .pi * 0.25)),
      ZSFilterAnimation(startTime: 4.5, endTime: 6, type: .rotate(from: .pi * 0.25, to: 0)),
      ZSFilterAnimation(startTime: 1.5, endTime: 2.5, type: .translate(from: CGPoint(x: 0, y: 0), to: CGPoint(x: -80, y: -80))),
      ZSFilterAnimation(startTime: 2.5, endTime: 4.5, type: .translate(from: CGPoint(x: -80, y: -80), to: CGPoint(x: 0, y: 0)))
    ]
    animations.forEach { bgFilter.add($0) }
  }
}
