//
//  PMEffectiveGenerator.m
//  01_Metal_Hello
//
//  Created by Bluce on 2021/8/27.
//  Copyright © 2021 CJL. All rights reserved.
//

#import "PMEffectiveGenerator.h"


@interface PMEffectiveGenerator (){
    
}

@end


static NSInteger _hue_shift;

@implementation PMEffectiveGenerator


struct hsvColor plasmaMap[3000][3000] = {{0}};

struct hsvColor hsv(float h,float s,float v){
struct hsvColor color;
color.h = h;
color.s = s;
color.v = v;
return color;
}

+(instancetype)generator{
    return [[self alloc] init];
}

-(struct hsvColor)getMorphColor:(vetor)vetor{
    struct hsvColor existColor = plasmaMap[(int)vetor.x][(int)vetor.y];
    if (_hue_shift > 0 ) {
        existColor.h = (int)(existColor.h + _hue_shift)%360;
        return existColor;
    }
    
//    if (_hue_shift > 0) {
//        size_t size = size_get(_morphVetex);
//        for (int i = 0; i < size; i++) {
//
//            LPVertex currentMorpthVector = _morphVetex[size];
//            if (currentMorpthVector.position.x == vetor.x && currentMorpthVector.position.y == vetor.y) {
//                float hue =  currentMorpthVector.color.x += _hue_shift;
//                hue = (int)hue%360;
//                haveExistColor = YES;
//                return hsv(hue, currentMorpthVector.color.y, currentMorpthVector.color.z);
//            }
//        }
//    }
        
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
//    LPVertex colorVertex = {{vetor.x,vetor.y,1},{color.h,color.s,color.v}};
//    _morphVetex = (LPVertex *)malloc(sizeof(colorVertex)*(size_get(_morphVetex)+1));
//    memcpy(_morphVetex,&colorVertex,sizeof(colorVertex));
    return color;
}
@end
