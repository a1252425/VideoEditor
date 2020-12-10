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
                                 constant float2x2 &transform [[ buffer(1) ]],
                                 uint2 gid [[ thread_position_in_grid ]]
                                 )
{
  constexpr sampler textureSampler(coord::normalized,
                                   address::clamp_to_zero,
                                   filter::linear);
  float2 uv = (float2(gid) - frame.xy) / float2(frame.zw);
  uv = ((uv * 2 - 1) * transform + 1) * 0.5;
  output.write(content.sample(textureSampler, uv), gid);
}
