//
//  MainFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/4.
//

#include <metal_stdlib>
using namespace metal;

//kernel void filter_main(
//                        texture2d<float, access::read> inputImage [[ texture(0) ]],
//                        texture2d<float, access::read> outputImage [[ texture(1) ]],
//                        uint2 gid [[ thread_position_in_grid ]],
//                        texture2d<float, access::read> table [[ texture(2) ]],
//                        constant Parameters *params [[ buffer(0) ]]
//                        )
//{
//  float2 p0 = static_cast<float2>(gid);
//  float3x3 transform = params->transform;
//  float4 dims = params->dims;
//  float4 v0 = read_and_transform(inputImage, p0, transform);
//  float4 v1 = filter_table(v0, table, dims);
//  outputImage.write(v1, gid)
//}
