//
//  GLScene.h
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct {
    GLuint positionSlot;
    GLuint texCoordSlot;
    GLuint modelViewUniform;
    GLuint textureUniform;
} VertexAttrib;

@protocol TouchDelegate <NSObject>

-(void)touchesBeganAt:(CGPoint)point;
-(void)touchesEndedAt:(CGPoint)point;
-(void)touchesMovedTo:(CGPoint)point;

@end

#define MAX_SPRITE_COUNT 100

@class Sprite;

@interface GLScene : UIView


-(void)load;
-(void)render;
-(void)addSprite:(Sprite*)sprite;
-(void)removeSprite:(Sprite*)sprite;

@property (nonatomic) NSObject<TouchDelegate>* touchDelegate;
@property (readonly) CGRect glFrame;

@end
