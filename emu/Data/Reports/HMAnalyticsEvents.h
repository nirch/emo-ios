//
//  HMAnalyticsEvents.h
//  emu
//
//  Created by build script on 11:08:42 05/03/15 IDT
//  Build script name: produce_events_resource_file.py
//  Copyright (c) 2015 Homage. All rights reserved.
//
//  >>> !!! This is an automatically generated file. !!! <<<
//  >>> !!!       Do NOT edit this file by hand      !!! <<<
//
//


#pragma mark - Super parameters
//
// Super parameters
//


/** True if the keyboard ever appeared. **/
#define AK_S_DID_KEYBOARD_EVER_APPEAR @"didKeyboardEverAppear"


/** The number of times the alpha numeric keyboard was shown. **/
#define AK_S_NUMBER_OF_ALPHA_NUMERIC_KB_APPEARANCES_COUNT @"numberOfAlphaNumericKBAppearancesCount"


/** The number of times the app did become active **/
#define AK_S_DID_BECOME_ACTIVE_COUNT @"didBecomeActiveCount"


/** True if in the context of a messanger conversation. **/
#define AK_S_IN_MESSANGER_CONTEXT @"inMessangerContext"


/** <number> - Number indicating the user's current
    UIUserNotificationSettings **/
#define AK_S_NOTIFICATIONS_SETTINGS @"notificationsSettings"


/** The model of the user's device **/
#define AK_S_DEVICE_MODEL @"deviceModel"


/** The long build version string in the following format:
    <big>.<small>.<build#> for production application. or
    <big>.<small>.<build#>.t for test application. **/
#define AK_S_BUILD_VERSION @"buildVersion"


/** True if numberOfAlphaNumericKBAppearancesCount>0 **/
#define AK_S_DID_ALPHA_NUMERIC_KB_EVER_APPEAR @"didAlphaNumericKBEverAppear"


/** The number of times the user launched the application. **/
#define AK_S_LAUNCHES_COUNT @"launchesCount"


/** true if numberOfSharesUsingAppCount > 0 **/
#define AK_S_DID_EVER_SHARE_USING_APP @"didEverShareUsingApp"


/** The number of times the user pressed "I love it" and confirmed the
    take in the recorder (not counting oboarding recorder) **/
#define AK_S_NUMBER_OF_APPROVED_RETAKES @"numberOfApprovedRetakes"


/** The number of times the user navigated to a different package in the
    app. **/
#define AK_S_NUMBER_OF_PACKAGES_NAVIGATED @"numberOfPackagesNavigated"


/** The localized language preference on the user's device (good to know
    for the time we will want to localize the app). **/
#define AK_S_LOCALIZATION_PREFERENCE @"localizationPreference"


/** The number of times keyboard did appear. **/
#define AK_S_NUMBER_OF_KB_APPEARANCES_COUNT @"numberOfKBAppearancesCount"


/** The number of times the user pressed an emu in the keyboard and copied
    to clipboard **/
#define AK_S_NUMBER_OF_KB_COPY_EMU_COUNT @"numberOfKBCopyEmuCount"


/** True if the user ever navigated to another package in the app. **/
#define AK_S_DID_EVER_NAVIGATE_TO_ANOTHER_PACKAGE @"didEverNavigateToAnotherPackage"


/** The number of times the user shared an emu from within the app. **/
#define AK_S_NUMBER_OF_SHARES_USING_APP_COUNT @"numberOfSharesUsingAppCount"


/** A mnemonic name of the application. Currently: "Emu iOS". Used in case
    we will create white labels of the Emu app in the future. **/
#define AK_S_CLIENT_NAME @"clientName"


/** Did the user ever finished a second retake. Opened the recorder and
    finished the recorder flow (disregarding oboarding) **/
#define AK_S_DID_EVER_FINISH_A_RETAKE @"didEverFinishARetake"



#pragma mark - Analytics events
//
// Analytics events
//


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The application did become active
**/
#define AK_E_APP_DID_BECOME_ACTIVE @"App:didBecomeActive"

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
Background fetch
**/
#define AK_E_BE_BACKGROUND_FETCH @"BE:backgroundFetch"

/** Param:resultType --> <string> - the result type of the fetch. Possible values:
 failed - the fetch failed
 newData - fetch success and new packages available
 noNewData - fetch success but no new packages available **/
#define AK_EP_RESULT_TYPE @"resultType"

/** Param:packageOID --> <string> - (optional) oid of a package, if user notified about that newly available package. **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:packageName --> <string> - (optional) name of a package, if user notified about that newly available package. **/
#define AK_EP_PACKAGE_NAME @"packageName"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
A zip file with resources for a package (that wasn't bundled with the
    app) failed to download to the device
**/
#define AK_E_BE_ZIPPED_PACKAGE_DOWNLOAD_FAILED @"BE:zippedPackageDownloadFailed"

/** Param:error --> <string> - description of the error **/
#define AK_EP_ERROR @"error"

/** Param:remoteURL --> <string> - the web url the file was downloaded from. **/
#define AK_EP_REMOTE_URL @"remoteURL"

/** Param:localFileName --> <string> - the local file name. **/
#define AK_EP_LOCAL_FILE_NAME @"localFileName"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
A zip file with resources for a package (that wasn't bundled with the
    app) downloaded to the device successfully
**/
#define AK_E_BE_ZIPPED_PACKAGE_DOWNLOAD_SUCCESS @"BE:zippedPackageDownloadSuccess"

/** Param:remoteURL --> <string> - the web url the file was downloaded from. **/
#define AK_EP_REMOTE_URL @"remoteURL"

/** Param:localFileName --> <string> - the local file name. **/
#define AK_EP_LOCAL_FILE_NAME @"localFileName"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
A zip file with resources for a package failed to unzip
**/
#define AK_E_BE_ZIPPED_PACKAGE_UNZIP_FAILED @"BE:zippedPackageUnzipFailed"

/** Param:packageName --> <string> - the name of the package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:error --> <string> - description of the error **/
#define AK_EP_ERROR @"error"

/** Param:localFileName --> <string> - the local file name. **/
#define AK_EP_LOCAL_FILE_NAME @"localFileName"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
A zip file with resources for a package was unzipped successfully
**/
#define AK_E_BE_ZIPPED_PACKAGE_UNZIP_SUCCESS @"BE:zippedPackageUnzipSuccess"

/** Param:packageName --> <string> - the name of the package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:localFileName --> <string> - the local file name. **/
#define AK_EP_LOCAL_FILE_NAME @"localFileName"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User without facebook messenger got a "Install messenger" alert, but
    chosen not to install.
**/
#define AK_E_FBM_DISMISSED_INSTALL @"FBM:dismissedInstall"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User without facebook messenger pressed the INSTALL FB Messenger
    option from our app.
**/
#define AK_E_FBM_INSTALL @"FBM:install"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Facebook messenger integration opened the app using a deep link.
**/
#define AK_E_FBM_INTEGRATION @"FBM:integration"

/** Param:linkType --> <string> - the type of link fb integration opened the app with. Possible value:
 cancel - user pressed cancel in fbm, after fbm was opened from Emu
 opened - user pressed Emu in the composer / discovery bar
 reply  - user pressed the reply button in fbm **/
#define AK_EP_LINK_TYPE @"linkType"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User selected an option
**/
#define AK_E_ITEM_DETAILS_USER_CHOICE @"ItemDetails:userChoice"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:choiceType --> <string> - the choice type the user selected **/
#define AK_EP_CHOICE_TYPE @"choiceType"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

**/
#define AK_E_ITEM_DETAILS_USER_PRESSED_BACK_BUTTON @"ItemDetails:userPressedBackButton"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User tapped the Emu
**/
#define AK_E_ITEM_DETAILS_USER_PRESSED_EMU @"ItemDetails:userPressedEmu"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

**/
#define AK_E_ITEM_DETAILS_USER_PRESSED_RETAKE_BUTTON @"ItemDetails:userPressedRetakeButton"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User pressed one of the share buttons in the emoticon screen.
**/
#define AK_E_ITEM_DETAILS_USER_PRESSED_SHARE_BUTTON @"ItemDetails:userPressedShareButton"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:shareMethod --> <string> - the name of the method of sharing (application name, save to camera roll etc) **/
#define AK_EP_SHARE_METHOD @"shareMethod"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user pressed canceled when presented by choices (after pressing the
    nav button)
**/
#define AK_E_ITEMS_USER_NAV_SELECTION_CANCEL @"Items:userNavSelectionCancel"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user chosen to reset a pack and use the master footage for rendring
    all emoticons in package
**/
#define AK_E_ITEMS_USER_NAV_SELECTION_RESET_PACK @"Items:userNavSelectionResetPack"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user pressed the emu button at the top and an 'about message' was
    shown.
**/
#define AK_E_ITEMS_USER_PRESSED_APP_BUTTON @"Items:userPressedAppButton"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user pressed the nav button and was given a list of options to choose
    from
**/
#define AK_E_ITEMS_USER_PRESSED_NAV_BUTTON @"Items:userPressedNavButton"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user pressed the retake button while in the emoticons screen
**/
#define AK_E_ITEMS_USER_PRESSED_RETAKE_BUTTON @"Items:userPressedRetakeButton"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user pressed the emu button at the top and an 'about message' was
    shown.
**/
#define AK_E_ITEMS_USER_RETAKE_CANCELED @"Items:userRetakeCanceled"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user selected to retake with an option (for all emoticons or all in
    package)
**/
#define AK_E_ITEMS_USER_RETAKE_OPTION @"Items:userRetakeOption"

/** Param:retakeOption --> <string> - 'all':All emoticons in all packages. 'package':All emoticons in package. **/
#define AK_EP_RETAKE_OPTION @"retakeOption"

/** Param:packageName --> <string> - the name of the related package (optional:  **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user pressed the emu button at the top and an 'about message' was
    shown.
**/
#define AK_E_ITEMS_USER_SELECTED_ITEM @"Items:userSelectedItem"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The keyboard appeared (event sent only when user actually enabled
    keyboard full access)
**/
#define AK_E_KB_DID_APPEAR @"KB:didAppear"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User pressed one of the emoticons for copying
**/
#define AK_E_KB_USER_PRESSED_BACK_BUTTON @"KB:userPressedBackButton"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User pressed one of the emoticons for copying
**/
#define AK_E_KB_USER_PRESSED_ITEM @"KB:userPressedItem"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User pressed the next input button (changed to another keyboard)
**/
#define AK_E_KB_USER_PRESSED_NEXT_INPUT_BUTTON @"KB:userPressedNextInputButton"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
App delegate notifications registration change
**/
#define AK_E_NOTIFICATIONS_REGISTRATION_SETTINGS @"Notifications:registrationSettings"

/** Param:notificationsSettings --> <number> - Number indicating the user's current UIUserNotificationSettings **/
#define AK_EP_NOTIFICATIONS_SETTINGS @"notificationsSettings"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User asked if want to receive notifications and the user declined by
    pressing the "Not Now" button.
**/
#define AK_E_NOTIFICATIONS_USER_NOT_NOW @"Notifications:userNotNow"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User asked if want to receive notifications and the user pressed OK.
**/
#define AK_E_NOTIFICATIONS_USER_OKAY @"Notifications:userOkay"

/** Param:afterConfirmation --> <string> - Indicates what happened after the user pressed the OK button. Possible values: **/
#define AK_EP_AFTER_CONFIRMATION @"afterConfirmation"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User opened a notification in notification center and laucnhed the app
**/
#define AK_E_NOTIFICATIONS_USER_OPENED_NOTIFICATION @"Notifications:userOpenedNotification"

/** Param:text --> <string> - The text sent with the notification **/
#define AK_EP_TEXT @"text"

/** Param:packageOID --> <string> - (optional) The oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:packageName --> <string> - (optional) The name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:notificationType --> <string> - The type of the notification: local,remote **/
#define AK_EP_NOTIFICATION_TYPE @"notificationType"


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
A threshold of good background was reached and fg extraction should
    start
**/
#define AK_E_REC_STAGE_ALIGN_GOOD_BACKGROUND_SATISFIED @"Rec:stageAlignGoodBackgroundSatisfied"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The background detection feedback UI is presented to the user. User is
    asked to align to silhoutte and gets feedback about bad
    background.
**/
#define AK_E_REC_STAGE_ALIGN_STARTED @"Rec:stageAlignStarted"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The background detection feedback UI is presented to the user. User is
    asked to align to silhoutte and gets feedback about bad
    background.
**/
#define AK_E_REC_STAGE_ALIGN_USER_PRESSED_CONTINUE_WITH_BAD_BACKGROUND @"Rec:stageAlignUserPressedContinueWithBadBackground"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The FG extraction stage has started. BG detection UI is dismissed.
    User can use a record button when ready.
**/
#define AK_E_REC_STAGE_EXT_STARTED @"Rec:stageExtStarted"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User canceled recording (by pressing the record button when it was
    counting down)
**/
#define AK_E_REC_STAGE_EXT_USER_CANCELED_RECORD @"Rec:stageExtUserCanceledRecord"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User pressed the record button while real time extraction was in
    progress.
**/
#define AK_E_REC_STAGE_EXT_USER_PRESSED_RECORD @"Rec:stageExtUserPressedRecord"

/** Param:latestBackgroundMark --> <int> - The latest background detection mark before user pressed the record button. **/
#define AK_EP_LATEST_BACKGROUND_MARK @"latestBackgroundMark"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Recording did finish.
**/
#define AK_E_REC_STAGE_RECORDING_DID_FINISH @"Rec:stageRecordingDidFinish"

/** Param:packageOID --> <string> - the oid of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:emuticonOID --> <string> - the oid of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"

/** Param:latestBackgroundMark --> <int> - The latest background detection mark before user pressed the record button. **/
#define AK_EP_LATEST_BACKGROUND_MARK @"latestBackgroundMark"

/** Param:flowType --> <string> - the flow type definition the recorder was opened with. Possible values: 
 'onboarding' - recorder on boarding when app launched for the first time.
 'retakeAll' - user wanted to retake and use the footage to all unlocked emoticons
 'retakePackage' - user wanted to retake and use the footage to all unlocked emoticons in a package.
 'retakeEmoticon' - user wanted to retake and lock an emoticon to a specific footage taken for that emoticon. **/
#define AK_EP_FLOW_TYPE @"flowType"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Recording did start.
**/
#define AK_E_REC_STAGE_RECORDING_DID_START @"Rec:stageRecordingDidStart"

/** Param:packageOID --> <string> - the oid of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:emuticonOID --> <string> - the oid of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"

/** Param:latestBackgroundMark --> <int> - The latest background detection mark before user pressed the record button. **/
#define AK_EP_LATEST_BACKGROUND_MARK @"latestBackgroundMark"

/** Param:flowType --> <string> - the flow type definition the recorder was opened with. Possible values: 
 'onboarding' - recorder on boarding when app launched for the first time.
 'retakeAll' - user wanted to retake and use the footage to all unlocked emoticons
 'retakePackage' - user wanted to retake and use the footage to all unlocked emoticons in a package.
 'retakeEmoticon' - user wanted to retake and lock an emoticon to a specific footage taken for that emoticon. **/
#define AK_EP_FLOW_TYPE @"flowType"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
When user asked if he likes the result he chose yes. Yeah! :-)
**/
#define AK_E_REC_STAGE_REVIEW_USER_PRESSED_CONFIRM_BUTTON @"Rec:stageReviewUserPressedConfirmButton"

/** Param:packageOID --> <string> - the oid of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:emuticonOID --> <string> - the oid of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"

/** Param:latestBackgroundMark --> <int> - The latest background detection mark before user pressed the record button. **/
#define AK_EP_LATEST_BACKGROUND_MARK @"latestBackgroundMark"

/** Param:flowType --> <string> - the flow type definition the recorder was opened with. Possible values: 
 'onboarding' - recorder on boarding when app launched for the first time.
 'retakeAll' - user wanted to retake and use the footage to all unlocked emoticons
 'retakePackage' - user wanted to retake and use the footage to all unlocked emoticons in a package.
 'retakeEmoticon' - user wanted to retake and lock an emoticon to a specific footage taken for that emoticon. **/
#define AK_EP_FLOW_TYPE @"flowType"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
When user asked if he likes the result he chose to try again and
    retake. You just can't please some people. :-(
**/
#define AK_E_REC_STAGE_REVIEW_USER_PRESSED_RETAKE_BUTTON @"Rec:stageReviewUserPressedRetakeButton"

/** Param:packageOID --> <string> - the oid of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:emuticonOID --> <string> - the oid of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"

/** Param:latestBackgroundMark --> <int> - The latest background detection mark before user pressed the record button. **/
#define AK_EP_LATEST_BACKGROUND_MARK @"latestBackgroundMark"

/** Param:flowType --> <string> - the flow type definition the recorder was opened with. Possible values: 
 'onboarding' - recorder on boarding when app launched for the first time.
 'retakeAll' - user wanted to retake and use the footage to all unlocked emoticons
 'retakePackage' - user wanted to retake and use the footage to all unlocked emoticons in a package.
 'retakeEmoticon' - user wanted to retake and lock an emoticon to a specific footage taken for that emoticon. **/
#define AK_EP_FLOW_TYPE @"flowType"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
user pressed (in recorder onboarding) the emu button (showing him an
    about emu message)
**/
#define AK_E_REC_USER_PRESSED_APP_BUTTON @"Rec:userPressedAppButton"

/** Param:stage --> <int> - the stage this happened. Possible values:
	0 - EMOnBoardingStageWelcome
    1 - EMOnBoardingStageAlign
    2 - EMOnBoardingStageExtractionPreview
    3 - EMOnBoardingStageRecording
    4 - EMOnBoardingStageFinishingUp
    5 - EMOnBoardingStageReview **/
#define AK_EP_STAGE @"stage"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

**/
#define AK_E_REC_USER_PRESSED_CANCEL_BUTTON @"Rec:userPressedCancelButton"

/** Param:stage --> <int> - the stage this happened. Possible values:
	0 - EMOnBoardingStageWelcome
    1 - EMOnBoardingStageAlign
    2 - EMOnBoardingStageExtractionPreview
    3 - EMOnBoardingStageRecording
    4 - EMOnBoardingStageFinishingUp
    5 - EMOnBoardingStageReview **/
#define AK_EP_STAGE @"stage"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The user pressed the restart button that causes the recorder to
    restart the flow of the recorder.
**/
#define AK_E_REC_USER_PRESSED_RESTART_BUTTON @"Rec:userPressedRestartButton"

/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Recorder was dismissed.
**/
#define AK_E_REC_WAS_DISMISSED @"Rec:wasDismissed"

/** Param:finishedFlow --> <int> - 0:user didn't finish the flow. 1:the user finished the flow. **/
#define AK_EP_FINISHED_FLOW @"finishedFlow"

/** Param:emuticonOID --> <string> - the oid of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon (optional. only if recorder opened in the retakeEmoticon flow) **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:packageOID --> <string> - the oid of the related package (sent even in onboarding according to the used package set in AppCFG) **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:timePassedSinceRecorderOpened --> <interval> - the time interval passed since the Rec:opened event. **/
#define AK_EP_TIME_PASSED_SINCE_RECORDER_OPENED @"timePassedSinceRecorderOpened"

/** Param:latestBackgroundMark --> <int> - The latest background detection mark before user pressed the record button. **/
#define AK_EP_LATEST_BACKGROUND_MARK @"latestBackgroundMark"

/** Param:flowType --> <string> - the flow type definition the recorder was opened with. Possible values: 
 'onboarding' - recorder on boarding when app launched for the first time.
 'retakeAll' - user wanted to retake and use the footage to all unlocked emoticons
 'retakePackage' - user wanted to retake and use the footage to all unlocked emoticons in a package.
 'retakeEmoticon' - user wanted to retake and lock an emoticon to a specific footage taken for that emoticon. **/
#define AK_EP_FLOW_TYPE @"flowType"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
User opened iOS settings application.
**/
#define AK_E_SETTINGS_USER_OPENED_SETTINGS_APP @"Settings:userOpenedSettingsApp"

/** Param:reason --> <string> - The reason the user asked to open the settings app. **/
#define AK_EP_REASON @"reason"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Sharing was canceled by the user.
**/
#define AK_E_SHARE_CANCELED @"Share:canceled"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:shareMethod --> <string> - the name of the method of sharing (application name, save to camera roll etc) **/
#define AK_EP_SHARE_METHOD @"shareMethod"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:senderUI --> <string> - The originating UI the share was initated from. ShareVC, keyboard, etc. **/
#define AK_EP_SENDER_UI @"senderUI"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Sharing failed. (Not related to any specific UI)
**/
#define AK_E_SHARE_FAILED @"Share:failed"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:shareMethod --> <string> - the name of the method of sharing (application name, save to camera roll etc) **/
#define AK_EP_SHARE_METHOD @"shareMethod"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:senderUI --> <string> - The originating UI the share was initated from. Emoticon screen, keyboard, etc. **/
#define AK_EP_SENDER_UI @"senderUI"


/** - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Sharing was successful. (Not related to any specific UI)
**/
#define AK_E_SHARE_SUCCESS @"Share:success"

/** Param:packageOID --> <string> - the oid of the related package **/
#define AK_EP_PACKAGE_OID @"packageOID"

/** Param:shareMethod --> <string> - the name of the method of sharing (application name, save to camera roll etc) **/
#define AK_EP_SHARE_METHOD @"shareMethod"

/** Param:emuticonOID --> <string> - the oid of the related emoticon **/
#define AK_EP_EMUTICON_OID @"emuticonOID"

/** Param:packageName --> <string> - the name of the related package **/
#define AK_EP_PACKAGE_NAME @"packageName"

/** Param:emuticonName --> <string> - the name of the related emoticon **/
#define AK_EP_EMUTICON_NAME @"emuticonName"

/** Param:senderUI --> <string> - The originating UI the share was initated from. Emoticon screen, keyboard, etc. **/
#define AK_EP_SENDER_UI @"senderUI"



