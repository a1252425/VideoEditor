//
//  CommonView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

import MetalKit

final class CommonView: MTKView {
  private var textures = [ZSTexture]()
  private lazy var paFilter: ZSPictureAnimationFilter = {
    return ZSPictureAnimationFilter(content: textures[0].texture)
  }()
  
  private var timer: Float = 0
  
  override init(frame frameRect: CGRect, device: MTLDevice?) {
    super.init(frame: frameRect, device: device)
    framebufferOnly = false
    backgroundColor = .clear
    createTextures()
    addAnimations()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func update() {
    timer += 0.01
    print("timer: \(timer)")
  }
  
  override func draw(_ rect: CGRect) {
    update()
    guard let drawable = currentDrawable else { return }
    
    paFilter.render(drawable.texture,
                    frame: CGRect(x: 60, y: 30, width: 210, height: 210),
                    time: timer)
    
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
    let textures = textureLoader.newTextures(URLs: urls, options: nil, error: nil)
    self.textures.append(ZSIconBgTexture(textures[0]))
    self.textures.append(ZSUpperTexture(textures[1]))
    self.textures.append(ZSFootballTexture(textures[2]))
    self.textures.append(ZSDisplayTexture(textures[3]))
    self.textures.append(ZSStarTexture(textures[4]))
    self.textures.append(ZSTitleTexture(textures[5]))
  }
}

extension CommonView {
  private func addAnimations() {
    let animations: [ZSFilterAnimation] = [
      ZSFilterAnimation(startTime: 1.5, endTime: 2.5, type: .scale(from: 1, to: 0)),
      ZSFilterAnimation(startTime: 2.5, endTime: 3.5, type: .scale(from: 0, to: 1)),
      ZSFilterAnimation(startTime: 3.9, endTime: 4.5, type: .rotate(from: 0, to: .pi * 0.25)),
      ZSFilterAnimation(startTime: 4.5, endTime: 6, type: .rotate(from: .pi * 0.25, to: 0)),
      ZSFilterAnimation(startTime: 1.5, endTime: 2.5, type: .translate(from: CGPoint(x: 120, y: 400), to: CGPoint(x: 400, y: 900)))
    ]
    animations.forEach { paFilter.add($0) }
  }
}
