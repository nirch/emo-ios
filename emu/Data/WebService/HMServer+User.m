//
//  HMServer+User.m
//  emu
//
//  Created by Aviv Wolf on 30/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "HMServer+User.h"
#import "EMUserParser.h"
#import "EMNotificationCenter.h"

@implementation HMServer (User)

-(void)signInUserWithPushToken:(NSString *)pushToken
{
    UIDevice *device = UIDevice.currentDevice;
    
    HMParams *params = [HMParams new];
    [params addKey:@"serial" valueIfNotNil:device.identifierForVendor.UUIDString];
    [params addKey:@"model" valueIfNotNil:device.model];
    [params addKey:@"device_name" valueIfNotNil:device.name];
    [params addKey:@"system_name" valueIfNotNil:device.systemName];
    [params addKey:@"system_version" valueIfNotNil:device.systemVersion];
    [params addKey:@"push_token" valueIfNotNil:pushToken];
    
    [self postRelativeURLNamed:@"user"
                    parameters:params.dictionary
              notificationName:emkUserSignedIn
                          info:nil
                        parser:[EMUserParser new]];
}

@end
