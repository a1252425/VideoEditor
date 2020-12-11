//
//  ZSShootFilterGroup.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/11.
//

import MetalKit

final class ZSShootFilterGroup {
  private var filters = [ZSFilter]()
  
  init() {
    let textureLoader = MetalInstance.shared.textureLoader
    let urls: [URL] = [
      "event_shoot_circle_1",
      "event_shoot_circle_2",
      "event_shoot_circle_3",
      "event_shoot_circle_4",
      "event_shoot_circle_5",
      "event_shoot_circle_6",
      "event_shoot_speed_bg",
      "event_shoot_arrow"
    ]
    .map { Bundle.main.path(forResource: $0, ofType: "png")! }
    .map { URL(fileURLWithPath: $0) }
    let textures = textureLoader.newTextures(URLs: urls, options: nil, error: nil)
    
    let center = CGPoint(x: 600 + 80, y: 60 + 80)
    let size: CGFloat = 200
    
    let circle1Frame = CGRect.make(center, size: CGSize(width: size, height: size))
    let circle1Filter = ZSFilter(circle1Frame)
    circle1Filter.set(content: textures[0])
    filters.append(circle1Filter)
    
    let circle2Frame = CGRect.make(center, size: CGSize(width: size - 8, height: size - 8))
    let circle2Filter = ZSFilter(circle2Frame)
    circle2Filter.set(content: textures[1])
    filters.append(circle2Filter)
    
    let circle3Frame = CGRect.make(center, size: CGSize(width: size - 16, height: size - 16))
    let circle3Filter = ZSFilter(circle3Frame)
    circle3Filter.set(content: textures[2])
    filters.append(circle3Filter)
    
    let circle4Frame = CGRect.make(center, size: CGSize(width: size - 24, height: size - 24))
    let circle4Filter = ZSFilter(circle4Frame)
    circle4Filter.set(content: textures[3])
    filters.append(circle4Filter)
    
    let circle5Frame = CGRect.make(center, size: CGSize(width: size - 32, height: size - 32))
    let circle5Filter = ZSFilter(circle5Frame)
    circle5Filter.set(content: textures[4])
    filters.append(circle5Filter)
    
    let circle6Frame = CGRect.make(center, size: CGSize(width: size - 40, height: size - 40))
    let circle6Filter = ZSFilter(circle6Frame)
    circle6Filter.set(content: textures[5])
    filters.append(circle6Filter)
    
    let rotateAnimation = ZSFilterAnimation(startTime: 1.0, endTime: 4.0, type: .rotate(from: 0, to: .pi * 4))
    let reverceRotateAnimation = ZSFilterAnimation(startTime: 1.0, endTime: 4.0, type: .rotate(from: 0, to: -.pi * 4))
    circle1Filter.add(rotateAnimation)
    circle3Filter.add(reverceRotateAnimation)
    circle4Filter.add(rotateAnimation)
    circle5Filter.add(reverceRotateAnimation)
    circle6Filter.add(rotateAnimation)
    
    filters.forEach { (filter) in
      filter.add(ZSFilterAnimation(startTime: 0.0, endTime: 1.0, type: .scale(from: 0, to: 1)))
    }
    
//    let arrowFilter = ZSFilter(CGRect(x: 400, y: 30, width: 90, height: 90))
//    circle1Filter.set(content: textures[0])
//    filters.append(circle1Filter)
  }
  
  func render(_ inTexture: MTLTexture, timer: Float) {
    filters.forEach { $0.render(inTexture, time: timer) }
  }
}

extension CGRect {
  static func make(_ center: CGPoint, size: CGSize) -> CGRect {
    let origin = CGPoint(x: center.x - size.width * 0.5,
                         y: center.y - size.height * 0.5)
    return CGRect(origin: origin, size: size)
  }
}
