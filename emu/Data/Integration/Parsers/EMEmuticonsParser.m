//
//  EMEmuticonsParser.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMEmuticonsParser.h"
#import "EMEmuticonParser.h"
#import "EMDB.h"

@implementation EMEmuticonsParser

-(void)parse
{
    NSArray *emuticonsDefinitions = self.objectToParse[@"emuticons"];
    EMEmuticonParser *emParser = [[EMEmuticonParser alloc] initWithContext:self.ctx];
    
    for (NSDictionary *emuticonDefinition in emuticonsDefinitions) {
        emParser.objectToParse = emuticonDefinition;
        [emParser parse];
    }
    [EMDB.sh save];
}

@end
