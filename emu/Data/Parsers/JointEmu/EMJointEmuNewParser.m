//
//  EMJointEmuNewParser.m
//  emu
//
//  Created by Aviv Wolf on 10/14/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMJointEmuNewParser.h"
#import "EMDB.h"

@implementation EMJointEmuNewParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    
    // emu id in local storage must be part of the info provided with the request.
    NSString *emuOID = [self.parseInfo safeOIDStringForKey:emkEmuticonOID];
    
    if ([emuOID isEqualToString:@"create"]) {

        // The request may explicitly indicate that a creation of a new local storage emu is required.
        NSString *invitationCode = [self.parseInfo safeStringForKey:emkJEmuInviteCode];
        NSString *emuDefOID = [info safeOIDStringForKey:@"emuticon_id"]; // inconsistency remark: emuticon_id means emu definition id here.
        EmuticonDef *emuDef = [EmuticonDef findWithID:emuDefOID context:EMDB.sh.context];
        Emuticon *newEmu = [Emuticon newForEmuticonDef:emuDef context:EMDB.sh.context];
        emuOID = newEmu.oid;
        [newEmu gainFocus];
        if ([invitationCode isKindOfClass:[NSString class]]) {
            // New joint emuticon created by an invitation from another emu user.
            newEmu.createdWithInvitationCode = invitationCode;
        }
        
    } else if (emuOID == nil) {
        // No explicit request to create a new emu and emu doesn't exist in local storage?
        // Do nothing.
        return;
    }
    
    // Get the emu.
    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    if (emu == nil) return;
    
    // Update the joint emu info.
    emu.jointEmuInstance = info;
    
    // Save
    [EMDB.sh save];
}

@end
