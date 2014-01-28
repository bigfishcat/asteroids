//
//  GLScene.m
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "GLScene.h"
#import "Sprite.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface GLScene()
{
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    GLuint _projectionUniform;
    VertexAttrib _vertexAttrib;
}

@property (nonatomic) NSMutableArray* sprites;

@end

@implementation GLScene

@synthesize sprites;
@synthesize touchDelegate;

-(CGRect) glFrame
{
    CGFloat height = 2 * self.frame.size.height / self.frame.size.width;
    return CGRectMake(-1., -height / 2, 2, height);
}

+(Class) layerClass
{
    return [CAEAGLLayer class];
}

-(void)load
{
    [Sprite reinitSprites];
    [self setupLayer];
    [self setupContext];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self compileShaders];
    self.sprites = [[NSMutableArray alloc] initWithObjects:
                    [[Sprite alloc] initWithName:@"space-sky"
                                        andFrame:self.glFrame],
                    nil];
    [self setupParams];
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"failed to make complete framebuffer object %x", status);
    }
}

-(void) addSprite:(Sprite*)sprite
{
    [self.sprites addObject:sprite];
}

-(void)removeSprite:(Sprite*)sprite
{
    [self.sprites removeObject:sprite];
    
}

-(void)setupParams
{
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    glClearColor(0., 0., 0., 1.);
}

-(void) setupLayer
{
    _eaglLayer = (CAEAGLLayer *) self.layer;
    _eaglLayer.opaque = YES;
}

-(void) setupContext
{
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!_context)
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context)
    {
        NSLog(@"Failed to initialize OpenGLES context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

-(void) setupRenderBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

-(void) setupFrameBuffer
{
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
    if (!shaderString)
    {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char * shaderStringUTF8 = [shaderString UTF8String];
    GLint shaderStringLength = (GLint)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (void)compileShaders
{
    GLuint vertexShader = [self compileShader:@"Vertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"Fragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    VertexAttrib attribs = {
        glGetAttribLocation(programHandle, "vertexPosition"),
        glGetAttribLocation(programHandle, "texCoordIn"),
        glGetUniformLocation(programHandle, "modelview"),
        glGetUniformLocation(programHandle, "Texture")
    };
    _vertexAttrib = attribs;
    _projectionUniform = glGetUniformLocation(programHandle, "projection");
    glEnableVertexAttribArray(attribs.positionSlot);
    glEnableVertexAttribArray(attribs.texCoordSlot);
}

-(void) applyOrthoWithLeft:(GLfloat)left
                  andRight:(GLfloat)right
                 andBottom:(GLfloat)bottom
                    andTop:(GLfloat)top
                   andNear:(GLfloat)near
                    andFar:(GLfloat)far
{
    GLfloat a = 2.0f / (right - left);
    GLfloat b = 2.0f / (top - bottom);
    GLfloat c = -2.0f / (far - near);
    
    GLfloat tx = - (right + left)/(right - left);
    GLfloat ty = - (top + bottom)/(top - bottom);
    GLfloat tz = - (far + near)/(far - near);
    
    GLfloat ortho[16] = {
        a, 0, 0, tx,
        0, b, 0, ty,
        0, 0, c, tz,
        0, 0, 0, 1
    };
    
    glUniformMatrix4fv(_projectionUniform, 1, GL_FALSE, &ortho[0]);
}

-(void)render
{
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGSize frameSize = self.frame.size;
    glViewport(0, 0, frameSize.width, frameSize.height);
    [self applyOrthoWithLeft:-1.
                   andRight: 1.
                  andBottom:-1. / (frameSize.width / frameSize.height)
                     andTop: 1. / (frameSize.width / frameSize.height)
                    andNear:.01
                     andFar:100];
    
    for (Sprite* sprite in self.sprites)
        [sprite drawWithAttrib:&_vertexAttrib andFrameSize:frameSize];
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

-(CGPoint)translatePointToGL:(CGPoint)nsPoint
{
    CGSize frameSize = self.frame.size;
    CGFloat x = nsPoint.x / frameSize.width * 2. - 1.;
    CGFloat y = (frameSize.height - nsPoint.y) / frameSize.height * 2. - frameSize.height / frameSize.width;
    return CGPointMake(x, y);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch * touch in touches)
    {
        CGPoint touchLocation = [touch locationInView:self];
        [touchDelegate touchesBeganAt:[self translatePointToGL:touchLocation]];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch * touch in touches)
    {
        CGPoint touchLocation = [touch locationInView:self];
        [touchDelegate touchesEndedAt:[self translatePointToGL:touchLocation]];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch * touch in touches)
    {
        CGPoint touchLocation = [touch locationInView:self];
        [touchDelegate touchesMovedTo:[self translatePointToGL:touchLocation]];
    }
}

@end
