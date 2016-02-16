//
//  EMMajorRetakeOptionsSheet.m
//  emu
//
//  Created by Aviv Wolf on 10/9/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMMajorRetakeOptionsSheet.h"
#import "EMUINotifications.h"
#import "EMRecorderDelegate.h"
#import "AppManagement.h"
#import "EMDB.h"
#import "EMEmusFeedNavigationCFG.h"
#import "EMFootagesVC.h"

@implementation EMMajorRetakeOptionsSheet

-(id)initWithPackOID:(NSString *)packOID
           packLabel:(NSString *)packLabel
            packName:(NSString *)packName
{
    self = [super init];
    if (self) {
        _currentPackageOID = packOID;
        _currentPackLabel = packLabel;
        _currentPackName = packName;
        self = [self initWithSections:[self configuredSections]];
    }
    return self;
}


-(NSArray *)configuredSections
{
    NSInteger sectionIndex = 0;
    EMActionsArray *actionsMapping = [EMActionsArray new];
    self.actionsMapping = actionsMapping;

    Package *package = [Package findWithID:self.currentPackageOID context:EMDB.sh.context];
    
    //
    // Retake options
    //
    NSString *title = LS(@"RETAKE_CHOICE_TITLE");
    
    EMHolySheetSection *section1 = nil;
    if (package != nil && package.anyEmuRequiresDedicatedCapture == NO && package.anyIsJointEmu == NO) {
        // Retake package.
        // Allow only packs that none of their emus require a dedicated footage.
        [actionsMapping addAction:EMK_NAV_ACTION_RETAKE_CHOICE_PACKAGE text:[SF:@"%@ (%@)", LS(@"RETAKE_CHOICE_PACKAGE"),self.currentPackLabel] section:sectionIndex];
        section1 = [EMHolySheetSection sectionWithTitle:title message:nil buttonTitles:[actionsMapping textsForSection:sectionIndex] buttonStyle:JGActionSheetButtonStyleDefault];
        sectionIndex++;
    }
    
    //
    // Existing takes.
    //
    [actionsMapping addAction:EMK_NAV_ACTION_NEW_TAKE text:LS(@"EMU_SCREEN_CHOICE_RETAKE_EMU") section:sectionIndex];
    [actionsMapping addAction:EMK_NAV_ACTION_MY_TAKES text:LS(@"TAKES_ME_SCREEN_BUTTON") section:sectionIndex];
    EMHolySheetSection *section2 = [EMHolySheetSection sectionWithTitle:LS(@"TAKES") message:nil buttonTitles:[actionsMapping textsForSection:sectionIndex] buttonStyle:JGActionSheetButtonStyleDefault];
    
    //
    // Cancel
    //
    sectionIndex++;
    EMHolySheetSection *cancelSection = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:@[LS(@"CANCEL")] buttonStyle:JGActionSheetButtonStyleCancel];
    
    //
    // Sections
    //
    NSMutableArray *sections = [NSMutableArray new];
    if (section1) [sections addObject:section1];
    [sections addObject:section2];
    [sections addObject:cancelSection];
    return sections;
}

-(void)configureActions
{
    if (self.alreadyConfiguredActions) return;
    [super configureActions];
    
    __weak EMMajorRetakeOptionsSheet *wSelf = self;
    [self setButtonPressedBlock:^(JGActionSheet *sender, NSIndexPath *indexPath) {
        [sender dismissAnimated:YES];
        [wSelf handleRetakeChoiceWithIndexPath:indexPath actionsMapping:wSelf.actionsMapping];
    }];
    [self setOutsidePressBlock:^(JGActionSheet *sender) {
        [sender dismissAnimated:YES];
        [wSelf cancelRetake];
    }];
}

-(void)handleRetakeChoiceWithIndexPath:(NSIndexPath *)indexPath actionsMapping:(EMActionsArray *)actionsMapping
{
    NSString *actionName = [actionsMapping actionNameForIndexPath:indexPath];
    if (actionName == nil) return;
    
    if ([actionName isEqualToString:EMK_NAV_ACTION_RETAKE_CHOICE_PACKAGE]) {
        
        // Retake
        [self retakeCurrentPackage];
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_NEW_TAKE] ) {

        // Open recorder for a new take.
        // (that will be added to existing take. Not for a specific emu.)
        [self.interfaceDelegate controlSentActionNamed:EMK_NAV_ACTION_NEW_TAKE info:nil];
        
    } else if ([actionName isEqualToString:EMK_NAV_ACTION_MY_TAKES] ) {

        // My takes screen.
        [self.interfaceDelegate controlSentActionNamed:EMK_NAV_ACTION_MY_TAKES info:nil];
        
    } else {
        
        // Cancel
        [self cancelRetake];
        
    }
}

-(void)retakeCurrentPackage
{
    // Analytics
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_RETAKE_OPTION valueIfNotNil:@"package"];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.currentPackName];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.currentPackageOID];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
                          info:params.dictionary];
    
    // Recorder should be opened to retake a whole pack.
    NSMutableDictionary *requestInfo = [NSMutableDictionary new];
    requestInfo[emkRetakePackageOID] = self.currentPackageOID;

    // Notify main navigation controller that the recorder should be opened.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserRequestToOpenRecorder
                                                        object:self
                                                      userInfo:requestInfo];
}

-(void)cancelRetake
{
    // Analytics
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.currentPackName];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.currentPackageOID];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_CANCELED
                          info:params.dictionary];
}

@end
