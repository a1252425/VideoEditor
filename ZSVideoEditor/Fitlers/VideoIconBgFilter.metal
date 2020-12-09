//
//  VideoIconBgFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

#include <metal_stdlib>
using namespace metal;

kernel void video_icon_bg(
                          texture2d<float, access::read> input [[ texture(0) ]],
                          texture2d<float, access::write> output [[ texture(1) ]],
                          texture2d<float, access::sample> image [[ texture(2) ]],
                          constant float &timer [[ buffer(0) ]],
                          uint2 gid [[ thread_position_in_grid ]]
                          )
{
  float4 color = input.read(gid);
  int width = output.get_width();
  int height = output.get_height();
  
  float scaleDuration = 0.4;
  float scale = min(1.0, timer / scaleDuration);
  float iconSize = min(float(max(width, height)) * 0.4, float(min(width, height))) * scale;
  float lrSpace = (width - iconSize) * 0.5;
  float tbSpace = (height - iconSize) * 0.5;
  float2 uv = (float2(gid) - float2(lrSpace, tbSpace)) / iconSize;
  if (uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1) {
    constexpr sampler textureSampler(coord::normalized,
                                     address::clamp_to_zero,
                                     filter::linear);
    float4 imageColor = image.sample(textureSampler, uv);
    color = mix(color, imageColor, imageColor.a);
  }
  output.write(color, gid);
}
