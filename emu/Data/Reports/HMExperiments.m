
//
//  HMExperiments.m
//  emu
//
//  Created by produce_experiments_resource_file.py script.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMExperiments.h"
#import <Optimizely/Optimizely.h>
/**
---------------------------------------
featureVideoRender
---------------------------------------
value type: Bool
default values: False
description: <Bool> - Is the user allowed to render emus as videos?
*/
OptimizelyVariableKeyForBool(featureVideoRender, NO);


/**
---------------------------------------
featureVideoRenderExtraUserSettings
---------------------------------------
value type: Bool
default values: False
description: <Bool> - Is the user allowed to tweak some extra options in video files rendering?
(number of loops, ping pong effect etc)
*/
OptimizelyVariableKeyForBool(featureVideoRenderExtraUserSettings, NO);


/**
---------------------------------------
featureVideoRenderWithAudio
---------------------------------------
value type: Bool
default values: False
description: <Bool> - Is the user allowed to render emus as videos with audio?
*/
OptimizelyVariableKeyForBool(featureVideoRenderWithAudio, NO);


/**
---------------------------------------
iconNameNavRetake
---------------------------------------
value type: String
default values: retakeIcon
description: <String> - The name of the icon used for the retake button in the top navigation bar.
*/
OptimizelyVariableKeyForString(iconNameNavRetake, @"retakeIcon");



@implementation HMExperiments

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.opKeysByString = @{
            @"featureVideoRender":featureVideoRender,
			@"featureVideoRenderExtraUserSettings":featureVideoRenderExtraUserSettings,
			@"featureVideoRenderWithAudio":featureVideoRenderWithAudio,
			@"iconNameNavRetake":iconNameNavRetake
        };
    }
    return self;
}

@end
