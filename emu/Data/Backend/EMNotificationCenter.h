//
//  EMNotificationCenter.h
//  emu
//
//  Created by Aviv Wolf on 3/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#import "HMNotificationCenter.h"

#pragma mark - App lifecycle
#define emkAppDidBecomeActive @"emu app did become active"

#pragma mark - UI data requirements
// UI data requirements
#define emkDataDebug @"emk data debug"

// Notified backend that packages data should be refetched.
#define emkDataRequiredPackages @"emk data required packages"
#define emkDataRequiredUnhidePackages @"emk data required unhide packages"
#define emkDataRequestToOpenPackage @"emk data request to open package"
#define emkDataRequestInviteCode @"emk data request to open invitation"

#pragma mark - Data updates
#define emkDataUpdatedPackages @"emk data updated packages"
#define emkDataUpdatedUnhidePackages @"emk data updated unhide packages"

#define emkNavigateToEmuOID @"emk navigate to emu oid"
#define emkNavigateToStore @"emk navigate to store"

#define emkUserSignedIn @"emk user signed in"

#define emkJointEmuRefresh @"emk joint emu refresh"
#define emkJointEmuNew @"emk joint emu new"
#define emkJointEmuCreateInvite @"emk joint create invite"
#define emkJointEmuInviteTakeSlot @"emk joint emu take slot"
#define emkJointEmuNavigateToInviteCode @"emk joint emu navigate to invite code"

// Store
#define emkDataProductsInfoUpdated  @"emk data products info updated"
#define emkDataProductsError  @"emk data products error"
#define emkDataProductsHandledTransactions @"emk data products handled transaction"
#define emkDataProductsRestoredPurchases  @"emk data products restored purchases"

// Notification of navigation events
#define emkUINavigationTabSelected @"emk ui nav tab selected"
#define emkUINavigationShowBlockingProgress @"emk ui show blocking progress"
#define emkUINavigationUpdateBlockingProgress @"emk ui update blocking progress"
#define emkUINavigationShouldShowFeed @"emk ui should show the feed"

// Notification of the backend to the UI
#define emkUIDataRefreshPackages @"emk backend data refreshed packages"
#define emkUIDownloadedResourcesForEmuticon @"emk backend downloaded resources for emuticon"
#define emkUIMainShouldShowPackage @"emk ui main should show package"

#define emkUIRenderProgressReport @"emk render progress report"

