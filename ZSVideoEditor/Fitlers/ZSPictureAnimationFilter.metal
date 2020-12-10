//
//  ZSPictureAnimationFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/10.
//

#include <metal_stdlib>
using namespace metal;

kernel void zs_picture_animation(
                                 texture2d<float, access::write> output [[ texture(0) ]],
                                 texture2d<float, access::sample> content [[ texture(1) ]],
                                 constant float4 &frame [[ buffer(0) ]],
                                 constant float4x4 &transform [[ buffer(1) ]],
                                 uint2 gid [[ thread_position_in_grid ]]
                                 )
{
  constexpr sampler textureSampler(coord::normalized,
                                   address::clamp_to_zero,
                                   filter::linear);
  float2 translate = float2(transform[3][0], transform[3][1]);
  float2 uv = (float2(gid) - frame.xy + translate) / float2(frame.zw);
  uv = uv * 2 - 1;
  float4 uv4 = float4(uv, 0, 1) * transform;
  uv = (uv4.xy + 1) * 0.5;
  output.write(content.sample(textureSampler, uv), gid);
}
