//
//  IconFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

#include <metal_stdlib>
using namespace metal;

float2 upperBgUV(float2 size, float2 point) {
  float width = size.x / 256.0 * 236.0;
  float height = width / 256.0 * 185.0;
  float ltrSpace = (size.x - width) * 0.5;
  return float2(point.x - ltrSpace, point.y - ltrSpace) / float2(width, height);
}

float2 displayUV(float2 size, float2 point) {
  float width = size.x / 256.0 * 236.0;
  float height = width / 256.0 * 126.0;
  float lrSpace = (size.x - width) * 0.5;
  float tSpace = size.y / 256.0 * 40.0;
  return float2(point.x - lrSpace, point.y - tSpace) / float2(width, height);
}

float2 starUV(float2 size, float2 point) {
  float width = size.x / 256.0 * 25.0;
  float lSpace = size.x / 256.0 * 187.0;
  float tSpace = size.y / 256.0 * 54.0;
  return float2(point.x - lSpace, point.y - tSpace) / float2(width, width);
}

float2 footballUV(float2 size, float2 point) {
  float width = size.x * 0.5;
  float lSpace = width * 0.5;
  float tSpace = size.y / 256.0 * 145.0;
  return float2(point.x - lSpace, point.y - tSpace) / float2(width, width);
}

float2 titleUV(float2 size, float2 point) {
  float width = size.x / 256.0 * 156.0;
  float height = width / 256.0 * 58.0;
  float lrSpace = (size.x - width) * 0.5;
  float tSpace = size.y / 256.0 * 200.0;
  return float2(point.x - lrSpace, point.y - tSpace) / float2(width, height);
}

kernel void icon(
                 texture2d<float, access::write> output [[ texture(0) ]],
                 texture2d<float, access::sample> bg [[ texture(1) ]],
                 texture2d<float, access::sample> upperBg [[ texture(2) ]],
                 texture2d<float, access::sample> display [[ texture(3) ]],
                 texture2d<float, access::sample> star [[ texture(4) ]],
                 texture2d<float, access::sample> football [[ texture(5) ]],
                 texture2d<float, access::sample> title [[ texture(6) ]],
                 constant float &timer [[ buffer(0) ]],
                 uint2 gid [[ thread_position_in_grid ]])
{
  constexpr sampler textureSampler(coord::normalized,
                                   address::clamp_to_zero,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear);
  float4 color = float4(0.3, 0.8, 0.3, 1);
  
  int width = output.get_width();
  int height = output.get_height();
  
  //  bg
  float2 uv = float2(gid) / float2(width, height);
  float4 bgColor = bg.sample(textureSampler, uv);
  color = mix(color, bgColor, bgColor.a);
  
  //  upper bg
  {
    float2 uv = upperBgUV(float2(width, height), float2(gid));
    float4 subColor = upperBg.sample(textureSampler, uv);
    color = mix(color, subColor, subColor.a);
    
    // display
    {
      float2 uv = displayUV(float2(width, height), float2(gid));
      float4 subColor = display.sample(textureSampler, uv);
      color = mix(color, subColor, subColor.a);
    }
    
    // star
    {
      float2 uv = starUV(float2(width, height), float2(gid));
      float4 subColor = star.sample(textureSampler, uv);
      color = mix(color, subColor, subColor.a);
    }
    
    // football
    {
      float upperA = subColor.a > 0 ? 1 : 0;
      float2 uv = footballUV(float2(width, height), float2(gid));
      float4 subColor = football.sample(textureSampler, uv);
      color = mix(color, subColor, subColor.a * upperA);
    }
  }
  
  //  bottom
  {
    float2 uv = titleUV(float2(width, height), float2(gid));
    float4 subColor = title.sample(textureSampler, uv);
    color = mix(color, subColor, subColor.a);
  }
  
  output.write(color, gid);
}
