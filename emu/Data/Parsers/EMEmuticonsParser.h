//
//  EMEmuticonsParser.h
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMParser.h"

@class Package;

@interface EMEmuticonsParser : HMParser

/**
 *  EmuticonDefs can only be parsed in a context of the package
 *  they are related to. package must be set or parsing will fail.
 */
@property (nonatomic) Package *package;

@end
