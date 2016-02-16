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
#import "HMServer+JEmu.h"

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

-(NSInteger)jointEmuLocalSlotIndex
{
    if ([self isJointEmuInitiatedByThisUser]) {
        return [self jointEmuInitiatorSlot];
    } else {
        return [self jointEmuSlotForInvitedReceiver];
    }
}

#pragma mark - Initiator related.
-(NSString *)jointEmuInitiatorID
{
    if (self.jointEmuInstance == nil) return nil;
    return [self.jointEmuInstance safeOIDStringForKey:@"user_id"];
}

-(NSInteger)jointEmuInitiatorSlot
{
    NSString *initiatorID = [self jointEmuInitiatorID];
    if (self.jointEmuInstance == nil) return 0;
    for (NSInteger slot=1;slot<=self.jointEmuSlots.count;slot++) {
        if ([[self jointEmuUserIDAtSlot:slot] isEqualToString:initiatorID]) {
            return slot;
        }
    }
    return 0;

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
        if (state == EMSlotStateUninvited ||
            state == EMSlotStateCanceledByInitiator ||
            state == EMSlotStateDeclinedByReceiver ||
            state == EMSlotStateDeclinedFootageByInitiator
            ) return i;
    }
    return 0;
}

-(NSInteger)jointEmuSlotForInvitationCode:(NSString *)invitationCode
{
    for (NSInteger i=1;i<=self.jointEmuSlots.count;i++) {
        NSString *invitationCodeAtSlot = [self jointEmuInviteCodeAtSlot:i];
        if ([invitationCode isEqualToString:invitationCodeAtSlot]) {
            return i;
        }
    }
    return 0;
}

-(NSInteger)jointEmuSlotForInvitedReceiver
{
    NSString *invitationCode = self.createdWithInvitationCode;
    if (invitationCode == nil) return 0;
    return [self jointEmuSlotForInvitationCode:invitationCode];
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

    // Cancelations
    NSNumber *cancelCode = slot[@"cancel_reason"];
    if ([cancelCode isKindOfClass:[NSNumber class]]) {
        EMJEmuCancelInvite cancelReason = [cancelCode integerValue];
        switch (cancelReason) {
            case EMJEmuCancelInviteCanceledByInitiator:
                return EMSlotStateCanceledByInitiator;
            case EMJEmuCancelInviteDeclinedByReceiver:
                return EMSlotStateDeclinedByReceiver;
            case EMJEmuCancelInviteFootageDeclinedByInitiator:
                return EMSlotStateDeclinedFootageByInitiator;
        }
    }
    
    // Check if invited
    NSString *inviteCode = [self jointEmuInviteCodeAtSlot:slotIndex];
    if (inviteCode == nil)
        return EMSlotStateUninvited;
    
    // Invited
    return EMSlotStateInvited;
}

-(BOOL)isJointEmuCurrentReceiverAtSlot:(NSInteger)slotIndex
{
    NSAssert(self.isJointEmuInitiatedByThisUser == NO, @"Call this method only for receiver");
    
    // If user is the initiator, the answer is no.
    if (self.isJointEmuInitiatedByThisUser == YES) return NO;

    // Return YES if emu created locally using an invitation code in slotIndex.
    NSString *invitationCode = self.createdWithInvitationCode;
    if (invitationCode == nil) return NO;
    return [invitationCode isEqualToString:[self jointEmuInviteCodeAtSlot:slotIndex]];
}

-(NSDictionary *)jointEmuRemoteFilesAtSlot:(NSInteger)slotIndex
{
    NSDictionary *slot = [self jointEmuSlot:slotIndex];
    if (slot == nil) return nil;
    return slot[@"footage_files"];
}

#pragma mark - Footages
-(id<FootageProtocol>)jointEmuFootageAtSlot:(NSInteger)slotIndex
{
    // If created locally and no joint emu instance info yet, just use the most
    // preffered footage for the initiator slot and place holders for the rest.
    if (self.jointEmuInstance == nil) {
        NSInteger initiatorSlotIndex = self.emuDef.jointEmuDefInitiatorSlotIndex;
        return slotIndex==initiatorSlotIndex?[self mostPrefferedUserFootage]:[PlaceHolderFootage new];
    }
    
    // If we have more info from the server about the emu instance, use that info
    // to return the required footage for this slot.
    if (self.isJointEmuInitiatedByThisUser) {
        if ([self isJointEmuInitiatorAtSlot:slotIndex]) {
            
            // The initiator local slot.
            return [self mostPrefferedUserFootage];
            
        } else {
            
            // The remote slots.
            return [self jointEmuRemoteFootageAtSlot:slotIndex];
        }
        
    } else {
        
        // Receiver. As long as the joint emu is not finished, the receiver will
        // show placeholders for all slots except the initator slot and this receiver slot.
        if ([self isJointEmuCurrentReceiverAtSlot:slotIndex]) {

            // The receiver's local slot.
            return [self mostPrefferedUserFootage];
            
        } else {
            
            // The remote slots.
            return [self jointEmuRemoteFootageAtSlot:slotIndex];

        }
    }
    return nil;
}

-(NSArray *)allMissingRemoteFootageFiles
{
    NSMutableArray *allFiles = [NSMutableArray new];
    for (int slotIndex=1;slotIndex<=self.jointEmuSlots.count;slotIndex++) {
        UserFootage *footage = [self jointEmuRemoteFootageAtSlot:slotIndex];
        if (![footage isKindOfClass:[UserFootage class]]) continue;
        NSArray *missingFiles = [footage allMissingRemoteFiles];
        if (missingFiles.count>0) {
            for (NSString *file in missingFiles) {
                [allFiles addObject:file];
            }
        }
    }
    return allFiles;
}

-(id<FootageProtocol>)jointEmuRemoteFootageAtSlot:(NSInteger)slotIndex
{
    if (self.remoteFootages == nil) {
        self.remoteFootages = [NSMutableDictionary new];
    }
    
    NSString *footageOID = self.remoteFootages[@(slotIndex)];
    if (footageOID == nil) {
        // Placeholder
        return [PlaceHolderFootage new];
    } else {
        UserFootage *footage = [UserFootage findOrCreateWithID:footageOID context:EMDB.sh.context];
        if (footage) {
            return footage;
        } else {
            return [PlaceHolderFootage new];
        }
    }
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
