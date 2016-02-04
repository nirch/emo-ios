//
//  Emuticon+JointEmuLogic.m
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "Emuticon+JointEmuLogic.h"
#import "NSDictionary+TypeSafeValues.h"
#import "EmuticonDef.h"
#import "EMDB.h"

@implementation Emuticon (JointEmuLogic)

+(Emuticon *)findWithInvitationCode:(NSString *)invitationCode
                            context:(NSManagedObjectContext *)context
{
    if (invitationCode == nil) return nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createdWithInvitationCode=%@", invitationCode];
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_EMU
                                                        withPredicate:predicate
                                                            inContext:context];
    return (Emuticon *)object;

}


#pragma mark - General.
-(NSString *)jointEmuOID
{
    if (self.jointEmuInstance == nil) return nil;
    return [self.jointEmuInstance safeOIDStringForKey:@"_id"];
}

-(NSArray *)jointEmuSlots
{
    if (self.jointEmuInstance == nil) return nil;
    return self.jointEmuInstance[@"joint_emu_slots"];
}

#pragma mark - Initiator related.
-(NSString *)jointEmuInitiatorID
{
    if (self.jointEmuInstance == nil) return nil;
    return [self.jointEmuInstance safeOIDStringForKey:@"user_id"];
}

-(BOOL)isJointEmuInitiatedByThisUser
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    
    NSString *userID = appCFG.userSignInID;
    if (userID == nil) return NO;
    
    NSString *initiatorID = [self jointEmuInitiatorID];
    if (initiatorID == nil) return NO;
    
    return [userID isEqualToString:initiatorID];
}

-(NSInteger)jointEmuInvitationsSentCount
{
    if (self.jointEmuInstance == nil) return 0;
    NSInteger count = 0;
    for (NSInteger slot=1;slot<=self.jointEmuSlots.count;slot++) {
        if ([self jointEmuInviteCodeAtSlot:slot] != nil) count++;
    }
    return count;
}

#pragma mark - Invitations and receivers
-(NSInteger)jointEmuFirstUninvitedSlotIndex
{
    for (NSInteger i=1;i<=self.jointEmuSlots.count;i++) {
        EMSlotState state = [self jointEmuStateOfSlot:i];
        if (state == EMSlotStateUninvited) return i;
    }
    return 0;
}


#pragma mark - Questions about a specific slot
-(NSDictionary *)jointEmuSlot:(NSInteger)slotIndex
{
    if (slotIndex<1) return nil;
    if (slotIndex>self.jointEmuSlots.count) return nil;
    return self.jointEmuSlots[slotIndex-1];
}

-(NSString *)jointEmuInviteCodeAtSlot:(NSInteger)slotIndex
{
    NSDictionary *slot = [self jointEmuSlot:slotIndex];
    if (slot == nil) return nil;
    return slot[@"invite_code"];
}

-(NSString *)jointEmuUserIDAtSlot:(NSInteger)slotIndex
{
    NSDictionary *slot = [self jointEmuSlot:slotIndex];
    if (slot == nil) return nil;
    return [slot safeOIDStringForKey:@"user_id"];
}

-(BOOL)isJointEmuInitiatorAtSlot:(NSInteger)slotIndex
{
    NSString *userIDAtSlot = [self jointEmuUserIDAtSlot:slotIndex];
    if (userIDAtSlot == nil) return NO;
    
    NSString *initiatorID = [self jointEmuInitiatorID];
    if (initiatorID == nil) return NO;
    
    return [userIDAtSlot isEqualToString:initiatorID];
}

-(EMSlotState)jointEmuStateOfSlot:(NSInteger)slotIndex
{
    // Check if exists
    NSDictionary *slot = [self jointEmuSlot:slotIndex];
    if (slot == nil)
        return EMSlotStateUndefined;

    // Check if initiator
    if ([self isJointEmuInitiatorAtSlot:slotIndex])
        return EMSlotStateInitiator;

    // Check if invited
    NSString *inviteCode = [self jointEmuInviteCodeAtSlot:slotIndex];
    if (inviteCode == nil)
        return EMSlotStateUninvited;
    
    // Invited
    return EMSlotStateInvited;
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
