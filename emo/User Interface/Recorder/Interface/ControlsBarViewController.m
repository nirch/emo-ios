//
//  ControlsBarViewController.m
//  emo
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "ControlsBarViewController.h"

@interface ControlsBarViewController ()

@end

@implementation ControlsBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
}

-(void)initGUI
{
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = self.view.bounds;
    [self.view addSubview:visualEffectView];
}

@end
