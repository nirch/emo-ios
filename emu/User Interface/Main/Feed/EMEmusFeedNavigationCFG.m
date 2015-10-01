//
//  EMEmusFeedNavigationCFG.m
//  emu
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMEmusFeedNavigationCFG.h"
#import "EMEmusFeedVC.h"
//#import "EM

@interface EMEmusFeedNavigationCFG()

@property (nonatomic) NSMutableDictionary *cfgByState;

@end

@implementation EMEmusFeedNavigationCFG

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
                 EMK_NAV_ACTION_1:@{
                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_SELECT,
                         EMK_NAV_ACTION_TEXT:LS(@"SELECT") // TODO: localize
                         },
                 EMK_NAV_ACTION_2:@{
                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_RETAKE,
                         EMK_NAV_ACTION_ICON:@"retakeIcon4"
                         }
                 };
    self.cfgByState[@(EMEmusFeedStateBrowsing)] = stateCFG;
    
    // Selection state: two action buttons.
    // The cancel button and the clear button.
    stateCFG = @{
                 EMK_NAV_ACTION_1:@{
                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_SELECT,
                         EMK_NAV_ACTION_TEXT:LS(@"SELECT") // TODO: localize
                         },
                 EMK_NAV_ACTION_2:@{
                         EMK_NAV_ACTION_NAME:EMK_NAV_ACTION_RETAKE,
                         EMK_NAV_ACTION_ICON:@"retakeIcon4"
                         }
                 };
    self.cfgByState[@(EMEmusFeedStateBrowsing)] = stateCFG;    
}

-(NSDictionary *)navBarConfigurationForState:(NSInteger)state
{
    return self.cfgByState[@(state)];
}


@end
