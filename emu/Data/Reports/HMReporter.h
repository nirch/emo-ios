//
//  HMReporter.h
//

// Currently, remote logging implementation uses crashlytics.
#import <Crashlytics/Crashlytics.h>

#import "HMAnalyticsEvents.h"
#import "HMParams.h"

#define REMOTE_LOG(__FORMAT__, ...) CLS_LOG(__FORMAT__, ##__VA_ARGS__)
#define ANALYTICS(EVT, PARAMS) [HMReporter.sh analyticsEvent:EVT info:PARAMS]
#define IS_TEST_APP [HMReporter.sh isTestApp]

@interface HMReporter : NSObject

#pragma mark - Initialization
+(HMReporter *)sharedInstance;
+(HMReporter *)sh;
-(BOOL)isTestApp;
-(void)initializeAnalyticsWithLaunchOptions:(NSDictionary *)launchOptions;

#pragma mark - Tracking
-(void)reportSuperParameters;
-(void)checkAndReportIfAppUpdated;
-(void)analyticsEvent:(NSString *)event;
-(void)analyticsEvent:(NSString *)event info:(NSDictionary *)info;
-(void)explodeOnTestApplicationsWithInfo:(NSDictionary *)info;


@end
