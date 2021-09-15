//
//  CJLShaderTypes.h
//  01_Metal_Hello
//
//  Created by - on 2020/8/20.
//  Copyright © 2020 CJL. All rights reserved.
//

//C 与OC 之间产生桥接关系

/*
 介绍:
 头文件包含了 Metal shaders 与C/OBJC 源之间共享的类型和枚举常数
*/

#ifndef CJLShaderTypes_h
#define CJLShaderTypes_h
#define MAX_VALUE_COUNT 1024



// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用，相当于OpenGL ES中GLSL文件中position参数名称，即入口
//数据传递时的房间号，metal中表示index，类似于GLSL中的getAttribLocation、getUniformLocation
typedef enum CJLVertexInputIndex
{
//    顶点
    CJLVertexInputIndexVertices = 0,
    
//    视图大小
    CJLVertexInputIndexViewportSize = 1,
//颜色
    CJLFragmentInputIndexEffectType = 2,
}CJLVertexInputIndex;

typedef enum CJLFragmentInputIndex
{
//    色彩偏移
    CJLFragmentInputIndexColorShift = 0,
//动效类型
//    CJLFragmentInputIndexEffectType = 1,
    
}CJLFragmentInputIndex;

typedef enum PMEffectType
{
//    色彩偏移
    PMEffectTypeMorph = 0,
    PMEffectTypeFire = 1,
    PMEffectTypeFlow = 2,
    
}PMEffectType;


typedef enum PMEffectDirection{
    PMEffectDirectionUp = 0,
    PMEffectDirectionLeft = 1,
}PMEffectDirection;

//顶点数据结构体:顶点/颜色值
typedef struct
{
//    像素空间的位置
//    像素中心点（100，100）
    vector_float3 position;
    float pointsize;
    PMEffectType effectType;
//    RGBA颜色
    vector_float4 color;
    float fireColorIndex;
    
}CJLVertex;

typedef struct {
    vector_int2 index[MAX_VALUE_COUNT][MAX_VALUE_COUNT];
}CJIndexStruct;
//#define kSpaceWidth 2*3
#define pointSize 10
#define blockSize pointSize/2
#define size_get(x) (sizeof(x)/sizeof(x[0]))
#define kNUM_COLUMNS [UIScreen mainScreen].bounds.size.width/pointSize * 3
#define kNUM_ROWS [UIScreen mainScreen].bounds.size.width/pointSize * 3
#endif /* CJLShaderTypes_h */
