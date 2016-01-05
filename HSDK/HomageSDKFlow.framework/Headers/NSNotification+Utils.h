//
//  NSNotification+Utils.h
//  Homage
//
//  Created by Aviv Wolf on 1/17/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  A utils category on NSNotification.
 */
@interface NSNotification (Utils)

/**
 *  BOOL YES if reportedError is not nil.
 */
@property (readonly, nonatomic) BOOL isReportingError;

/**
 *  May contain some reported NSError (or nil if no error reported)
 */
@property (readonly, nonatomic) NSError *reportedError;

@end
