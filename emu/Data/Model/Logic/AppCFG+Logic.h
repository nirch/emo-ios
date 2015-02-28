//
//  AppCFG+Logic.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define E_APP_CFG @"AppCFG"

@class Package;

#import "AppCFG.h"

@interface AppCFG (Logic)

+(AppCFG *)cfgInContext:(NSManagedObjectContext *)context;
-(Package *)packageForOnboarding;

@end
