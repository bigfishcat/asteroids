//
//  Director.m
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "Director.h"
#import "Sprite.h"

@interface Director()
{
    NSTimer * _shooter;
    NSMutableArray * _fireBlasts;
    NSMutableSet * _amunition;
}

@property (nonatomic) GLScene * scene;
@property (nonatomic) Sprite * spaceship;
@property (nonatomic) Sprite * fireButton;

@end

@implementation Director

@synthesize scene;
@synthesize spaceship;
@synthesize fireButton;

-(id)initWithScene:(GLScene *)glScene
{
    if (self = [super init])
    {
        _shooter = [NSTimer timerWithTimeInterval:.3
                                               target:self
                                             selector:@selector(fire:)
                                             userInfo:nil
                                              repeats:YES];
        self.scene = glScene;
        self.scene.touchDelegate = self;
        self.spaceship = [[Sprite alloc] initWithName:@"spaceship"
                                             andFrame:CGRectMake(-.125, -0.9, .25, .5)];
        [self.scene addSprite:self.spaceship];
        self.fireButton = [[Sprite alloc] initWithFrame:CGRectMake(.70, -1.3, .25, .25)
                                               andNames:@"fire_button", @"fire_button_pressed", nil];
        [self.scene addSprite:self.fireButton];
        _fireBlasts = [[NSMutableArray alloc] init];
        _amunition = [[NSMutableSet alloc] init];
        
        CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self
                                                                 selector:@selector(render:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)render:(CADisplayLink*)displayLink
{
    for (Sprite * blast in [_fireBlasts copy])
    {
        [blast moveBy:CGVectorMake(0, 0.05)];
        if (![blast isInRect:self.scene.glFrame])
        {
            [self.scene removeSprite:blast];
            [_amunition addObject:blast];
            [_fireBlasts removeObject:blast];
        }
        
    }
    [self.spaceship moveTo:CGPointMake(sin(CACurrentMediaTime()) / 5 * 4 - .125, -1)];
    [self.scene render];
}

-(void)fire:(NSTimer*)sender
{
    CGRect blastFrame = self.spaceship.frame;
    blastFrame.origin.y += blastFrame.size.height;
    blastFrame.origin.x += blastFrame.size.width / 4;
    blastFrame.size.width = blastFrame.size.width / 2;
    blastFrame.size.height = blastFrame.size.width / 2;
    blastFrame.origin.y -= blastFrame.size.height;
    Sprite * blast = nil;
    if (_amunition.count > 0)
    {
        blast = [_amunition anyObject];
        [_amunition removeObject:blast];
        [blast moveTo:blastFrame.origin];
    }
    else
    {
        blast = [[Sprite alloc] initWithName:@"blast" andFrame:blastFrame];
    }
    [self.scene addSprite:blast];
    [_fireBlasts addObject:blast];
}

-(void)startFire
{
    [self.fireButton changeSpriteFrameTo:1];
    _shooter = [NSTimer scheduledTimerWithTimeInterval:.3
                                                target:self
                                              selector:@selector(fire:)
                                              userInfo:nil
                                               repeats:YES];
}

-(void)stopFire
{
    [self.fireButton changeSpriteFrameTo:0];
    [_shooter invalidate];
    _shooter = nil;
}

-(void)touchesBeganAt:(CGPoint)point
{
    if ([self.fireButton checkPoint:point])
        [self startFire];
}

-(void)touchesEndedAt:(CGPoint)point
{
    [self stopFire];
}

-(void)touchesMovedTo:(CGPoint)point
{
    if (![self.fireButton checkPoint:point])
        [self stopFire];
}

@end
