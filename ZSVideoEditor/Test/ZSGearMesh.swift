//
//  ZSGearMesh.swift
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/22.
//

import MetalKit

struct ICBVertex {
  let position: packed_float2
  let texcoord: packed_float2
}

struct ICBObjectMesh {
  let vertices: [ICBVertex]
  let numVerts: UInt32
}

struct ICBObjectParameters {
  let position: packed_float2
}

struct ICBFrameState {
  var aspectScale: vector_float2
}

func GearMesh(_ device: MTLDevice, numTeeth: Int) -> MTLBuffer {
  
  let innerRatio: Float = 0.8
  let toothWidth: Float = 0.25
  let toothSlope: Float = 0.2
  
  let angle: Float = .pi * 2.0 / Float(numTeeth)
  let origin: packed_float2 = [0.0, 0.0]
  
  var vertices = [ICBVertex]()
  for tooth in (0..<numTeeth) {
    let toothF = Float(tooth)
    let toothStartAngle = toothF * angle
    let toothTip1Angle = (toothF + toothSlope) * angle
    let toothTip2Angle = (toothF + toothSlope + toothWidth) * angle
    let toothEndAngle = (toothF + 2 * toothSlope + toothWidth) * angle
    let nextToothAngle = (toothF + 1.0) * angle
    
    let groove1: packed_float2 = [
      sin(toothStartAngle) * innerRatio,
      cos(toothStartAngle) * innerRatio
    ]
    let tip1: packed_float2 = [
      sin(toothTip1Angle),
      cos(toothTip1Angle)
    ]
    let tip2: packed_float2 = [
      sin(toothTip2Angle),
      cos(toothTip2Angle)
    ]
    let groove2: packed_float2 = [
      sin(toothEndAngle) * innerRatio,
      cos(toothEndAngle) * innerRatio
    ]
    let nextGroove: packed_float2 = [
      sin(nextToothAngle) * innerRatio,
      cos(nextToothAngle) * innerRatio
    ]
    
    vertices.append(ICBVertex(position: groove1, texcoord: (groove1 + 1.0) / 2.0))
    vertices.append(ICBVertex(position: tip1, texcoord: (tip1 + 1.0) / 2.0))
    vertices.append(ICBVertex(position: tip2, texcoord: (tip2 + 1.0) / 2.0))
    
    vertices.append(ICBVertex(position: groove1, texcoord: (groove1 + 1.0) / 2.0))
    vertices.append(ICBVertex(position: tip2, texcoord: (tip2 + 1.0) / 2.0))
    vertices.append(ICBVertex(position: groove2, texcoord: (groove2 + 1.0) / 2.0))
    
    vertices.append(ICBVertex(position: origin, texcoord: (origin + 1.0) / 2.0))
    vertices.append(ICBVertex(position: groove1, texcoord: (groove1 + 1.0) / 2.0))
    vertices.append(ICBVertex(position: groove2, texcoord: (groove2 + 1.0) / 2.0))
    
    vertices.append(ICBVertex(position: origin, texcoord: (origin + 1.0) / 2.0))
    vertices.append(ICBVertex(position: groove2, texcoord: (groove2 + 1.0) / 2.0))
    vertices.append(ICBVertex(position: nextGroove, texcoord: (nextGroove + 1.0) / 2.0))
  }
  
  let bufferSize: Int = MemoryLayout<ICBVertex>.stride * vertices.count
  guard let buffer = device.makeBuffer(length: bufferSize, options: []) else {
    fatalError("buffer create fail")
  }
  memcpy(buffer.contents(), vertices, bufferSize)
  
  return buffer
}
