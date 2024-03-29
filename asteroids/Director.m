//
//  Director.m
//  AsteroidsIOS
//
//  Created by Andrey Tumanov on 27/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "Director.h"
#import "Sprite.h"
#import "Asteroid.h"

@interface Director()
{
    NSTimer * _shooter;
    NSTimer * _asteroidLauncher;
    CGVector _movement;
    NSMutableArray * _asteroids;
    NSMutableArray * _fireBlasts;
    NSMutableSet * _amunition;
    GLfloat _bottomLine;
}

@property (nonatomic) GLScene * scene;
@property (nonatomic) Sprite * spaceship;
@property (nonatomic) Sprite * fireButton;
@property (nonatomic) Sprite * crossButton;
@property (nonatomic) CGRect playTable;

@end

@implementation Director

@synthesize scene;
@synthesize spaceship;
@synthesize fireButton;
@synthesize crossButton;
@synthesize playTable;

-(id)initWithScene:(GLScene *)glScene
{
    if (self = [super init])
    {
        self.scene = glScene;
        self.scene.touchDelegate = self;
        GLfloat buttonSize = .25;
        CGSize shipSize = CGSizeMake(.25, .5);
        _bottomLine = glScene.glFrame.origin.y + buttonSize * 1.4;
        self.fireButton = [[Sprite alloc] initWithFrame:CGRectMake(1 - buttonSize * 1.2,
                                                                   _bottomLine - buttonSize * 1.2,
                                                                   buttonSize, buttonSize)
                                               andNames:@"fire_button", @"fire_button_pressed", nil];
        [self.scene addObject:self.fireButton];
        self.crossButton = [[Sprite alloc] initWithName:@"cross_button"
                                               andFrame:CGRectMake(buttonSize * .2 - 1,
                                                                   _bottomLine - buttonSize * 1.2,
                                                                   2 * buttonSize, 2 * buttonSize)];
        [self.scene addObject:self.crossButton];
        
        self.spaceship = [[Sprite alloc] initWithName:@"spaceship"
                                             andFrame:CGRectMake(-shipSize.width/2, _bottomLine,
                                                                 shipSize.width, shipSize.height)];
        [self.scene addObject:self.spaceship];
        
        _asteroids = [[NSMutableArray alloc] init];
        _fireBlasts = [[NSMutableArray alloc] init];
        _amunition = [[NSMutableSet alloc] init];
        
        CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self
                                                                 selector:@selector(render:)];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        _asteroidLauncher = [NSTimer scheduledTimerWithTimeInterval:0.4
                                                             target:self
                                                           selector:@selector(createAsteroid:)
                                                           userInfo:nil
                                                            repeats:YES];
    }
    return self;
}

-(void)removeAsteroid:(Asteroid*)asteroid
{
    [self.scene removeObject:asteroid];
    [_asteroids removeObject:asteroid];
}

-(void)removeBlast:(Sprite*)blast
{
    [self.scene removeObject:blast];
    [_amunition addObject:blast];
    [_fireBlasts removeObject:blast];
}

-(void)restart
{
    for (Sprite * blast in [_fireBlasts copy])
        [self removeBlast:blast];
    for (Asteroid * asteroid in [_asteroids copy])
        [self removeAsteroid:asteroid];
    [self.spaceship resetPosition];
}

-(CGRect)shipFrame
{
    const CGFloat width = 108.f/128.f;
    const CGFloat height = 172.f/256.f;
    CGRect frame = self.spaceship.frame;
    CGFloat dx = frame.size.width * width / 2;
    CGFloat dy = frame.size.height * height / 2;
    return CGRectMake(frame.origin.x + dx, frame.origin.y + dy,
                      frame.size.width - 2 * dx, frame.size.height - 2 * dy);
}

-(void)processObjects
{
    for (int i = 0; i < _asteroids.count; i++)
    {
        Asteroid * asteroid = [_asteroids objectAtIndex:i];
        if ([asteroid intersectFrame:[self shipFrame]])
        {
            [self restart];
            return;
        }
        if (![asteroid isInHollow:self.scene.glFrame])
        {
            [self removeAsteroid:asteroid];
        }
        else
        {
            for (int k = i + 1; k < _asteroids.count; k++)
            {
                Asteroid * asteroid2 = [_asteroids objectAtIndex:k];
                if([asteroid intersectAsteroid:asteroid2])
                    [asteroid repelAsteroid:asteroid2];
            }
        }

    }
    
    for (Sprite * blast in [_fireBlasts copy])
    {
        [blast moveBy:CGVectorMake(0, 0.05)];
        
        for (Asteroid * asteroid in [_asteroids copy])
        {
            if ([asteroid intersectAsCircleSprite:blast])
            {
                [self removeBlast:blast];
                if (asteroid.toughness > 1)
                {
                    NSArray * childs = [asteroid produceChilds];
                    for (Asteroid * child in childs)
                    {
                        [self.scene addObject:child];
                        [_asteroids addObject:child];
                    }
                }
                [self removeAsteroid:asteroid];
                break;
            }
        }
        
        if (![blast isInRect:self.scene.glFrame])
        {
            [self removeBlast:blast];
        }
    }
}

-(void)render:(CADisplayLink*)displayLink
{
    [self processObjects];
    [self.scene render];
}

-(void)createAsteroid:(NSTimer*)sender
{
    CGRect r = self.scene.glFrame;
    CGPoint initPoint = CGPointMake(arc4random() % 200 / 100. - 1., r.origin.y + r.size.height);
    CGVector initVelocity = CGVectorMake(arc4random() % 20 / 40000. - .0002, arc4random() % 20 / 40000. - .0007);
    Asteroid * asteroid = [[Asteroid alloc]
                           initWithPosition:initPoint
                                andVelocity:initVelocity];
    [self.scene addObject:asteroid];
    [_asteroids addObject:asteroid];
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
    [self.scene addObject:blast];
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

-(CGRect)playTable
{
    CGRect table = self.scene.glFrame;
    table.size.height -= _bottomLine - table.origin.y;
    table.origin.y = _bottomLine;
    return table;
}

-(void)moveShipBy:(CGVector)vector
{
    const float k = 0.3;
    [self.spaceship moveBy:CGVectorMake(vector.dx * k, vector.dy * k) inRect:self.playTable];
}

-(void)touchesBeganAt:(CGPoint)point
{
    if ([self.fireButton checkPoint:point])
    {
        [self startFire];
        [self fire:nil];
    }
    else if ([self.crossButton checkPoint:point])
    {
        [self moveShipBy:[self.crossButton relativeDirection:point]];
    }
}

-(void)touchesEndedAt:(CGPoint)point
{
    if ([self.fireButton checkPoint:point])
        [self stopFire];
}

-(void)touchesMovedTo:(CGPoint)point
{
    if ([self.crossButton checkPoint:point])
        [self moveShipBy:[self.crossButton relativeDirection:point]];
    else if (![self.fireButton checkPoint:point])
        [self stopFire];
}

@end
