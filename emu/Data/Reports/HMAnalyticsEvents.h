//
//  HMAnalyticsEvents.h
//  emu
//
//  Created by build script on 22:30:19 03/16/15 IST
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



