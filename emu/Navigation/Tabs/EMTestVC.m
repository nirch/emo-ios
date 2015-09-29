//
//  EMTestVC.m
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMTestVC.h"
#import "EMNavBarVC.h"

@interface EMTestVC ()

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;

@property (nonatomic) UIColor *backgroundColor;

@end

@implementation EMTestVC

+(EMTestVC *)testVCWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor
{
    EMTestVC *vc = [[EMTestVC alloc] init];
    vc.backgroundColor = backgroundColor;
    vc.view.backgroundColor = [UIColor whiteColor];
    vc.view.frame = frame;
    return vc;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    EMNavBarVC *navBarVC;
    navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:self.backgroundColor];
    self.navBarVC = navBarVC;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.navBarVC bounce];
}

@end
