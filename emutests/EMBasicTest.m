//
//  EMBasicTest.m
//  emu
//
//  Created by Aviv Wolf on 25/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AWSCore/AWSCore.h>

@interface EMBasicTest : XCTestCase

@end

@implementation EMBasicTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
