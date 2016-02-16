//
//  EMHolySheet.h
//  emu
//
//  Created by Aviv Wolf on 4/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "JGActionSheet.h"
#import "EMHolySheetSection.h"
#import "EMActionsArray.h"
#import "EMInterfaceDelegate.h"

@interface EMHolySheet : JGActionSheet

@property (nonatomic) CGFloat targetAlpha;
@property (nonatomic) EMActionsArray *actionsMapping;
@property (nonatomic, readonly) BOOL alreadyConfiguredActions;
@property (nonatomic, weak) id<EMInterfaceDelegate> interfaceDelegate;

-(void)showModalOnTopAnimated:(BOOL)animated;
-(void)configureActions;

@end
