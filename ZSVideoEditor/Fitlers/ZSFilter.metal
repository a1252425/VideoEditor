//
//  ZSFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

#include <metal_stdlib>
using namespace metal;

kernel void zs_view(
                    texture2d<float, access::read> input [[ texture(0) ]],
                    texture2d<float, access::write> output [[ texture(1) ]],
                    texture2d<float, access::sample> content [[ texture(2) ]],
                    constant float4 &frame [[ buffer(0) ]],
                    constant float4x4 &transform [[ buffer(1) ]],
                    uint2 gid [[ thread_position_in_grid ]]
                    )
{
  float4 color = input.read(gid);
  constexpr sampler textureSampler(coord::normalized,
                                   address::clamp_to_zero,
                                   filter::linear);
  float2 translate = float2(transform[3][0], transform[3][1]);
  float2x2 rotateAndScale = float2x2(
                                     transform[0][0], transform[0][1],
                                     transform[1][0], transform[1][1]
                                     );
  float2 result = (float2(gid) - frame.xy + translate) * rotateAndScale;
  float2 uv = result / float2(frame.zw);
  float4 contentColor = content.sample(textureSampler, uv);
  color = mix(color, contentColor, contentColor.a);
  output.write(color, gid);
}

kernel void zs_view_clear(
                          texture2d<float, access::write> output [[ texture(0) ]],
                          uint2 gid [[ thread_position_in_grid ]]
                          )
{
  output.write(float4(0.3, 0.8, 0.3, 1), gid);
}
