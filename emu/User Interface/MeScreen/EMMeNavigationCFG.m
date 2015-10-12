//
//  EMEmusFeedNavigationCFG.m
//  emu
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMMeNavigationCFG.h"
#import "EMMeVC.h"

@interface EMMeNavigationCFG()

@property (nonatomic) NSMutableDictionary *cfgByState;

@end

@implementation EMMeNavigationCFG

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
    
    // Browsing state: two action buttons.
    // The select button and the retake button.
    stateCFG = @{
//                 EMK_NAV_ACTION_1:@{
//                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_LOGIN,
//                         EMK_NAV_ACTION_TEXT:LS(@"LOGIN")
//                         },
                 EMK_NAV_ACTION_2:@{
                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_MY_TAKES,
                         EMK_NAV_ACTION_TEXT:LS(@"TAKES_ME_SCREEN_BUTTON")
                         }
                 };
    self.cfgByState[@(EMMeStateNormal)] = stateCFG;    
}

-(NSDictionary *)navBarConfigurationForState:(NSInteger)state
{
    return self.cfgByState[@(state)];
}

@end
