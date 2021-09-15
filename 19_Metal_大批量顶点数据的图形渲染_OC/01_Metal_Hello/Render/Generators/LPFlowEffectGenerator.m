//
//  LPFlowEffectGenerator.m
//  01_Metal_Hello
//
//  Created by Bluce on 2021/9/5.
//  Copyright © 2021 CJL. All rights reserved.
//

#import "LPFlowEffectGenerator.h"

@interface LPFlowEffectGenerator (){
    
}

@end

@implementation LPFlowEffectGenerator
-(struct hsvColor)getEffectColor:(vector_float2)vetor{
//    [super getEffectColor:vetor];
    //(fabs(kNUM_ROWS - index) 这个更改是为了向上流动 因为直接使用index是向下流动的
    struct hsvColor existColor = colorMap[(int)vetor.x][(int)vetor.y];
    if (_hue_shift > 0 ) {
        existColor.h = (int)(existColor.h + _hue_shift)%360;
        return existColor;
    }
    struct hsvColor flowColor;
    NSInteger index = [self flowIndexWithVector:vetor];
    short pixel_hue =_hue_shift  + ((fabs(kNUM_ROWS - index) + 1) * 360 / kNUM_ROWS);
    flowColor = hsv(pixel_hue%360, 100/100.0, 100/100.0);
    colorMap[(int)vetor.x][(int)vetor.y] = flowColor;
    return flowColor;
}
-(NSInteger)flowIndexWithVector:(vector_float2)vector{
    if (self.effectDirection == PMEffectDirectionUp) {
        //这个地方没有写反 是render里面的x和y写反了
        return vector.x;
    }else{
        return vector.y;
    }
}
-(void)updateShiftStatus{
    _hue_shift +=1.0;
}


@end
