//
//  HMServer.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//
#define TAG @"HMServer"

#import "HMServer.h"
#import "HMParser.h"
#import "HMJSONResponseSerializerWithData.h"
#import "HMPanel.h"
#import "AppManagement.h"

@interface HMServer()

@property (strong, nonatomic) NSMutableDictionary *cfg;
@property (strong, nonatomic) NSString *defaultsFileName;
@property (strong,nonatomic) NSDictionary *context;
@property (strong,nonatomic) NSString *appVersionInfo;
@property (strong,nonatomic) NSString *appBuildInfo;
@property (strong,nonatomic) NSString *currentUserID;

@property (strong, nonatomic, readwrite) NSURL *serverURL;
@property (nonatomic) BOOL usingPublicDataBase;

@end

@implementation HMServer

@synthesize configurationInfo = _configurationInfo;

#pragma mark - Initialization
-(id)init
{
    self = [super init];
    if (self) {
        self.usingPublicDataBase = YES;
        [self loadCFG];
        [self loadAppDetails];
        [self initSessionManager];
        self.urlsCachedInfo = [NSCache new];
    }
    return self;
}

-(void)initSessionManager
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [[AFHTTPSessionManager alloc] initWithBaseURL:self.serverURL sessionConfiguration:configuration];
    
    self.session.responseSerializer = [HMJSONResponseSerializerWithData new];
    self.session.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html",@"application/json"]];

}

-(void)chooseSerializerForParser:(HMParser *)parser
{
    self.session.requestSerializer = [AFHTTPRequestSerializer new];
    
    // Add app information to the headers.
    [self.session.requestSerializer setValue:self.appBuildInfo forHTTPHeaderField:@"APP_BUILD_INFO"];
    [self.session.requestSerializer setValue:self.appVersionInfo forHTTPHeaderField:@"APP_VERSION_INFO"];
    [self.session.requestSerializer setValue:@"Emu iOS" forHTTPHeaderField:@"APP_CLIENT_NAME"];
    
    // Using public database or just the scratchpad?
    if (self.usingPublicDataBase == NO) {
        [self.session.requestSerializer setValue:@"true" forHTTPHeaderField:@"SCRATCHPAD"];
    }
    
    // Is user sampled (or was sampled) by the server?
    if ([AppManagement.sh userSampledByServer]) {
        [self.session.requestSerializer setValue:@"true" forHTTPHeaderField:@"USER_SAMPLED_BY_SERVER"];
    }
    
    // Add homage's internal application identifier
    NSString *applicationIdentifier = self.configurationInfo[@"application"];
    if (applicationIdentifier) {
        [NSString stringWithFormat:@"Homage:%@", applicationIdentifier];
        [self.session.requestSerializer setValue:applicationIdentifier forHTTPHeaderField:@"HOMAGE_CLIENT"];
    }
    
    // Add current user id to the headers (if set)
    if (self.currentUserID) {
         [self.session.requestSerializer setValue:self.currentUserID forHTTPHeaderField:@"USER_ID"];
    }
    
    // Localization
    [self.session.requestSerializer setValue:AppManagement.sh.prefferedLanguages forHTTPHeaderField:@"Accept-Language"];
    
    // Set the session response serializer and set the acceptable content types
    self.session.responseSerializer = [HMJSONResponseSerializerWithData new];
    self.session.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html",@"application/json"]];
}

#pragma mark - URL named
-(NSString *)absoluteURLNamed:(NSString *)urlName
{
    NSString *url = self.cfg[@"urls"][urlName];
    if (!url) return nil;
    // Must start with http:// or https://
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) return url;
    return nil;
}

-(NSString *)relativeURLNamed:(NSString *)relativeURLName
{
    NSString *relativeURL = self.cfg[@"urls"][relativeURLName];
    return relativeURL;
}

-(NSString *)relativeURLNamed:(NSString *)relativeURLName withSuffix:(NSString *)suffix
{
    NSString *relativeURL = self.cfg[@"urls"][relativeURLName];
    relativeURL = [NSString stringWithFormat:@"%@/%@", relativeURL, suffix];
    return relativeURL;
}

#pragma mark - provide server woth request context
-(void)chooseCurrentUserID:(NSString *)userID
{
    self.currentUserID = userID;
}

-(void)storeFetchedConfiguration:(NSDictionary *)info
{
    // Store in local storage for future use.
    [[NSUserDefaults standardUserDefaults] setValue:info forKey:@"config"];
    
    // Also update the configuration in memory.
    NSMutableDictionary *cfg = [NSMutableDictionary dictionaryWithDictionary:[self configurationInfo]];
    [cfg addEntriesFromDictionary:info];
    _configurationInfo = cfg;
}

-(NSDictionary *)configurationInfo
{
    // If in memory, return configuration from memory.
    if (_configurationInfo) return _configurationInfo;
    
    // Not in memory. Load hard coded defaults from app bundle.
    NSMutableDictionary *configuration;
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:self.defaultsFileName ofType:@"plist"];
    configuration = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];

    // Update with defaults specific to label (if defined)
    NSString *labelDefaultsFile = [NSString stringWithFormat:@"Label%@", self.defaultsFileName];
    plistPath = [[NSBundle mainBundle] pathForResource:labelDefaultsFile ofType:@"plist"];
    [configuration addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:plistPath]];
    
    // After loading defaults, override values stored in local storage.
    // (The values stored in local storage are values fetched from the server in the past)
    NSDictionary *storedValues = [[NSUserDefaults standardUserDefaults] valueForKey:@"config"];
    if (storedValues) {
        [configuration addEntriesFromDictionary:storedValues];
    }
    
    // Return the configuration info dictionary (and store it in memory).
    _configurationInfo = configuration;
    return _configurationInfo;
}

-(void)loadAppDetails
{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.appBuildInfo = appBuildString;
    self.appVersionInfo = appVersionString;
}

-(NSDictionary *)addAppDetailsToDictionary:(NSDictionary *)dict
{
    NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
    [tmpDict setValue:self.context forKey:@"app_info"];
    NSDictionary *newDict = [NSDictionary dictionaryWithDictionary:tmpDict];
    return newDict;
}

#pragma mark - Server CFG
-(void)loadCFG
{
    //
    // Loads networking info from the ServerCFG.plist file.
    //
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"ServerCFG" ofType:@"plist"];
    self.cfg = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    
    // Init the server NSURL
    NSString *port;
    NSString *protocol;
    NSString *host;

    if (AppManagement.sh.isDevApp) {
        
        //
        // In development application.
        // Use only the test servers.
        // Hardcoded choice if to use scratchpad or public data while developing.
        //
        port =      self.cfg[@"dev_port"];
        protocol =  self.cfg[@"dev_protocol"];
        host =      self.cfg[@"dev_host"];
        self.usingPublicDataBase = YES;
        
    } else {

        //
        // Production or test application.
        // Use production server.
        // Test app builds will work with the SCRATCHPAD data.
        //
        port =      self.cfg[@"prod_port"];
        protocol =  self.cfg[@"prod_protocol"];
        host =      self.cfg[@"prod_host"];
        self.usingPublicDataBase = !AppManagement.sh.isTestApp;
        
    }
    
    if (port) {
        _serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@", protocol, host, port]];
    } else {
        _serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", protocol, host]];
    }
    HMLOG(TAG, EM_DBG, @"Server url: %@", _serverURL);
}

#pragma mark - GET requests
// The most basic GET request
-(void)getRelativeURLNamed:(NSString *)relativeURLName
                parameters:(NSDictionary *)parameters
          notificationName:(NSString *)notificationName
                      info:(NSDictionary *)info
                    parser:(HMParser *)parser
{
    
    
    
    [self getRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
              parameters:(NSDictionary *)parameters
        notificationName:(NSString *)notificationName
                    info:(NSDictionary *)info
                  parser:(HMParser *)parser];
}



// The most basic GET request
-(void)getRelativeURL:(NSString *)relativeURL
           parameters:(NSDictionary *)parameters
     notificationName:(NSString *)notificationName
                 info:(NSDictionary *)info
               parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    if (!moreInfo) {
        moreInfo = [NSMutableDictionary new];
    }
    
    
    //
    // send GET Request to server
    //
    #if defined(DEBUG)
    NSDate *requestDateTime = [NSDate date];
    HMLOG(TAG, EM_DBG, @"GET request:%@/%@", self.session.baseURL, relativeURL);
    #endif
    
    [self chooseSerializerForParser:parser];
    
    [self.session GET:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

        //
        // Successful response from server.
        //
        HMLOG(TAG, EM_DBG, @"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
    
        if (parser) {
            //
            // Parse response.
            //
            parser.objectToParse = responseObject;
            parser.parseInfo = moreInfo;
            [parser parse];
            if (parser.error) {

                //
                // Parser error.
                //
                HMLOG(TAG, EM_DBG, @"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                [moreInfo addEntriesFromDictionary:@{@"error":parser.error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                return;
                
            }
        }
        
        //
        // Successful request and parsing.
        //
        [moreInfo addEntriesFromDictionary:parser.parseInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];

    
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //
        // Failed request.
        //
        HMLOG(TAG, EM_DBG, @"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    }];
}

#pragma mark - POST requests
// The most basic POST request
-(void)postRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser
{
    
    NSMutableDictionary *moreInfo = [info mutableCopy];    
    [self postRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
               parameters:(NSDictionary *)parameters
         notificationName:(NSString *)notificationName
                     info:(NSDictionary *)moreInfo
                   parser:(HMParser *)parser];
}

// The most basic POST request
-(void)postRelativeURL:(NSString *)relativeURL
            parameters:(NSDictionary *)parameters
      notificationName:(NSString *)notificationName
                  info:(NSDictionary *)info
                parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    //
    // send POST Request to server
    //
    #if defined(DEBUG)
    NSDate *requestDateTime = [NSDate date];
    HMLOG(TAG, EM_DBG, @"POST request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    #endif
    
    [self chooseSerializerForParser:parser];
    [self.session POST:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //
        // Successful response from server.
        //
        HMLOG(TAG, EM_DBG, @"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
        
        if (parser) {
            //
            // Parse response.
            //
            parser.objectToParse = responseObject;
            parser.parseInfo = moreInfo;
            [parser parse];
            if (parser.error) {
                
                //
                // Parser error.
                //
                HMLOG(TAG, EM_DBG, @"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                [moreInfo addEntriesFromDictionary:@{@"error":parser.error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                return;

            }
        }
        
        [moreInfo addEntriesFromDictionary:parser.parseInfo];
        
        //
        // Successful request and parsing.
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        //
        // Failed request.
        //
        HMLOG(TAG, EM_DBG, @"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
    }];
}

#pragma mark - DELETE requests
// The most basic DELETE request
-(void)deleteRelativeURLNamed:(NSString *)relativeURLName
                   parameters:(NSDictionary *)parameters
             notificationName:(NSString *)notificationName
                         info:(NSDictionary *)info
                       parser:(HMParser *)parser
{
    [self deleteRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser];
}

// The most basic DELETE request
-(void)deleteRelativeURL:(NSString *)relativeURL
              parameters:(NSDictionary *)parameters
        notificationName:(NSString *)notificationName
                    info:(NSDictionary *)info
                  parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    //
    // send DELETE Request to server
    //
    #if defined(DEBUG)
    NSDate *requestDateTime = [NSDate date];
    HMLOG(TAG, EM_DBG, @"DELETE request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    #endif
    
    [self chooseSerializerForParser:parser];
    [self.session DELETE:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //
        // Successful response from server.
        //
        HMLOG(TAG, EM_DBG, @"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
        HMLOG(TAG, EM_DBG, @"Response:%@", responseObject);
        if (parser) {
            //
            // Parse response.
            //
            parser.objectToParse = responseObject;
            parser.parseInfo = moreInfo;
            [parser parse];
            if (parser.error) {
                
                //
                // Parser error.
                //
                HMLOG(TAG, EM_DBG, @"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                [moreInfo addEntriesFromDictionary:@{@"error":parser.error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                return;
                
            }
        }
        
        //
        // Successful request and parsing.
        //
        [moreInfo addEntriesFromDictionary:parser.parseInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //
        // Failed request.
        //
        HMLOG(TAG, EM_DBG, @"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    }];
}


// The most basic PUT request
-(void)putRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser
{
    [self putRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
               parameters:(NSDictionary *)parameters
         notificationName:(NSString *)notificationName
                     info:(NSDictionary *)info
                   parser:(HMParser *)parser];
}


// The most basic PUT request
-(void)putRelativeURL:(NSString *)relativeURL
            parameters:(NSDictionary *)parameters
      notificationName:(NSString *)notificationName
                  info:(NSDictionary *)info
                parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    //
    // send PUT Request to server
    //
    #if defined(DEBUG)
    NSDate *requestDateTime = [NSDate date];
    HMLOG(TAG, EM_DBG, @"PUT request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    #endif
    
    [self chooseSerializerForParser:parser];
    [self.session PUT:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //
        // Successful response from server.
        //
        HMLOG(TAG, EM_DBG, @"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
        
        if (parser) {
            //
            // Parse response.
            //
            parser.objectToParse = responseObject;
            parser.parseInfo = moreInfo;
            [parser parse];
            if (parser.error) {
                
                //
                // Parser error.
                //
                HMLOG(TAG, EM_DBG, @"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                [moreInfo addEntriesFromDictionary:@{@"error":parser.error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                return;
                
            }
        }
        
        [moreInfo addEntriesFromDictionary:parser.parseInfo];
        
        //
        // Successful request and parsing.
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //
        // Failed request.
        //
        HMLOG(TAG, EM_DBG, @"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    }];
}

@end
