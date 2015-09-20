//
//  MainNavigationVC.m
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMMainNavigationVC.h"

@interface EMMainNavigationVC ()

@end

@implementation EMMainNavigationVC

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Initializations

#pragma mark - Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

#pragma mark - Status bar
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========


@end
