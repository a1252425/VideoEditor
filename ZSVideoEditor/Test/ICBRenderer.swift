//
//  ICBRenderer.swift
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/19.
//

import MetalKit

fileprivate let kMaxFramesInFlight: Int = 3
fileprivate let kNumObjects: Int = 15
fileprivate let kGridWidth: Int = 5
fileprivate let kGridHeight: Int = (kNumObjects + kGridWidth - 1) / kGridWidth
fileprivate let kObjectDistance: Float = 2.1

class ICBRenderer: NSObject {
  
  private lazy var _inFlightSemaphore = DispatchSemaphore(value: kMaxFramesInFlight)
  private lazy var _device = mtkView.device!
  private lazy var _commandQueue = _device.makeCommandQueue()!
  
  private lazy var _vertexBuffer: [MTLBuffer] = {
    var buffers = [MTLBuffer]()
    for index in (0..<kNumObjects) {
      let numTeeth = index < 8 ? index + 3 : index * 3
      buffers.append(GearMesh(_device, numTeeth: numTeeth))
      buffers[index].label = "Object \(index) Buffer"
    }
    return buffers
  }()
  private lazy var _objectParameters: MTLBuffer = {
    let gridDimensions: vector_float2 = [ Float(kGridWidth), Float(kGridHeight) ]
    let offset: vector_float2 = (kObjectDistance / 2.0) * (gridDimensions - 1)
    
    var params = [ICBObjectParameters]()
    for index in 0..<kNumObjects {
      let gridPos: vector_float2 = [ Float(index % kGridWidth), Float(index / kGridWidth) ]
      let position: vector_float2 = -offset + gridPos * kObjectDistance
      params.append(ICBObjectParameters(position: position))
    }
    
    let paramsBufferSize: Int = MemoryLayout<ICBObjectParameters>.stride * params.count
    let paramsBuffer = _device.makeBuffer(length: paramsBufferSize, options: [])!
    memcpy(paramsBuffer.contents(), params, paramsBufferSize)
    
    return paramsBuffer
  }()
  private lazy var _frameStateBuffer: [MTLBuffer] = {
    var buffers = [MTLBuffer]()
    for index in 0..<kMaxFramesInFlight {
      let buffer = _device.makeBuffer(length: MemoryLayout<ICBFrameState>.stride, options: .storageModeShared)!
      buffer.label = "frame state buffer \(index)"
      buffers.append(buffer)
    }
    return buffers
  }()
  
  private lazy var _renderPipelineState: MTLRenderPipelineState = {
    let defaultLibrary = _device.makeDefaultLibrary()!
    
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.label = "ICBPipeline"
    pipelineStateDescriptor.sampleCount = mtkView.sampleCount
    pipelineStateDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "ICBVertexShader")
    pipelineStateDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "ICBFragmentShader")
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
    pipelineStateDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
    pipelineStateDescriptor.supportIndirectCommandBuffers = true
    
    do {
      return try _device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    } catch {
      fatalError(error.localizedDescription)
    }
  }()
  private lazy var _indirectFrameStateBuffer: MTLBuffer = {
    let buffer = _device.makeBuffer(length: MemoryLayout<ICBFrameState>.stride, options: .storageModePrivate)!
    buffer.label = "Indirect Frame State Buffer"
    return buffer
  }()
  
  private var _inFlightIndex: Int = 0
  private var _frameNumber: Int = 0
  
  private lazy var _indirectCommandBuffer: MTLIndirectCommandBuffer = {
    let icbDesc = MTLIndirectCommandBufferDescriptor()
    icbDesc.commandTypes = .draw
    icbDesc.inheritBuffers = false
    icbDesc.maxVertexBufferBindCount = 3
    icbDesc.maxFragmentBufferBindCount = 0
    icbDesc.inheritPipelineState = true
    return _device.makeIndirectCommandBuffer(descriptor: icbDesc, maxCommandCount: kNumObjects, options: [])!
  }()
  
  private var _aspectScale: vector_float2 = .zero
  
  private let mtkView: MTKView
  
  init(_ mtkView: MTKView) {
    self.mtkView = mtkView
    super.init()
    
    mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0.5, alpha: 1)
    mtkView.depthStencilPixelFormat = .depth32Float
    mtkView.sampleCount = 1
    
    for index in 0..<_indirectCommandBuffer.size {
      let ICBCommand = _indirectCommandBuffer.indirectRenderCommandAt(index)
      ICBCommand.setVertexBuffer(_vertexBuffer[index], offset: 0, at: 0)
      ICBCommand.setVertexBuffer(_objectParameters, offset: 0, at: 1)
      ICBCommand.setVertexBuffer(_indirectFrameStateBuffer, offset: 0, at: 2)
      let vertexCount = _vertexBuffer[index].length / MemoryLayout<ICBVertex>.stride
      ICBCommand.drawPrimitives(.triangle,
                                vertexStart: 0,
                                vertexCount: vertexCount,
                                instanceCount: 1,
                                baseInstance: index)
    }
  }
}

extension ICBRenderer: MTKViewDelegate {
  
  private func update() {
    _frameNumber += 1
    _inFlightIndex = _frameNumber % kMaxFramesInFlight
    
    var frameState = ICBFrameState(aspectScale: _aspectScale)
    let frameStateSize = MemoryLayout<ICBFrameState>.stride
    let contents = _frameStateBuffer[_inFlightIndex].contents().advanced(by: frameStateSize * _inFlightIndex)
    memcpy(contents, &frameState, frameStateSize)
  }
  
  func draw(in view: MTKView) {
    _inFlightSemaphore.wait()
    update()
    guard let commandBuffer = _commandQueue.makeCommandBuffer() else {
      return
    }
    commandBuffer.label = "Frame Command Buffer"
    commandBuffer.addCompletedHandler { [weak self] (_) in
      self?._inFlightSemaphore.signal()
    }
    guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
      return
    }
    blitEncoder.copy(from: _frameStateBuffer[_inFlightIndex], sourceOffset: 0,
                     to: _indirectFrameStateBuffer, destinationOffset: 0,
                     size: _indirectFrameStateBuffer.length)
    blitEncoder.endEncoding()
    
    guard
      let renderPassDescriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    else { return }
    renderEncoder.label = "Main Render Encoder"
    renderEncoder.setCullMode(.back)
    renderEncoder.setRenderPipelineState(_renderPipelineState)
    
    for index in 0..<kNumObjects {
      renderEncoder.useResource(_vertexBuffer[index], usage: .read)
    }
    renderEncoder.useResource(_objectParameters, usage: .read)
    renderEncoder.useResource(_indirectFrameStateBuffer, usage: .read)
    
    renderEncoder.executeCommandsInBuffer(_indirectCommandBuffer, range: 0..<kNumObjects)
    renderEncoder.endEncoding()
    
    commandBuffer.present(view.currentDrawable!)
    
    commandBuffer.commit()
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    _aspectScale.x = Float(size.height / size.width)
    _aspectScale.y = 1.0
  }
}
