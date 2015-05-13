//
//  EMEmuticonParser.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMParser.h"

@class Package;

@interface EMEmuticonParser : HMParser

/**
 *  EmuticonDefs can only be parsed in a context of the package
 *  they are related to. package must be set or parsing will fail.
 */
@property (nonatomic) Package *package;

/**
 *  Order value passed from the parent parser (optional)
 */
@property (nonatomic) NSNumber *incrementalOrder;


/**
 *  Order value in mixed screen passed from the parent parser (optional)
 */
@property (nonatomic) NSNumber *mixedScreenOrder;


/**
 *  A dictionary containing default values for missing key-value pairs.
 */
@property (nonatomic) NSDictionary *defaults;


@end
