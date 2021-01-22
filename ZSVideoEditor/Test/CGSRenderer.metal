//
//  CGSRenderer.metal
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/22.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

typedef  struct
{
  float4 position [[ position ]];
  float4 color;
} RasterizerData;

typedef struct {
  float2 position;
  float4 color;
} CGSVertex;

vertex RasterizerData CGSVertexShader(const uint vertexID [[ vertex_id ]],
                                      const device CGSVertex *vertices [[ buffer(0) ]],
                                      constant vector_uint2 *viewportSizePointer [[ buffer(1) ]])
{
  RasterizerData out;
  float2 pixelSpacePosition = vertices[vertexID].position.xy;
  vector_float2 viewportSize = vector_float2(*viewportSizePointer);
  
  float scale = min(float(vertexID) / 500.0 + 0.3, 1.0);
  
  out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
  out.position.xy = pixelSpacePosition / (viewportSize / 2.0) * scale;
  
  out.color = vertices[vertexID].color;
  
  return out;
}

fragment float4 CGSFragmentShader(RasterizerData in [[ stage_in ]])
{
  return in.color;
}
