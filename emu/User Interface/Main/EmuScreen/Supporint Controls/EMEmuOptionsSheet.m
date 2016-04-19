//
//  EMMajorRetakeOptionsSheet.m
//  emu
//
//  Created by Aviv Wolf on 10/9/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMEmuOptionsSheet.h"
#import "EMUINotifications.h"
#import "EMDB.h"
#import "EMRecorderDelegate.h"
#import "emu-Swift.h"

@interface EMEmuOptionsSheet()

@property (nonatomic, readwrite) NSString *currentEmuOID;

@end

@implementation EMEmuOptionsSheet

-(id)initWithEmuOID:(NSString *)emuOID
{
    self = [super init];
    if (self) {
        self.currentEmuOID = emuOID;
        self = [self initWithSections:[self configuredSections]];
    }
    return self;
}


-(NSArray *)configuredSections
{
    NSInteger sectionIndex = 0;
    EMActionsArray *actionsMapping = [EMActionsArray new];
    self.actionsMapping = actionsMapping;
    
    Emuticon *emu = [Emuticon findWithID:self.currentEmuOID context:EMDB.sh.context];
    EmuticonDef *emuDef = emu.emuDef;
    
    // Dedicated footage required?
    BOOL dedicatedFootageRequired = [emuDef requiresDedicatedCapture];
    
    //
    // options
    //
    NSString *message = @"";
    NSString *title = @"";
    
    if (dedicatedFootageRequired) {
        title = [emuDef emuStoryTimeTitle];
        message = LS(@"DEDICATED_FOOTAGE_REQUIRED_MESSAGE");
    }
    
    // -----------------
    // Actions section
    // -----------------
    // If no dedicated footage required, allow to choose footage from the footage screen.
    if (dedicatedFootageRequired == NO) {
        // Retake package.
        // Allow only packs that none of their emus require a dedicated footage.
        [actionsMapping addAction:EMK_EMU_FOOTAGE_ACTION_CHOOSE text:LS(@"EMU_SCREEN_CHOICE_REPLACE_TAKE") section:sectionIndex];
    }
    [actionsMapping addAction:EMK_EMU_FOOTAGE_ACTION_RETAKE text:LS(@"EMU_SCREEN_CHOICE_RETAKE_EMU") section:sectionIndex];
    
    EMHolySheetSection *optionsSection = [EMHolySheetSection sectionWithTitle:title message:message buttonTitles:[actionsMapping textsForSection:sectionIndex] buttonStyle:JGActionSheetButtonStyleDefault];
    
    //
    // Cancel
    //
    sectionIndex++;
    EMHolySheetSection *cancelSection = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:@[LS(@"CANCEL")] buttonStyle:JGActionSheetButtonStyleCancel];
    
    // return the configured sections
    return @[optionsSection, cancelSection];
}

-(void)configureActions
{
    if (self.alreadyConfiguredActions) return;
    [super configureActions];
    
    __weak EMEmuOptionsSheet *wSelf = self;
    [self setButtonPressedBlock:^(JGActionSheet *sender, NSIndexPath *indexPath) {
        [sender dismissAnimated:YES];
        if (wSelf.holyDelegate && [wSelf.holyDelegate respondsToSelector:@selector(handleSheetActionWithIndexPath:actionsMapping:)]) {
            [wSelf.holyDelegate handleSheetActionWithIndexPath:indexPath actionsMapping:wSelf.actionsMapping];
        }
    }];
    [self setOutsidePressBlock:^(JGActionSheet *sender) {
        [sender dismissAnimated:YES];
    }];
}

@end
