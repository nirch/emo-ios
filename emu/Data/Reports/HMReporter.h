//
//  HMReporter.h
//

// Currently, remote logging implementation uses crashlytics.
#import <Crashlytics/Crashlytics.h>

#import "HMAnalyticsEvents.h"
#import "HMParams.h"

#define REMOTE_LOG(__FORMAT__, ...) CLS_LOG(__FORMAT__, ##__VA_ARGS__)

@interface HMReporter : NSObject

#pragma mark - Initialization
+(HMReporter *)sharedInstance;
+(HMReporter *)sh;
-(void)initializeAnalyticsWithLaunchOptions:(NSDictionary *)launchOptions;

#pragma mark - Tracking
-(void)reportSuperParameters;
-(void)reportSuperParameters:(NSDictionary *)parameters;
-(void)checkAndReportIfAppUpdated;
-(void)analyticsForceSend;
-(void)analyticsEvent:(NSString *)event;
-(void)analyticsEvent:(NSString *)event info:(NSDictionary *)info;
-(void)explodeOnTestApplicationsWithInfo:(NSDictionary *)info;


@end
