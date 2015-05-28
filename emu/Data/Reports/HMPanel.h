//
//  HMPanel.h
//

// Currently, remote logging implementation uses crashlytics.
#import <Crashlytics/Crashlytics.h>

#import <Optimizely/Optimizely.h>
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

#pragma mark - Experiments
-(void)initializeExperimentsWithLaunchOptions:(NSDictionary *)launchOptions;
-(BOOL)handleOpenURL:(NSURL *)url;

@end
