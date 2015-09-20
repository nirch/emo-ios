//
//  EMTestVC.m
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMTestVC.h"

@interface EMTestVC ()

@end

@implementation EMTestVC

+(EMTestVC *)testVCWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor
{
    EMTestVC *vc = [[EMTestVC alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    vc.view.frame = frame;
    return vc;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end
