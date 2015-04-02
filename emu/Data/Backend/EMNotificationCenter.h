//
//  EMNotificationCenter.h
//  emu
//
//  Created by Aviv Wolf on 3/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#import "HMNotificationCenter.h"

#pragma mark - UI data requirements
// UI data requirements

// Notified backend that packages data should be refetched.
#define emkDataRequiredPackages @"emk data required packages"

#pragma mark - Data updates
#define emkDataUpdatedPackages @"emk data updated packages"

// Notification of the backend to the UI
#define emkUIDataRefreshPackages @"emk backend data refreshed packages"
#define emkUIDownloadedResourcesForEmuticon @"emk backend downloaded resources for emuticon"
#define emkUIMainShouldShowPackage @"emk ui main should show package"