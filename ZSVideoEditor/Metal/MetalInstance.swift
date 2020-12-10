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
  
  public class func makeTexture(width: Int, height: Int, textures: [MTLTexture]) -> MTLTexture {
    let buffer = MetalInstance.sharedCommandQueue.makeCommandBuffer()!
    let blitEncoder = buffer.makeBlitCommandEncoder()!
    let desc = MTLTextureDescriptor()
    desc.pixelFormat = .bgra8Unorm
    desc.width = textures.max(by: { $0.width < $1.width })!.width
    desc.height = textures.max(by: { $0.height < $1.height })!.height
    desc.usage = [.shaderRead, .shaderWrite]
    desc.arrayLength = textures.count
    desc.textureType = .type2DArray
    let texture = MetalInstance.sharedDevice.makeTexture(descriptor: desc)!
    (0..<textures.count).forEach { (index) in
      let item = textures[index]
      blitEncoder.copy(from: textures[index],
                       sourceSlice: 0,
                       sourceLevel: 0,
                       sourceOrigin: MTLOriginMake(0, 0, 0),
                       sourceSize: MTLSizeMake(item.width, item.height, 1),
                       to: texture,
                       destinationSlice: index,
                       destinationLevel: 0,
                       destinationOrigin: MTLOriginMake(0, 0, 0))
    }
    blitEncoder.endEncoding()
    buffer.commit()
    buffer.waitUntilCompleted()
    return texture
  }
}

extension MTLComputeCommandEncoder {
  func dispatchThreadgroups(_ texture: MTLTexture) {
    let threadGroupCount = MTLSizeMake(8, 8, 1)
    let threadGroupsWidth = (texture.width - 1) / threadGroupCount.width + 1
    let threadGroupsHeight = (texture.height - 1) / threadGroupCount.height + 1
    let threadGroups = MTLSizeMake(threadGroupsWidth, threadGroupsHeight, 1)
    dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
  }
}
