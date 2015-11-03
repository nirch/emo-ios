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
    
    //
    // Retake options
    //
    NSString *title = LS(@"RETAKE_CHOICE_TITLE");
    [actionsMapping addAction:@"RETAKE_CHOICE_PACKAGE" text:[SF:@"%@ (%@)", LS(@"RETAKE_CHOICE_PACKAGE"),self.currentPackLabel] section:sectionIndex];
    EMHolySheetSection *section1 = [EMHolySheetSection sectionWithTitle:title message:nil buttonTitles:[actionsMapping textsForSection:sectionIndex] buttonStyle:JGActionSheetButtonStyleDefault];
    
    //
    // Debug options (only in test applications)
    //
    EMHolySheetSection *debugSection = nil;
    if (AppManagement.sh.isTestApp) {
        sectionIndex++;
        NSString *title = @"DEBUG OPTIONS";
        [actionsMapping addAction:@"RETAKE_CHOICE_PACKAGE" text:[SF:@"%@ (%@)", LS(@"RETAKE_CHOICE_PACKAGE"),self.currentPackLabel] section:sectionIndex];
        debugSection = [EMHolySheetSection sectionWithTitle:title message:@"Test app only options" buttonTitles:[actionsMapping textsForSection:sectionIndex] buttonStyle:JGActionSheetButtonStyleDefault];
    }
    
    //
    // Cancel
    //
    sectionIndex++;
    EMHolySheetSection *cancelSection = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:@[LS(@"CANCEL")] buttonStyle:JGActionSheetButtonStyleCancel];
    
    //
    // Sections
    //
    NSMutableArray *sections = [NSMutableArray new];
    [sections addObject:section1];
    if (debugSection) [sections addObject:debugSection];
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
    
    if ([actionName isEqualToString:@"RETAKE_CHOICE_ALL"]) {
        
        // Retake them all
        [self retakeAll];
        
    } else if ([actionName isEqualToString:@"RETAKE_CHOICE_PACKAGE"]) {
        
        // Retake
        [self retakeCurrentPackage];
        
    } else {
        
        // Cancel
        [self cancelRetake];
        
    }
}

-(void)retakeAll
{
    // Analytics
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_RETAKE_OPTION valueIfNotNil:@"all"];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
                          info:params.dictionary];
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
