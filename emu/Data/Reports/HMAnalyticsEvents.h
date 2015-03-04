//
//  HMAnalyticsEvents.h
//  emu
//
//  Created by build script on 16:21:09 03/04/15 IST
//  Copyright (c) 2015 Homage. All rights reserved.
//


#pragma mark - Super parameters
//
// Super parameters
//


/** The long build version string in the following format:
    <big>.<small>.<build#> for production application. or
    <big>.<small>.<build#>.t for test application. **/
#define AK_S_BUILD_VERSION @"buildVersion"


/** The localized language preference on the user's device (good to know
    for the time we will want to localize the app). **/
#define AK_S_LOCALIZATION_PREFERENCE @"localizationPreference"


/** The number of times the user launched the application. **/
#define AK_S_LAUNCHES_COUNT @"launchesCount"


/** A mnemonic name of the application. Currently: "Emu iOS". Used in case
    we will create white labels of the Emu app in the future. **/
#define AK_S_CLIENT_NAME @"clientName"


/** The model of the user's device **/
#define AK_S_DEVICE_MODEL @"deviceModel"



#pragma mark - Analytics events
//
// Analytics events
//


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The application entered the background (user pressed home screen,
    changed to another app, etc.)
**/
#define AK_E_APP_ENTERED_BACKGROUND @"App:enteredBackground"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The user launched or returned to the application.
**/
#define AK_E_APP_ENTERED_FOREGROUND @"App:enteredForeground"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The application was launched by the user.
**/
#define AK_E_APP_LAUNCHED @"App:launched"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The application was launched with a higher version than the version it
    was launched with previously.
**/
#define AK_E_APP_VERSION_UPDATED @"App:versionUpdated"

/** Param:previousVersion --> <string> - the previous version the app was launched with **/
#define AK_EP_PREVIOUS_VERSION @"previousVersion"

/** Param:currentVersion --> <string> - the current version the app was launched with **/
#define AK_EP_CURRENT_VERSION @"currentVersion"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The recorder screen was opened and just appeared on screen. The event
    will also include info about the flow option the recorder was
    opened for.
**/
#define AK_E_REC_OPENED @"Rec:opened"

/** Param:flowType --> <string> - the flow type definition the recorder was opened with. Possible values: 
 'onboarding' - recorder on boarding when app launched for the first time.
 'retakeAll' - user wanted to retake and use the footage to all unlocked emoticons
 'retakePackage' - user wanted to retake and use the footage to all unlocked emoticons in a package.
 'retakeEmoticon' - user wanted to retake and lock an emoticon to a specific footage taken for that emoticon. **/
#define AK_EP_FLOW_TYPE @"flowType"

/** Param:emuticonOID --> <string> - the oid of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:packageOID --> <string> - the oid of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

**/
#define AK_E_REC_STAGE_ALIGN_STARTED @"Rec:stageAlignStarted"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

**/
#define AK_E_REC_USER_PRESSED_APP_BUTTON @"Rec:userPressedAppButton"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

**/
#define AK_E_REC_USER_PRESSED_CANCEL_BUTTON @"Rec:userPressedCancelButton"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

**/
#define AK_E_REC_USER_PRESSED_RESTART_BUTTON @"Rec:userPressedRestartButton"


