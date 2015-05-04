//
//  emutests.m
//  emutests
//
//  Created by Aviv Wolf on 5/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EMUniquenessTester.h"

@interface EmuWebserviceIntegrationTests : XCTestCase

@end

/**
 *  Integration tests with the web service.
 *  Downloads and tests the correctness of the data received
 *  from the server side API.
 */
@implementation EmuWebserviceIntegrationTests

static NSString *_url;
static NSDictionary *_json;
static BOOL _useScratchpad;

+(void)setUp
{
    [super setUp];
    _url = @"http://app.emu.im/emuapi/packages/full";
    _useScratchpad = NO;
}

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}


#pragma mark - General data tests

/**
 *  Make sure the data was downloaded and available locally.
 */
-(void)ensureDataAvailable
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"public data available"];
    if (_json == nil) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url]];
        
        if (_useScratchpad) {
            [request setValue:@"true" forHTTPHeaderField:@"SCRATCHPAD"];
        }

        NSError *error = nil;
        NSURLResponse* response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        XCTAssert(data);
        _json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) XCTFail(@"JSON parse error: %@", error);
        XCTAssert([_json isKindOfClass:[NSDictionary class]], @"Data expected to be dictionary");
    }
    [expectation fulfill];
}


/**
 *  Parsed data exists?
 */
-(void)testData
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];
    
    // Ensure json data is available.
    XCTAssertNotNil(_json);
}

#pragma mark - Packs & Emus
/**
 *  Check the string format of all names of packs and emus in the data.
 */
-(void)testAllNamesFormat
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    NSString *nameFormat = @"^[a-z0-9\\-]+$";
    NSPredicate *regMatch = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameFormat];
    NSArray *packs = _json[@"packages"];
    XCTAssertNotNil(packs, @"No packs?");
    for (NSDictionary *pack in packs) {
        NSString *name = pack[@"name"];
        XCTAssertNotNil(name, @"Pack name is nil?");
        if (![regMatch evaluateWithObject:name]) {
            XCTFail(@"Wrong name used for pack:%@ format:%@", name, nameFormat);
        }
        
        // Check the emus names
        NSArray *emus = pack[@"emuticons"];
        XCTAssertNotNil(emus, @"No emus?");
        for (NSDictionary *emu in emus) {
            NSString *name = emu[@"name"];
            XCTAssertNotNil(name, @"Emu name is nil?");
            if (![regMatch evaluateWithObject:name]) {
                XCTFail(@"Wrong name used for emu:%@ format:%@", name, nameFormat);
            }
        }
    }
}


/**
 *  Checks that all objects in the system have unique identifiers.
 */
-(void)testAllUniqueKeys
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];
    
    NSString *errorMessage = nil;
    EMUniquenessTester *ut = [EMUniquenessTester new];

    errorMessage = [ut testIdentifier:_json[@"_id"]];
    if (errorMessage) XCTFail(@"Fail: %@", errorMessage);
    
    NSArray *packs = _json[@"packages"];
    for (NSDictionary *pack in packs) {
        errorMessage = [ut testIdentifier:pack[@"_id"]];
        if (errorMessage) XCTFail(@"Fail pack id: %@", errorMessage);
        
        NSArray *emus = pack[@"emuticons"];
        for (NSDictionary *emu in emus) {
            errorMessage = [ut testIdentifier:emu[@"_id"]];
            if (errorMessage) XCTFail(@"Fail emu id: %@", errorMessage);
        }
    }
}


/**
 *  Test that all names of objects in the system are unique.
 */
-(void)testAllUniqueNames
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    // Packs names uniqueness
    NSString *errorMessage = nil;
    EMUniquenessTester *ut = [EMUniquenessTester new];
    NSArray *packs = _json[@"packages"];
    for (NSDictionary *pack in packs) {
        errorMessage = [ut testIdentifier:pack[@"name"]];
        if (errorMessage) XCTFail(@"Fail pack name: %@", errorMessage);
    }
    
    // Emus names uniqueness
    ut = [EMUniquenessTester new];
    for (NSDictionary *pack in packs) {
        NSArray *emus = pack[@"emuticons"];
        for (NSDictionary *emu in emus) {
            errorMessage = [ut testIdentifier:emu[@"name"]];
            if (errorMessage) XCTFail(@"Fail emu name: %@ in pack: %@", errorMessage, pack[@"name"]);
        }
    }
}


/**
 *  Tests the correct number of emus appear in each pack.
 *  - All packs currently must have at least 6 emus.
 *  - All packs must have an even number of emus in the pack.
 */
-(void)testAllPacksEmusCount
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    NSArray *packs = _json[@"packages"];
    XCTAssertNotNil(packs, @"Packs are nil?");
    XCTAssert(packs.count>0, @"No packs?");
    for (NSDictionary *pack in packs) {
        NSArray *emus = pack[@"emuticons"];
        XCTAssertNotNil(emus, @"No emus in pack: %@", pack[@"name"]);
        XCTAssert(emus.count>=6, @"Not enough emus (%@) in pack: %@", @(emus.count), pack[@"name"]);
        XCTAssert(emus.count%2 == 0, @"Emus count (%@) must be an even number in pack: %@", @(emus.count), pack[@"name"]);
    }
}


/**
 *  Test that all the emus in all packs have at least a defined background layer.
 */
-(void)testAllEmusHaveBackgroundLayer
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];
    
    NSArray *packs = _json[@"packages"];
    for (NSDictionary *pack in packs) {
        NSArray *emus = pack[@"emuticons"];
        for (NSDictionary *emu in emus) {
            XCTAssert(emu[@"source_back_layer"], @"Missing source back layer in emu:%@ pack:%@", emu[@"name"], pack[@"name"]);
        }
    }
}


///**
// *  Test that exactly 1 emu is marked as use_for_preview per pack.
// */
//-(void)testOnlyOneEmuPerPackWithUseForPreviewFlag
//{
//    [self ensureDataAvailable];
//    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
//        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
//    }];
//    
//    NSArray *packs = _json[@"packages"];
//    for (NSDictionary *pack in packs) {
//        NSArray *emus = pack[@"emuticons"];
//        NSInteger useForPreviewInPackCount = 0;
//        for (NSDictionary *emu in emus) {
//            if (emu[@"use_for_preview"] && [emu[@"use_for_preview"] boolValue]) {
//                useForPreviewInPackCount++;
//            }
//        }
//        XCTAssert(useForPreviewInPackCount==1, @"Exactly 1 emu should be marked as use for preview per pack. %@ marked in pack: %@", @(useForPreviewInPackCount), pack[@"name"]);
//    }
//}

#pragma mark - Configuration
/**
 *  Test for expected configuration values.
 */
-(void)testConfig
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    // Expected client name: Emu iOS
    XCTAssert([_json[@"client_name"] isEqualToString:@"Emu iOS"], @"Unexpected client_name: %@", _json[@"client_name"]);

    // Expected config type: app config
    XCTAssert([_json[@"config_type"] isEqualToString:@"app config"], @"Wrong config type: %@", _json[@"config_type"]);
    
    // Expected base resource url
    XCTAssert([_json[@"base_resource_url"] isEqualToString:@"http://s3.amazonaws.com"], @"Unexpected resource url: %@", _json[@"base_resource_url"]);
}

@end
