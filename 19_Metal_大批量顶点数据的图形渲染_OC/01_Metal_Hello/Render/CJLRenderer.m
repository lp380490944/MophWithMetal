//
//  -Renderer.m
//  01_Metal_Hello
//
//  Created by - on 2020/8/19.
//  Copyright © 2020 -. All rights reserved.
//

//CJLRenderer是服务于MTKView的

#import "CJLRenderer.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@import Metal;

//头 在C代码之间共享，这里执行Metal API命令，和.metal文件，这些文件使用这些类型作为着色器的输入。

@interface CJLRenderer ()

@end

@implementation CJLRenderer
{
//    [UIScreen mainScreen].bounds.size.width
//    渲染设备（GPU）
    id<MTLDevice> _device;
    
//    渲染管道：顶点着色器/片元着色器,存储于.metal shader文件中
    id<MTLRenderPipelineState> _pipelineState;
    
//    命令队列：从命令缓存区中获取
    id<MTLCommandQueue> _commandQueue;
    
//    ！！！顶点缓存区（大批量顶点数据的图形渲染时使用）
    id<MTLBuffer> _vertexBuffer;
    
//    当前视图大小,这样我们才可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
    id <MTLBuffer> _colorBuffer[1];
    id <MTLBuffer> _effectTypeBuffer;
//    顶点个数
    NSInteger _numVertices;
    
    LPEffectGenerator * _generator;
    dispatch_semaphore_t _inFlightSemaphore;
    UInt8 _counter;
}
static float _hue_shift;
//初始化
- (id)initWithMetalKitView: (MTKView *)mtkView mtkviewType:(PMMTKViewType)mtkviewType effectType:(PMEffectType)effectType effectDirection:(PMEffectDirection)effectDirection{
    self = [super init];
    if (self) {
        NSLog(@"initWithMetalKitView");
//        都是准备工作
//        1、初始化GPU设备
        _device = mtkView.device;
//        2、加载metal文件
        _hue_shift = 0;
        self.mtkviewType = mtkviewType;
        self.effectType = effectType;
        _generator = [LPEffectGenerator generatorWithEffectType:self.effectType];
        _generator.effectDirection = self.effectDirection = effectDirection;
        [self loadMetal:mtkView];
        [self reloadVertexData];
        _counter = 0;
    }
    return self;
}
- (void)loadMetal: (nonnull MTKView*)mtkView{
//    1、设置绘制纹理的像素格式
    mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    
//    2、加载.metal文件 & 加载顶点和片元函数
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
//    3、创建渲染管道 / 配置用于创建管道状态的管道：命名 & 设置顶点和片元function & 设置颜色数据的组件格式 即颜色附着点
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    if (@available(iOS 11.0, *)) {
        pipelineDescriptor.vertexBuffers[CJLVertexInputIndexVertices].mutability = MTLMutabilityMutable;
    } else {
        // Fallback on earlier versions
    }
    
    
//    4、创建渲染管线对象/同步创建并返回渲染管线对象 & 判断是否创建成功
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

-(void)reloadVertexData{
    //    5、获取顶点数据
        NSData *vertexData = [self generateVertexData];
    //    创建一个vertex buffer,可以由GPU来读取
        _vertexBuffer = [_device newBufferWithLength:vertexData.length options:MTLResourceStorageModeShared];
    //    复制vertex data 到vertex buffer 通过缓存区的"content"内容属性访问指针
            /*
             memcpy(void *dst, const void *src, size_t n);
             dst:目的地 -- 读取到那里
             src:源内容 -- 源数据在哪里
             n: 长度 -- 读取长度
             */
        memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);
    //    计算顶点个数 = 顶点数据长度 / 单个顶点大小
        _numVertices = vertexData.length / sizeof(CJLVertex);
    
    _colorBuffer[CJLFragmentInputIndexColorShift] = [_device newBufferWithLength:sizeof(_hue_shift) options:MTLResourceCPUCacheModeDefaultCache];
        _effectTypeBuffer = [_device newBufferWithLength:sizeof(self.effectType) options:MTLResourceCPUCacheModeDefaultCache];
    //    6、通过device创建commandQueue，即命令队列
        _commandQueue = [_device newCommandQueue];
}
//typedef struct
//{
////    像素空间的位置
////    像素中心点（100，100）
//    vector_float3 position;
////    float pointsize;
////    RGBA颜色
//    vector_float3 color;
//}LPVertex;
//
//hsvColor plasmaMap[NUM_ROWS][NUM_COLUMNS] = {{0}};


static bool isLock = false;
//顶点数据 -- 制造出非常多的顶点数据
- (nonnull NSData*)generateVertexData{
//    1、正方形 = 三角形+三角形
    const CJLVertex quadVertices[] =
    {
//        顶点坐标位于物体坐标系，需要在顶点着色函数中作归一化处理，即物体坐标系 -- NDC
        // Pixel 位置, RGBA 颜色
        { { -blockSize,   blockSize,1 },pointSize,self.effectType,{1,1,1,1}},
    };
    
    //行/列 数量
    const NSUInteger NUM_COLUMNS = kNUM_COLUMNS;
    const NSUInteger NUM_ROWS = kNUM_ROWS;
    //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(CJLVertex);
    //四边形间距
//    const float QUAD_SPACING = kSpaceWidth;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSInteger dataStr = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
//    2、开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataStr];
    //当前四边形
    CJLVertex *currentQuad = vertexData.mutableBytes;
    
//    3、获取顶点坐标（循环计算）??? 需要研究
    //行
    if (isLock) {
        return vertexData;
    }
    
    isLock = true;
    for (NSUInteger row = 0; row < NUM_ROWS; row++) {
        //计算每一行的列数 如果是三角形的话是从上到下递减，此处需要注意的是当前的坐标系的原点是在左下角(0,0);
        NSInteger perRowColumnNum = [self perRowColumnNum:row];
     
        for (NSUInteger column = 0; column < perRowColumnNum; column++) {
            
            vector_float2 position;
            position.x = row;
            position.y = column;
            struct hsvColor fireColor = [_generator getEffectColor:position];
            
            CJLVertex quadVerticesNew[] = {
                { { -blockSize,   blockSize ,1},pointSize,self.effectType,{fireColor.h,fireColor.s,fireColor.v,1.0}},
            };
            //A.左上角的位置
            vector_float3 upperLeftPosition;
            //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
            upperLeftPosition.x = (column + -((float)NUM_COLUMNS)/2)*pointSize;
            upperLeftPosition.y = row*pointSize + (-(float)NUM_ROWS/2)*pointSize;
            //C.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVerticesNew, sizeof(quadVerticesNew));
            //D.遍历currentQuad中的数据
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++) {
                //修改vertexInQuad中的position
                currentQuad[vertexInQuad].position += upperLeftPosition;
            }
            //E.更新索引
            currentQuad += 1;
        }
    }
    //60帧  drawMTView 每秒60次调用；
    isLock = false;
    return vertexData;
}

-(NSInteger)perRowColumnNum:(NSInteger)currentRowIndex{
    NSInteger NUM_COLUMNS = kNUM_COLUMNS;
    NSInteger NUM_ROWS = kNUM_ROWS;
    NSInteger reslut;
    switch (self.mtkviewType) {
        case PMMTKViewTypeTriangle:{
            reslut = NUM_COLUMNS - (NUM_ROWS - currentRowIndex);
            break;
        }
        case PMMTKViewTypeRectangle:{
            reslut = NUM_COLUMNS;
            break;
        }
        default:
            reslut = NUM_COLUMNS;
            break;
    }
    return reslut;
}

#pragma -- MTKViewDelegate
//当MTKView视图发生大小改变时调用
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size{
    NSLog(@"drawableSizeWillChange");
    
    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    
}

//每当视图需要渲染时调用
- (void)drawInMTKView:(MTKView *)view{
    NSLog(@"drawInMTKView");
//    1、为当前渲染的每个渲染传递创建一个新的命令缓冲区 & 指定缓存区名称
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    [_generator updateShiftStatus];
    //如果是fireeffectModel 或者flow 需要更新新的颜色
    if (self.effectType != PMEffectTypeMorph && _counter < 120) {
        [self updateFireEffectBufferData];
        _counter ++;
//        [self reloadVertexData];
    }else{
        return;
    }
    
    
//    2、通过view创建渲染描述
//     MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
    //currentRenderPassDescriptor 从currentDrawable's texture,view's depth, stencil, and sample buffers and clear values.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    //判断渲染目标是否为空
    if (renderPassDescriptor != nil) {
//        3、创建渲染命令编码器,这样我们才可以渲染到something & 设置渲染器名称
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        commandEncoder.label = @"MyRenderEncoder";
        
//        4、设置视口/设置我们绘制的可绘制区域
        [commandEncoder setViewport: (MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0}];
        
//        5、设置渲染管道状态
        [commandEncoder setRenderPipelineState:_pipelineState];
        
//        6、传递数据
        //我们调用-[MTLRenderCommandEncoder setVertexBuffer:offset:atIndex:] 为了从我们的OC代码找发送数据预加载的MTLBuffer 到我们的Metal 顶点着色函数中
        /* 这个调用有3个参数
            1) buffer - 包含需要传递数据的缓冲对象
            2) offset - 它们从缓冲器的开头字节偏移，指示“顶点指针”指向什么。在这种情况下，我们通过0，所以数据一开始就被传递下来.偏移量
            3) index - 一个整数索引，对应于我们的“vertexShader”函数中的缓冲区属性限定符的索引。注意，此参数与 -[MTLRenderCommandEncoder setVertexBytes:length:atIndex:] “索引”参数相同。
         */
        
        //将_vertexBuffer 设置到顶点缓存区中，顶点数据很多时，存储到buffer
        [commandEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:CJLVertexInputIndexVertices];
        
        //可以buffer 和 bytes传递混合使用
        //将 _viewportSize 设置到顶点缓存区绑定点设置数据
        [commandEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:CJLVertexInputIndexViewportSize];
        //传递颜色数据
        //设置colorShiftBuffer
        memcpy(_colorBuffer[CJLFragmentInputIndexColorShift].contents, &_hue_shift, sizeof(_hue_shift));
        [commandEncoder setFragmentBuffer:_colorBuffer[CJLFragmentInputIndexColorShift] offset:0 atIndex:CJLFragmentInputIndexColorShift];
            memcpy(_effectTypeBuffer.contents, &_effectType, sizeof(self.effectType));
            [commandEncoder setVertexBuffer:_effectTypeBuffer offset:0 atIndex:CJLFragmentInputIndexEffectType];
        
//        7、绘制
        // @method drawPrimitives:vertexStart:vertexCount:
        //@brief 在不使用索引列表的情况下,绘制图元
        //@param 绘制图形组装的基元类型
        //@param 从哪个位置数据开始绘制,一般为0
        //@param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
        [commandEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:_numVertices];
//        [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:_numVertices indexType:MTLIndexTypeUInt16 indexBuffer:_vertexBuffer indexBufferOffset:0];
        
//        8、表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
        [commandEncoder endEncoding];
        
//        9、一旦框架缓冲区完成，使用当前可绘制的进度表
        [commandBuffer presentDrawable:view.currentDrawable];
        
    }
//    10、最后,在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
    _hue_shift += 1;
}
-(void)updateFireEffectBufferData{
    CJLVertex *vertexs = _vertexBuffer.contents;
    for (int i  = 0; i < _numVertices; i++) {
        CJLVertex vertex = vertexs[i];
        float x = vertex.position.y/pointSize  + (float)kNUM_COLUMNS/2;
        float y = vertex.position.x/pointSize  + (float)kNUM_ROWS/2;
        simd_float2 pos =  simd_make_float2(x,y);
        struct hsvColor fireColor = [_generator getEffectColor:pos];
        NSLog(@"x:%f,y:%f color = %f、%f、%f",x,y,fireColor.h,fireColor.s,fireColor.v);
//        vector_float4 color = {255,255,255.0f,1.0};
        vertex.color =  simd_make_float4(fireColor.h,fireColor.s,fireColor.v,1.0f);
    }
    memcpy(_vertexBuffer.contents, &vertexs, sizeof(vertexs));
}
#pragma mark-- lazy load



@end
