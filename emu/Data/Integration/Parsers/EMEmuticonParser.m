//
//  EMEmuticonParser.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

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

    // Find or create the object
    NSString *oid = [info safeOIDStringForKey:@"oid"];
    EmuticonDef *emuDef = [EmuticonDef findOrCreateWithID:oid
                                             context:self.ctx];
    
    // Use auto order or the one defined
    NSNumber *orderSet = [info safeNumberForKey:@"order"];
    emuDef.order                       = orderSet? orderSet:self.incrementalOrder;
    
    // Parse the emuticon definition info.
    emuDef.name                        = [info safeStringForKey:@"name"];
    emuDef.sourceBackLayer             = [info safeStringForKey:@"source_back_layer"];
    emuDef.sourceFrontLayer            = [info safeStringForKey:@"source_front_layer"];
    emuDef.sourceUserLayerMask         = [info safeStringForKey:@"source_user_layer_mask"];
    emuDef.framesCount                 = [info safeNumberForKey:@"frames_count"];
    emuDef.outputVideoMaxFPS           = [info safeNumberForKey:@"output_video_max_fps"];
    emuDef.outputAnimGifMaxFPS         = [info safeNumberForKey:@"output_anim_gif_max_fps"];
    emuDef.useForPreview               = [info safeBoolNumberForKey:@"use_for_preview"];
    emuDef.duration                    = @2.0;
}

@end
