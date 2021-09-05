//
//  PMEffectAlgorithmGenerator.metal
//  01_Metal_Hello
//
//  Created by Bluce on 2021/9/2.
//  Copyright © 2021 CJL. All rights reserved.
//
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
//#include <math.h>
#include "PMEffectAlgorithmGenerator.h"


hsvColor hsv(float h,float s,float v){
 hsvColor color;
color.h = h;
color.s = s;
color.v = v;
return color;
}
rgb hsv2rgb(hsvColor input)
{
    float      hh, p, q, t, ff;
    long        i;
    rgb         output;

    if(input.s <= 0.0) {       // < is bogus, just shuts up warnings
        output.r = input.v;
        output.g = input.v;
        output.b = input.v;
        return output;
    }
    hh = input.h;
    if(hh >= 360.0) hh = 0.0;
    hh /= 60.0;
    i = (long)hh;
    ff = hh - i;
    p = input.v * (1.0 - input.s);
    q = input.v * (1.0 - (input.s * ff));
    t = input.v * (1.0 - (input.s * (1.0 - ff)));

    switch(i) {
    case 0:
        output.r = input.v;
        output.g = t;
        output.b = p;
        break;
    case 1:
        output.r = q;
        output.g = input.v;
        output.b = p;
        break;
    case 2:
        output.r = p;
        output.g = input.v;
        output.b = t;
        break;

    case 3:
        output.r = p;
        output.g = q;
        output.b = input.v;
        break;
    case 4:
        output.r = t;
        output.g = p;
        output.b = input.v;
        break;
    case 5:
    default:
        output.r = input.v;
        output.g = p;
        output.b = q;
        break;
    }
    return output;
}
 hsvColor morphColor(float2 vetor,float hueShift){
    
    float value = 0;

    value += sin(vetor.x/600.0);

    value += sin(vetor.y/300.0);

    value += sin((vetor.x + vetor.y)/600.0);

    value += sin(sqrt(vetor.x * vetor.x + vetor.y * vetor.y)/600.0);

    // shift range from -4 .. 4 to 0 .. 8
    value += 4;
    
    // bring range down to 0 .. 1
    value /= 8;
     hsvColor color  = hsv(((int)hueShift  + (uint16_t)(value * 360) )% 360 , 100/100.0, 100/100.0);
    return color;
}


float4 blur9(metal::sampler sampler2D, metal::texture2d<float> texture, float2 uv, float2 resolution, float2 direction) {
  float4 color = float4(0.0);
  float2 off1 = float2(1.3846153846) * direction;
  float2 off2 = float2(3.2307692308) * direction;
  color += texture.sample(sampler2D, uv) * 0.2270270270;
  color += texture.sample(sampler2D, uv + (off1 / resolution)) * 0.3162162162;
  color += texture.sample(sampler2D, uv - (off1 / resolution)) * 0.3162162162;
  color += texture.sample(sampler2D, uv + (off2 / resolution)) * 0.0702702703;
  color += texture.sample(sampler2D, uv - (off2 / resolution)) * 0.0702702703;
  return color;
}
//erff implementation
float erf(float x)
{
    // constants
    float a1 =  0.254829592;
    float a2 = -0.284496736;
    float a3 =  1.421413741;
    float a4 = -1.453152027;
    float a5 =  1.061405429;
    float p  =  0.3275911;

    // Save the sign of x
    int sign = 1;
    if (x < 0)
        sign = -1;
    x = fabs(x);

    // A&S formula 7.1.26
    float t = 1.0/(1.0 + p*x);
    float y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*exp(-x*x);

    return sign*y;
}

unsigned short cumulative_distribution(unsigned short color_count, unsigned short mean, unsigned short deviation)
{
    unsigned short value = 127.0 * (1.0 + erf((color_count - mean) / (deviation * sqrt(2.0))));
    return value;
}

