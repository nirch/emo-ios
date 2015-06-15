//
//  EMMainOptionsBarVC.m
//  emu
//
//  Created by Aviv Wolf on 6/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMMainOptionsBarVC.h"

@interface EMMainOptionsBarVC ()

@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;

@end

@implementation EMMainOptionsBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
}


-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self initGUI];
}


-(void)initGUI
{
    //
    // Add blur effect to the background.
    //
    self.guiBlurredView.backgroundColor = [UIColor clearColor];
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.guiBlurredView.bounds;
    [self.guiBlurredView addSubview:visualEffectView];
}


@end
