//
//  EmuticonDef+JointEmuLogic.m
//  emu
//
//  Created by Aviv Wolf on 13/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EmuticonDef+JointEmuLogic.h"
#import "EMDB.h"

@implementation EmuticonDef (JointEmuLogic)

#pragma mark - Joint emu
-(BOOL)isJointEmu
{
    if (self.jointEmu != nil) return YES;
    return NO;
}

-(NSInteger)jointEmuDefSlotsCount
{
    if (self.isJointEmu == NO) return 0;
    NSArray *slots = self.jointEmu[@"slots"];
    if ([slots isKindOfClass:[NSArray class]]) return slots.count;
    return 0;
}

-(NSInteger)jointEmuDefInitiatorSlotIndex
{
    NSDictionary *jointEmuDef = self.jointEmu;
    NSNumber *initiatorSlot = jointEmuDef[@"initiator_slot"];
    if (initiatorSlot) return [initiatorSlot integerValue];
    return 0;
}

-(void)latestEmuGainFocus
{
    NSArray *sortBy = @[[NSSortDescriptor sortDescriptorWithKey:@"timeCreated" ascending:YES]];
    NSArray *emus = [self emusOrdered:sortBy];
    Emuticon *emu = [emus lastObject];
    [emu gainFocus];
}


-(NSDictionary *)jointEmuDefSlot:(NSInteger)slotIndex
{
    NSDictionary *jointEmuDef = self.jointEmu;
    if (![jointEmuDef isKindOfClass:[NSDictionary class]]) return nil;
    NSArray *slots = jointEmuDef[@"slots"];
    if (![slots isKindOfClass:[NSArray class]]) return nil;
    if (slotIndex > 0 && slotIndex<= slots.count) {
        return slots[slotIndex-1];
    }
    return nil;
}

-(NSTimeInterval)jointEmuDefCaptureDurationAtSlot:(NSInteger)slotIndex
{
    NSDictionary *slot = [self jointEmuDefSlot:slotIndex];
    if (slot != nil) {
        if ([slot[@"capture_duration"] isKindOfClass:[NSNumber class]]) {
            return [slot[@"capture_duration"] doubleValue];
        }
    }
    if (self.captureDuration) return self.captureDuration.doubleValue;
    return self.duration.doubleValue;
}

-(NSString *)jointEmuDefCaptureDurationStringAtSlot:(NSInteger)slotIndex
{
    NSString *title = LS(@"X_SECONDS_VIDEO");
    NSInteger duration = [self jointEmuDefCaptureDurationAtSlot:slotIndex];
    NSString *durationString = [NSString stringWithFormat:@"%@", @(duration)];
    title = [title stringByReplacingOccurrencesOfString:@"#" withString:durationString];
    return title;
}

-(BOOL)jointEmuDefRequiresDedicatedCaptureAtSlot:(NSInteger)slotIndex
{
    NSTimeInterval duration = [self jointEmuDefCaptureDurationAtSlot:slotIndex];
    return duration > 2.0;
}


@end
