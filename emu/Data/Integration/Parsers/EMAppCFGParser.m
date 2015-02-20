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
    
    // Find or create the object
    AppCFG *appCFG = [AppCFG cfgInContext:self.ctx];
    
    // Parse the emuticon definition info.
    appCFG.animGifMaxFPS =          [info safeNumberForKey:@"anim_gif_max_fps"];
    appCFG.videoMaxFPS =            [info safeNumberForKey:@"video_max_fps"];
    [EMDB.sh save];
}

@end
