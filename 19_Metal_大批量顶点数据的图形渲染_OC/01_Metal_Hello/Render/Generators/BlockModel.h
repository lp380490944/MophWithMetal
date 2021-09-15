//
//  BlockModel.h
//  01_Metal_Hello
//
//  Created by Bluce on 2021/9/15.
//  Copyright © 2021 CJL. All rights reserved.
//

#import <Foundation/Foundation.h>
@import  MetalKit;
#import "CJLShaderTypes.h"
NS_ASSUME_NONNULL_BEGIN

@interface BlockModel : NSObject

@property(nonatomic)vector_float2 position;
//在屏幕坐标系下的位置
@property(nonatomic)vector_int2 rowColumnPosition;

@property(nonatomic)vector_float4 color;

@property(nonatomic,assign)float currentPointSize;

@property(nonatomic,assign)float fireColorIndex;

@property(nonatomic,assign)PMEffectType effectType;

@end

NS_ASSUME_NONNULL_END
