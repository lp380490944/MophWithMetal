//
//  PMColorPointModel.h
//  01_Metal_Hello
//
//  Created by Bluce on 2021/9/5.
//  Copyright © 2021 CJL. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;
#import "CJLShaderTypes.h"
NS_ASSUME_NONNULL_BEGIN

@interface PMColorPointModel : NSObject
@property (nonatomic) vector_float3 position;
@property (nonatomic) vector_float4 color;
@property(nonatomic,assign)PMEffectType effectType;
@property(nonatomic,assign)float pointsize;
@end

NS_ASSUME_NONNULL_END
