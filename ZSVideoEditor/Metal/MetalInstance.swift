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
