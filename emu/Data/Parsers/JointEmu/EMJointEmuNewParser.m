//
//  EMJointEmuNewParser.m
//  emu
//
//  Created by Aviv Wolf on 10/14/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMJointEmuNewParser.h"
#import "EMDB.h"
#import "HMServer+JEmu.h"

@implementation EMJointEmuNewParser

/**
 *  Joint emus are currently deprecated
 */
-(void)parse
{
//    NSDictionary *info = self.objectToParse;
//    
//    // emu id in local storage must be part of the info provided with the request.
//    NSString *emuOID = [self.parseInfo safeOIDStringForKey:emkEmuticonOID];
//    
//    if ([emuOID isEqualToString:@"create"]) {
//
//        // The request may explicitly indicate that a creation of a new local storage emu is required.
//        NSString *invitationCode = [self.parseInfo safeStringForKey:emkJEmuInviteCode];
//        NSString *emuDefOID = [info safeOIDStringForKey:@"emuticon_id"]; // inconsistency remark: emuticon_id means emu definition id here.
//        EmuticonDef *emuDef = [EmuticonDef findWithID:emuDefOID context:EMDB.sh.context];
//        Emuticon *newEmu = [Emuticon newForEmuticonDef:emuDef context:EMDB.sh.context];
//        emuOID = newEmu.oid;
//        [newEmu gainFocus];
//        if ([invitationCode isKindOfClass:[NSString class]]) {
//            // New joint emuticon created by an invitation from another emu user.
//            newEmu.createdWithInvitationCode = invitationCode;
//            
//            // Also create the remote footage object with the initiator's footage.
//            newEmu.remoteFootages = [NSMutableDictionary new];
//            
//            // Update the joint emu info.
//            newEmu.jointEmuInstance = info;
//        }
//        
//    } else if (emuOID == nil) {
//        // No explicit request to create a new emu and emu doesn't exist in local storage?
//        // Do nothing.
//        return;
//    }
//    
//    // Get the emu.
//    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
//    if (emu == nil) return;
//
//    // In some cases, we will delete an existing emu from local storage.
//    if (self.parseInfo[emkJEmuCancelReason]) {
//        EMJEmuCancelInvite cancelInviteReason = [self.parseInfo[emkJEmuCancelReason] integerValue];
//        if (cancelInviteReason == EMJEmuCancelInviteDeclinedByReceiver) {
//            NSString *emuDefOID = emu.emuDef.oid;
//            
//            // If receiver just canceled the emu, we can just delete it from local storage.
//            [EMDB.sh.context deleteObject:emu];
//            
//            // Latest emu for emuDef should get focus.
//            EmuticonDef *emuDef = [EmuticonDef findWithID:emuDefOID context:EMDB.sh.context];
//            [emuDef latestEmuGainFocus];
//            [EMDB.sh save];
//            
//            return;
//        }
//    }
//
//    // Update the joint emu info.
//    emu.jointEmuInstance = info;
//    emu.jointEmuInstanceOID = [info safeOIDStringForKey:@"_id"];
//    
//    // Remote footages
//    if (info[@"joint_emu_slots"]) {
//        for (NSDictionary *slotInfo in info[@"joint_emu_slots"]) {
//            NSNumber *slotIndexNumber = [slotInfo safeNumberForKey:@"slot_id"];
//            if (![slotIndexNumber isKindOfClass:[NSNumber class]]) continue;
//            NSInteger slotIndex = slotIndexNumber.integerValue;
//            
//            NSDictionary *remoteFootageFiles = [emu jointEmuRemoteFilesAtSlot:slotIndex];
//            if (![remoteFootageFiles isKindOfClass:[NSDictionary class]]) continue;
//            
//            NSString *footageOID = [remoteFootageFiles safeOIDStringForKey:@"_id"];
//            if (![footageOID isKindOfClass:[NSString class]]) continue;
//            
//            // Check if remote footage already exists.
//            UserFootage *remoteFootage = [UserFootage findWithID:footageOID context:EMDB.sh.context];
//            if (remoteFootage == nil) {
//                // Create the remote footage object.
//                [UserFootage newFootageWithID:footageOID
//                              remoteFilesInfo:remoteFootageFiles
//                                      context:EMDB.sh.context];
//                NSMutableDictionary *remoteFootagesDict = [NSMutableDictionary dictionaryWithDictionary:emu.remoteFootages?emu.remoteFootages:@{}];
//                remoteFootagesDict[@(slotIndex)] = footageOID;
//                emu.remoteFootages = remoteFootagesDict;
//            }
//        }
//    }
//        
//    // Save
//    [EMDB.sh save];
}

@end
