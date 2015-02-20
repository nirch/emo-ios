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
    NSDictionary *info = self.objectToParse;
    if (info == nil) return;

    /*
     Example for an emuticon object
     
     {
         "oid": {"$oid": "54919516454c61f4080000e5"},
         "name": "test",
         "order": 1,
         "duration": 2.0,
         "source_back_layer": "test_yellow_bg.gif",
         "source_back_layer_frames": 50,
         "source_front_layer": "test_i_love_you.gif",
         "source_front_layer_frames": 50,
         "source_user_layer_mask": "test_mask.png",
         "output_video_max_fps": 15,
         "output_anim_gif_max_fps": 7,
         "tags":"love,happy,hearts",
         "package": "demo"
     }
     
     */
    
    // Find or create the object
    NSString *oid = [info safeOIDStringForKey:@"oid"];
    EmuticonDef *emuDef = [EmuticonDef findOrCreateWithID:oid
                                             context:self.ctx];
    
    // Parse the emuticon definition info.
    emuDef.name                        = [info safeStringForKey:@"name"];
    emuDef.order                       = [info safeNumberForKey:@"order"];
    emuDef.duration                    = [info safeDecimalNumberForKey:@"duration"];
    emuDef.sourceBackLayer             = [info safeStringForKey:@"source_back_layer"];
    emuDef.sourceBackLayerFramesCount  = [info safeNumberForKey:@"source_front_layer_frames"];
    emuDef.sourceFrontLayer            = [info safeStringForKey:@"source_front_layer"];
    emuDef.sourceFrontLayerFramesCount = [info safeNumberForKey:@"source_front_layer_frames"];
    emuDef.sourceUserLayerMask         = [info safeStringForKey:@"source_user_layer_mask"];
    emuDef.outputVideoMaxFPS           = [info safeNumberForKey:@"output_video_max_fps"];
    emuDef.outputAnimGifMaxFPS         = [info safeNumberForKey:@"output_anim_gif_max_fps"];
    
}

@end
