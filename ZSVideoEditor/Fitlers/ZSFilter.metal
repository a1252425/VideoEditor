//
//  ZSFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
  int4 frame;
  float2x2 transform;
};

kernel void zs_compute(
                       texture2d<float, access::write> output [[ texture(0) ]],
                       texture2d<float, access::sample> texture1 [[ texture(1) ]],
                       texture2d<float, access::sample> texture2 [[ texture(2) ]],
                       texture2d<float, access::sample> texture3 [[ texture(3) ]],
                       texture2d<float, access::sample> texture4 [[ texture(4) ]],
                       texture2d<float, access::sample> texture5 [[ texture(5) ]],
                       texture2d<float, access::sample> texture6 [[ texture(6) ]],
                       texture2d<float, access::sample> texture7 [[ texture(7) ]],
                       texture2d<float, access::sample> texture8 [[ texture(8) ]],
                       texture2d<float, access::sample> texture9 [[ texture(9) ]],
                       constant Uniforms *uniforms [[ buffer(0) ]],
                       uint2 gid [[ thread_position_in_grid ]]
                       )
{
  float4 color = float4(0);
  
  constexpr sampler textureSampler(coord::normalized,
                                   address::clamp_to_zero,
                                   filter::linear);
  if (is_null_texture(texture1) == false) {
    constant Uniforms &uniform = uniforms[0];
    float2 origin = float2(gid) - float2(uniform.frame.xy);
    float2 uv = ((origin / float2(uniform.frame.zw) * 2 - 1) * uniform.transform + 1) * 0.5;
    if (uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1) {
      float4 imageColor = texture1.sample(textureSampler, uv);
      color = mix(color, imageColor, imageColor.a);
    }
  }
  
  output.write(color, gid);
}

struct VertexIO
{
  float4 poistion [[ position ]];
};
