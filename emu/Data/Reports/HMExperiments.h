//
//  HMExperiments.h
//  emu
//
//  Created by produce_experiments_resource_file.py script.
//  Copyright (c) 2015 Homage. All rights reserved.
//


#pragma mark - Live Variables
//
// Live Variables
//

/** featureVideoRender : <Bool> - Is the user allowed to render emus as videos?  */
#define VK_FEATURE_VIDEO_RENDER @"featureVideoRender" 

/** featureVideoRenderExtraUserSettings : <Bool> - Is the user allowed to tweak some extra options in video files rendering?
(number of loops, ping pong effect etc)  */
#define VK_FEATURE_VIDEO_RENDER_EXTRA_USER_SETTINGS @"featureVideoRenderExtraUserSettings" 

/** featureVideoRenderWithAudio : <Bool> - Is the user allowed to render emus as videos with audio?  */
#define VK_FEATURE_VIDEO_RENDER_WITH_AUDIO @"featureVideoRenderWithAudio" 

/** htmlShareAppBody : <String> - The body html for the email sent when the user select to share app link using email.  */
#define VK_HTML_SHARE_APP_BODY @"htmlShareAppBody" 

/** iconNameNavRetake : <String> - The name of the icon used for the retake button in the top navigation bar.  */
#define VK_ICON_NAME_NAV_RETAKE @"iconNameNavRetake" 

/** onboardingEmusForPreviewList : <String> - A list of preffered emus oids to use for preview in the onboarding stage (given as a comma delimited string)  */
#define VK_ONBOARDING_EMUS_FOR_PREVIEW_LIST @"onboardingEmusForPreviewList" 

/** recorderRecordButtonCountdownFrom : <Int> - Number of seconds to countdown from before starting to record (if 0 will not count down and start recording immediately)  */
#define VK_RECORDER_RECORD_BUTTON_COUNTDOWN_FROM @"recorderRecordButtonCountdownFrom" 

/** recorderShowAdvancedCameraOptionsOnOnboarding : <Bool> - Boolean value indicating if the advanced camera options are shown to the user when the recorder is opened for the first time for onboarding.  */
#define VK_RECORDER_SHOW_ADVANCED_CAMERA_OPTIONS_ON_ONBOARDING @"recorderShowAdvancedCameraOptionsOnOnboarding" 

/** textShareAppBody : <String> - The body text for the email sent when the user select to share app link using email.  */
#define VK_TEXT_SHARE_APP_BODY @"textShareAppBody" 

/** textShareAppSubject : <String> - The subject text for the email sent when the user select to share app link using email.  */
#define VK_TEXT_SHARE_APP_SUBJECT @"textShareAppSubject" 



#pragma mark - Goals
//
// Goals
//

/** browsingViewed20Emus : The user browsed content and seen at least 20 rendered emus.  */
#define GK_BROWSING_VIEWED20_EMUS @"browsingViewed20Emus" 

/** browsingViewed40Emus : The user browsed content and seen at least 50 rendered emus.  */
#define GK_BROWSING_VIEWED40_EMUS @"browsingViewed40Emus" 

/** browsingViewedManyEmus : The user browsed content and seen at least 75% of all emus.  */
#define GK_BROWSING_VIEWED_MANY_EMUS @"browsingViewedManyEmus" 

/** keyboardOpened : The user opened the keyboard.  */
#define GK_KEYBOARD_OPENED @"keyboardOpened" 

/** notificationsUserAgreed : The user browsed content and seen at least 75% of all emus.  */
#define GK_NOTIFICATIONS_USER_AGREED @"notificationsUserAgreed" 

/** onboardingFinished : The user finished successfully the recorder onboarding.  */
#define GK_ONBOARDING_FINISHED @"onboardingFinished" 

/** onboardingFinishedWithGoodBackground : The user finished successfully the recorder onboarding and the take was with good background mark.  */
#define GK_ONBOARDING_FINISHED_WITH_GOOD_BACKGROUND @"onboardingFinishedWithGoodBackground" 

/** retakeNew : The user opened the recorder for a retake and finished the recorder flow succesfully (onboarding excluded).  */
#define GK_RETAKE_NEW @"retakeNew" 

/** retakeNewWithGoodBackground : The user opened the recorder for a retake and finished the recorder flow succesfully with good background (onboarding excluded).  */
#define GK_RETAKE_NEW_WITH_GOOD_BACKGROUND @"retakeNewWithGoodBackground" 

/** shareFBM : User shared using facebook messenger.  */
#define GK_SHARE_FBM @"shareFBM" 

/** shareKB : User copied to clipboard using the keyboard extension.  */
#define GK_SHARE_KB @"shareKB" 

/** shared : User shared content (of any type).  */
#define GK_SHARED @"shared" 

/** sharedEngagingVideo : User shared a video created with more engagement by the user. The user added audio or played around with the advanced video settings before sharing.  */
#define GK_SHARED_ENGAGING_VIDEO @"sharedEngagingVideo" 

/** sharedGif : User shared animated gif content.  */
#define GK_SHARED_GIF @"sharedGif" 

/** sharedVideo : User shared video content.  */
#define GK_SHARED_VIDEO @"sharedVideo" 



/**
 HMExperiments auto generated class
 */
@interface HMExperiments : NSObject

@property NSDictionary *opKeysByString;

@end


