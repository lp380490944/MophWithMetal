//
//  PMEffectiveGenerator.h
//  01_Metal_Hello
//
//  Created by Bluce on 2021/8/27.
//  Copyright © 2021 CJL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
struct hsvColor {
float h;
float s;
float v;
};
typedef struct{
    float x;
    float y;
}vetor;






@interface PMEffectiveGenerator : NSObject
-(struct hsvColor)getMorphColor:(vetor)vetor;
+(instancetype)generator;
@end

NS_ASSUME_NONNULL_END
