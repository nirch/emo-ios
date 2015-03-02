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
    if (self.package == nil) return;
    
    NSArray *emuticonsDefinitions = self.objectToParse[@"emuticons"];

    NSInteger index = 0;
    EMEmuticonParser *emParser = [[EMEmuticonParser alloc] initWithContext:self.ctx];
    for (NSDictionary *emuticonDefinition in emuticonsDefinitions) {
        index++;
        emParser.objectToParse = emuticonDefinition;
        emParser.incrementalOrder = @(index);
        emParser.package = self.package;
        [emParser parse];
    }
}

@end
