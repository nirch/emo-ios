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

#pragma mark - Data updates
#define emkDataUpdatedPackages @"emk data updated packages"
#define emkDataUpdatedUnhidePackages @"emk data updated unhide packages"

// Store
#define emkDataProductsInfoUpdated  @"emk data products info updated"
#define emkDataProductsHandledTransactions  @"emk data products handled transactions"

// Notification of navigation events
#define emkUINavigationTabSelected @"emk ui nav tab selected"

// Notification of the backend to the UI
#define emkUIDataRefreshPackages @"emk backend data refreshed packages"
#define emkUIDownloadedResourcesForEmuticon @"emk backend downloaded resources for emuticon"
#define emkUIMainShouldShowPackage @"emk ui main should show package"

#define emkUIRenderProgressReport @"emk render progress report"

