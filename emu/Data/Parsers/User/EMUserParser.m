//
//  EMUserParser.m
//  emu
//
//  Created by Aviv Wolf on 10/14/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMUserParser.h"
#import "EMDB.h"
#import "HMParams.h"

@implementation EMUserParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    NSString *oid = [info safeOIDStringForKey:@"_id"];
    if (oid) {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
//        appCFG.userSignInID = oid;
        [EMDB.sh save];
    }
}

@end
