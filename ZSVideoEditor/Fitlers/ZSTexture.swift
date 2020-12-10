//
//  ZSTexture.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/10.
//

import MetalKit

class ZSTexture {
  let texture: MTLTexture
  lazy var uniform: ZSUniform = {
    let frame = vector_int4(0, 0, Int32(texture.width), Int32(texture.height))
    let transform = matrix_float4x4.identity.xy_2d
    return ZSUniform(frame: frame, transform: transform)
  }()
  init(_ texture: MTLTexture) {
    self.texture = texture
  }
  func update(_ timer: Float) {
    
  }
}
