//
//  HMServer.h
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@class HMParser;

#define ERROR_DOMAIN_NETWORK @"Network error"

typedef NS_ENUM(NSInteger, HMNetworkErrorCode) {
    HMNetworkErrorMissingURL,
    HMNetworkErrorGetRequestFailed,
    HMNetworkErrorPostRequestFailed,
    HMNetworkErrorDeleteRequestFailed,
    HMNetworkErrorImageLoadingFailed
};


@interface HMServer : NSObject

// Cache urls
@property (nonatomic) NSCache *urlsCachedInfo;

// HTTP session manager
@property (strong, nonatomic, readonly) AFHTTPSessionManager *session;

// Status
@property (nonatomic) NSString *connectionLabel;

// More info
@property (strong,nonatomic, readonly) NSDictionary *configurationInfo;

@property (strong, nonatomic, readonly) NSURL *serverURL;
@property (nonatomic, readonly) BOOL usingPublicDataBase;


#pragma mark - URL named
-(NSString *)absoluteURLNamed:(NSString *)urlName;
-(NSString *)relativeURLNamed:(NSString *)urlName;
-(NSString *)relativeURLNamed:(NSString *)relativeURLName withSuffix:(NSString *)suffix;

#pragma mark - provide server with request context
//-(void)chooseCurrentUserID:(NSString *)userID;
-(void)storeFetchedConfiguration:(NSDictionary *)info;

#pragma mark - GET requests
///
/**
*  A simple HTTP GET request with a name of the URL.
*   @code
[self getRelativeURLNamed:@"stories"
               parameters:nil
         notificationName:HM_NOTIFICATION_SERVER_STORIES
                   parser:[HMStoriesParser new]
];
*   @endcode
*  @param relativeURLName  The name of the wanted url (defined in ServerCFG.plist)
*  @param parameters       A dictionary of key,value parameters for the GET request. (optional)
*  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
*  @param parser           An HMParser instance that will parse the response from the server.
*/
-(void)getRelativeURLNamed:(NSString *)relativeURLName
                parameters:(NSDictionary *)parameters
          notificationName:(NSString *)notificationName
                      info:(NSDictionary *)info
                    parser:(HMParser *)parser;


///
/**
 *  A simple HTTP GET request with a relative URL.
 *  @code
[self getRelativeURL:@"someurl/example"
          parameters:nil
    notificationName:HM_NOTIFICATION_SERVER_EXAMPLE
              parser:[HMSomeParser new]
];
 *  @endcode
 *  @param relativeURL      The relative url (Relative to the host defined in ServerCFG.plist)
 *  @param parameters       A dictionary of key,value parameters for the GET request. (optional)
 *  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
 *  @param parser           An HMParser instance that will parse the response from the server.
 */
-(void)getRelativeURL:(NSString *)relativeURL
           parameters:(NSDictionary *)parameters
     notificationName:(NSString *)notificationName
                 info:(NSDictionary *)info
               parser:(HMParser *)parser;

#pragma mark - POST requests
///
/**
 *  A simple HTTP POST request with a name of the URL.
 *  @code
    [self postRelativeURLNamed:@"remake"
                    parameters:@{@"story_id":storyID, @"user_id":userID}
              notificationName:HM_NOTIFICATION_SERVER_NEW_REMAKE
                        parser:[HMRemakeParser new]
    ];
 *  @endcode
 *  @param relativeURLName  The name of the wanted url (defined in ServerCFG.plist)
 *  @param parameters       A dictionary of key,value parameters for the POST request. (optional)
 *  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
 *  @param parser           An HMParser instance that will parse the response from the server.
 */
-(void)postRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser;

///
/**
 *  A simple HTTP POST request with a relative URL.
 *  @code
    [self postRelativeURL:@"someurl/example"
               parameters:@{@"story_id":storyID, @"user_id":userID}
         notificationName:HM_NOTIFICATION_SERVER_SOME_EXAMPLE
                   parser:[HMSomeParser new]
    ];
 *  @endcode
 *  @param relativeURL      The relative url (Relative to the host defined in ServerCFG.plist)
 *  @param parameters       A dictionary of key,value parameters for the POST request. (optional)
 *  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
 *  @param parser           An HMParser instance that will parse the response from the server.
 */
-(void)postRelativeURL:(NSString *)relativeURL
            parameters:(NSDictionary *)parameters
      notificationName:(NSString *)notificationName
                  info:(NSDictionary *)info
                parser:(HMParser *)parser;


#pragma mark - DELETE requests
///
/**
 *  A simple HTTP DELETE request with a name of the URL.
 *  @code
[self deleteRelativeURLNamed:@"delete remake"
                  parameters:@{@"remake_id":remakeID}
            notificationName:HM_NOTIFICATION_SERVER_REMAKE_DELETION
                      parser:[???]
];
 *  @endcode
 *  @param relativeURLName  The name of the wanted url (defined in ServerCFG.plist)
 *  @param parameters       A dictionary of key,value parameters for the DELETE request. (optional)
 *  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
 *  @param parser           An HMParser instance that will parse the response from the server.
 */
-(void)deleteRelativeURLNamed:(NSString *)relativeURLName
                   parameters:(NSDictionary *)parameters
             notificationName:(NSString *)notificationName
                         info:(NSDictionary *)info
                       parser:(HMParser *)parser;


///
/**
 *  A simple HTTP DELETE request with a relative URL.
 *  @code
[self deleteRelativeURL:@"remake"
             parameters:@{@"remake_id":remakeID}
       notificationName:HM_NOTIFICATION_SERVER_REMAKE_DELETION
                 parser:[???]
];
 *  @endcode
 *  @param relativeURL      The relative url (Relative to the host defined in ServerCFG.plist)
 *  @param parameters       A dictionary of key,value parameters for the DELETE request. (optional)
 *  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
 *  @param parser           An HMParser instance that will parse the response from the server.
 */
-(void)deleteRelativeURL:(NSString *)relativeURL
              parameters:(NSDictionary *)parameters
        notificationName:(NSString *)notificationName
                    info:(NSDictionary *)info
                  parser:(HMParser *)parser;


///
/**
 *  A simple HTTP PUT request with a name of the URL.
 *  @code
 [self putRelativeURLNamed:@"remake"
 parameters:@{@"story_id":storyID, @"user_id":userID}
 notificationName:HM_NOTIFICATION_SERVER_NEW_REMAKE
 parser:[HMRemakeParser new]
 ];
 *  @endcode
 *  @param relativeURLName  The name of the wanted url (defined in ServerCFG.plist)
 *  @param parameters       A dictionary of key,value parameters for the PUT request. (optional)
 *  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
 *  @param parser           An HMParser instance that will parse the response from the server.
 */
-(void)putRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser;

///
/**
 *  A simple HTTP PUT request with a relative URL.
 *  @code
 [self putRelativeURL:@"someurl/example"
 parameters:@{@"story_id":storyID, @"user_id":userID}
 notificationName:HM_NOTIFICATION_SERVER_SOME_EXAMPLE
 parser:[HMSomeParser new]
 ];
 *  @endcode
 *  @param relativeURL      The relative url (Relative to the host defined in ServerCFG.plist)
 *  @param parameters       A dictionary of key,value parameters for the PUT request. (optional)
 *  @param notificationName The name of the notification posted with notification center, when the request+parsing are done (with an error or successfully).
 *  @param parser           An HMParser instance that will parse the response from the server.
 */
-(void)putRelativeURL:(NSString *)relativeURL
            parameters:(NSDictionary *)parameters
      notificationName:(NSString *)notificationName
                  info:(NSDictionary *)info
                parser:(HMParser *)parser;






@end
