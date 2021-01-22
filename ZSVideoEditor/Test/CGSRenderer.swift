//
//  CGSRenderer.swift
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/22.
//

// https://developer.apple.com/documentation/metal/synchronization/synchronizing_cpu_and_gpu_work

import MetalKit

fileprivate let kMaxFramesInFlight: Int = 3
fileprivate let kNumTriangles: Int = 50

fileprivate enum CGSVertexInputIndex: Int {
  case vertices = 0
  case viewportSize = 1
}

class CGSRenderer: NSObject {
  private let mtkView: MTKView
  private lazy var device: MTLDevice = { mtkView.device! }()
  private lazy var commandQueue: MTLCommandQueue = { device.makeCommandQueue()! }()
  private lazy var pipelineState: MTLRenderPipelineState = {
    let defaultLibrary = device.makeDefaultLibrary()!
    let desc = MTLRenderPipelineDescriptor()
    desc.label = "CPU-GPU-Synchronization-Pipeline"
    desc.sampleCount = mtkView.sampleCount
    desc.vertexFunction = defaultLibrary.makeFunction(name: "CGSVertexShader")
    desc.fragmentFunction = defaultLibrary.makeFunction(name: "CGSFragmentShader")
    desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
    desc.vertexBuffers[0].mutability = .immutable
    do {
      return try device.makeRenderPipelineState(descriptor: desc)
    } catch {
      fatalError(error.localizedDescription)
    }
  }()
  private lazy var viewportSize: vector_int2 = .zero
  private lazy var triangles: [ZSTriangle] = []
  private lazy var totalVertexCount: Int = 0
  private lazy var wavePosition: Float = 0
  
  private let inFlightSemaphore = DispatchSemaphore(value: kMaxFramesInFlight)
  private var vertexBuffers: [MTLBuffer] = [MTLBuffer]()
  private var currentBufferIndex: Int = 0
  
  init(_ mtkView: MTKView) {
    self.mtkView = mtkView
    super.init()
    
    generateTriangles()
    
    let triangleVertexCount = ZSTriangle.vertexCount()
    totalVertexCount = triangleVertexCount * triangles.count
    
    let triangleVertexBufferSize: Int = totalVertexCount * MemoryLayout<ZSVertex>.stride
    var buffers = [MTLBuffer]()
    for index in (0..<kMaxFramesInFlight) {
      let buffer = device.makeBuffer(length: triangleVertexBufferSize, options: .storageModeShared)!
      buffer.label = "Vertex Buffer #\(index)"
      buffers.append(buffer)
    }
    vertexBuffers = buffers
  }
  
  private func generateTriangles() {
    let colors: [vector_float4] = [
      [ 1.0, 0.0, 0.0, 1.0 ],
      [ 0.0, 1.0, 0.0, 1.0 ],
      [ 0.0, 0.0, 1.0, 1.0 ],
      [ 1.0, 0.0, 1.0, 1.0 ],
      [ 0.0, 1.0, 1.0, 1.0 ],
      [ 1.0, 1.0, 0.0, 1.0 ]
    ]
    let horizontalSpacing: Float = 16
    var triangles = [ZSTriangle]()
    for index in (0..<kNumTriangles) {
      let triangle = ZSTriangle()
      triangle.position = [
        ((Float(-kNumTriangles) / 2) + Float(index)) * horizontalSpacing, 0
      ]
      triangle.color = colors[index % colors.count]
      triangles.append(triangle)
    }
    self.triangles = triangles
  }
  
  private func update() {
    let waveMagnitude: Float = 128.0
    let waveSpeed: Float = 0.05
    
    wavePosition += waveSpeed
    
    let triangleVertices = ZSTriangle.vertices()
    let triangleVertexCount = ZSTriangle.vertexCount()
    
    let currentTriangleVertices = vertexBuffers[currentBufferIndex].contents()
    
    for triangleIndex in (0..<kNumTriangles) {
      var position = triangles[triangleIndex].position
      position.y = sin(position.x / waveMagnitude + wavePosition) * waveMagnitude
      triangles[triangleIndex].position = position
      for vertexIndex in (0..<triangleVertexCount) {
        let position = triangleVertices[vertexIndex].position + triangles[triangleIndex].position
        let color = triangles[triangleIndex].color
        var vertex = ZSVertex(position: position, color: color)
        let offset = (triangleIndex * triangleVertexCount + vertexIndex) * MemoryLayout<ZSVertex>.stride
        memcpy(currentTriangleVertices.advanced(by: offset),
               &vertex,
               MemoryLayout<ZSVertex>.stride)
      }
    }
  }
}

extension CGSRenderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    generateTriangles()
    viewportSize.x = Int32(size.width)
    viewportSize.y = Int32(size.height)
  }
  
  func draw(in view: MTKView) {
    inFlightSemaphore.wait()
    
    currentBufferIndex = (currentBufferIndex + 1) % kMaxFramesInFlight
    
    update()
    
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let desc = view.currentRenderPassDescriptor
    else { return }
    
    commandBuffer.label = "CGSCommandBuffer"
    
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc)
    renderEncoder?.label = "CGSRenderEncoder"
    
    renderEncoder?.setRenderPipelineState(pipelineState)
    
    renderEncoder?.setVertexBuffer(vertexBuffers[currentBufferIndex], offset: 0, index: 0)
    
    renderEncoder?.setVertexBytes(&viewportSize, length: MemoryLayout<vector_int2>.stride, index: 1)
    
    renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: totalVertexCount)
    
    renderEncoder?.endEncoding()
    
    commandBuffer.present(view.currentDrawable!)
    
    commandBuffer.addCompletedHandler { [weak self] (_) in
      self?.inFlightSemaphore.signal()
    }
    
    commandBuffer.commit()
  }
}

struct ZSVertex {
  let position: vector_float2
  let color: vector_float4
}

class ZSTriangle: NSObject {
  var position: vector_float2 = .zero
  var color: vector_float4 = .zero
  
  override init() {
    super.init()
  }
  
  class func vertices() -> [ZSVertex] {
    let TriangleSize: Float = 64
    return [
      ZSVertex(position: [-0.5*TriangleSize, -0.5*TriangleSize], color: [1, 1, 1, 1]),
      ZSVertex(position: [ 0.0*TriangleSize,  0.5*TriangleSize], color: [1, 1, 1, 1]),
      ZSVertex(position: [ 0.5*TriangleSize, -0.5*TriangleSize], color: [1, 1, 1, 1])
    ]
  }
  
  class func vertexCount() -> Int {
    return 3
  }
}
