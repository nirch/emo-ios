//
//  HMPanel.h
//

// Currently, remote logging implementation uses crashlytics.
#import <Crashlytics/Crashlytics.h>

#import "HMAnalyticsEvents.h"
#import "HMParams.h"
#import <MPTweakInline.h>

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
-(void)reportCountedSuperParameterForKey:(NSString *)key;
-(NSNumber *)didEverCountedKey:(NSString *)counterKey;
-(BOOL)checkAndReportIfAppUpdated;
-(void)analyticsForceSend;
-(void)analyticsEvent:(NSString *)event;
-(void)analyticsEvent:(NSString *)event info:(NSDictionary *)info;
-(void)explodeOnTestApplicationsWithInfo:(NSDictionary *)info;

#pragma mark - Counting stuff
-(BOOL)counterExistsNamed:(NSString *)counterName;
-(NSNumber *)advanceCounterNamed:(NSString *)counterName;

#pragma mark - People
-(void)personIdentify;
-(void)personIdentifyWithIdentifier:(NSString *)identifier;
-(void)personDetails:(NSDictionary *)details;


#pragma mark - Tweaking
// Wrapper of mixpanel tweak inline macros
#define HMPanelTweakValue(name_, ...) MPTweakValue(name_, __VA_ARGS__)


@end
