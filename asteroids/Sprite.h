//
//  Sprite.h
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLScene.h"

@interface Sprite : NSObject

+(void)reinitSprites;

-(id)initWithName:(NSString*)name andFrame:(CGRect)frame;
-(id)initWithFrame:(CGRect)frame andNames:(NSString*)name1, ... NS_REQUIRES_NIL_TERMINATION;
-(void)drawWithAttrib:(VertexAttrib*)vertexAttrib andFrameSize:(CGSize)frameSize;
-(void)moveTo:(CGPoint)point;
-(void)moveBy:(CGVector)vector;
-(void)changeSpriteFrameTo:(NSUInteger)index;
-(Boolean)checkPoint:(CGPoint)point;
-(Boolean)isInRect:(CGRect)rect;

@property (nonatomic, readonly) CGRect frame;

@end
