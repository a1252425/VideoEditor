//
//  MetalInstance.swift
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/2.
//

import Metal

public class MetalInstance {
  public static let shared: MetalInstance = MetalInstance()
  public static var sharedDevice: MTLDevice { return shared.device }
  public static var sharedCommandQueue: MTLCommandQueue { return shared.commandQueue }

  public let device: MTLDevice
  public let commandQueue: MTLCommandQueue

  private init() {
    device = MTLCreateSystemDefaultDevice()!
    commandQueue = device.makeCommandQueue()!
  }
}

extension MetalInstance {
  public class func makeTexture(width: Int,
                                height: Int,
                                format: MTLPixelFormat = .rgba8Unorm,
                                usage: MTLTextureUsage = [.shaderWrite, .shaderRead],
                                mipmapped: Bool = false) -> MTLTexture? {
    let desc = MTLTextureDescriptor()
    desc.pixelFormat = format
    desc.width = width
    desc.height = height
    desc.usage = usage
    return sharedDevice.makeTexture(descriptor: desc)
  }

  public class func makeTexture(_ texture: MTLTexture,
                                usage: MTLTextureUsage = [.shaderWrite, .shaderRead]) -> MTLTexture? {
    return makeTexture(width: texture.width,
                       height: texture.height,
                       format: texture.pixelFormat)
  }
  
  func testDescriptoor1() {
    let colorTexDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                width: 1280,
                                                                height: 720,
                                                                mipmapped: false)
    let colorTex = device.makeTexture(descriptor: colorTexDesc)
    let depthTexDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                width: 1280,
                                                                height: 720,
                                                                mipmapped: false)
    let depthTex = device.makeTexture(descriptor: depthTexDesc)
    
    let renderPassDesc = MTLRenderPassDescriptor()
    renderPassDesc.colorAttachments[0].texture = colorTex
    renderPassDesc.colorAttachments[0].loadAction = .clear
    renderPassDesc.colorAttachments[0].storeAction = .store
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
    renderPassDesc.depthAttachment.texture = depthTex
    renderPassDesc.depthAttachment.loadAction = .clear
    renderPassDesc.depthAttachment.storeAction = .store
    renderPassDesc.depthAttachment.clearDepth = 1
  }
  
  func testDescriptoor2() {
    let colorTexDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                 width: 1280,
                                                                 height: 720,
                                                                 mipmapped: false)
    let colorTex = device.makeTexture(descriptor: colorTexDesc)
    let msaaTexDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                               width: 1280,
                                                               height: 720,
                                                               mipmapped: false)
    msaaTexDesc.textureType = .type2DMultisample
    msaaTexDesc.sampleCount = 2
    let msaaTex = device.makeTexture(descriptor: msaaTexDesc)
    
    let renderPassDesc = MTLRenderPassDescriptor()
    renderPassDesc.colorAttachments[0].texture = msaaTex
    renderPassDesc.colorAttachments[0].resolveTexture = colorTex
    renderPassDesc.colorAttachments[0].loadAction = .clear
    renderPassDesc.colorAttachments[0].storeAction = .multisampleResolve
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
    let commandBuffer = commandQueue.makeCommandBuffer()
    let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesc)
    renderEncoder?.setTriangleFillMode(.lines)
    
    guard
      let library = device.makeDefaultLibrary(),
      let vertexFunc = library.makeFunction(name: "vertexMath")
    else { return }
    
    let parallelRenderCommandEncoder = commandBuffer?.makeParallelRenderCommandEncoder(descriptor: renderPassDesc)
    let rce1 = parallelRenderCommandEncoder?.makeRenderCommandEncoder()
    let rce2 = parallelRenderCommandEncoder?.makeRenderCommandEncoder()
    let rce3 = parallelRenderCommandEncoder?.makeRenderCommandEncoder()
    rce1?.endEncoding()
    rce2?.endEncoding()
    rce3?.endEncoding()
    parallelRenderCommandEncoder?.endEncoding()
    
    let renderPiplineDesc = MTLRenderPipelineDescriptor()
    
//    renderPiplineDesc.fragmentFunction =
    renderPiplineDesc.colorAttachments[0].pixelFormat = .rgba8Unorm
    renderPiplineDesc.colorAttachments[0].isBlendingEnabled = true
    renderPiplineDesc.colorAttachments[0].rgbBlendOperation = .add
    renderPiplineDesc.colorAttachments[0].alphaBlendOperation = .add
    renderPiplineDesc.colorAttachments[0].sourceRGBBlendFactor = .one
    renderPiplineDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
    renderPiplineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    renderPiplineDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    
    let vertexDesc = MTLVertexDescriptor()
    vertexDesc.attributes[0].format = .float2
    vertexDesc.attributes[0].bufferIndex = 0
    vertexDesc.attributes[0].offset = 0
    vertexDesc.attributes[1].format = .float4
    vertexDesc.attributes[1].bufferIndex = 0
    vertexDesc.attributes[1].offset = 2 * MemoryLayout.size(ofValue: MTLVertexFormat.float)
    vertexDesc.attributes[2].format = .float2
    vertexDesc.attributes[2].bufferIndex = 0
    vertexDesc.attributes[2].offset = 8 * MemoryLayout.size(ofValue: MTLVertexFormat.float)
    vertexDesc.attributes[3].format = .float2
    vertexDesc.attributes[3].bufferIndex = 0
    vertexDesc.attributes[3].offset = 6 * MemoryLayout.size(ofValue: MTLVertexFormat.float)
    vertexDesc.layouts[0].stride = 10 * MemoryLayout.size(ofValue: MTLVertexFormat.float)
    vertexDesc.layouts[0].stepFunction = .perVertex
    
    renderPiplineDesc.vertexDescriptor = vertexDesc
    renderPiplineDesc.vertexFunction = vertexFunc
    
    let dsDesc = MTLDepthStencilDescriptor()
    dsDesc.depthCompareFunction = .less
    dsDesc.isDepthWriteEnabled = true
    dsDesc.frontFaceStencil.stencilCompareFunction = .equal
    dsDesc.frontFaceStencil.stencilFailureOperation = .keep
    dsDesc.frontFaceStencil.depthFailureOperation = .incrementClamp
    dsDesc.frontFaceStencil.depthStencilPassOperation = .incrementClamp
    dsDesc.frontFaceStencil.readMask = 0x1
    dsDesc.frontFaceStencil.writeMask = 0x1
    dsDesc.backFaceStencil = nil
    
    let dsState = device.makeDepthStencilState(descriptor: dsDesc)
    renderEncoder?.setDepthStencilState(dsState)
    
    let piplineState = try? device.makeRenderPipelineState(descriptor: renderPiplineDesc)
    
    renderEncoder?.setRenderPipelineState(piplineState!)
    
    renderEncoder?.setVertexBuffer(nil, offset: 0, index: 0)
  }
  
  func testComputer1() {
    //  LEVEL:  1000
    guard let library = device.makeDefaultLibrary() else { return }
    //  LEVEL:  100
    guard
      let filter = library.makeFunction(name: "filter_main"),
      let filterState = try? device.makeComputePipelineState(function: filter)
    else { return }
    
    //  LEVEL:  0
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
    else { return }
    
    computeCommandEncoder.setComputePipelineState(filterState)
//    computeCommandEncoder.setTexture(inputImage, index: 0)
//    computeCommandEncoder.setTexture(outputImage, index: 1)
//    computeCommandEncoder.setTexture(inputTableData, index: 2)
//    computeCommandEncoder.setBuffer(paramsBuffer, offset: 0, index: 0)
    let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
    let numThreadGroups = MTLSize(
      width: 1280 / threadsPerGroup.width,
      height: 720 / threadsPerGroup.height,
      depth: 1
    )
    
    computeCommandEncoder.dispatchThreads(threadsPerGroup, threadsPerThreadgroup: numThreadGroups)
    computeCommandEncoder.endEncoding()
    commandBuffer.commit()
  }
}
