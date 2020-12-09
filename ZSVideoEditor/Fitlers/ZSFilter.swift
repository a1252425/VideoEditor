//
//  ZSFilter.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/8.
//

import MetalKit

struct ZSUniforms {
  let frame: vector_int4
  let transform: matrix_float2x2
}

class ZSFilter {
  var outTexture: MTLTexture?
  private(set) var subfilters = [ZSFilter]()
  
  let uniforms: ZSUniforms
  let content: MTLTexture
  init(_ uniforms: ZSUniforms, content: MTLTexture) {
    self.uniforms = uniforms
    self.content = content
  }
  
  func render(inTexture: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
//    subfilters.forEach {
//      outTexture = $0.render(inTexture: content, commandBuffer: commandBuffer)
//    }
    return outTexture
  }
  
  func addSubfilter(_ filter: ZSFilter) {
    subfilters.append(filter)
  }
  
  func removeSubfilter(_ filter: ZSFilter) {
    guard
      let index = subfilters.firstIndex(where: { $0 === filter })
    else { return }
    subfilters.remove(at: index)
  }
}
