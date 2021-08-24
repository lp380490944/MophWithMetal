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
//

//头 在C代码之间共享，这里执行Metal API命令，和.metal文件，这些文件使用这些类型作为着色器的输入。
#import "CJLShaderTypes.h"

#define kSpaceWidth 6
#define pointSize 6
#define blockSize kSpaceWidth/2
#define kNUM_COLUMNS (int)[UIScreen mainScreen].bounds.size.width/2
#define kNUM_ROWS (int)[UIScreen mainScreen].bounds.size.width/2
#define size_get(x) (sizeof(x)/sizeof(x[0]))
#define kScreenW (int)[UIScreen mainScreen].bounds.size.width
#define kScreenH (int)[UIScreen mainScreen].bounds.size.height

@interface CJLRenderer (){
    NSMutableArray * _morphArray;
}

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
    
//    顶点个数
    NSInteger _numVertices;
}

//初始化
- (id)initWithMetalKitView: (MTKView *)mtkView{
    self = [super init];
    if (self) {
        NSLog(@"initWithMetalKitView");
        NSError *error = NULL;
        _morphArray = [NSMutableArray array];
        
//        都是准备工作
//        1、初始化GPU设备
        _device = mtkView.device;
//        2、加载metal文件
        [self loadMetal:mtkView];
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
    
//    4、创建渲染管线对象/同步创建并返回渲染管线对象 & 判断是否创建成功
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
  

}

-(void)reloadVertexData{
    //    5、获取顶点数据
        NSData *vertexData = [CJLRenderer generateVertexData];
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
        
    //    6、通过device创建commandQueue，即命令队列
        _commandQueue = [_device newCommandQueue];
}
CGFLOAT_TYPE _hue_shift = 0;


struct hsvColor {
float h;
float s;
float v;
};



struct hsvColor hsv(CGFloat h,CGFloat s,CGFloat v){
struct hsvColor color;
color.h = h;
color.s = s;
color.v = v;
return color;
}

typedef struct
{
//    像素空间的位置
//    像素中心点（100，100）
    vector_float3 position;
//    float pointsize;
//    RGBA颜色
    vector_float3 color;
}LPVertex;

static  LPVertex _morphVetex[] = {};
struct hsvColor plasmaMap[3000][3000] = {{0}};
//hsvColor plasmaMap[NUM_ROWS][NUM_COLUMNS] = {{0}};

//顶点数据 -- 制造出非常多的顶点数据
+ (nonnull NSData*)generateVertexData{
//    1、正方形 = 三角形+三角形
    const CJLVertex quadVertices[] =
    {
//        顶点坐标位于物体坐标系，需要在顶点着色函数中作归一化处理，即物体坐标系 -- NDC
        // Pixel 位置, RGBA 颜色
        { { -blockSize,   blockSize,1 },pointSize, { 1, 0, 0, 1 } },
        { {  blockSize,   blockSize ,1},pointSize ,{ 1, 0, 0, 1 } },
        { { -blockSize,  -blockSize ,1}, pointSize,{ 1, 0, 0, 1 } },
        { {  blockSize,  -blockSize ,1}, pointSize, { 0, 1, 0, 1 } },
        { { -blockSize,  -blockSize ,1}, pointSize, { 0, 1, 0, 1 } },
        { {  blockSize,   blockSize ,1}, pointSize, { 1, 0, 0, 1 } },
    };
    
    //行/列 数量
    const NSUInteger NUM_COLUMNS = kNUM_COLUMNS;
    const NSUInteger NUM_ROWS = kNUM_ROWS;
//    static  LPVertex _morphVetex[] = {};
    

    //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(CJLVertex);
    //四边形间距
    const float QUAD_SPACING = kSpaceWidth;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSInteger dataStr = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;
    
//    2、开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataStr];
    //当前四边形
    CJLVertex *currentQuad = vertexData.mutableBytes;
    
//    3、获取顶点坐标（循环计算）??? 需要研究
    //行
    for (NSUInteger row = 0; row < NUM_ROWS; row++) {
        //列
        for (NSUInteger column = 0; column < NUM_COLUMNS; column++) {
            
            vector_float2 position;
            position.x = row;
            position.y = column;
            struct hsvColor color = getMorphColor(position);
//            plasmaMap[row][column] = color;
            UIColor * hsvColor = [UIColor colorWithHue:color.h/360 saturation:1.0 brightness:1.0 alpha:1.0];
            CGFloat r;
            CGFloat g;
            CGFloat b;
            CGFloat a;
            [hsvColor getRed:&r green:&g blue:&b alpha:&a];
            CJLVertex quadVerticesNew[] = {
                { { -blockSize,   blockSize ,1},pointSize,    { r,g,b,1.0f } },
                { {  blockSize,  blockSize ,1}, pointSize,   { r,g,b, 1.0f } },
                { { -blockSize,  -blockSize ,1},pointSize,   { r,g,b, 1.0f } },
                { {  blockSize,  -blockSize ,1}, pointSize,{ r,g,b, 1.0f } },
                { { -blockSize,  -blockSize ,1}, pointSize, { r,g,b, 1.0f }},
                { {  blockSize,   blockSize ,1}, pointSize,{ r,g,b, 1.0f }},
            };
            //A.左上角的位置
            vector_float3 upperLeftPosition;
            //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
//            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING  + QUAD_SPACING/2.0;
//            upperLeftPosition.x = (column + -((float)NUM_COLUMNS)/2) * QUAD_SPACING;
//            upperLeftPosition.z = 1;
            
            upperLeftPosition.x =  (column + -((float)NUM_COLUMNS)/2)*kSpaceWidth;
            
//            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;
//            upperLeftPosition.y = (row + -((float)NUM_ROWS)/2) * QUAD_SPACING;
            upperLeftPosition.y = (row + -((float)NUM_ROWS)/2)* kSpaceWidth;
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
    _hue_shift += 1;//60帧  drawMTView 每秒60次调用；
    return vertexData;
}

struct hsvColor getMorphColor(vector_float2 vetor){
    BOOL haveExistColor = NO;
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
//    [self loadMetal:view];
    [self reloadVertexData];
//    [NSThread sleepForTimeInterval:0.3f];
    
//    1、为当前渲染的每个渲染传递创建一个新的命令缓冲区 & 指定缓存区名称
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
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
}

@end
