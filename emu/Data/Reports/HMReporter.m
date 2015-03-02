//
//  HMReporter.m
//

#import "HMReporter.h"
#import <Crashlytics/Crashlytics.h>

@interface HMReporter()

@property (nonatomic) NSString *applicationBuild;
@property (nonatomic) BOOL isBuildOfTestApplication;

@end

@implementation HMReporter

#pragma mark - Initialization
// A singleton
+(HMReporter *)sharedInstance
{
    static HMReporter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMReporter alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMReporter *)sh
{
    return [HMReporter sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        // Build number
        [self initBuildInfo];
        
        // Crashlytics
        [self initCrashlytics];
    }
    return self;
}

-(NSString *)trimmedString:(NSString *)str
{
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(void)initBuildInfo
{
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    self.applicationBuild = [[self trimmedString:build] uppercaseString];
    self.isBuildOfTestApplication = [self.applicationBuild hasSuffix:@"T"];
}

-(void)initCrashlytics
{
    [Crashlytics startWithAPIKey:@"daa34917843cd9e52b65a68cec43efac16fb680a"];
    REMOTE_LOG(@"Initialized crashlytics");
}


#pragma mark - HMReporterProtocol
-(BOOL)isTestApp
{
    return self.isBuildOfTestApplication;
}


-(void)analyticsEvent:(NSString *)event
{
    // TODO: implement.
}


-(void)analyticsEvent:(NSString *)event info:(NSDictionary *)info
{
    // TODO: implement.
}


-(void)explodeOnTestApplicationsWithInfo:(NSDictionary *)info
{
    if ([self isTestApp]) {
        REMOTE_LOG(@"TEST APP GOES BOOM! %@", [info description]);
        abort();
    }
}

@end
