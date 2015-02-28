//
//  EMAppCFGParser.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMAppCFGParser.h"
#import "EMDB.h"

@implementation EMAppCFGParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    if (info == nil) return;
    
    // (yes, this is kind of empty now. will build on this in the future)
    /*
     {
     "default_output_video_max_fps": 15
     }
     */
    
    
    // Find or create the object
    AppCFG *appCFG = [AppCFG cfgInContext:self.ctx];
    
    // Parse the application configuration
    appCFG.defaultOutputVideoMaxFps = [info safeNumberForKey:@"default_output_video_max_fps"];
    appCFG.onboardingUsingPackage = [info safeOIDStringForKey:@"onboarding_using_package"];
    [EMDB.sh save];
}

@end
