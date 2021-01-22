//
//  InnerShadowLayer.swift
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/19.
//

import UIKit

class InnerShadowLayer: CALayer {
  
  var innerShadowColor: CGColor? = UIColor.black.cgColor {
    didSet {
      setNeedsDisplay()
    }
  }
  var innerShadowOffset: CGSize = .zero {
    didSet {
      setNeedsDisplay()
    }
  }
  var innerShadowRadius: CGFloat = 8 {
    didSet {
      setNeedsDisplay()
    }
  }
  var innerShadowOpacity: Float = 1 {
    didSet {
      setNeedsDisplay()
    }
  }
  
  override init() {
    super.init()
    masksToBounds = true
    shouldRasterize = true
    contentsScale = UIScreen.main.scale
    rasterizationScale = UIScreen.main.scale
    setNeedsDisplay()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(in ctx: CGContext) {
    //  抗锯齿
    ctx.setAllowsAntialiasing(true)
    //  平滑
    ctx.setShouldAntialias(true)
    //  插值质量
    ctx.interpolationQuality = .high
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let rect = bounds.insetBy(dx: borderWidth, dy: borderWidth)
    let radius = max(cornerRadius - borderWidth, 0)
    
    //  可渲染区域
    let someInnerPath = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
    ctx.addPath(someInnerPath)
    ctx.clip()
    
    //  镂空中心
    let shadowPath = CGMutablePath()
    let shadowRect = rect.insetBy(dx: -rect.size.width, dy: -rect.size.width)
    shadowPath.addRect(shadowRect)
    shadowPath.addPath(someInnerPath)
    shadowPath.closeSubpath()
    
    let oldComponents = innerShadowColor?.components
    var newComponents: [CGFloat] = [0, 0, 0, 0]
    let numberOfComponents = innerShadowColor?.numberOfComponents
    switch numberOfComponents {
      case 2:
        newComponents[0] = oldComponents![0]
        newComponents[1] = oldComponents![0]
        newComponents[2] = oldComponents![0]
        newComponents[3] = oldComponents![1] * CGFloat(innerShadowOpacity)
      case 4:
        newComponents[0] = oldComponents![0]
        newComponents[1] = oldComponents![1]
        newComponents[2] = oldComponents![2]
        newComponents[3] = oldComponents![3] * CGFloat(innerShadowOpacity)
      default: break
    }
    
    let innerShadowColorWithMultipledAlpha = CGColor(colorSpace: colorSpace, components: newComponents)
    
    ctx.setFillColor(innerShadowColorWithMultipledAlpha!)
    ctx.setShadow(offset: innerShadowOffset, blur: innerShadowRadius, color: innerShadowColorWithMultipledAlpha)
    ctx.addPath(shadowPath)
    ctx.fillPath(using: .evenOdd)
  }
}
