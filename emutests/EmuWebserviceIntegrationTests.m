//
//  EmuWebserviceIntegrationTests.m
//  EmuWebserviceIntegrationTests
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

-(NSDictionary *)allEmusByOID
{
    NSMutableDictionary *emus = [NSMutableDictionary new];
    for (NSDictionary *pack in _json[@"packages"]) {
        for (NSDictionary *emu in pack[@"emuticons"]) {
            NSString *oid = emu[@"_id"][@"$oid"];
            emus[oid] = emu;
        }
    }
    XCTAssert(emus.count >= 6, @"Strange number of emus: %@", @(emus.count));
    return emus;
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


#pragma mark - Mixed screen
-(void)testMixedScreen
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    NSDictionary *mixedScreen = _json[@"mixed_screen"];
    XCTAssertNotNil(mixedScreen, @"Mixed screen data missing.");
    XCTAssert([mixedScreen isKindOfClass:[NSDictionary class]], @"Mixed screen data is invalid: %@", mixedScreen);

    NSDictionary *emusByOID = [self allEmusByOID];
    
    NSArray *emus = mixedScreen[@"emus"];
    XCTAssertNotNil(emus, @"No emus defined for mixed screen?");
    XCTAssert([emus isKindOfClass:[NSArray class]], @"Emus data for mixed screen is invalid: %@", emus);
    XCTAssert(emus.count>0 && emus.count%2==0, @"Wrong number of emus in mixed screen: %@", @(emus.count));
    
    // Check all emus in mixed screen.
    for (NSDictionary *emu in emus) {
        
        // Ensure emu definition exists and with the correct oid.
        NSString *oid = emu[@"oid"];
        NSString *name = emu[@"name"];
        NSDictionary *emuDef = emusByOID[oid];
        XCTAssertNotNil(emuDef, @"Mixed screen contains unknown emu:%@ name:%@", oid, name);
        
        // Ensure name of the emu used is the correct one.
        XCTAssert([name isEqualToString:emuDef[@"name"]], @"Mixed screen uses emu named: %@ but name should be: %@", name, emuDef[@"name"]);
    }
    
    // Prioritized emus
    emus = mixedScreen[@"prioritized_emus"];
    XCTAssertNotNil(emus, @"No prioritized emus defined for mixed screen?");
    XCTAssert([emus isKindOfClass:[NSArray class]], @"Prioritized emus data for mixed screen is invalid: %@", emus);

    // Check all prioritized emus in mixed screen.
    for (NSDictionary *emu in emus) {
        
        // Ensure emu definition exists and with the correct oid.
        NSString *oid = emu[@"oid"];
        NSString *name = emu[@"name"];
        NSDictionary *emuDef = emusByOID[oid];
        XCTAssertNotNil(emuDef, @"Mixed screen contains unknown prioritized emu:%@ name:%@", oid, name);
        
        // Ensure name of the emu used is the correct one.
        XCTAssert([name isEqualToString:emuDef[@"name"]], @"Mixed screen uses emu named: %@ but name should be: %@", name, emuDef[@"name"]);
    }
}

-(void)testMixedScreenLocalResources
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];
    
    NSDictionary *mixedScreen = _json[@"mixed_screen"];
    XCTAssertNotNil(mixedScreen, @"Mixed screen data missing.");
    XCTAssert([mixedScreen isKindOfClass:[NSDictionary class]], @"Mixed screen data is invalid: %@", mixedScreen);
    NSArray *emus = mixedScreen[@"emus"];
    XCTAssertNotNil(emus, @"No emus defined for mixed screen?");
    NSDictionary *emusByOID = [self allEmusByOID];
    
    // Check all emus in mixed screen.
    for (NSDictionary *emu in emus) {
        
        // Ensure emu definition exists and with the correct oid.
        NSString *oid = emu[@"oid"];
        NSString *name = emu[@"name"];
        NSDictionary *emuDef = emusByOID[oid];
        XCTAssertNotNil(emuDef, @"Mixed screen contains unknown emu:%@ name:%@", oid, name);
    }
}


-(void)testAllPackagesHaveDataUpdateTimeStamp
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    NSArray *packs = _json[@"packages"];
    for (NSDictionary *pack in packs) {
        NSNumber *timeStampNumber = pack[@"data_update_time_stamp"];
        XCTAssertNotNil(timeStampNumber, @"Missing data_update_time_stamp for pack: %@", pack[@"name"]);
        
        NSInteger timeStamp = timeStampNumber.integerValue;
        XCTAssert(timeStamp > 1400000000, @"Unexpected data_update_time_stamp value (%@) for pack: %@", @(timeStamp), pack[@"name"]);
    }
}

@end
