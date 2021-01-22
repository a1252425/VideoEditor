//
//  ICBRenderer.metal
//  ZSVideoEditor
//
//  Created by DDS on 2021/1/22.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

typedef struct
{
  packed_float2 position;
} ICBObjectPerameters;

typedef struct
{
  packed_float2 position;
  packed_float2 texcoord;
} ICBVertex;

typedef struct
{
  vector_float2 aspectScale;
} ICBFrameState;

typedef struct
{
    float4 position [[position]];
    float2 tex_coord;
} ICBRasterizerData;

vertex ICBRasterizerData
ICBVertexShader(uint                         vertexID      [[ vertex_id ]],
             uint                         objectIndex   [[ instance_id ]],
             const device ICBVertex *    vertices      [[ buffer(0) ]],
             const device ICBObjectPerameters* object_params [[ buffer(1) ]],
             constant ICBFrameState *    frame_state   [[ buffer(2) ]])
{
  ICBRasterizerData out;

    float2 worldObjectPostion  = object_params[objectIndex].position;
    float2 modelVertexPosition = vertices[vertexID].position;
    float2 worldVertexPosition = modelVertexPosition + worldObjectPostion;
    float2 clipVertexPosition  = frame_state->aspectScale * 0.25 * worldVertexPosition;

    out.position = float4(clipVertexPosition.x, clipVertexPosition.y, 0, 1);
    out.tex_coord = float2(vertices[vertexID].texcoord);

    return out;
}

fragment float4
ICBFragmentShader(ICBRasterizerData in [[ stage_in ]])
{
    float4 output_color = float4(in.tex_coord.x, in.tex_coord.y, 0, 1);
    return output_color;
}
