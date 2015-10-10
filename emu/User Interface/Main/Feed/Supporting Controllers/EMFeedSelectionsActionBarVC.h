//
//  EMFeedSelectionsActionBarVC.h
//  emu
//
//  Created by Aviv Wolf on 10/5/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMInterfaceDelegate.h"

#define emkSelectionsActionRetakeSelected @"sections action retake selected"
#define emkSelectionsActionReplaceSelected @"sections action replace selected"

@interface EMFeedSelectionsActionBarVC : UIViewController

@property (nonatomic) id<EMInterfaceDelegate> delegate;
@property (nonatomic) NSInteger selectedCount;

-(void)communicateErrorToUser;

@end
