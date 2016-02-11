//
//  EMEmuticonParser.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMEmuticonParser"

#import "EMEmuticonParser.h"
#import "EMDB.h"

@implementation EMEmuticonParser

-(void)parse
{
    if (self.package == nil ||
        self.objectToParse == nil)
        return;

    /*
     Example for an emuticon object
     
     {
     "oid": {"$oid": "54919516454c61f4080000e5"},
     "name": "angel",
     "source_back_layer": "angel-bg.gif",
     "source_front_layer": "angel-fg.gif",
     "source_user_layer_mask": "angel-mask.jpg",
     "use_for_preview":true
     "duration": 2.0,
     "frames_count": 24,
     "thumbnail_frame_index": 23
     }
     
     */

    NSDictionary *info = self.objectToParse;
    NSDictionary *defaults = self.defaults;

    // Find or create the object
    NSString *oid = [info safeOIDStringForKey:@"_id"];
    EmuticonDef *emuDef = [EmuticonDef findOrCreateWithID:oid
                                             context:self.ctx];
    emuDef.package = self.package;
    
    // Use auto order or the one defined in json.
    NSNumber *orderSet = [info safeNumberForKey:@"order"];
    emuDef.order                       = orderSet? orderSet:self.incrementalOrder;
    
    // Mixed screen ordering.
    // If no order provided, generate a high random order (but only if not already generated).
    if (self.mixedScreenOrder) {
        emuDef.mixedScreenOrder = self.mixedScreenOrder;
    } else {
        emuDef.mixedScreenOrder = @(arc4random() % 1000 + 1000);
    }
    
    // Parse the emuticon definition info.
    emuDef.name                        = [info safeStringForKey:@"name" defaultsDictionary:defaults];

    // If emu def patched (one of the resources or definitions updated)
    // Will need to rerender the emu for the user.
    NSDate *patchedOn = [self parseDateOfString:[info safeStringForKey:@"patched_on" defaultsDictionary:defaults]];
    if (patchedOn != nil) {
        if (![patchedOn isEqualToDate:emuDef.patchedOn]) {
            for (Emuticon *emu in emuDef.emus) {
                [emu cleanUp];
                [emu.emuDef removeAllResources];
            }
        }
        emuDef.patchedOn = patchedOn;
    }

    // Emu definitions and resources
    emuDef.sourceBackLayer                      = [info safeStringForKey:@"source_back_layer" defaultsDictionary:defaults];
    emuDef.sourceBackLayer2X                    = [info safeStringForKey:@"source_back_layer_2x" defaultsDictionary:defaults];
    emuDef.sourceFrontLayer                     = [info safeStringForKey:@"source_front_layer" defaultsDictionary:defaults];
    emuDef.sourceFrontLayer2X                   = [info safeStringForKey:@"source_front_layer_2x" defaultsDictionary:defaults];
    emuDef.sourceUserLayerMask                  = [info safeStringForKey:@"source_user_layer_mask" defaultsDictionary:defaults];
    emuDef.sourceUserLayerMask2X                = [info safeStringForKey:@"source_user_layer_mask_2x" defaultsDictionary:defaults];
    emuDef.sourceUserLayerDynamicMask           = [info safeStringForKey:@"source_user_dynamic_mask" defaultsDictionary:defaults];
    emuDef.sourceUserLayerDynamicMask2X         = [info safeStringForKey:@"source_user_dynamic_mask_2x" defaultsDictionary:defaults];

    emuDef.useForPreview                        = [info safeBoolNumberForKey:@"use_for_preview" defaultsDictionary:defaults];
    emuDef.duration                             = [info safeDecimalNumberForKey:@"duration" defaultsDictionary:defaults];
    emuDef.framesCount                          = [info safeNumberForKey:@"frames_count" defaultsDictionary:defaults];
    emuDef.thumbnailFrameIndex                  = [info safeNumberForKey:@"thumbnail_frame_index" defaultsDictionary:defaults];
    emuDef.palette                              = [info safeStringForKey:@"palette" defaultsDictionary:defaults];
    emuDef.disallowedForOnboardingPreview       = [info safeBoolNumberForKey:@"disallowed_for_onboarding_preview" defaultsValue:@NO];
    emuDef.effects                              = [info safeDictionaryForKey:@"effects" defaultValue:nil];
    emuDef.prefferedWaterMark                   = [info safeStringForKey:@"preffered_watermark" defaultsDictionary:defaults];
    emuDef.hdAvailable                          = [info safeBoolNumberForKey:@"hd_available" defaultsValue:@NO];
    emuDef.emuWidth                             = [info safeNumberForKey:@"emu_width" defaultsDictionary:defaults];
    emuDef.emuHeight                            = [info safeNumberForKey:@"emu_height" defaultsDictionary:defaults];
    
    // Joint emu
    emuDef.jointEmu                             = [info safeDictionaryForKey:@"joint_emu" defaultValue:nil];
    
    // Default assumed size of user's layers when using positining.
    NSArray *assumedUsersLayersSize = [info safeArrayForKey:@"assumed_users_layers_size" defaultValue:nil];
    emuDef.assumedUsersLayersWidth = assumedUsersLayersSize? assumedUsersLayersSize[0]:@240;
    emuDef.assumedUsersLayersHeight = assumedUsersLayersSize? assumedUsersLayersSize[1]:@240;
    
    HMLOG(TAG, EM_VERBOSE, @"Parsed emuticon def named: %@", emuDef.name);
}

@end
