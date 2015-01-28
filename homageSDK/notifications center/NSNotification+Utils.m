//
//  NSNotification+Utils.m
//  Homage
//
//  Created by Aviv Wolf on 1/17/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "NSNotification+Utils.h"

@implementation NSNotification (Utils)

-(BOOL)isReportingError
{
    if ([self reportedError]) return YES;
    return NO;
}

-(NSError *)reportedError
{
    NSError *error = self.userInfo[@"error"];
    if ([error isKindOfClass:[NSError class]]) return error;
    return nil;
}

@end
