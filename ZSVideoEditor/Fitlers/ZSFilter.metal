//
//  ZSFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

#include <metal_stdlib>
using namespace metal;

struct Uniform {
  int4 frame;
  float2x2 transform;
  texture2d<float, access::sample> texture;
};

kernel void zs_compute(
                       texture2d<float, access::read> input [[ texture(0) ]],
                       texture2d<float, access::write> output [[ texture(1) ]],
                       constant Uniform *uniforms [[ buffer(0) ]],
                       constant uint &count [[ buffer(1) ]],
                       uint2 gid [[ thread_position_in_grid ]]
                       )
{
  float4 color = input.read(gid);
  
  constexpr sampler textureSampler(coord::normalized,
                                   address::clamp_to_zero,
                                   filter::linear);
  int width = input.get_width();
  int height = input.get_height();
  float2 uv = float2(gid) / float2(width, height);
  constant Uniform &uniform = uniforms[1];
  color = uniform.texture.sample(textureSampler, uv);
//  for (uint i = 0; i < count; ++i) {
//    constant Uniform &uniform = uniforms[i];
//    float2 uv = (float2(gid) - float2(uniform.frame.xy)) / float2(uniform.frame.zw);
//    uv = uv * 2 - 1;
//    uv = uv * uniform.transform;
//    uv = (uv + 1) * 0.5;
//    if (uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1) {
//      float4 imageColor = textures.sample(textureSampler, uv, i);
//      color = mix(color, imageColor, imageColor.a);
//    }
//  }
  
  output.write(color, gid);
}
