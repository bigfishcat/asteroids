//
//  GLObject.m
//  asteroids
//
//  Created by Andrey Tumanov on 29/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "GLObject.h"

@implementation GLObject

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
    _movement.dx = (point.x - _position.x) * (-_position.z);
    _movement.dy = (point.y - _position.y) * (-_position.z);
}

-(void)moveBy:(CGVector)vector
{
    _movement.dx += vector.dx * (-_position.z);
    _movement.dy += vector.dy * (-_position.z);
}

-(void) drawWithAttrib:(VertexAttrib*)vertexAttrib andFrameSize:(CGSize)frameSize
{
    
}

@end
