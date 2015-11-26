//
//  testRenderManager.m
//  emu
//
//  Created by Aviv Wolf on 6/15/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMRenderManager2.h"
#import "EMDB.h"

@interface EmuRenderManagerTests : XCTestCase

@end

@implementation EmuRenderManagerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

-(void)testRenderQueueOfEmusWithAvailableLocalResources
{
    EMDB *db = [EMDB new];
    [db initFakeDBNamed:@"gaga"];
    
    NSError *error;
    [db deleteStoreWithError:&error];
}


@end
