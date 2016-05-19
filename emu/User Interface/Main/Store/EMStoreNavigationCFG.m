//
//  EMEmusFeedNavigationCFG.m
//  emu
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMStoreNavigationCFG.h"
#import "EMStoreVC.h"

@interface EMStoreNavigationCFG()

@property (nonatomic) NSMutableDictionary *cfgByState;

@end

@implementation EMStoreNavigationCFG

-(id)init
{
    self = [super init];
    if (self) {
        [self initCFG];
    }
    return self;
}

-(void)initCFG
{
    NSDictionary *stateCFG;
    self.cfgByState = [NSMutableDictionary new];
    
    stateCFG = @{
                 EMK_NAV_ACTION_2:@{
                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_RESTORE_PURCHASES,
                         EMK_NAV_ACTION_TEXT:LS(@"SETTINGS_ACTION_RESTORE_PURCHASES")
                         },
                 };
    self.cfgByState[@(EMStoreStateNormal)] = stateCFG;
}

-(NSDictionary *)navBarConfigurationForState:(NSInteger)state
{
    return self.cfgByState[@(state)];
}

@end
