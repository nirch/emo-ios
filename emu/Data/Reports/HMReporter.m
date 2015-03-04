//
//  HMReporter.m
//
#define TAG @"HMReporter"


#import "HMReporter.h"
#import <Crashlytics/Crashlytics.h>
#import <Mixpanel.h>
#import <sys/utsname.h>

@interface HMReporter()

@property (nonatomic) NSMutableDictionary *cfg;
@property (nonatomic) NSString *applicationBuild;
@property (nonatomic) BOOL isBuildOfTestApplication;

@property (nonatomic) NSString *mixPanelToken;
@property (nonatomic) Mixpanel *mixPanel;

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
        
        // Read configuration
        [self initCFG];
        
        // Crashlytics
        [self initCrashlytics];
    }
    return self;
}

-(void)initializeAnalyticsWithLaunchOptions:(NSDictionary *)launchOptions
{
    [self initMixPanelWithOptions:launchOptions];
}

-(NSString *)trimmedString:(NSString *)str
{
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(void)initBuildInfo
{
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    self.applicationBuild = [[self trimmedString:build] uppercaseString];
    self.isBuildOfTestApplication = [self.applicationBuild hasSuffix:@"T"] || [self.applicationBuild hasSuffix:@"D"];
}

-(void)initCFG
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Analytics" ofType:@"plist"];
    self.cfg = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
}

-(void)initCrashlytics
{
    [Crashlytics startWithAPIKey:@"daa34917843cd9e52b65a68cec43efac16fb680a"];
    REMOTE_LOG(@"Initialized crashlytics");
}

-(void)initMixPanelWithOptions:(NSDictionary *)launchOptions
{
    self.mixPanelToken = self.cfg[@"token"][self.isTestApp?@"testToken":@"productionToken"];
    self.mixPanel = [Mixpanel sharedInstance];

    // Init mixpanel using the token
    if ([Mixpanel sharedInstance] == nil) {
        HMLOG(TAG, EM_DBG, @"Initializing mixpanel with token: %@", self.mixPanelToken);
        self.mixPanel = [Mixpanel sharedInstanceWithToken:self.mixPanelToken
                                            launchOptions:launchOptions];
    } else {
        HMLOG(TAG, EM_DBG, @"Mixpanel already initialized.");
    }
}

-(void)reportSuperParameters
{
    HMParams *params = [HMParams new];
    [params addKey:AK_S_BUILD_VERSION value:self.applicationBuild];
    [params addKey:AK_S_LOCALIZATION_PREFERENCE value:[self localizationPreference]];
    [params addKey:AK_S_DEVICE_MODEL value:[HMReporter deviceModelName]];
    [params addKey:AK_S_LAUNCHES_COUNT value:[self launchesCount]];
    [params addKey:AK_S_CLIENT_NAME value:self.cfg[AK_S_CLIENT_NAME]];
    NSDictionary *info = params.dictionary;
    [self.mixPanel registerSuperProperties:info];
}

#pragma mark - HMReporterProtocol
-(BOOL)isTestApp
{
    return self.isBuildOfTestApplication;
}

-(void)analyticsForceSend
{
    [self.mixPanel flush];
}

-(void)analyticsEvent:(NSString *)event
{
    [self analyticsEvent:event info:nil];
}

-(void)analyticsEvent:(NSString *)event info:(NSDictionary *)info
{
    if (event == nil) return;
    
    // Ensure the event is defined.
    // If it is not defined, warn about it in production and explode on test/development.
    id e = self.cfg[@"events"][event];
    if (![e isKindOfClass:[NSDictionary class]]) {
        NSString *errMessage = [SF:@"Wrong analytics event name used '%@'", event];
        HMLOG(TAG, EM_ERR, @"%@", errMessage);
        // if a test app, just explode
        [self explodeOnTestApplicationsWithInfo:@{@"description":errMessage}];
        return;
    }
    
    // Report event to mixpanel.
    [self.mixPanel track:event properties:info];
}


-(void)explodeOnTestApplicationsWithInfo:(NSDictionary *)info
{
    if ([self isTestApp]) {
        REMOTE_LOG(@"TEST APP GOES BOOM! %@", [info description]);
        [[Crashlytics sharedInstance] crash];
    }
}

#pragma mark - App Info
-(void)checkAndReportIfAppUpdated
{
    // We don't care about this for test applications
    //if (self.isTestApp) return;
    
    // Production app should track update events.
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *previousBuildLaunched = [prefs stringForKey:@"previousBuildLaunched"];
    if (previousBuildLaunched && ![previousBuildLaunched isEqualToString:self.applicationBuild]) {
        // Check if it was an upgrade
        if ([self.applicationBuild compare:previousBuildLaunched options:NSNumericSearch] == NSOrderedDescending) {
            // A newer app build was installed. Track this event.
            HMParams *params = [HMParams new];
            [params addKey:AK_EP_CURRENT_VERSION value:self.applicationBuild];
            [params addKey:AK_EP_PREVIOUS_VERSION value:previousBuildLaunched];
            [self analyticsEvent:AK_E_APP_VERSION_UPDATED info:params.dictionary];
        }
    }
    
    // Store current build as the the previousBuildLaunched
    [prefs setObject:self.applicationBuild forKey:@"previousBuildLaunched"];
    [prefs synchronize];
}

-(NSNumber *)launchesCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger counter = [prefs integerForKey:@"launchesCounter"];
    counter++;
    [prefs setValue:@(counter) forKey:@"launchesCounter"];
    [prefs synchronize];
    return @(counter);
}

-(NSString *)localizationPreference
{
    NSArray *languages = [NSLocale preferredLanguages];
    if (languages == nil) return @"unknown";
    return [languages componentsJoinedByString:@","];
}

+(NSString *)deviceModelName
{
    NSDictionary *commonNamesDictionary = @{
      @"i386":     @"iPhone Simulator",
      @"x86_64":   @"iPad Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4(Rev A)",
      @"iPhone3,3":    @"iPhone 4(CDMA)",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5(GSM)",
      @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3":    @"iPhone 5c(GSM)",
      @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1":    @"iPhone 5s(GSM)",
      @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
      
      @"iPhone7,1":    @"iPhone 6+ (GSM+CDMA)",
      @"iPhone7,2":    @"iPhone 6 (GSM+CDMA)",
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini 1G (WiFi)",
      @"iPad2,6":  @"iPad Mini 1G (GSM)",
      @"iPad2,7":  @"iPad Mini 1G (GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",
      
      @"iPad4,1":  @"iPad Air(WiFi)",
      @"iPad4,2":  @"iPad Air(GSM)",
      @"iPad4,3":  @"iPad Air(GSM+CDMA)",
      
      @"iPad4,4":  @"iPad Mini 2G (WiFi)",
      @"iPad4,5":  @"iPad Mini 2G (GSM)",
      @"iPad4,6":  @"iPad Mini 2G (GSM+CDMA)",
      
      @"iPad4,6":  @"iPad Mini 2G (GSM+CDMA)",
      @"iPad4,6":  @"iPad Mini 2G (GSM+CDMA)",
      @"iPad4,6":  @"iPad Mini 2G (GSM+CDMA)",
      
      @"iPad5,3":  @"iPad Air 2",
      @"iPad5,4":  @"iPad Air 2",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      
    };
    
    NSString *name = machineName();
    NSString *mnemonicName = commonNamesDictionary[name];
    return mnemonicName? mnemonicName:name;
}

NSString* machineName()
{
    /*
     @"i386"      on 32-bit Simulator
     @"x86_64"    on 64-bit Simulator
     @"iPod1,1"   on iPod Touch
     @"iPod2,1"   on iPod Touch Second Generation
     @"iPod3,1"   on iPod Touch Third Generation
     @"iPod4,1"   on iPod Touch Fourth Generation
     @"iPhone1,1" on iPhone
     @"iPhone1,2" on iPhone 3G
     @"iPhone2,1" on iPhone 3GS
     @"iPad1,1"   on iPad
     @"iPad2,1"   on iPad 2
     @"iPad3,1"   on 3rd Generation iPad
     @"iPhone3,1" on iPhone 4
     @"iPhone4,1" on iPhone 4S
     @"iPhone5,1" on iPhone 5 (model A1428, AT&T/Canada)
     @"iPhone5,2" on iPhone 5 (model A1429, everything else)
     @"iPad3,4" on 4th Generation iPad
     @"iPad2,5" on iPad Mini
     @"iPhone5,3" on iPhone 5c (model A1456, A1532 | GSM)
     @"iPhone5,4" on iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)
     @"iPhone6,1" on iPhone 5s (model A1433, A1533 | GSM)
     @"iPhone6,2" on iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)
     @"iPad4,1" on 5th Generation iPad (iPad Air) - Wifi
     @"iPad4,2" on 5th Generation iPad (iPad Air) - Cellular
     @"iPad4,4" on 2nd Generation iPad Mini - Wifi
     @"iPad4,5" on 2nd Generation iPad Mini - Cellular
     @"iPhone7,1" on iPhone 6 Plus
     @"iPhone7,2" on iPhone 6
     */
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *model = [NSString stringWithCString:systemInfo.machine
                                         encoding:NSUTF8StringEncoding];
    return model;
}

@end
