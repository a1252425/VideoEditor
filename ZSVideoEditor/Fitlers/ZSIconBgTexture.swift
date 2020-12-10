//
//  ZSIconBgTexture.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/10.
//

import MetalKit

final class ZSIconBgTexture: ZSTexture {
  override func update(_ timer: Float) {
    let scale = Int32(UIScreen.main.scale)
    let frame = vector_int4(40 * scale,
                            20 * scale,
                            256 * scale,
                            256 * scale)
    let transform = matrix_float4x4.scale(1 / min(1, timer)).xy_2d
    uniform = ZSUniform(frame: frame, transform: transform)
  }
}
