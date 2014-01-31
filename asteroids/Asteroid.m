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
#import <math.h>

#define MIN_POINTS_COUNT 16
#define MAX_POINTS_COUNT 32

Boolean isIntersect(CGPoint start1, CGPoint end1, CGPoint start2, CGPoint end2, CGPoint *out_intersection)
{
    CGVector dir1 = CGVectorMake(end1.x - start1.x, end1.y - start1.y);
    CGVector dir2 = CGVectorMake(end2.x - start2.x, end2.y - start2.y);
    
    CGFloat a1 = -dir1.dy;
    CGFloat b1 = dir1.dx;
    CGFloat d1 = -(a1*start1.x + b1*start1.y);
    
    CGFloat a2 = -dir2.dy;
    CGFloat b2 = dir2.dx;
    CGFloat d2 = -(a2*start2.x + b2*start2.y);
    
    CGFloat seg1_line2_start = a2*start1.x + b2*start1.y + d2;
    CGFloat seg1_line2_end = a2*end1.x + b2*end1.y + d2;
    
    CGFloat seg2_line1_start = a1*start2.x + b1*start2.y + d1;
    CGFloat seg2_line1_end = a1*end2.x + b1*end2.y + d1;
    
    if (seg1_line2_start * seg1_line2_end >= 0 ||
        seg2_line1_start * seg2_line1_end >= 0)
        return NO;
    
    CGFloat u = seg1_line2_start / (seg1_line2_start - seg1_line2_end);
    if (out_intersection)
        *out_intersection = CGPointMake(start1.x + u * dir1.dx,
                                        start1.y + u * dir1.dy);
    
    return YES;
}

Boolean isCircleIntersect(CGPoint center, CGFloat radius, CGPoint a, CGPoint b, CGFloat l)
{
    double xv = (b.x - a.x)/l;
    double yv = (b.y - a.y)/l;
    double xd = a.x - center.x;
    double yd = a.y - center.y;
    double B = 2*(xd*xv + yd*yv);
    double C = xd*xd +yd*yd - radius*radius;
    double D = B*B - 4*C;
    if (D < 0)
        return false;
    
    D = sqrtf(D);
    double l1 = (-B + D) * 0.5;
    double l2 = (-B - D) * 0.5;
    return (l1 >= 0 && l1 <= l) || (l2 >= 0 && l2 <= l);
}

CGFloat orient(CGPoint a, CGPoint b, CGPoint c)
{
    return (b.x - a.x)*(c.y - b.y) - (b.y - a.y)*(c.x - b.x);
}

Boolean semiSign(CGPoint a, CGPoint b, CGPoint c)
{
    return orient(a, b, c) >= 0;
}

@interface Asteroid()
{
    Vertex _roots[MIN_POINTS_COUNT];
    GLubyte _indices[MIN_POINTS_COUNT];
    GLint _rootsCount;
    GLfloat _mass;
    CGFloat _radius;
    CGPoint _center;
    CFTimeInterval _lastRenderTime;
}

@property (readwrite) NSInteger toughness;

@end

@implementation Asteroid

@synthesize toughness;
@synthesize velocity = _velocity;

#define DT (1./60)

-(id)initWithPosition:(CGPoint)position andVelocity:(CGVector)velocity andToughness:(NSInteger)t
{
    if (self = [super init])
    {
        self.toughness = t;
        self.velocity = velocity;
        const CGFloat a = (arc4random() % 25  + 25) / 400. * t;
        _mass = a * a;
        _radius = a / 2;
        _position = position;
        CGRect area = CGRectMake(position.x, position.y, a, a);
        int pointCount = arc4random() % (MAX_POINTS_COUNT - MIN_POINTS_COUNT) +
        MIN_POINTS_COUNT;
        CGPoint points[MAX_POINTS_COUNT] = {0};
        for (int i = 0; i < pointCount; i++)
        points[i] = [self getRandomPointInRect:area];
        [self jarvismarchForArray:points withSize:pointCount];
        
        [self setupVBOs];
        static GLuint texture = 0;
        if (texture == 0)
            texture = [self loadTexture:@"stone"];
        _texture = texture;
    }
    return self;
}

-(id)initWithPosition:(CGPoint)position andVelocity:(CGVector)velocity
{
    return [self initWithPosition:position andVelocity:velocity andToughness:4];
}

-(void)move
{
    CFTimeInterval current = CACurrentMediaTime();
    CFTimeInterval dt = current - _lastRenderTime;
    if (dt < .1 || dt > 1)
        dt = DT;
    [self moveBy:CGVectorMake(self.velocity.dx / dt, self.velocity.dy / dt)];
    _lastRenderTime = current;
}

-(void)onRemoveFromScene
{
    [super onRemoveFromScene];
    if (_vertexBuffer && _indexBuffer)
    {
        GLuint buffers[] = {_vertexBuffer, _indexBuffer};
        glDeleteBuffers(2, buffers);
        _vertexBuffer = 0;
        _indexBuffer = 0;
    }
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
            if (orient(points[lastRoot], points[rightPoint], points[currentPoint]) < 0)
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
    _center = CGPointMake(0, 0);
    for (int i = 0; i < rootIndexes.count; i++)
    {
        NSInteger rootIndex = [[rootIndexes objectAtIndex:i] integerValue];
        CGPoint point = points[rootIndex];
        
        _roots[i].Position[0] = point.x / self.scaleFactor;
        _roots[i].Position[1] = point.y / self.scaleFactor;
        _roots[i].Position[2] = self.zOrder;
        _roots[i].TexCoord[0] = arc4random() % 100 / 100.;
        _roots[i].TexCoord[1] = arc4random() % 100 / 100.;
        _center.x += _roots[i].Position[0];
        _center.y += _roots[i].Position[1];
    }
    _center.x /= _rootsCount;
    _center.y /= _rootsCount;
    
    int max = 0;
    for (int i = 1; i < rootIndexes.count; i++)
    {
        CGFloat x1 = _roots[i].Position[0];
        CGFloat y1 = _roots[i].Position[1];
        CGFloat r1 = [self distance:_center from:CGPointMake(x1, y1)];
        CGFloat x2 = _roots[max].Position[0];
        CGFloat y2 = _roots[max].Position[1];
        CGFloat r2 = [self distance:_center from:CGPointMake(x2, y2)];
        
        if (r2 < r1)
        {
            _radius = sqrtf(r1) * self.scaleFactor;
            max = i;
        }
        else
        {
            _radius = sqrtf(r2) * self.scaleFactor;
        }
    }
        
}

-(CGFloat) distance:(CGPoint)a from:(CGPoint)b
{
    return (a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y);
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
    if (_vertexBuffer == 0 || _indexBuffer == 0)
        return;
    
    [self move];
    
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

-(CGPoint)currentPosition:(CGPoint)point
{
    return CGPointMake((point.x + _movement.dx) * self.scaleFactor,
                       (point.y + _movement.dy) * self.scaleFactor);
}

-(CGPoint)currentPositionWithVertex:(Vertex)vertex
{
    return [self currentPosition:CGPointMake(vertex.Position[0],
                                             vertex.Position[1])];
}

-(Boolean)isInHollow:(CGRect)hollow
{
    GLfloat y = (_center.y + _movement.dy) * self.scaleFactor;
    if (y + 0.001 > hollow.origin.y + hollow.size.height)
        return true;
    
    for (int i = 0; i < _rootsCount; i++)
    {
        CGPoint root = [self currentPositionWithVertex:_roots[i]];
        if (CGRectContainsPoint(hollow, root))
            return true;
    }
    
    return false;
}

-(Boolean)intersectAsteroid:(Asteroid*)asteroid
{
    CGRect frame1 = self.frame;
    CGRect frame2 = asteroid.frame;
    
    if (!CGRectIntersectsRect(frame1, frame2)&&
        !CGRectContainsRect(frame1, frame2) &&
        !CGRectContainsRect(frame2, frame1))
        return NO;
    
    for (int i = 0; i < _rootsCount; i++)
    {
        int m = i == 0 ? _rootsCount - 1 : i - 1;
        CGPoint a = [self currentPositionWithVertex:_roots[m]];
        CGPoint b = [self currentPositionWithVertex:_roots[i]];
        for (int k = 0; k < asteroid->_rootsCount; k++)
        {
            int n = k == 0 ? _rootsCount - 1 : k - 1;
            CGPoint c = [asteroid currentPositionWithVertex:asteroid->_roots[n]];
            CGPoint d = [asteroid currentPositionWithVertex:asteroid->_roots[k]];
            CGPoint intersection;
            if (isIntersect(a, b, c, d, &intersection))
                return YES;
        }
    }
    return NO;
}

-(Boolean)intersectFrame:(CGRect)frame
{
    if (!CGRectIntersectsRect(frame, self.frame) &&
        !CGRectContainsRect(frame, self.frame) &&
        !CGRectContainsRect(self.frame, frame))
        return NO;
    
    CGPoint rect[] = {
        CGPointMake(frame.origin.x, frame.origin.y),
        CGPointMake(frame.origin.x + frame.size.width, frame.origin.y),
        CGPointMake(frame.origin.x, frame.origin.y + frame.size.height),
        CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height)
    };
    
    for (int i = 0; i < _rootsCount; i++)
    {
        int m = i == 0 ? _rootsCount - 1 : i - 1;
        CGPoint a = [self currentPositionWithVertex:_roots[m]];
        CGPoint b = [self currentPositionWithVertex:_roots[i]];
        for (int k = 0; k < 4; k++)
        {
            int n = k == 0 ? _rootsCount - 1 : k - 1;
            if (isIntersect(a, b, rect[n], rect[k], nil))
                return YES;
        }
    }
    
    return NO;
}

-(Boolean)intersectSprite:(Sprite*)sprite
{
    return [self intersectFrame:sprite.frame];
}

-(Boolean)intersectAsCircleSprite:(Sprite*)sprite
{
    CGRect frame = sprite.frame;
    CGPoint c = [self currentPosition:_center];
    
    CGPoint rect[] = {
        CGPointMake(frame.origin.x, frame.origin.y),
        CGPointMake(frame.origin.x + frame.size.width, frame.origin.y),
        CGPointMake(frame.origin.x, frame.origin.y + frame.size.height),
        CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height)
    };
    
    CGPoint indot = CGPointMake(frame.origin.x + frame.size.width / 2,
                                frame.origin.y + frame.size.height / 2);
    
    int inside = 0;
    
    for (int i = 0; i < 4; i++)
    {
        int m = i == 0 ? _rootsCount - 1 : i - 1;
        if (semiSign(rect[i], rect[m], indot) == semiSign(rect[i], rect[m], c))
            inside++;
        if (isCircleIntersect(c, _radius, rect[i], rect[m],
                              sqrtf([self distance:rect[i] from:rect[m]])))
            return YES;
    }
    
    if (inside == 4)
        return YES;
    
    if ([self distance:c from:indot] < _radius * _radius)
        return YES;
    
    return NO;
}

-(void)repelAsteroid:(Asteroid *)asteroid
{
    CGPoint a = [self currentPosition:_center];
    CGPoint b = [asteroid currentPosition:asteroid->_center];
    
    CGVector v1 = self.velocity;
    CGVector v2 = asteroid.velocity;
    
    CGFloat m1 = _mass;
    CGFloat m2 = asteroid->_mass;
    
    CGVector un = CGVectorMake(a.x - b.x, a.y - b.y);
    CGFloat una = sqrtf(un.dx * un.dx + un.dy * un.dy);
    un = CGVectorMake(un.dx / una, un.dy / una);
    CGVector ut = CGVectorMake(-un.dy, un.dx);
    
    CGFloat v1n = v1.dx*un.dx + v1.dy*un.dy;
    CGFloat v2n = v2.dx*un.dx + v2.dy*un.dy;
    CGFloat v1t = v1.dx*ut.dx + v1.dy*ut.dy;
    CGFloat v2t = v2.dx*ut.dx + v2.dy*ut.dy;
    
    CGFloat v1n2 = (v1n*(m1-m2) + 2*m2*v2n)/(m1+m2);
    CGFloat v2n2 = (v2n*(m2-m1) + 2*m1*v1n)/(m1+m2);
    
    self.velocity = CGVectorMake(v1n2*un.dx + v1t*ut.dx, v1n2*un.dy + v1t*ut.dy);
    asteroid.velocity = CGVectorMake(v2n2*un.dx + v2t*ut.dx, v2n2*un.dy + v2t*ut.dy);
}

-(NSArray*)produceChilds
{
    int count = arc4random() % (_rootsCount - 2) + 2;
    NSMutableArray * childs = [[NSMutableArray alloc] initWithCapacity:count];
    CGFloat dx = self.velocity.dx;
    for (int i = 0; i < count; i ++)
    {
        CGFloat vx = i == count - 1 ? dx : arc4random() % (100 * count) / 100. * dx;
        dx = dx - vx;
        Asteroid * child = [[Asteroid alloc] initWithPosition:[self currentPositionWithVertex:_roots[i]]
                                                  andVelocity:CGVectorMake(vx, self.velocity.dy)
                                                 andToughness:1];
        if (childs.count > 0)
            [child repelAsteroid:childs.lastObject];
        [childs addObject:child];
    }
    
    return [NSArray arrayWithArray:childs];
}

-(CGRect) frame
{
    CGPoint c = [self currentPosition:_center];
    return CGRectMake(c.x - _radius, c.y - _radius, c.x + _radius, c.y + _radius);
}

@end
