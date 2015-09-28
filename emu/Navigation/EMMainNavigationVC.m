//
//  MainNavigationVC.m
//  emu
//
//  -----------------------------------------------------------------------
//  Responsibilities:
//      - The main VC of the application.
//      - Contains the main tabs vc of the whole app.
//      - Handles the flow of "First launch flow" / "After onboarding flow"
//  -----------------------------------------------------------------------
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMMainNavigationVC.h"

#define TAG @"EMMainNavigationVC"

@interface EMMainNavigationVC ()

@end

@implementation EMMainNavigationVC

#pragma mark - VC lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HMLOG(TAG, EM_DBG, @"Navigation VC did appear");
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
