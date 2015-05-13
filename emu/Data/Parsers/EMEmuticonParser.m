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
    emuDef.mixedScreenOrder = self.mixedScreenOrder? self.mixedScreenOrder:@9999;
    
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
    emuDef.sourceBackLayer             = [info safeStringForKey:@"source_back_layer" defaultsDictionary:defaults];
    emuDef.sourceFrontLayer            = [info safeStringForKey:@"source_front_layer" defaultsDictionary:defaults];
    emuDef.sourceUserLayerMask         = [info safeStringForKey:@"source_user_layer_mask" defaultsDictionary:defaults];
    emuDef.useForPreview               = [info safeBoolNumberForKey:@"use_for_preview" defaultsDictionary:defaults];
    emuDef.duration                    = [info safeDecimalNumberForKey:@"duration" defaultsDictionary:defaults];
    emuDef.framesCount                 = [info safeNumberForKey:@"frames_count" defaultsDictionary:defaults];
    emuDef.thumbnailFrameIndex         = [info safeNumberForKey:@"thumbnail_frame_index" defaultsDictionary:defaults];
    emuDef.palette                     = [info safeStringForKey:@"palette" defaultsDictionary:defaults];
    
    HMLOG(TAG, EM_VERBOSE, @"Parsed emuticon def named: %@", emuDef.name);
}

@end
