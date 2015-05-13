//
//  main.m
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        BOOL runningTests = NSClassFromString(@"XCTestCase") != nil;
        if(!runningTests)
        {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
        else
        {
            return UIApplicationMain(argc, argv, nil, @"EmuTestsAppDelegate");
        }
    }
}
