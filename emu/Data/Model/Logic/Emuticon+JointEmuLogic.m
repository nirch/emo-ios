//
//  Emuticon+JointEmuLogic.m
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "Emuticon+JointEmuLogic.h"
#import "NSDictionary+TypeSafeValues.h"

@implementation Emuticon (JointEmuLogic)

-(NSInteger)jointEmuInvitationsSentCount
{
    if (self.jointEmuInstance == nil) return 0;
    NSInteger count = 0;
    NSArray *receiversSlots = [self receiversSlots];
    for (NSDictionary *slot in receiversSlots) {
        if (slot[@"invite_code"] != nil) count++;
    }
    return count;
}

-(NSString *)jointEmuOID
{
    if (self.jointEmuInstance == nil) return nil;
    return [self.jointEmuInstance safeOIDStringForKey:@"_id"];
}

//-(NSArray *)remoteSlots
//{
//    NSString *initiatorOID = [self initiatorOID];
//    NSMutableArray *slots = [NSMutableArray new];
//    for (NSDictionary *slot in self.jointEmuInstance[@"joint_emu_slots"]) {
//        if (slot[@"user_id"] != nil && ![slot[@"user_id"] isEqualToString:initiatorOID]) {
//            [slots addObject:slot];
//        }
//    }
//    return slots;
//}

//-(NSArray *)remoteEmptySlots
//{
//    NSMutableArray *slots = [NSMutableArray new];
//    for (NSDictionary *slot in [self slots]) {
//        if (slot[@"user_id"] == nil && slot[@"invite_code"]) {
//            [slots addObject:slot];
//        }
//    }
//    return slots;
//}

-(NSArray *)receiversSlots
{
    NSString *initiatorOID = [self initiatorOID];
    NSMutableArray *slots = [NSMutableArray new];
    for (NSDictionary *slot in [self slots]) {
        if (slot[@"user_id"] == nil || ![[slot safeOIDStringForKey:@"user_id"] isEqualToString:initiatorOID]) {
            [slots addObject:slot];
        }
    }
    return slots;
}

-(NSArray *)slots
{
    return self.jointEmuInstance[@"joint_emu_slots"];
}

-(NSString *)initiatorOID
{
    NSString *oid = [self.jointEmuInstance safeOIDStringForKey:@"user_id"];
    return oid;
}

-(NSDictionary *)slotAtIndex:(NSInteger)slotIndex
{
    NSInteger realIndex = slotIndex-1;
    NSArray *slots = self.jointEmuInstance[@"joint_emu_slots"];
    if (slots == nil) return nil;
    if (realIndex<0 || realIndex >= slots.count) return nil;
    return slots[realIndex];
}

-(NSString *)jointEmuInviteCodeAtSlot:(NSInteger)slotIndex
{
    NSDictionary *slot = [self slotAtIndex:slotIndex];
    if (slot == nil) return nil;
    return slot[@"invite_code"];
}

#pragma mark - AWS S3
-(NSString *)s3KeyForFile:(NSString *)fileName slot:(NSInteger)slot ext:(NSString *)ext
{
    NSString *jeOID = [self jointEmuOID];

    if (jeOID)
        return [NSString stringWithFormat:@"users_content/JointEmu/%@/%@-%@.%@", jeOID, fileName, @(slot), ext];

    return nil;
}


@end
