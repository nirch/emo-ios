//
//  Emuticon+JointEmuLogic.h
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "Emuticon.h"

#pragma mark - States
typedef NS_ENUM(NSInteger, EMSlotState){
    EMSlotStateUndefined    = 0,
    EMSlotStateInitiator    = 1,
    EMSlotStateUninvited    = 2,
    EMSlotStateInvited      = 3,
    EMSlotStateCanceled     = 4
};


@interface Emuticon (JointEmuLogic)

+(Emuticon *)findWithInvitationCode:(NSString *)invitationCode
                context:(NSManagedObjectContext *)context;


#pragma mark - General.
-(NSString *)jointEmuOID;
-(NSArray *)jointEmuSlots;

#pragma mark - Initiator related.
-(NSString *)jointEmuInitiatorID;
-(BOOL)isJointEmuInitiatedByThisUser;
-(NSInteger)jointEmuInvitationsSentCount;

#pragma mark - Invitations and receivers
-(NSInteger)jointEmuFirstUninvitedSlotIndex;

#pragma mark - Questions about a specific slot
-(NSString *)jointEmuInviteCodeAtSlot:(NSInteger)slotIndex;
-(NSString *)jointEmuUserIDAtSlot:(NSInteger)slotIndex;
-(BOOL)isJointEmuInitiatorAtSlot:(NSInteger)slotIndex;
-(EMSlotState)jointEmuStateOfSlot:(NSInteger)slotIndex;

#pragma mark - AWS S3
-(NSString *)s3KeyForFile:(NSString *)fileName slot:(NSInteger)slot ext:(NSString *)ext;

@end
