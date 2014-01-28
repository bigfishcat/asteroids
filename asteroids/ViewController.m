//
//  ViewController.m
//  asteroids
//
//  Created by Andrey Tumanov on 28/01/14.
//  Copyright (c) 2014 Andrey Tumanov. All rights reserved.
//

#import "ViewController.h"
#import "GLScene.h"
#import "Director.h"

@interface ViewController ()

@property (nonatomic) Director *director;

@end

@implementation ViewController

@synthesize director;

- (void)viewDidLoad
{
    [super viewDidLoad];
	[(GLScene*)self.view load];
    self.director = [[Director alloc] initWithScene:(GLScene*)self.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
