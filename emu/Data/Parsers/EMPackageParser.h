//
//  EMPackageParser.h
//  emu
//
//  Created by Aviv Wolf on 2/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMParser.h"

@interface EMPackageParser : HMParser

//@property (nonatomic) NSNumber *incrementalOrder;
@property (nonatomic) BOOL parseForOnboarding;
@property (nonatomic) NSDictionary *mixedScreenPriorities;
//@property (nonatomic) NSDictionary *packagesPriorities;
//@property (nonatomic) NSTimeInterval now;

@end
