//
//  EmuParsersTests.m
//  emu
//
//  Created by Aviv Wolf on 6/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMDB.h"
#import "EMPackagesParser.h"

@interface EmuParsersTests : XCTestCase

@end

@implementation EmuParsersTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - tests
-(void)testParsePackages
{
    EMDB *db = [self fakeDB];
    NSDictionary *info = [self jsonData];
    EMPackagesParser *parser = [[EMPackagesParser alloc] initWithContext:db.context];
    parser.objectToParse = info;
    [parser parse];
    
    NSArray *packages = [Package allPackagesPrioritizedInContext:db.context];
    NSInteger expectedPackagesCount = 22;
    XCTAssertNotNil(packages, @"No packages. Parsing failed?");
    XCTAssert(packages.count == expectedPackagesCount, @"Expected %@ packages. Got %@ instead.", @(expectedPackagesCount), @(packages.count));
    
    // Iterate the packages
    for (Package *package in packages) {
        XCTAssertNotNil(package.name, @"Missing package name");
        XCTAssertNotNil(package.label, @"Missing package label");
        
        // Iterate emu defs in package
        XCTAssert(package.emuDefs.count == 6, @"Expected 6 pack. %@ emus defined in pack %@.", @(package.emuDefs.count), package.name);
        for (EmuticonDef *emuDef in package.emuDefs) {
            XCTAssertNotNil(emuDef.name, @"Missing emu def name");
            XCTAssertNotNil(emuDef.sourceBackLayer, @"Missing emu def backlayer: %@", emuDef.name);
        }
    }
}

-(void)testParsingPerformance
{
    EMDB *db = [self fakeDB];
    NSDictionary *info = [self jsonData];
    [self measureBlock:^{
        EMPackagesParser *parser = [[EMPackagesParser alloc] initWithContext:db.context];
        parser.objectToParse = info;
        [parser parse];
    }];
}

#pragma mark - Helpers
-(EMDB *)fakeDB
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *fakeDBName = [NSString stringWithFormat:@"testdb%@", uuid];
    EMDB *db = [EMDB new];
    [db initFakeDBNamed:fakeDBName];
    return db;
}

-(NSDictionary *)jsonData
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *filePath = [bundle pathForResource:@"packages_data_for_tests" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    XCTAssert(data, @"Missing data to parse.");
    
    NSError *error;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssert(info, @"Failed parsing JSON file: %@", [error localizedDescription]);
    return info;
}




@end
