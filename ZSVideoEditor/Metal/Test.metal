//
//  Test.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/3.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInput {
  float2 position [[ attribute(0) ]];
  float4 color    [[ attribute(1) ]];
  float4 uv1      [[ attribute(2) ]];
  float4 uv2      [[ attribute(3) ]];
};

struct VertexOut {
  float4 pos  [[ position ]];
  float4 color;
};

vertex VertexOut vertexMath(VertexInput in [[ stage_in ]])
{
  VertexOut out;
  out.pos = float4(in.position.x, in.position.y, 0.0, 1.0);
  
  float sum1 = in.uv1.x + in.uv2.x;
  float sum2 = in.uv1.y + in.uv2.y;
  out.color = in.color + float4(sum1, sum2, 0.0f, 0.0f);
  return out;
}
