//
//  VideoIconBgUpper.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
//

#include <metal_stdlib>
using namespace metal;

kernel void video_icon_bg_upper(
                                texture2d<float, access::read> input [[ texture(0) ]],
                                texture2d<float, access::write> output [[ texture(1) ]],
                                texture2d<float, access::sample> image [[ texture(2) ]],
                                constant float &timer [[ buffer(0) ]],
                                uint2 gid [[ thread_position_in_grid ]]
                                )
{
  if (timer < 0.4) return;
  
}
