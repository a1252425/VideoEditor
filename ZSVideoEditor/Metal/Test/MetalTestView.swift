//
//  MetalTestView.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/4.
//

import UIKit
import MetalKit
import simd

final class MetalTestView: MTKView {
  private var commandQueue: MTLCommandQueue?
  private var vertexBuffer: MTLBuffer?
  private var index_buffer: MTLBuffer?
  private lazy var uniform_buffer: MTLBuffer? = {
    return device?.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [])
  }()
  private var rps: MTLRenderPipelineState?
  
  var rotaton: Float = 0
  
  init(frame frameRect: CGRect = .zero) {
    super.init(frame: frameRect, device: MTLCreateSystemDefaultDevice())
    commandQueue = device?.makeCommandQueue()
    
    createRenderBuffer()
    createRenderPiplineState()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func createRenderBuffer() {
    let vertexData: [Vertex] = [
      Vertex(pos: [-1.0, -1.0,  1.0, 1.0], col: [1, 0, 0, 1]),
      Vertex(pos: [ 1.0, -1.0,  1.0, 1.0], col: [0, 1, 0, 1]),
      Vertex(pos: [ 1.0,  1.0,  1.0, 1.0], col: [0, 0, 1, 1]),
      Vertex(pos: [-1.0,  1.0,  1.0, 1.0], col: [1, 1, 1, 1]),
      Vertex(pos: [-1.0, -1.0, -1.0, 1.0], col: [0, 0, 1, 1]),
      Vertex(pos: [ 1.0, -1.0, -1.0, 1.0], col: [1, 1, 1, 1]),
      Vertex(pos: [ 1.0,  1.0, -1.0, 1.0], col: [1, 0, 0, 1]),
      Vertex(pos: [-1.0,  1.0, -1.0, 1.0], col: [0, 1, 0, 1])
    ]
    let dataSize = vertexData.count * MemoryLayout<Vertex>.size
    vertexBuffer = device?.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    
    let index_data: [UInt16] = [
      0, 1, 2, 2, 3, 0,
      1, 5, 6, 6, 2, 1,
      3, 2, 6, 6, 7, 3,
      4, 5, 1, 1, 0, 4,
      4, 0, 3, 3, 7, 4,
      7, 6, 5, 5, 4, 7
    ]
    let indexSize = index_data.count * MemoryLayout<UInt16>.size
    index_buffer = device?.makeBuffer(bytes: index_data, length: indexSize, options: [])
  }
  
  private func createRenderPiplineState() {
    let library = device?.makeDefaultLibrary()
    let vertex_func = library?.makeFunction(name: "vertex_func")
    let frag_func = library?.makeFunction(name: "fragment_func")
    let rpld = MTLRenderPipelineDescriptor()
    rpld.vertexFunction = vertex_func
    rpld.fragmentFunction = frag_func
    rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
    rps = try? device?.makeRenderPipelineState(descriptor: rpld)
  }
  
  func update() {
    let scaled = scalingMaxtri(0.5)
    rotaton += 1.0 / 100 * .pi / 4
    let rotatedY = rotationMatrix(rotaton, axis: vector_float3(0, 1, 0))
    let rotatedX = rotationMatrix(.pi / 4, axis: vector_float3(1, 0, 0))
    let modelMatrix = matrix_multiply(matrix_multiply(rotatedX, rotatedY), scaled)
    let cameraPosition = vector_float3(0, 0, -3)
    let viewMatrix = translationMatrix(cameraPosition)
    let aspect = Float(drawableSize.width / drawableSize.height)
    let projMatrix = projectionMatrix(near: 0, far: 10, aspect: aspect, fovy: 1)
    let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
    let bufferPointer = uniform_buffer?.contents()
    var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
    memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
  }
  
  override func draw(_ rect: CGRect) {
    guard
      let drawable = currentDrawable,
      let rpd = currentRenderPassDescriptor
    else { return }
    update()
    rpd.colorAttachments[0].texture = drawable.texture
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.5, 0.5, 1)
    guard
      let commandBuffer = commandQueue?.makeCommandBuffer()
    else { return }
    
    guard
      let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
    else { return }
    commandEncoder.setFrontFacing(.counterClockwise)
    commandEncoder.setCullMode(.back)
    commandEncoder.setRenderPipelineState(rps!)
    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    commandEncoder.setVertexBuffer(uniform_buffer, offset: 0, index: 1)
    let indexCount = index_buffer!.length / MemoryLayout<UInt16>.size
    commandEncoder.drawIndexedPrimitives(type: .triangle,
                                         indexCount: indexCount,
                                         indexType: .uint16,
                                         indexBuffer: index_buffer!,
                                         indexBufferOffset: 0)
    commandEncoder.endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
