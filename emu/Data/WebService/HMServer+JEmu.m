//
//  HMServer+JEmu.m
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "HMServer+JEmu.h"
#import "EMJointEmuNewParser.h"
#import "EMNotificationCenter.h"
#import "EMDB.h"

@implementation HMServer (JEmu)

-(void)jointEmuRefetch:(NSString *)jeOID emuOID:(NSString *)emuOID
{
    NSString *urlString = [NSString stringWithFormat:@"/jointemu/%@", jeOID];
    [self getRelativeURL:urlString
              parameters:@{}
        notificationName:emkJointEmuRefresh
                    info:@{emkJEmuOID:jeOID, emkEmuticonOID:emuOID}
                  parser:[EMJointEmuNewParser new]];

}

-(void)jointEmuNewForEmuOID:(NSString *)emuOID
{
    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    HMParams *params = [HMParams new];
    [params addKey:@"emuticon_id" valueIfNotNil:emu.emuDef.oid];
    [self postRelativeURLNamed:@"jointemu"
                    parameters:params.dictionary
              notificationName:emkJointEmuNew
                          info:@{emkEmuticonOID:emuOID}
                        parser:[EMJointEmuNewParser new]];
}

-(void)jointEmuCreateInvite:(NSString *)jeOID slot:(NSInteger)slot emuOID:(NSString *)emuOID
{
    NSString *urlString = [NSString stringWithFormat:@"/jointemu/%@/slot/%@/invite", jeOID, @(slot)];
    [self postRelativeURL:urlString
               parameters:@{}
         notificationName:emkJointEmuCreateInvite
                     info:@{emkJEmuOID:jeOID, emkJEmuSlot:@(slot), emkEmuticonOID:emuOID}
                   parser:[EMJointEmuNewParser new]];
}

-(void)jointEmuCancelInvite:(NSString *)inviteCode cancelCode:(EMJEmuCancelInvite)cancelCode emuOID:(NSString *)emuOID
{
    NSString *urlString = [NSString stringWithFormat:@"/jointemu/invite/%@/cancel", inviteCode];
    [self putRelativeURL:urlString
              parameters:@{@"cancel_reason":@(cancelCode)}
        notificationName:emkJointEmuRefresh
                    info:@{emkJEmuInviteCode:inviteCode, emkEmuticonOID:emuOID}
                  parser:[EMJointEmuNewParser new]];
}

-(void)jointEmuTakeSlotForInviteCode:(NSString *)inviteCode
{
    NSString *urlString = [NSString stringWithFormat:@"/jointemu/invite/%@/take_slot", inviteCode];
    [self putRelativeURL:urlString
              parameters:@{}
        notificationName:emkJointEmuInviteTakeSlot
                    info:@{
                           emkJEmuInviteCode:inviteCode,
                           emkEmuticonOID:@"create"
                           }
                  parser:[EMJointEmuNewParser new]];
}

@end
