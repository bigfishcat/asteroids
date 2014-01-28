//
//  GLObject.h
//  asteroids
//
//  Created by Andrey Tumanov on 29/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import "GLScene.h"

typedef struct
{
    GLfloat Position[3];
    GLfloat TexCoord[2];
} Vertex;

typedef struct {
    CGFloat x;
    CGFloat y;
    CGFloat z;
} GLPoint;

@interface GLObject : NSObject
{
    @protected
    GLuint _texture;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    CGVector _movement;
    GLPoint _position;
}

-(void)drawWithAttrib:(VertexAttrib*)vertexAttrib andFrameSize:(CGSize)frameSize;

-(void)applyTranslationWithX:(GLfloat)x andY:(GLfloat)y andZ:(GLfloat)z
                andModelView:(GLuint)modelViewUniform;

- (GLuint)loadTexture:(NSString *)fileName;

-(void)moveTo:(CGPoint)point;

-(void)moveBy:(CGVector)vector;

@end
