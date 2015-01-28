//
//  NSNotification+Utils.h
//  Homage
//
//  Created by Aviv Wolf on 1/17/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotification (Utils)

@property (readonly, nonatomic) BOOL isReportingError;
@property (readonly, nonatomic) NSError *reportedError;

@end
