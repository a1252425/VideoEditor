//
//  ZSFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
  float4 frame;
  float2x2 transform;
};

kernel void zs_compute(
                       texture2d<float, access::read> input [[ texture(0) ]],
                       texture2d<float, access::write> output [[ texture(1) ]],
                       texture2d<float, access::sample> target [[ texture(2) ]],
                       constant Uniforms &uniforms [[ buffer(0) ]],
                       uint2 gid [[ thread_position_in_grid ]]
                       )
{
  float4 color = input.read(gid);
  
  float2 uv = (float2(gid) - uniforms.frame.xy) / uniforms.frame.zw;
  uv = uv * 2 - 1;
  uv = uv * uniforms.transform;
  uv = (uv + 1) * 0.5;
  
  if (uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1) {
    constexpr sampler textureSampler(coord::normalized,
                                     address::clamp_to_zero,
                                     filter::linear);
    float4 imageColor = target.sample(textureSampler, uv);
    color = mix(color, imageColor, imageColor.a);
  }
  
  output.write(color, gid);
}
