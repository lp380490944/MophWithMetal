//
//  LPEffectiveGenerator.h
//  01_Metal_Hello
//
//  Created by Bluce on 2021/8/29.
//  Copyright © 2021 CJL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CJLRenderer.h"
#include <simd/simd.h>
NS_ASSUME_NONNULL_BEGIN

#define kNUM_COLUMNS [UIScreen mainScreen].bounds.size.width
#define kNUM_ROWS [UIScreen mainScreen].bounds.size.width
#define gardCount 1
#define FIRE_GRAD_COLORS_COUNT [UIScreen mainScreen].bounds.size.width/6*3/gardCount

typedef enum PMEffectDirection{
    PMEffectDirectionUp = 0,
    PMEffectDirectionLeft = 1,
}PMEffectDirection;

@interface LPEffectGenerator : NSObject



struct hsvColor {
float h;
float s;
float v;
};

-(struct hsvColor) getEffectColor:(vector_float2)vetor;
-(void)updateShiftStatus;
//struct hsvColor getMorphColor(vector_float2 vetor);
struct hsvColor hsv(float h,float s,float v);
+(instancetype)generatorWithEffectType:(PMEffectType)effectType;
@property(nonatomic,assign)PMEffectType effectType;
@property(nonatomic,assign)PMEffectDirection effectDirection;

@end

NS_ASSUME_NONNULL_END
