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
    
    // emu id in local storage must always be part of the info provided with the request.
    NSString *emuOID = [self.parseInfo safeOIDStringForKey:emkEmuticonOID];
    if (emuOID == nil) return;
    
    // 
    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    if (emu == nil) return;
    
    emu.jointEmuInstance = info;
    
    [EMDB.sh save];
}

@end
