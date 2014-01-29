//
//  GLObject.m
//  asteroids
//
//  Created by Andrey Tumanov on 29/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "GLObject.h"

typedef struct {
    GLint buffer[MAX_SPRITE_COUNT];
    size_t count;
    size_t position;
} ZOrderStack;

void initZOrderStack(ZOrderStack * stack)
{
    stack->buffer[0] = 1 - MAX_SPRITE_COUNT;
    for (int i = 1; i < MAX_SPRITE_COUNT - 1; i++)
        stack->buffer[i] = - i;
    stack->count = MAX_SPRITE_COUNT - 1;
    stack->position = 0;
}

Boolean pushZOrderStack(ZOrderStack * stack, GLint value)
{
    if (stack == NULL || stack->count == MAX_SPRITE_COUNT)
        return NO;
    
    stack->buffer[--stack->position] = value;
    stack->count++;
    return YES;
}

GLint popZOrderStack(ZOrderStack * stack)
{
    if (stack == NULL || stack->count == 0)
        return 0;
    stack->count--;
    return stack->buffer[stack->position++];
}

@interface GLObject()
@property (readwrite) GLint zOrder;
@end

@implementation GLObject

@synthesize zOrder;

ZOrderStack zOrderSet;

+(void)resetOrder
{
    initZOrderStack(&zOrderSet);
}

-(id)init
{
    if (self = [super init])
    {
        self.zOrder = popZOrderStack(&zOrderSet);
    }
    return self;
}

-(void) applyTranslationWithX:(GLfloat)x andY:(GLfloat)y andZ:(GLfloat)z
                 andModelView:(GLuint)modelViewUniform
{
    GLfloat translation[16] = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        x, y, z, 1
    };
    
    glUniformMatrix4fv(modelViewUniform, 1, GL_FALSE, &translation[0]);
}

- (GLuint)loadTexture:(NSString *)fileName;
{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"png"];
    NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
    CGImageRef image = [[UIImage alloc] initWithData:texData].CGImage;
    return image ?
    [self loadImage:image
           withSize:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))] :
    0;
}

-(GLuint)loadImage:(CGImageRef)image withSize:(CGSize)size
{
    GLuint spriteTexture = 0;
    void *imageData = malloc(size.height * size.width * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(imageData, size.width, size.height,
                                                 8, 4 * size.width, colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    glGenTextures(1, &spriteTexture);
    glBindTexture(GL_TEXTURE_2D, spriteTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    free(imageData);
    return spriteTexture;
}

-(void)moveTo:(CGPoint)point
{
    _movement.dx = (point.x - _position.x) / self.scaleFactor;
    _movement.dy = (point.y - _position.y) / self.scaleFactor;
}

-(void)moveBy:(CGVector)vector
{
    _movement.dx += vector.dx / self.scaleFactor;
    _movement.dy += vector.dy / self.scaleFactor;
}

-(void)onRemoveFromScene
{
    pushZOrderStack(&zOrderSet, self.zOrder);
}

-(void) drawWithAttrib:(VertexAttrib*)vertexAttrib andFrameSize:(CGSize)frameSize
{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

-(GLfloat)scaleFactor
{
    return 1. / (1 - self.zOrder);
}

@end
