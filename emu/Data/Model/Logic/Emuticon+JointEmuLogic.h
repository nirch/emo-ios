//
//  Emuticon+JointEmuLogic.h
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "Emuticon.h"

@class UserFootage;

#pragma mark - States
typedef NS_ENUM(NSInteger, EMSlotState){
    EMSlotStateUndefined                        = 0,
    EMSlotStateInitiator                        = 1,
    EMSlotStateUninvited                        = 2,
    EMSlotStateInvited                          = 3,
    EMSlotStateCanceledByInitiator              = 4,
    EMSlotStateDeclinedByReceiver               = 5,
    EMSlotStateDeclinedFootageByInitiator       = 6
};


@interface Emuticon (JointEmuLogic)

+(Emuticon *)findWithInvitationCode:(NSString *)invitationCode
                context:(NSManagedObjectContext *)context;


#pragma mark - General.
-(NSString *)jointEmuOID;
-(NSArray *)jointEmuSlots;
-(NSInteger)jointEmuLocalSlotIndex;

#pragma mark - Initiator related.
-(NSString *)jointEmuInitiatorID;
-(NSInteger)jointEmuInitiatorSlot;
-(BOOL)isJointEmuInitiatedByThisUser;
-(NSInteger)jointEmuInvitationsSentCount;

#pragma mark - Invitations and receivers
-(NSInteger)jointEmuFirstUninvitedSlotIndex;
-(NSInteger)jointEmuSlotForInvitationCode:(NSString *)invitationCode;
-(NSInteger)jointEmuSlotForInvitedReceiver;

#pragma mark - Questions about a specific slot
-(NSString *)jointEmuInviteCodeAtSlot:(NSInteger)slotIndex;
-(NSString *)jointEmuUserIDAtSlot:(NSInteger)slotIndex;
-(BOOL)isJointEmuInitiatorAtSlot:(NSInteger)slotIndex;
-(EMSlotState)jointEmuStateOfSlot:(NSInteger)slotIndex;
-(NSDictionary *)jointEmuRemoteFilesAtSlot:(NSInteger)slotIndex;

#pragma mark - Footages
-(UserFootage *)jointEmuFootageAtSlot:(NSInteger)slotIndex;
-(NSArray *)allMissingRemoteFootageFiles;

#pragma mark - AWS S3
-(NSString *)s3KeyForFile:(NSString *)fileName slot:(NSInteger)slot ext:(NSString *)ext;

@end
