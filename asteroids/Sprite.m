//
//  Sprite.m
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "Sprite.h"

#define VERTICES_COUNT 4

@interface Sprite()
{
    Vertex _vertices[VERTICES_COUNT];
    GLushort _indices[VERTICES_COUNT];
    CGSize _size;
}

@property (nonatomic) NSMutableArray* spriteFrames;

@end

@implementation Sprite

@synthesize spriteFrames;

-(id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self)
    {
        [self createVerticesWithFrame:frame];
        [self setupVBOs];
    }
    return self;
}

-(id)initWithName:(NSString*)name andFrame:(CGRect)frame
{
    self = [self initWithFrame:frame];
    if (self)
        _texture = [self loadTexture:name];
    return self;
}

-(id)initWithFrame:(CGRect)frame andNames:(NSString*)name1, ...
{
    va_list params;
    va_start(params, name1);
    self = [self initWithName:name1 andFrame:frame];
    if (self)
    {
        self.spriteFrames = [[NSMutableArray alloc] initWithObjects:
                             [NSNumber numberWithUnsignedInt:_texture], nil];
        NSString * nameNext = nil;
        do {
            nameNext = va_arg(params, NSString*);
            if (nameNext == nil)
                break;
            [self.spriteFrames addObject:
             [NSNumber numberWithUnsignedInt:[self loadTexture:nameNext]]];
        } while (nameNext);
    }
    va_end(params);
    return self;
}

-(void)createVerticesWithFrame:(CGRect)frame
{
    GLfloat xs[VERTICES_COUNT / 2] = {frame.origin.x, frame.origin.x + frame.size.width};
    GLfloat ys[VERTICES_COUNT / 2] = {frame.origin.y, frame.origin.y + frame.size.height};
    int xi = 0;
    int yi = 0;
    _position.x = xs[0];
    _position.y = ys[0];
    _size = frame.size;
    for (int i = 0; i < VERTICES_COUNT; i++)
    {
        Vertex v = {{xs[xi] / self.scaleFactor, ys[yi] / self.scaleFactor, self.zOrder}, {xi, yi}};
        _vertices[i] = v;
        _indices[i] = i;
        if (++xi >= VERTICES_COUNT / 2)
        {
            xi = 0;
            yi++;
        }
    }
}

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 1
};

-(void)setupVBOs
{
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_vertices), _vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

-(void) drawWithAttrib:(VertexAttrib*)vertexAttrib andFrameSize:(CGSize)frameSize
{    
    [self applyTranslationWithX:_movement.dx
                           andY:_movement.dy
                           andZ:0
                   andModelView:vertexAttrib->modelViewUniform];
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glVertexAttribPointer(vertexAttrib->positionSlot, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), 0);
    glVertexAttribPointer(vertexAttrib->texCoordSlot, 2, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
//    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
//    glUniform1i(vertexAttrib.textureUniform, 0);
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}

-(void)moveBy:(CGVector)vector inRect:(CGRect)bound
{
    CGRect frame = self.frame;
    frame.origin.x += vector.dx;
    frame.origin.y += vector.dy;
    if (bound.origin.x > frame.origin.x ||
        bound.origin.x + bound.size.width < frame.origin.x + frame.size.width)
        vector.dx = 0;
    if (bound.origin.y > frame.origin.y||
        bound.origin.y + bound.size.height < frame.origin.y + frame.size.height)
        vector.dy = 0;
    
    [self moveBy:vector];
}

-(void)changeSpriteFrameTo:(NSUInteger)index
{
    if (self.spriteFrames && self.spriteFrames.count > index + 1)
        _texture = [[self.spriteFrames objectAtIndex:index] unsignedIntValue];
}

-(Boolean)checkPoint:(CGPoint)point
{
    return CGRectContainsPoint(self.frame, point);
}

-(CGRect)frame
{
    return CGRectMake(_position.x + _movement.dx * self.scaleFactor,
                      _position.y + _movement.dy * self.scaleFactor,
                      _size.width, _size.height);
}

-(Boolean)isInRect:(CGRect)rect
{
    return CGRectContainsRect(rect, self.frame);
}

-(CGVector)relativeDirection:(CGPoint)point
{
    CGFloat x = _position.x + _movement.dx * self.scaleFactor + _size.width / 2;
    CGFloat y = _position.y + _movement.dy * self.scaleFactor + _size.height / 2;
    return CGVectorMake(point.x - x, point.y - y);
}

@end
