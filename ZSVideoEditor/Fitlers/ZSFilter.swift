//
//  ZSFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import MetalKit

struct ZSUniform {
  let frame: vector_int4
  let transform: matrix_float2x2
}

struct ZSFilterUniform {
  let frame: vector_float4
  let transform: matrix_float2x2
}

enum ZSFilterAnimationType {
  case scale(from: Float, to: Float)
  case alpha(from: Float, to: Float)
  case translate(from: CGPoint, to: CGPoint)
  case rotate(from: Float, to: Float)
}

struct ZSFilterAnimation {
  let startTime: Float
  let endTime: Float
  let type: ZSFilterAnimationType
}

class ZSFilterAttactment {}

class ZSFilter {}

extension Collection where Element == ZSFilterAnimation {
  func transform2d(_ time: Float) -> matrix_float2x2 {
    var matrix = matrix_float4x4.identity
    
    //  translate
    if
      let translateAnimation = first(where: { (animation) -> Bool in
      if case .translate = animation.type {
        return animation.startTime < time && animation.endTime > time
      }
      return false
    }) {
      if case let .translate(from, to) = translateAnimation.type {
        let progress = (time - translateAnimation.startTime) / (translateAnimation.endTime - translateAnimation.startTime)
        let x = Float(to.x - from.x) * progress + Float(from.x)
        let y = Float(to.y - from.y) * progress + Float(from.y)
        matrix = matrix_float4x4.translation(vector_float3(x, y ,0))
      }
    }
    
    //  scale
    if
      let animation = first(where: { (animation) -> Bool in
      if case .scale = animation.type {
        return animation.startTime < time && animation.endTime > time
      }
      return false
    }) {
      if case let .scale(from, to) = animation.type {
        let progress = (time - animation.startTime) / (animation.endTime - animation.startTime)
        let scale = Float(to - from) * progress + Float(from)
        matrix = matrix_multiply(matrix, matrix_float4x4.scale(1/scale))
      }
    }
    
    //  rotate
    if
      let animation = first(where: { (animation) -> Bool in
      if case .rotate = animation.type {
        return animation.startTime < time && animation.endTime > time
      }
      return false
    }) {
      if case let .rotate(from, to) = animation.type {
        let progress = (time - animation.startTime) / (animation.endTime - animation.startTime)
        let rotate = Float(to - from) * progress + Float(from)
        matrix = matrix_multiply(matrix, matrix_float4x4.rotate(rotate, axis: vector_float3(0, 0, 1)))
      }
    }
    
    return matrix.xy_2d
  }
}
