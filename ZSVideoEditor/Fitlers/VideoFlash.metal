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

bool crossPositiveValue(float2 p1, float2 p2) {
  return (p1.x * p2.y - p2.x * p1.y) > 0;
}

bool isIn(Parallelogram parallelogram, float2 point) {
  return
  crossPositiveValue(parallelogram.rt - parallelogram.lt, point - parallelogram.lt) &&
  crossPositiveValue(parallelogram.rb - parallelogram.rt, point - parallelogram.rt) &&
  crossPositiveValue(parallelogram.lb - parallelogram.rb, point - parallelogram.rb) &&
  crossPositiveValue(parallelogram.lt - parallelogram.lb, point - parallelogram.lb);
}

float2 footer(float2 p1, float2 p2, float2 p) {
  float A = (p2.y - p1.y) / (p2.x - p1.x);
  float B = -1;
  float C = p1.y - A * p1.x;
  float x = (B * B * p.x - A * B * p.y - A * C)/(A * A + B * B);
  float y = (A * A * p.y - A * B * p.x - B * C)/(A * A + B * B);
  return float2(x, y);
}

Parallelogram formated(Parallelogram temp) {
  Parallelogram result;
  result.lt = footer(temp.lt, temp.lb, temp.rt);
  result.rt = temp.rt;
  result.rb = footer(temp.rt, temp.rb, temp.lb);
  result.lb = temp.lb;
  return result;
}

kernel void flash(
                  texture2d<float, access::write> output [[ texture(0) ]],
                  constant Uniforms &uniforms [[ buffer(0) ]],
                  constant float &timer [[ buffer(1) ]],
                  uint2 gid [[ thread_position_in_grid ]]
                  )
{
  float4 color = float4(0.5, 0.5, 0.5, 1);
  int width = output.get_width();
  int height = output.get_height();
  float k = float(width) / float(height);
  float left = float(height) / k;
  float len = left + float(width);
  float space = len / float(uniforms.count);
  Parallelogram p;
  for (int i = 0; i < uniforms.count; ++i) {
    p.lt = float2(space * float(i), 0);
    p.rt = float2(space * float(i + 1), 0);
    p.rb = float2(space * float(i + 1) - left, float(height));
    p.lb = float2(space * float(i) - left, float(height));
    if (isIn(p, float2(gid))) {
      float startTime = float(i) * uniforms.interval;
      float progress = (timer - startTime) / uniforms.duration;
      if (i % 2 == 0) {
        float header = min(1.0, max(-1.0, (1 - progress)));
        p.lt = float2(space * float(i) - left * header, float(height) * header);
        p.rt = float2(space * float(i + 1) - left * (1 - progress), float(height) * (1 - progress));
        float tail = min(2.0, max(-1.0, (2 - progress)));
        p.rb = float2(space * float(i + 1) - left * tail, float(height) * tail);
        p.lb = float2(space * float(i) - left * tail, float(height) * tail);
      } else {
        float head = min(2.0, max(0.0, (progress - 1)));
        p.lt = float2(space * float(i) - left * head, float(height) * head);
        p.rt = float2(space * float(i + 1) - left * head, float(height) * head);
        p.lb = float2(space * float(i) - left * progress, float(height) * progress);
        p.rb = float2(space * float(i + 1) - left * progress, float(height) * progress);
      }
      if (isIn(formated(p), float2(gid))) {
        color = i % 2 == 0 ? uniforms.color1 : uniforms.color2;
      }
      break;
    }
  }
  
  output.write(color, gid);
}
