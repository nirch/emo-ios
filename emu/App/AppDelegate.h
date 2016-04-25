//
//  AppDelegate.h
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
@import UIKit;

@class EMShareFBMessanger;
@class FBSDKMessengerContext;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// TODO: this us of "global" is ugly. Find another solution if possible.
@property (atomic, weak) EMShareFBMessanger *currentFBMSharer;
@property (nonatomic) FBSDKMessengerContext *fbContext;
-(BOOL)isInFBMContext;

@end
