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

@protocol EMHolySheetDelegate <NSObject>

-(void)handleSheetActionWithIndexPath:(NSIndexPath *)indexPath actionsMapping:(EMActionsArray *)actionsMapping;

@end

@interface EMHolySheet : JGActionSheet

@property (nonatomic, weak) id<EMHolySheetDelegate> holyDelegate;
@property (nonatomic) CGFloat targetAlpha;
@property (nonatomic) EMActionsArray *actionsMapping;
@property (nonatomic, readonly) BOOL alreadyConfiguredActions;
@property (nonatomic, weak) id<EMInterfaceDelegate> interfaceDelegate;

-(void)showModalOnTopAnimated:(BOOL)animated;
-(void)configureActions;

@end
