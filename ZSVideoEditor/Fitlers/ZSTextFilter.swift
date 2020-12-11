//
//  ZSTextFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/11.
//

import MetalKit

final class ZSTextFilter: ZSFilter {
  
  private(set) var textures = [(Float, MTLTexture)]()
  func set(speed: Float, beginTime: Float = 1.5, duration: Float) {
    textures.removeAll()
    let interval: Float = 0.04
    var timer: Float = 0
    while timer < duration {
      let sliceSpeed = speed / duration * timer
      textures.append((timer + beginTime, makeTexture(sliceSpeed)))
      timer += interval
    }
    textures.append((duration + beginTime, makeTexture(speed)))
  }
  
  func makeTexture(_ speed: Float) -> MTLTexture {
    let string = "\(Int(speed))KM/H"
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 50, weight: .semibold),
      .foregroundColor: UIColor.red
    ]
    let attributeString = NSAttributedString(string: string,
                                             attributes: attributes)
    let filterWidth = CGFloat(self.frame.z)
    let filterHeight = CGFloat(self.frame.w)
    let filterSize = CGSize(width: filterWidth, height: filterHeight)
    let size = attributeString.size()
    let origin = CGPoint(x: 0, y: (filterHeight - size.height) * 0.5)
    let frame = CGRect(origin: origin, size: size)
    let pngData = UIGraphicsImageRenderer(size: filterSize)
      .pngData { _ in attributeString.draw(in: frame) }
    do {
      return try MetalInstance
        .shared
        .textureLoader
        .newTexture(data: pngData, options: nil)
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  override func render(_ inTexture: MTLTexture, time: Float) {
    guard
      let texture = textures.last(where: { $0.0 < time })
    else { return }
    set(content: texture.1)
    super.render(inTexture, time: time)
  }
}
