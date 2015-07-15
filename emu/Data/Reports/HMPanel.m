//
//  HMPanel.m
//
#define TAG @"HMPanel"


#import "HMPanel.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Mixpanel.h>
#import "AppManagement.h"
#import "EMDB.h"

@interface HMPanel()

@property (nonatomic) NSMutableDictionary *cfg;
@property (nonatomic) NSString *mixPanelToken;
@property (nonatomic) Mixpanel *mixPanel;
@property (nonatomic) HMExperiments *experiments;

@end

@implementation HMPanel

#pragma mark - Initialization
// A singleton
+(HMPanel *)sharedInstance
{
    static HMPanel *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMPanel alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMPanel *)sh
{
    return [HMPanel sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        // Read configuration
        [self initCFG];
        
        // Crashlytics
        [self initCrashlytics];
        
        // Experiments
        [self initExperiments];
    }
    return self;
}

-(void)initializeAnalyticsWithLaunchOptions:(NSDictionary *)launchOptions
{
    [self initMixPanelWithOptions:launchOptions];
}

-(void)initCFG
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Analytics" ofType:@"plist"];
    self.cfg = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
}

-(void)initCrashlytics
{
    [Fabric with:@[CrashlyticsKit]];
    Crashlytics *crashlytics = [Crashlytics sharedInstance];
    [crashlytics setObjectValue:[[UIDevice currentDevice] name] forKey:@"device name"];
    REMOTE_LOG(@"Initialized crashlytics");
}

-(void)remoteKey:(NSString *)key value:(NSString *)value
{
    if (key == nil || value == nil) return;
    Crashlytics *crashlytics = [Crashlytics sharedInstance];
    [crashlytics setObjectValue:value forKey:key];
}

-(void)initMixPanelWithOptions:(NSDictionary *)launchOptions
{
    self.mixPanelToken = self.cfg[@"token"][AppManagement.sh.isTestApp?@"testToken":@"productionToken"];
    self.mixPanel = [Mixpanel sharedInstance];

    // Init mixpanel using the token
    if ([Mixpanel sharedInstance] == nil) {
        HMLOG(TAG, EM_DBG, @"Initializing mixpanel with token: %@", self.mixPanelToken);
        self.mixPanel = [Mixpanel sharedInstanceWithToken:self.mixPanelToken
                                            launchOptions:launchOptions];
        self.mixPanel.showSurveyOnActive = NO;
    } else {
        HMLOG(TAG, EM_DBG, @"Mixpanel already initialized.");
    }
}


-(void)userFeedbackDialoguesPoint
{
    [self.mixPanel showSurvey];
}


-(void)reportSuperParameters
{
    HMParams *params = [HMParams new];
    [params addKey:AK_S_BUILD_VERSION value:AppManagement.sh.applicationBuild];
    [params addKey:AK_S_LOCALIZATION_PREFERENCE value:[self localizationPreference]];
    [params addKey:AK_S_DEVICE_MODEL value:[AppManagement deviceModelName]];
    [params addKey:AK_S_LAUNCHES_COUNT value:[self launchesCount]];
    [params addKey:AK_S_CLIENT_NAME value:self.cfg[AK_S_CLIENT_NAME]?self.cfg[AK_S_CLIENT_NAME]:@"Emu iOS"];
    
    // More flags as super parameters
    [params addKey:AK_S_DID_EVER_SHARE_USING_APP value:[self didEverCountedKey:AK_S_NUMBER_OF_SHARES_USING_APP_COUNT]];
    [params addKey:AK_S_DID_EVER_SHARE_VIDEO_USING_APP value:[self didEverCountedKey:AK_S_NUMBER_OF_VIDEO_SHARES_USING_APP_COUNT]];
    [params addKey:AK_S_DID_EVER_FINISH_A_RETAKE value:[self didEverCountedKey:AK_S_NUMBER_OF_APPROVED_RETAKES]];
    [params addKey:AK_S_DID_EVER_NAVIGATE_TO_ANOTHER_PACKAGE value:[self didEverCountedKey:AK_S_NUMBER_OF_PACKAGES_NAVIGATED]];
    
    NSDictionary *info = params.dictionary;
    [self.mixPanel registerSuperProperties:info];
    
    if ([self isFirstLaunch]) {
        [self reportOnceSuperParameterKey:AK_S_FIRST_LAUNCH_DATE value:[NSDate date]];
    }
}


-(void)reportSuperParameters:(NSDictionary *)parameters
{
    HMParams *superParams = [HMParams new];
    for (NSString *key in parameters.allKeys) {
        [superParams addKey:key valueIfNotNil:parameters[key]];
    }
    [self.mixPanel registerSuperProperties:superParams.dictionary];
}

-(void)reportOnceSuperParameterKey:(NSString *)key value:(id)value
{
    [self.mixPanel registerSuperPropertiesOnce:@{key:value}];
}


-(void)reportSuperParameterKey:(NSString *)key value:(id)value
{
    HMParams *superParams = [HMParams new];
    [superParams addKey:key valueIfNotNil:value];
    [self.mixPanel registerSuperProperties:superParams.dictionary];
}

-(void)reportCountedSuperParameterForKey:(NSString *)key
{
    NSNumber *counterValue = [self advanceCounterNamed:key];
    [self reportSuperParameterKey:key value:counterValue];
}

-(NSNumber *)didEverCountedKey:(NSString *)counterKey
{
    if ([self counterExistsNamed:counterKey]) {
        return @YES;
    }
    return @NO;
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
    HMLOG(TAG, EM_VERBOSE, @"Event:%@ info:%@", event, info);
}

-(void)reportBuildInfo
{
    // Read build info plist if exists.
    NSString *fileName = AppManagement.sh.isTestApp?@"emubeta_latest_build_info":@"emu_latest_build_info";
    NSDictionary *buildInfo = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"]];
    HMLOG(TAG, EM_DBG, @"latest build info: %@", buildInfo);
    
    // Super properties.
    HMParams *params = [HMParams new];
    [params addKey:@"build_counter" value:buildInfo[@"build_counter"]];
    [params addKey:@"build_date" value:buildInfo[@"build_date"]];
    [self reportSuperParameters:params.dictionary];
    
    // Person details.
    params = [HMParams new];
    [params addKey:@"latest_build_counter" value:buildInfo[@"build_counter"]];
    [params addKey:@"latest_build_date" value:buildInfo[@"build_date"]];
    [self personDetails:params.dictionary];
}

-(void)explodeOnTestApplicationsWithInfo:(NSDictionary *)info
{
    if (AppManagement.sh.isTestApp) {
        REMOTE_LOG(@"TEST APP GOES BOOM! %@", [info description]);
        [[Crashlytics sharedInstance] crash];
    }
}

#pragma mark - App Info
-(BOOL)checkAndReportIfAppUpdated
{
    BOOL wasUpdated = NO;
    
    // We don't care about this for test applications
    if (AppManagement.sh.isTestApp) return NO;
    
    // Production app should track update events.
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *previousBuildLaunched = [prefs stringForKey:@"previousBuildLaunched"];
    if (previousBuildLaunched && ![previousBuildLaunched isEqualToString:AppManagement.sh.applicationBuild]) {
        // Check if it was an upgrade
        if ([AppManagement.sh.applicationBuild compare:previousBuildLaunched options:NSNumericSearch] == NSOrderedDescending) {
            // A newer app build was installed. Track this event.
            HMParams *params = [HMParams new];
            [params addKey:AK_EP_CURRENT_VERSION value:AppManagement.sh.applicationBuild];
            [params addKey:AK_EP_PREVIOUS_VERSION value:previousBuildLaunched];
            [self analyticsEvent:AK_E_APP_VERSION_UPDATED info:params.dictionary];
            wasUpdated = YES;
        }
    }
    
    // Store current build as the the previousBuildLaunched
    [prefs setObject:AppManagement.sh.applicationBuild forKey:@"previousBuildLaunched"];
    [prefs synchronize];
    return wasUpdated;
}

/**
 *  Count the number of launches. Avances the count by 1 and returns the value.
 *
 *  @return NSNumber holding the number of times this method was called.
 */
-(NSNumber *)launchesCount
{
    return [self advanceCounterNamed:@"launchesCounter"];
}

/**
 *  The number of times "launchesCount" was called. (doesn't advance the count)
 *
 *  @return NSInteger holding the value of the counter.
 */
-(NSNumber *)countedLaunches
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger counter = [prefs integerForKey:@"launchesCounter"];
    return @(counter);
}

-(BOOL)isFirstLaunch
{
    return [[self countedLaunches] integerValue]<=1;
}

-(NSNumber *)sharesCount
{
    return [self advanceCounterNamed:@"sharesCounter"];
}

-(NSNumber *)advanceCounterNamed:(NSString *)counterName
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger counter = [prefs integerForKey:counterName];
    counter++;
    [prefs setValue:@(counter) forKey:counterName];
    [prefs synchronize];
    return @(counter);
}

-(NSNumber *)counterValueNamed:(NSString *)counterName
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger counter = [prefs integerForKey:counterName];
    return @(counter);
}


-(BOOL)counterExistsNamed:(NSString *)counterName
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger counter = [prefs integerForKey:counterName];
    return counter > 0;
}

-(NSString *)localizationPreference
{
    NSArray *languages = [NSLocale preferredLanguages];
    if (languages == nil) return @"unknown";
    return [languages componentsJoinedByString:@","];
}

#pragma mark - People
-(void)personIdentify
{
    NSString *identifier = UIDevice.currentDevice.identifierForVendor.UUIDString;
    [self personIdentifyWithIdentifier:identifier];
}

-(void)personIdentifyWithIdentifier:(NSString *)identifier
{
    [self.mixPanel identify:identifier];
}

-(void)reportPersonDetails
{
    NSDate *now = [NSDate date];
    
    HMParams *params = [HMParams new];
    [params addKey:AK_PD_NUMBER_OF_BECAME_ACTIVE value:[self counterValueNamed:AK_S_DID_BECOME_ACTIVE_COUNT]];
    [params addKey:AK_PD_LAST_LAUNCH_DATE value:now];
    
    [params addKey:AK_PD_DID_EVER_SHARE_USING_APP value:[self didEverCountedKey:AK_S_NUMBER_OF_SHARES_USING_APP_COUNT]];
    [params addKey:AK_PD_NUMBER_OF_SHARES_USING_APP_COUNT value:[self counterValueNamed:AK_S_NUMBER_OF_SHARES_USING_APP_COUNT]];

    [params addKey:AK_PD_DID_EVER_FINISH_A_RETAKE value:[self didEverCountedKey:AK_S_NUMBER_OF_APPROVED_RETAKES]];
    [params addKey:AK_PD_NUMBER_OF_APPROVED_RETAKES value:[self counterValueNamed:AK_S_NUMBER_OF_APPROVED_RETAKES]];

    [params addKey:AK_PD_DID_KEYBOARD_EVER_APPEAR value:[self didEverCountedKey:AK_S_NUMBER_OF_KB_APPEARANCES_COUNT]];
    [params addKey:AK_PD_NUMBER_OF_KB_APPEARANCES_COUNT value:[self counterValueNamed:AK_S_NUMBER_OF_KB_APPEARANCES_COUNT]];

    [params addKey:AK_PD_NUMBER_OF_KB_COPY_EMU_COUNT value:[self counterValueNamed:AK_S_NUMBER_OF_KB_COPY_EMU_COUNT]];
    
    [self personDetails:params.dictionary];

    if ([self isFirstLaunch]) {
        [self.mixPanel.people setOnce:@{AK_PD_FIRST_LAUNCH_DATE:now}];
    }
}

-(void)personDetails:(NSDictionary *)details
{
    [self.mixPanel.people set:details];
}

-(void)personPushToken:(NSData *)pushToken
{
    if (pushToken == nil) return;
    [self.mixPanel.people addPushDeviceToken:pushToken];
    [self personDetails:@{@"pushToken":[pushToken description]}];
}


#pragma mark - Experiments
-(void)initExperiments
{
    self.experiments = [HMExperiments new];
}

-(void)initializeExperimentsWithLaunchOptions:(NSDictionary *)launchOptions
{
    [Optimizely startOptimizelyWithAPIToken:@"AAM7hIkAjQ2O6Dtl6TfFywzCXVVjq4W5~2898251091"
                              launchOptions:launchOptions
                  experimentsLoadedCallback:^(BOOL success, NSError *error) {
                      [Optimizely activateMixpanelIntegration];
                  }];
}

-(BOOL)handleOpenURL:(NSURL *)url
{
    if([Optimizely handleOpenURL:url]) {
        return YES;
    }
    return NO;
}


-(void)experimentGoalEvent:(NSString *)eventName
{
    [Optimizely trackEvent:eventName];
}

-(BOOL)boolForKey:(NSString *)key fallbackValue:(BOOL)fallbackValue
{
    // Forced emu server tweaked value?
    NSNumber *boolNumber = [AppCFG tweakedNumber:key];
    if (boolNumber) return [boolNumber boolValue];
    
    // Optimizely live variables.
    OptimizelyVariableKey *opKey = self.experiments.opKeysByString[key];
    if (opKey) return [Optimizely boolForKey:opKey];

    // Nope. So use the passed fallback value instead.
    return fallbackValue;
}

-(NSNumber *)numberForKey:(NSString *)key fallbackValue:(NSNumber *)fallbackValue
{
    // Forced emu server tweaked value?
    NSNumber *number = [AppCFG tweakedNumber:key];
    if (number) return number;

    // Optimizely live variables.
    OptimizelyVariableKey *opKey = self.experiments.opKeysByString[key];
    if (opKey) return [Optimizely numberForKey:opKey];

    // Nope. So use the passed fallback value instead.
    return fallbackValue;
}


-(NSString *)stringForKey:(NSString *)key fallbackValue:(NSString *)fallbackValue
{
    // Forced emu server tweaked value?
    NSString *str = [AppCFG tweakedString:key];
    if (str) return str;
    
    // Optimizely live variables.
    OptimizelyVariableKey *opKey = self.experiments.opKeysByString[key];
    if (opKey &&
        [Optimizely stringForKey:opKey] &&
        [[Optimizely stringForKey:opKey] length]>0) {
        // A non empty string defined. Return it.
        return [Optimizely stringForKey:opKey];
    }
    
    // Nope. So use the passed fallback value instead.
    return fallbackValue;
}


-(NSArray *)listForKey:(NSString *)key fallbackValue:(NSArray *)fallbackValue
{
    // Forced emu server tweaked value?
    NSString *str = [AppCFG tweakedString:key];
    if (str) return [self listFromString:str];

    // Optimizely live variables.
    OptimizelyVariableKey *opKey = self.experiments.opKeysByString[key];
    if (opKey) return [self listFromString:[Optimizely stringForKey:opKey]];
    
    // Nope. So use the passed fallback value instead.
    return fallbackValue;
}

-(NSArray *)listFromString:(NSString *)str
{
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (str.length == 0) return nil;
    NSArray *list = [str componentsSeparatedByString:@","];
    return list;
}


@end
