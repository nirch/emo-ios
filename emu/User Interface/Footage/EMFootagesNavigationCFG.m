//
//  EMEmusFeedNavigationCFG.m
//  emu
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFootagesNavigationCFG.h"
#import "EMFootagesVC.h"

@interface EMFootagesNavigationCFG()

@property (nonatomic) NSMutableDictionary *cfgByState;

@end

@implementation EMFootagesNavigationCFG

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
    
    self.cfgByState[@(EMFootagesFlowTypeChooseFootage)] = @{};
    
    stateCFG = @{
                 EMK_NAV_ACTION_1:@{
                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_FOOTAGES_DONE,
                         EMK_NAV_ACTION_TEXT:LS(@"DONE")
                         },
//                 EMK_NAV_ACTION_2:@{
//                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_MY_TAKES,
//                         EMK_NAV_ACTION_TEXT:LS(@"DONE")
//                         }
                 };
    self.cfgByState[@(EMFootagesFlowTypeMangementScreen)] = stateCFG;
    
}

-(NSDictionary *)navBarConfigurationForState:(NSInteger)state
{
    return self.cfgByState[@(state)];
}

@end
