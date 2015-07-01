//
//  HMPanel.h
//

// Currently, remote logging implementation uses crashlytics.
#import <Crashlytics/Crashlytics.h>

#import <Optimizely/Optimizely.h>
#import "HMAnalyticsEvents.h"
#import "HMParams.h"
#import <MPTweakInline.h>
#import "HMExperiments.h"

#define VK_FEATURE_VIDEO_RENDER @"featureVideoRender"
#define VK_FEATURE_VIDEO_RENDER_WITH_AUDIO @"featureVideoRenderWithAudio"
#define VK_FEATURE_VIDEO_RENDER_EXTRA_USER_SETTINGS @"featureVideoRenderExtraUserSettings"

#define REMOTE_LOG(__FORMAT__, ...) CLS_LOG(__FORMAT__, ##__VA_ARGS__)

@interface HMPanel : NSObject

#pragma mark - Initialization
+(HMPanel *)sharedInstance;
+(HMPanel *)sh;
-(void)initializeAnalyticsWithLaunchOptions:(NSDictionary *)launchOptions;

#pragma mark - Tracking
-(void)reportSuperParameters;
-(void)reportSuperParameters:(NSDictionary *)parameters;
-(void)reportSuperParameterKey:(NSString *)key value:(id)value;
-(void)reportOnceSuperParameterKey:(NSString *)key value:(id)value;
-(void)reportCountedSuperParameterForKey:(NSString *)key;
-(NSNumber *)didEverCountedKey:(NSString *)counterKey;
-(BOOL)checkAndReportIfAppUpdated;
-(void)analyticsForceSend;

-(void)analyticsEvent:(NSString *)event;
-(void)analyticsEvent:(NSString *)event info:(NSDictionary *)info;
-(void)explodeOnTestApplicationsWithInfo:(NSDictionary *)info;
-(void)reportBuildInfo;

#pragma mark - Counting stuff
-(BOOL)counterExistsNamed:(NSString *)counterName;
-(NSNumber *)advanceCounterNamed:(NSString *)counterName;
-(NSNumber *)counterValueNamed:(NSString *)counterName;

#pragma mark - People
-(void)personIdentify;
-(void)personIdentifyWithIdentifier:(NSString *)identifier;
-(void)reportPersonDetails;
-(void)personDetails:(NSDictionary *)details;
-(void)personPushToken:(NSData *)pushToken;

#pragma mark - Experiments, tweaks & user feedback
-(void)initializeExperimentsWithLaunchOptions:(NSDictionary *)launchOptions;
-(BOOL)handleOpenURL:(NSURL *)url;
-(void)experimentGoalEvent:(NSString *)eventName;
-(void)userFeedbackDialoguesPoint;

// -----------------------------------------
// Live variables
//
// The value is defined by this logic:
//      - If a tweak value is forced by >>emu server<< (in the tweaks dictionary), that value will be used.
//      - otherwise If an experiment defined that value, that value will be used or the related default.
//      - if no value was defined at all for given key (key not recognized), the fallback value is returned.
//
-(BOOL)boolForKey:(NSString *)key fallbackValue:(BOOL)fallbackValue;
-(NSNumber *)numberForKey:(NSString *)key fallbackValue:(NSNumber *)fallbackValue;
-(NSString *)stringForKey:(NSString *)key fallbackValue:(NSString *)fallbackValue;
-(NSArray *)listForKey:(NSString *)key fallbackValue:(NSArray *)fallbackValue;
// -----------------------------------------


@end
