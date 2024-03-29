
//
//  HMExperiments.m
//  emu
//
//  Created by produce_experiments_resource_file.py script.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMExperiments.h"
/**
---------------------------------------
featureVideoRender
---------------------------------------
value type: Bool
default values: False
description: <Bool> - Is the user allowed to render emus as videos?
*/
//OptimizelyVariableKeyForBool(featureVideoRender, NO);


/**
---------------------------------------
featureVideoRenderExtraUserSettings
---------------------------------------
value type: Bool
default values: False
description: <Bool> - Is the user allowed to tweak some extra options in video files rendering?
(number of loops, ping pong effect etc)
*/
//OptimizelyVariableKeyForBool(featureVideoRenderExtraUserSettings, NO);


/**
---------------------------------------
featureVideoRenderWithAudio
---------------------------------------
value type: Bool
default values: False
description: <Bool> - Is the user allowed to render emus as videos with audio?
*/
//OptimizelyVariableKeyForBool(featureVideoRenderWithAudio, NO);


/**
---------------------------------------
htmlShareAppBody
---------------------------------------
value type: String
default values: 
description: <String> - The body html for the email sent when the user select to share app link using email.
*/
//OptimizelyVariableKeyForString(htmlShareAppBody, @"");


/**
---------------------------------------
iconNameNavRetake
---------------------------------------
value type: String
default values: retakeIcon
description: <String> - The name of the icon used for the retake button in the top navigation bar.
*/
//OptimizelyVariableKeyForString(iconNameNavRetake, @"retakeIcon");


/**
---------------------------------------
logicBGRemovalBehavior
---------------------------------------
value type: Number
default values: 0
description: <Number> - 0 - Normal. 1 - New behavior with bg detection sync changes.
(number of loops, ping pong effect etc)
*/
//OptimizelyVariableKeyForNumber(logicBGRemovalBehavior, @0);


/**
---------------------------------------
mainFeedScrollDecelerationSpeed
---------------------------------------
value type: Number
default values: 0
description: <Number> - 0 - Normal. 1 - Faster deceleration.
(number of loops, ping pong effect etc)
*/
//OptimizelyVariableKeyForNumber(mainFeedScrollDecelerationSpeed, @0);


/**
---------------------------------------
onboardingEmusForPreviewList
---------------------------------------
value type: String
default values: 
description: <String> - A list of preffered emus oids to use for preview in the onboarding stage (given as a comma delimited string)
*/
//OptimizelyVariableKeyForString(onboardingEmusForPreviewList, @"");


/**
---------------------------------------
recorderRecordButtonCountdownFrom
---------------------------------------
value type: Number
default values: 0
description: <Int> - Number of seconds to countdown from before starting to record (if 0 will not count down and start recording immediately)
*/
//OptimizelyVariableKeyForNumber(recorderRecordButtonCountdownFrom, @0);


/**
---------------------------------------
recorderShowAdvancedCameraOptionsOnOnboarding
---------------------------------------
value type: Bool
default values: False
description: <Bool> - Boolean value indicating if the advanced camera options are shown to the user when the recorder is opened for the first time for onboarding.
*/
//OptimizelyVariableKeyForBool(recorderShowAdvancedCameraOptionsOnOnboarding, NO);


/**
---------------------------------------
settingsRedeemCodeOption
---------------------------------------
value type: Number
default values: 0
description: Redeem code option in settings screen. 0: disabled. 1: enabled. 2: hidden (long press homage icon)
*/
//OptimizelyVariableKeyForNumber(settingsRedeemCodeOption, @0);


/**
---------------------------------------
textShareAppBody
---------------------------------------
value type: String
default values: Hi\n\nCheck out this cool app:\n\nEmu - Selfie Stickers\nhttps://geo.itunes.apple.com/app/id969789079?mt=8&uo=6
description: <String> - The body text for the email sent when the user select to share app link using email.
*/
//OptimizelyVariableKeyForString(textShareAppBody, @"Hi\n\nCheck out this cool app:\n\nEmu - Selfie Stickers\nhttps://geo.itunes.apple.com/app/id969789079?mt=8&uo=6");


/**
---------------------------------------
textShareAppSubject
---------------------------------------
value type: String
default values: Emu - Selfie Stickers
description: <String> - The subject text for the email sent when the user select to share app link using email.
*/
//OptimizelyVariableKeyForString(textShareAppSubject, @"Emu - Selfie Stickers");



@implementation HMExperiments

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.opKeysByString = @{};
//        self.opKeysByString = @{
//            @"featureVideoRender":featureVideoRender,
//			@"featureVideoRenderExtraUserSettings":featureVideoRenderExtraUserSettings,
//			@"featureVideoRenderWithAudio":featureVideoRenderWithAudio,
//			@"htmlShareAppBody":htmlShareAppBody,
//			@"iconNameNavRetake":iconNameNavRetake,
//			@"logicBGRemovalBehavior":logicBGRemovalBehavior,
//			@"mainFeedScrollDecelerationSpeed":mainFeedScrollDecelerationSpeed,
//			@"onboardingEmusForPreviewList":onboardingEmusForPreviewList,
//			@"recorderRecordButtonCountdownFrom":recorderRecordButtonCountdownFrom,
//			@"recorderShowAdvancedCameraOptionsOnOnboarding":recorderShowAdvancedCameraOptionsOnOnboarding,
//			@"settingsRedeemCodeOption":settingsRedeemCodeOption,
//			@"textShareAppBody":textShareAppBody,
//			@"textShareAppSubject":textShareAppSubject
//        };
    }
    return self;
}

@end
