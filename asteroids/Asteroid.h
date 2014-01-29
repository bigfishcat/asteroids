//
//  Asteroid.h
//  asteroids
//
//  Created by Andrey Tumanov on 28/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLObject.h"

@interface Asteroid : GLObject

-(id)initWithPosition:(CGPoint)position;

@property (readonly) NSInteger toughness;
@property CGVector speed;

@end
