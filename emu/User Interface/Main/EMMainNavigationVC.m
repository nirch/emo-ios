//
//  EMMainNavigationVC.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMMainNavigationVC.h"

@interface EMMainNavigationVC ()

@end

@implementation EMMainNavigationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.backgroundColor = [UIColor redColor];
    self.navigationBar.tintColor = [UIColor blueColor];
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
