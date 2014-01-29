//
//  Asteroid.m
//  asteroids
//
//  Created by Andrey Tumanov on 28/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "Asteroid.h"
#import "Sprite.h"
#import <stdlib.h>

#define MIN_POINTS_COUNT 16
#define MAX_POINTS_COUNT 32

@interface Asteroid()
{
    Vertex _roots[MIN_POINTS_COUNT];
    GLubyte _indices[MIN_POINTS_COUNT];
    GLint _rootsCount;
    
    GLuint _texture;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    NSTimer * _mover;
}

@property (readwrite) NSInteger toughness;

@end

@implementation Asteroid

@synthesize toughness;
@synthesize velocity = _velocity;

#define DT 0.05

-(id)initWithPosition:(CGPoint)position andVelocity:(CGVector)velocity
{
    if (self = [super init])
    {
        self.toughness = 2;
        self.velocity = velocity;
        const CGFloat a = (arc4random() % 25  + 25) / 100.;
        CGRect area = CGRectMake(position.x, position.y, a, a);
        int pointCount = arc4random() % (MAX_POINTS_COUNT - MIN_POINTS_COUNT) +
            MIN_POINTS_COUNT;
        CGPoint points[MAX_POINTS_COUNT] = {0};
        for (int i = 0; i < pointCount; i++)
            points[i] = [self getRandomPointInRect:area];
        [self jarvismarchForArray:points withSize:pointCount];
        
        [self setupVBOs];
        _texture = [self loadTexture:@"stone"];
        
        _mover = [NSTimer scheduledTimerWithTimeInterval:DT
                                                  target:self
                                                selector:@selector(move:)
                                                userInfo:nil
                                                 repeats:YES];
    }
    return self;
}

-(void)move:(NSTimer*)sender
{
    [self moveBy:CGVectorMake(self.velocity.dx / DT, self.velocity.dy / DT)];
}

-(void)onRemoveFromScene
{
    [super onRemoveFromScene];
    [_mover invalidate];
    _mover = nil;
}

-(CGPoint)getRandomPointInRect:(CGRect)rect
{
    const int precision = MAX_POINTS_COUNT * 4;
    int x = arc4random() % (int)(rect.size.width * precision) +
        (int)(rect.origin.x * precision);
    int y = arc4random() % (int)(rect.size.height * precision) +
        (int)(rect.origin.y * precision);
    return CGPointMake(x * 1. / precision, y * 1. / precision);
}

-(CGFloat)rotate:(CGPoint)a andPoint:(CGPoint)b withPoint:(CGPoint)c
{
    return (b.x - a.x)*(c.y - b.y) - (b.y - a.y)*(c.x - b.x);
}

-(int)findLeftPointInArray:(CGPoint*)points withSize:(int)count
{
    int leftPointIndex = 0;
    for (int i = 1; i < count; i++)
    {
        if (points[i].x < points[leftPointIndex].x)
            leftPointIndex = i;
    }
    return leftPointIndex;
}

-(void)jarvismarchForArray:(CGPoint*)points withSize:(int)count
{
    NSMutableArray * rootIndexes = [[NSMutableArray alloc] initWithCapacity:count];
    NSMutableArray * pointIndexes = [[NSMutableArray alloc] initWithCapacity:count];
    int leftPointIndex = [self findLeftPointInArray:points withSize:count];
    [rootIndexes addObject:[NSNumber numberWithInt:leftPointIndex]];
    for (int i = 0; i < count; i++)
    {
        if (i != leftPointIndex)
            [pointIndexes addObject:[NSNumber numberWithInt:i]];
    }
    [pointIndexes addObject:[rootIndexes firstObject]];
    
    while (TRUE)
    {
        int right = 0;
        NSInteger lastRoot = [[rootIndexes lastObject] integerValue];
        for (int i = 0; i < pointIndexes.count; i++)
        {
            NSInteger rightPoint = [[pointIndexes objectAtIndex:right] integerValue];
            NSInteger currentPoint = [[pointIndexes objectAtIndex:i] integerValue];
            if ([self rotate:points[lastRoot]
                    andPoint:points[rightPoint]
                   withPoint:points[currentPoint]] < 0)
                right = i;
        }
        
        if ([[pointIndexes objectAtIndex:right] integerValue] ==
            [[rootIndexes firstObject] integerValue] ||
            rootIndexes.count == MIN_POINTS_COUNT)
        {
            break;
        }
        else
        {
            [rootIndexes addObject:[pointIndexes objectAtIndex:right]];
            [pointIndexes removeObjectAtIndex:right];
        }
    }
    
    _rootsCount = (GLint)rootIndexes.count;
    for (int i = 0; i < rootIndexes.count; i++)
    {
        NSInteger rootIndex = [[rootIndexes objectAtIndex:i] integerValue];
        CGPoint point = points[rootIndex];
        
        _roots[i].Position[0] = point.x / self.scaleFactor;
        _roots[i].Position[1] = point.y / self.scaleFactor;
        _roots[i].Position[2] = self.zOrder;
        _roots[i].TexCoord[0] = arc4random() % 100 / 100.;
        _roots[i].TexCoord[1] = arc4random() % 100 / 100.;
    }
}

-(void)setupVBOs
{
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _rootsCount * sizeof(Vertex), _roots, GL_STATIC_DRAW);
    
    _indices[0] = _rootsCount - 1;
    for (int i = 1; i < _rootsCount - 1; i++)
        _indices[i] = i - 1;
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _rootsCount, _indices, GL_STATIC_DRAW);
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
    
    glDrawElements(GL_TRIANGLE_FAN, _rootsCount, GL_UNSIGNED_BYTE, 0);
}

@end
