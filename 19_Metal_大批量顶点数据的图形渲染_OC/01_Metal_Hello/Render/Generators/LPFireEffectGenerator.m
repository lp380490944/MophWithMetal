//
//  LPFireEffectGenerator.m
//  01_Metal_Hello
//
//  Created by Bluce on 2021/9/5.
//  Copyright © 2021 CJL. All rights reserved.
//

#import "LPFireEffectGenerator.h"

@interface LPFireEffectGenerator (){
    int _fireGardColorCount;
    int fireIndexMap[3000][3000];
    struct hsvColor fireGradColors[1000];
}

@end

@implementation LPFireEffectGenerator
-(instancetype)init{
    if (self = [super init]) {
        _fireGardColorCount = ceil([UIScreen mainScreen].bounds.size.width/6*3/gardCount);
        [self initFireColor];
    }
    return self;
}
-(void)initFireColor{
    for (int i = 0; i < _fireGardColorCount; i++) {
        unsigned short value =  cumulative_distribution(i, 10, 2);
        fireGradColors[i] = hsv(0,100/100.0, value/255.0);
    }
}
-(struct hsvColor)getEffectColor:(vector_float2)vetor{
    return [self getFireColor:vetor];
}

-(struct hsvColor) getFireColor:(vector_float2)vetor{
    struct hsvColor resultColor = hsv(0, 0, 1.0);
    int ind = fireIndexMap[(int)vetor.x][(int)vetor.y];
    resultColor =  fireGradColors[ind];
    return resultColor;
}

-(void)updateShiftStatus{
    [super updateShiftStatus];
    [self moveUpAndFade];
}



-(void)moveUpAndFade

{
    int columnNum = (int)kNUM_COLUMNS;
    int rowNum = (int)kNUM_COLUMNS;
    for (int i = rowNum; i > 0; i--)
    {
        for (int j = 0; j < columnNum; j++)
        {
            int n = 0;
            if (fireIndexMap[i - 1][j] > 0)
            {
                n = fireIndexMap[i - 1][j] - 1;
            }
            fireIndexMap[i][j] = n;
        }
    }
    int N = rowNum/gardCount;
    for (int j = 0; j < columnNum; j++)
    {
        fireIndexMap[0][j] = random()%N;
    }

}
struct  hsvColor cal_color(size_t index, short hue_shift)
{
    short pixel_hue = hue_shift + ((index + 1) * 360 / (kNUM_ROWS));
    struct hsvColor flowColor = hsv(pixel_hue, 1.0, 1.0);
    return flowColor;
}
unsigned short cumulative_distribution(unsigned short color_count, unsigned short mean, unsigned short deviation)
{
    unsigned short value = 127.0 * (1.0 + erff((color_count - mean) / (deviation * sqrt(2.0))));
    return value;
}


@end
