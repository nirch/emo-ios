//
//  AppManagement
//  emu
//
//  Created by Aviv Wolf on 3/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "AppManagement.h"
#import "EMDB.h"
#import <sys/utsname.h>
#import <RegExCategories.h>

@interface AppManagement()

/*
 Build:
 
 with .d suffix - considered a test application and a dev application.
 with .t suffix - considered a test application.
 without suffix - considered a production application.
 
 */
@property (nonatomic) BOOL isBuildOfTestApplication;
@property (nonatomic) BOOL isBuildOfDevelopmentApplication;

@property (nonatomic) NSDictionary *serverSideLocalizationString;

@end

@implementation AppManagement

@synthesize ioQueue = _ioQueue;
@synthesize prefferedLanguages = _prefferedLanguages;
@synthesize resourcesScaleString = _resourcesScaleString;

#pragma mark - Initialization
// A singleton
+(AppManagement *)sharedInstance
{
    static AppManagement *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppManagement alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(AppManagement *)sh
{
    return [AppManagement sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        // Build version string
        [self initBuildInfo];
    }
    return self;
}

#pragma mark - Info
-(BOOL)isTestApp
{
    return self.isBuildOfTestApplication;
}

-(BOOL)isDevApp
{
    return self.isBuildOfDevelopmentApplication;
}

-(BOOL)userSampledByServer
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSDictionary *info = appCFG.uploadUserContent;
    if (info == nil || info[@"enabled"] == nil) return NO;
    return [info[@"enabled"] boolValue];
}

-(void)initBuildInfo
{
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    self.applicationBuild = [[self trimmedString:build] uppercaseString];
    self.isBuildOfTestApplication = [self.applicationBuild hasSuffix:@"T"] || [self.applicationBuild hasSuffix:@"D"];
    self.isBuildOfDevelopmentApplication = [self.applicationBuild hasSuffix:@"D"];
}

-(NSString *)trimmedString:(NSString *)str
{
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


#pragma mark - Queues
-(dispatch_queue_t)ioQueue
{
    if (_ioQueue) return _ioQueue;
    _ioQueue = dispatch_queue_create("io Queue", DISPATCH_QUEUE_SERIAL);
    return _ioQueue;
}

/**
 *  Will try to recognise the generation of the device.
 *  will return nil if unrecognised (or unimportant)
 *  (return nil on iPhone simulator or iPad simulator)
 *
 *  @return NSNumber with the detected device generation (or nil)
 */
+(NSNumber *)deviceGeneration
{
    NSString *name = machineName();
    if (![name isMatch:RX(@"(iPhone|iPod|iPad).*")]) return nil;
    
    NSArray *matches = [name matchesWithDetails:RX(@"^(iPhone|iPod|iPad)(\\d+)?,(\\d+)$")];
    if (matches.count < 1) return nil;
    
    RxMatch *match = matches[0];
    RxMatchGroup *m = match.groups[2];
    NSString *numStr = m.value;
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *num = [f numberFromString:numStr];
    return num;
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

#pragma mark - device specific info
-(NSString *)resourcesScaleString
{
    if (_resourcesScaleString) return _resourcesScaleString;
    NSInteger screenScale = [[UIScreen mainScreen] scale];
    _resourcesScaleString = [SF:@"@%@x", @(screenScale)];
    return _resourcesScaleString;
}

#pragma mark - Localization
-(NSString *)prefferedLanguages
{
    if (_prefferedLanguages) return _prefferedLanguages;    
    NSArray *languages = [NSLocale preferredLanguages];
    if (languages == nil) languages = @[@"en"];
    _prefferedLanguages = [languages componentsJoinedByString:@","];
    return _prefferedLanguages;
}

-(NSString *)serverSideLocalizedString:(NSString *)stringKey defaultValue:(NSString *)defaultValue
{
    NSString *string = self.serverSideLocalizationString[stringKey];
    if (string == nil) return defaultValue;
    return string;
}

-(void)updateLocalizedStrings
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    _serverSideLocalizationString = appCFG.localization;
}

@end
