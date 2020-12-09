//
//  VideoFlash.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/7.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
  float4 color1;
  float4 color2;
  float interval;
  float duration;
  int count;
};

struct Parallelogram {
  float2 lt;
  float2 rt;
  float2 rb;
  float2 lb;
};

static bool crossPositiveValue(float2 p1, float2 p2) {
  return (p1.x * p2.y - p2.x * p1.y) > 0;
}

static bool isIn(Parallelogram parallelogram, float2 point) {
  return
  crossPositiveValue(parallelogram.rt - parallelogram.lt, point - parallelogram.lt) &&
  crossPositiveValue(parallelogram.rb - parallelogram.rt, point - parallelogram.rt) &&
  crossPositiveValue(parallelogram.lb - parallelogram.rb, point - parallelogram.rb) &&
  crossPositiveValue(parallelogram.lt - parallelogram.lb, point - parallelogram.lb);
}

static float2 footer(float2 p1, float2 p2, float2 p) {
  float A = (p2.y - p1.y) / (p2.x - p1.x);
  float B = -1;
  float C = p1.y - A * p1.x;
  float x = (B * B * p.x - A * B * p.y - A * C)/(A * A + B * B);
  float y = (A * A * p.y - A * B * p.x - B * C)/(A * A + B * B);
  return float2(x, y);
}

static Parallelogram formated(Parallelogram temp) {
  Parallelogram result;
  result.lt = footer(temp.lt, temp.lb, temp.rt);
  result.rt = temp.rt;
  result.rb = footer(temp.rt, temp.rb, temp.lb);
  result.lb = temp.lb;
  return result;
}

static float4 paralelogramColor(float width, float height, Uniforms uniforms, float timer, float2 gid)
{
  float4 color = float4(0);
  float k = float(width) / float(height);
  float left = float(height) / k;
  float len = left + float(width);
  float space = len / float(uniforms.count);
  
  Parallelogram p;
  for (int i = 0; i < uniforms.count; ++i) {
    float startTime = float(i) * uniforms.interval;
    float progress = (timer - startTime) / uniforms.duration * 2.0;
    
    if (i % 2 == 0) {
      p.lt = float2(space * float(i) + left * (1.0 - progress), float(height) * (progress - 1.0));
      p.lb = float2(space * float(i) + left * (0.0 - progress), float(height) * (progress - 0.0));
      p.rt = float2(space * float(i + 1) + left * (1.0 - progress), float(height) * (progress - 1.0));
      p.rb = float2(space * float(i + 1) + left * (0.0 - progress), float(height) * (progress - 0.0));
    } else {
      p.lt = float2(space * float(i) + left * (progress - 1.0), float(height) * (1.0 - progress));
      p.lb = float2(space * float(i) + left * (progress - 2.0), float(height) * (2.0 - progress));
      p.rt = float2(space * float(i + 1) + left * (progress - 1.0), float(height) * (1.0 - progress));
      p.rb = float2(space * float(i + 1) + left * (progress - 2.0), float(height) * (2.0 - progress));
    }
    
    if (isIn(formated(p), float2(gid))) {
      color = i % 2 == 0 ? uniforms.color1 : uniforms.color2;
      break;
    }
  }
  return color;
}

kernel void flash(
                  texture2d<float, access::read> input [[ texture(0) ]],
                  texture2d<float, access::write> output [[ texture(1) ]],
                  constant Uniforms &uniforms [[ buffer(0) ]],
                  constant float &timer [[ buffer(1) ]],
                  uint2 gid [[ thread_position_in_grid ]]
                  )
{
  float4 color = input.read(gid);
  int width = output.get_width();
  int height = output.get_height();
  float4 pColor = paralelogramColor(float(width),
                                    float(height),
                                    uniforms,
                                    timer,
                                    float2(gid));
  color = mix(color, pColor, pColor.a);
  output.write(color, gid);
}
