//
//  PMEffectAlgorithmGenerator.h
//  01_Metal_Hello
//
//  Created by Bluce on 2021/9/2.
//  Copyright © 2021 CJL. All rights reserved.
//

#ifndef PMEffectAlgorithmGenerator_h
#define PMEffectAlgorithmGenerator_h


typedef struct {
float h;
float s;
float v;
}hsvColor;
typedef struct {
    float r;       // a fraction between 0 and 1
    float g;       // a fraction between 0 and 1
    float b;       // a fraction between 0 and 1
} rgb;

hsvColor hsv(float h,float s,float v);
//HSV转RGB
rgb hsv2rgb(hsvColor input);
//morph动效的颜色
hsvColor morphColor(float2 vetor,float hueShift);

//高斯模糊的算法
float4 blur9(sampler sampler2D, texture2d<float> texture, float2 uv, float2 resolution, float2 direction);

//根据index获取火焰效果的颜色
hsvColor fireColorWithIndex(float colorIndex);

#endif /* PMEffectAlgorithmGenerator_h */
