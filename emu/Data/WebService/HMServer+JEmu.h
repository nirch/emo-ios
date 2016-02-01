//
//  HMServer+JEmu.h
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "HMServer.h"

typedef NS_ENUM(NSInteger, EMJEmuCancelInvite) {
    EMJEmuCancelInviteCanceledByInitiator               = 1,
    EMJEmuCancelInviteDeclinedByReceiver                = 2,
    EMJEmuCancelInviteFootageDeclinedByInitiator        = 3
};


@interface HMServer (JEmu)

-(void)jointEmuRefetch:(NSString *)jeOID emuOID:(NSString *)emuOID;
-(void)jointEmuNewForEmuOID:(NSString *)emuOID;
-(void)jointEmuCreateInvite:(NSString *)jeOID slot:(NSInteger)slot emuOID:(NSString *)emuOID;
-(void)jointEmuCancelInvite:(NSString *)inviteCode cancelCode:(EMJEmuCancelInvite)cancelCode emuOID:(NSString *)emuOID;

@end
