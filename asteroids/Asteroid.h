//
//  Asteroid.h
//  asteroids
//
//  Created by Andrey Tumanov on 28/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLObject.h"

@class Sprite;

@interface Asteroid : GLObject

-(id)initWithPosition:(CGPoint)position andVelocity:(CGVector)velocity;
-(Boolean)isInHollow:(CGRect)hollow;
-(Boolean)intersectAsteroid:(Asteroid*)asteroid;
-(Boolean)intersectSprite:(Sprite*)sprite;
-(Boolean)intersectFrame:(CGRect)frame;
-(void)repelAsteroid:(Asteroid*)asteroid;
-(NSArray*)produceChilds;

@property (readonly) NSInteger toughness;
@property CGVector velocity;

@end
