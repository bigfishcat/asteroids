//
//  Sprite.m
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "Sprite.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

typedef struct
{
    CGFloat x;
    CGFloat y;
    CGFloat z;
} GLPoint;

typedef struct
{
    GLfloat Position[3];
    GLfloat TexCoord[2];
} Vertex;

#define VERTICES_COUNT 4

@interface Sprite()
{
    GLuint _texture;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    Vertex _vertices[VERTICES_COUNT];
    GLushort _indices[VERTICES_COUNT];
    CGVector _movement;
    GLPoint _position;
    CGSize _size;
}

@property (nonatomic) NSMutableArray* spriteFrames;

@end

static int zOrder = -MAX_SPRITE_COUNT;

@implementation Sprite

@synthesize spriteFrames;

+(void)reinitSprites
{
    zOrder = -MAX_SPRITE_COUNT;
}

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
            [self.spriteFrames addObject:
             [NSNumber numberWithUnsignedInt:[self loadTexture:nameNext]]];
        } while (nameNext);
    }
    va_end(params);
    return self;
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

-(void)createVerticesWithFrame:(CGRect)frame
{
    GLfloat xs[VERTICES_COUNT / 2] = {frame.origin.x, frame.origin.x + frame.size.width};
    GLfloat ys[VERTICES_COUNT / 2] = {frame.origin.y, frame.origin.y + frame.size.height};
    int xi = 0;
    int yi = 0;
    _position.x = xs[0];
    _position.y = ys[0];
    _position.z = ++zOrder;
    _size = frame.size;
    for (int i = 0; i < VERTICES_COUNT; i++)
    {
        Vertex v = {{xs[xi] * (1 - _position.z), ys[yi] * (1 - _position.z), _position.z}, {xi, yi}};
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
    return CGRectMake(_position.x + _movement.dx / (-_position.z),
                      _position.y + _movement.dy / (-_position.z),
                      _size.width, _size.height);
}

-(Boolean)isInRect:(CGRect)rect
{
    return CGRectContainsRect(rect, self.frame);
}

-(CGVector)relativeDirection:(CGPoint)point
{
    CGFloat x = _position.x + _movement.dx / (-_position.z) + _size.width / 2;
    CGFloat y = _position.y + _movement.dy / (-_position.z) + _size.height / 2;
    return CGVectorMake(point.x - x, point.y - y);
}

@end
