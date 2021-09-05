//
//  PMEffectAlgorithmGenerator.hpp
//  01_Metal_Hello
//
//  Created by Bluce on 2021/9/1.
//  Copyright © 2021 CJL. All rights reserved.
//

#ifndef PMEffectAlgorithmGenerator_hpp
#define PMEffectAlgorithmGenerator_hpp

#include <stdio.h>
#include <simd/simd.h>
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
hsvColor hsv(float h,float s,float v){
 hsvColor color;
color.h = h;
color.s = s;
color.v = v;
return color;
}
hsvColor morphColor(simd_float2 vetor);
#endif /* PMEffectAlgorithmGenerator_hpp */
