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
  let texture: MTLTexture
}

//class ZSFilter {
//  private(set) var subfilters = [ZSFilter]()
//  private let uniform: ZSUniform
//  init(_ frame: CGRect, content: MTLTexture) {
//    let scale = UIScreen.main.scale
//    let frame = vector_int4(Int32(frame.origin.x * scale),
//                            Int32(frame.origin.y * scale),
//                            Int32(frame.width * scale),
//                            Int32(frame.height * scale))
//    let transform = matrix_float4x4.identity.xy_2d
//    self.uniform = ZSUniform(frame: frame,
//                             transform: transform)
//  }
//  
//  func render(_ frame: CGRect, texture: MTLTexture) {
//  }
//  
//  func addSubfilter(_ filter: ZSFilter) {
//    removeSubfilter(filter)
//    subfilters.append(filter)
//  }
//  
//  func removeSubfilter(_ filter: ZSFilter) {
//    guard
//      let index = subfilters.firstIndex(where: { $0 === filter })
//    else { return }
//    subfilters.remove(at: index)
//  }
//}
