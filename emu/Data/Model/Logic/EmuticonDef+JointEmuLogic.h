//
//  EmuticonDef+JointEmuLogic.h
//  emu
//
//  Created by Aviv Wolf on 13/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EmuticonDef.h"

@interface EmuticonDef (JointEmuLogic)

#pragma mark - General
-(BOOL)isJointEmu;
-(NSInteger)jointEmuDefSlotsCount;
-(NSInteger)jointEmuDefInitiatorSlotIndex;

#pragma mark - Joint emu instances
-(void)latestEmuGainFocus;

#pragma mark - Questions about a specific slot
-(NSDictionary *)jointEmuDefSlot:(NSInteger)slotIndex;
-(NSTimeInterval)jointEmuDefCaptureDurationAtSlot:(NSInteger)slotIndex;
-(BOOL)jointEmuDefRequiresDedicatedCaptureAtSlot:(NSInteger)slotIndex;

@end
