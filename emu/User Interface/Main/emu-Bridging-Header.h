//
//  emu-Bridging-Header.h
//  emu
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#ifndef emu_emu_Bridging_Header_h
#define emu_emu_Bridging_Header_h

// General
#import "AppManagement.h"
#import "AppDelegate.h"

// UI
#import "EmuStyle.h"
#import "EML.h"
#import "EMRecordButton.h"
#import "UIView+CommonAnimations.h"
#import "EMFlowButton.h"
#import "EMUISound.h"
#import "EMLabel.h"
#import "EMTickingProgressView.h"
#import "EMEmuCell.h"
#import "YLProgressBar.h"
#import <iCarousel.h>
#import "EMShareDelegate.h"
#import "EMShareProtocol.h"
#import "EMInterfaceDelegate.h"
#import <UIView+Toast.h>
#import "EMCaches.h"
#import "EMHolySheet.h"
#import "EMEmuOptionsSheet.h"

// Notifications
#import "HMNotificationCenter.h"
#import "EMNotificationCenter.h"
#import "EMUINotifications.h"

// View Controllers
#import "EMOnboardingVC.h"
#import "EMFootagesVC.h"

// Delegation & protocols
#import "EMRecorderDelegate.h"
#import "EMPreviewDelegate.h"

// Rendering & Downloads management
#import "EMRenderTypes.h"
#import "EMDownloadsManager2.h"
#import "Emuticon+DownloadsHelpers.h"
#import "EmuticonDef+DownloadsHelpers.h"

// Data & Backend
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMBackend.h"
#import "HMServer.h"
#import "HMServer+User.h"
#import "HMServer+JEmu.h"
#import "HMParams.h"
#import "HMPanel.h"
#import "HMParams.h"
#import "EMCaches.h"

// Sharing
#import "EMShare.h"
#import "EMUploadPublicFootageForJointEmu.h"
#import "EMShareDelegate.h"
#import "EMShareInputVC.h"

// Share methods
#import "EMShareCopy.h"
#import "EMShareSaveToCameraRoll.h"
#import "EMShareMail.h"
#import "EMShareAppleMessage.h"
#import "EMShareFBMessanger.h"
#import "EMShareDocumentInteraction.h"
#import "EMShareTwitter.h"
#import "EMShareFacebook.h"
#import "EMShareInstoosh.h"

// Libraries & Pods
#import <SIAlertView.h>
#import <PINRemoteImage/UIImageView+PINRemoteImage.h>
#import <FLAnimatedImage.h>
#import <FLAnimatedImageView.h>

// HSDK
#pragma mark - Homage SDK imports
#import <HomageSDKCore/HomageSDKCore.h>
#import <HomageSDKFlow/HomageSDKFlow.h>

#endif
