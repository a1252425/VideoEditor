//
//  ZSEventShootArrowFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/11.
//

#include <metal_stdlib>
using namespace metal;

static bool isInOriginalRect(float2 point, float2 size) {
  return
  point.x > 0 &&
  point.y > 0 &&
  point.x < size.x &&
  point.y < size.y;
}

kernel void zs_event_shoot_arrow(
                                 texture2d<float, access::read> input [[ texture(0) ]],
                                 texture2d<float, access::write> output [[ texture(1) ]],
                                 texture2d<float, access::sample> content [[ texture(2) ]],
                                 constant float4 &frame [[ buffer(0) ]],
                                 constant float &angle [[ buffer(1) ]],
                                 constant float &time [[ buffer(2) ]],
                                 uint2 gid [[ thread_position_in_grid ]]
                                 )
{
  float4 color = input.read(gid);
  float2x2 mat = float2x2(
                          cos(angle), -sin(angle),
                          sin(angle), cos(angle)
                          );
  float2 rotateXY = (float2(gid) - frame.xy) * mat;
  if (isInOriginalRect(rotateXY, frame.zw)) {
    float contentWidth = frame.w / 17.0 * 220;
    float contentHeight = frame.z;
    float2 uv = (rotateXY + float2(time * 100, 0)) / float2(contentWidth, contentHeight);
    float a = 1.0 - min(1.0, abs((rotateXY.x / frame.z * 1.4 - 0.7) * 2));
    constexpr sampler textureSampler(coord::normalized,
                                     address::repeat,
                                     filter::linear);
    float4 contentColor = content.sample(textureSampler, uv);
    color = mix(color, contentColor, contentColor.a * a);
  }
  output.write(color, gid);
}
