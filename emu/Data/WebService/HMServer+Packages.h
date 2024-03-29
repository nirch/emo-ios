//
//  HMServer+Packages.h
//  emu
//
//  Created by Aviv Wolf on 3/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Packages)

-(void)fetchPackagesFullInfoWithInfo:(NSDictionary *)info;
-(void)fetchPackagesUpdatesSince:(NSNumber *)timestamp withInfo:(NSDictionary *)info;
-(void)unhideUsingCode:(NSString *)code withInfo:(NSDictionary *)info;

@end
