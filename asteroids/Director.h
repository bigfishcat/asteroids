//
//  Director.h
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLScene.h"

@interface Director : NSObject<TouchDelegate>

-(id)initWithScene:(GLScene *)glScene;

@end
