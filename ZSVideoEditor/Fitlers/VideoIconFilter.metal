//
//  VideoIconFilter.metal
//  ZSVideoEditor
//
//  Created by DDS on 2020/12/9.
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

kernel void video_icon(
                       texture2d<float, access::write> output     [[ texture(0) ]],
                       texture2d<float, access::sample> bg        [[ texture(1) ]],
                       texture2d<float, access::sample> upperBg   [[ texture(2) ]],
                       texture2d<float, access::sample> display   [[ texture(3) ]],
                       texture2d<float, access::sample> star      [[ texture(4) ]],
                       texture2d<float, access::sample> football  [[ texture(5) ]],
                       texture2d<float, access::sample> title     [[ texture(6) ]],
                       constant Uniforms &uniforms  [[ buffer(0) ]],
                       constant float &timer        [[ buffer(1) ]],
                       uint2 gid [[ thread_position_in_grid ]])
{
  constexpr sampler textureSampler(coord::normalized,
                                   address::clamp_to_zero,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear);
  float4 color = float4(0);
  
  int width = output.get_width();
  int height = output.get_height();
  
  float scaleDuration = 0.4;
  float flashDuration = 0.4;
  float footballDuration = 0.4;
  
  //  bg
  float scale = min(1.0, timer / scaleDuration);
  float2 uv = (float2(gid) - float2(float(width) * (1 - scale) * 0.5)) / float2(float(width) * scale);
  float4 bgColor = bg.sample(textureSampler, uv);
  color = mix(color, bgColor, bgColor.a * scale * scale);
  
  //  upper bg
  if (timer > scaleDuration)
  {
    float2 uv = upperBgUV(float2(width, height), float2(gid));
    float4 subColor = upperBg.sample(textureSampler, uv);
    color = mix(color, subColor, subColor.a);
    
    float upperA = subColor.a > 0 ? 1 : 0;
    
    //  flash
    {
      float4 flashColor = paralelogramColor(float(width),
                                            float(height),
                                            uniforms,
                                            timer,
                                            float2(gid));
      color = mix(color, flashColor, flashColor.a * upperA);
    }
    
    // display
    {
      float2 uv = displayUV(float2(width, height), float2(gid));
      float4 subColor = display.sample(textureSampler, uv);
      color = mix(color, subColor, subColor.a);
    }
    
    // star
    {
      float2 uv = starUV(float2(width, height), float2(gid));
      float t = (timer - scaleDuration) * 2;
      uv = uv * 2 - 1;
      uv = uv * float2x2(cos(t), -sin(t), sin(t), cos(t));
      uv = (uv + 1) * 0.5;
      float4 subColor = star.sample(textureSampler, uv);
      color = mix(color, subColor, subColor.a);
    }
    
    // football
    {
      float2 uv = footballUV(float2(width, height), float2(gid));
      float t = timer - scaleDuration;
      uv = uv * 2 - 1;
      uv = uv * float2x2(cos(t), -sin(t), sin(t), cos(t));
      uv = (uv + 1) * 0.5;
      float4 subColor = football.sample(textureSampler, uv);
      color = mix(color, subColor, subColor.a * upperA);
    }
  }
  
  //  bottom
  if (timer > scaleDuration + footballDuration + flashDuration)
  {
    float2 uv = titleUV(float2(width, height), float2(gid));
    float4 subColor = title.sample(textureSampler, uv);
    color = mix(color, subColor, subColor.a);
  }
  
  output.write(color, gid);
}
