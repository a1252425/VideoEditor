//
//  ZSFlashFilterGroup.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/14.
//

import MetalKit

final class ZSFlashFilterGroup {
  private var filters = [ZSFilterProtocol]()
  
  init(_ frame: CGRect) {
    let textureLoader = MetalInstance.shared.textureLoader
    let urls: [URL] = [
      "icon_line",
      "icon_line_black"
    ]
    .map { Bundle.main.path(forResource: $0, ofType: "png")! }
    .map { URL(fileURLWithPath: $0) }
    let textures = textureLoader.newTextures(URLs: urls, options: nil, error: nil)
    
    let dx = frame.width / 8
    let dy = frame.height / 8
    
    let frameLength = sqrt(frame.width * frame.width + frame.height * frame.height)
    let lineWidth = frameLength / 8
    let lineHeight = frame.width / lineWidth * frame.height
    let angle = -atan(frame.height / frame.width)
    
    let line1Frame = CGRect(x: dx * 3,
                            y: dy * 3,
                            width: lineWidth,
                            height: frame.height)
    let line1Filter = ZSFilter(line1Frame)
    line1Filter.set(content: textures[0])
    filters.append(line1Filter)
//    let line1Translate1 = ZSFilterAnimation(startTime: 0, endTime: 1.5, type: .translate(from: CGPoint(x: -lineHeight, y: -lineWidth), to: CGPoint(x: -lineHeight, y: -lineWidth)))
//    let line1Translate2 = ZSFilterAnimation(startTime: 1.5, endTime: 4.0, type: .translate(from: CGPoint(x: -lineHeight, y: -lineWidth), to: CGPoint(x: lineHeight, y: lineWidth)))
//    line1Filter.add(line1Translate1)
//    line1Filter.add(line1Translate2)
    
    let rotateAnimation = ZSFilterAnimation(startTime: 0, endTime: 40.0, type: .rotate(from: Float(angle), to: Float(angle)))
    filters.forEach { (filter) in
      filter.add(rotateAnimation)
//      filter.add(ZSFilterAnimation(startTime: 0.0, endTime: 0.7, type: .scale(from: 0, to: 0)))
//      filter.add(ZSFilterAnimation(startTime: 0.7, endTime: 1.0, type: .scale(from: 0, to: 1)))
    }
  }
  
  func render(_ inTexture: MTLTexture, timer: Float) {
    filters.forEach { $0.render(inTexture, time: timer) }
  }
}
