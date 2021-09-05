//
//  LPEffectiveGenerator.m
//  01_Metal_Hello
//
//  Created by Bluce on 2021/8/29.
//  Copyright © 2021 CJL. All rights reserved.
//

#import "LPEffectGenerator.h"
#import "LPFireEffectGenerator.h"

@implementation LPEffectGenerator
struct hsvColor hsv(float h,float s,float v){
        struct hsvColor color;
        color.h = h;
        color.s = s;
        color.v = v;
        return color;
}


+(instancetype)generatorWithEffectType:(PMEffectType)effectType{
    switch (effectType) {
        case PMEffectTypeMorph:
            return [[LPEffectGenerator alloc] init];
            break;
        case PMEffectTypeFire:{
            return [[LPFireEffectGenerator alloc] init];
            break;
        }
        default:
            break;
    }
    return nil;
}

-(instancetype)initWithEffectType:(PMEffectType)effecttype{
    if (self = [super init]) {
        _effectType = effecttype;
    }
    return self;
}



CGFLOAT_TYPE _hue_shift = 0;
/*
 
//morph effect 由于morpheffect 是计算出来的所以就直接放在了.metal里面
struct hsvColor plasmaMap[3000][3000] = {{0}};


struct hsvColor getMorphColor(vector_float2 vetor){
    struct hsvColor existColor = plasmaMap[(int)vetor.x][(int)vetor.y];
    if (_hue_shift > 0 ) {
        existColor.h = (int)(existColor.h + _hue_shift)%360;
        return existColor;
    }
    double value = 0;

    value += sin(vetor.x/300.0);

    value += sin(vetor.y/150.0);

    value += sin((vetor.x + vetor.y)/300.0);

    value += sin(sqrt(vetor.x * vetor.x + vetor.y * vetor.y)/300.0);
    // shift range from -4 .. 4 to 0 .. 8
    value += 4;
    // bring range down to 0 .. 1
    value /= 8;
    
    NSInteger row = vetor.x;
    NSInteger column = vetor.y;
    struct hsvColor color  = hsv(_hue_shift  + (uint16_t)(value * 360) % 360 , 100, 100);
    plasmaMap[row][column] = color;
    return color;
}
 */

#pragma mark-- flow effect
-(struct hsvColor) getEffectColor:(vector_float2)vetor{
    
    return hsv(0, 0, 0);
}
-(void)updateShiftStatus;{
    _hue_shift +=1;
}
@end
