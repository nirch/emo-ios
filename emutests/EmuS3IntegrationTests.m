//
//  EmuS3IntegrationTests.m
//  EmuS3IntegrationTests
//
//  Created by Aviv Wolf on 5/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AWSCore.h>
#import <AWSS3.h>
#import "EMDB.h"

@interface EmuS3IntegrationTests : XCTestCase

@end

/**
 *  Integration tests with the web service.
 *  Downloads and tests the correctness of the data received
 *  from the server side API.
 */
@implementation EmuS3IntegrationTests

static NSString *_url;
static NSDictionary *_json;
static BOOL _useScratchpad;

// S3 credentials (read only)
#define S3_READ_ONLY_ACCESS_KEY @"AKIAIPDINW5633DLB22Q"
#define S3_READ_ONLY_SECRET_KEY @"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"


+(void)setUp
{
    [super setUp];
    _url = @"http://app.emu.im/emuapi/packages/full";
    _useScratchpad = NO;
    
    //[AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:S3_READ_ONLY_ACCESS_KEY secretKey:S3_READ_ONLY_SECRET_KEY];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
}

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}


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

-(void)listFolder:(NSString *)folder
         inBucket:(NSString *)bucket
      expectation:(id)expectation
           result:(NSArray **)result
{
    AWSS3 *s3 = [AWSS3 defaultS3];
    XCTAssertNotNil(s3, @"No connection to s3");
    
    AWSS3ListObjectsRequest *request = [[AWSS3ListObjectsRequest alloc] init];
    request.bucket = bucket;
    request.prefix = folder;
    AWSTask *task = [s3 listObjects:request];
    
    // Send list request to s3.
    __block AWSTask *responseTask;
    [task continueWithExecutor:[AWSExecutor defaultExecutor] withBlock:^id(AWSTask *task) {
        responseTask = task;
        [expectation fulfill];
        return task;
    }];
    
    // Wait for the response from s3.
    [self waitForExpectationsWithTimeout:20.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];
    XCTAssertNil(responseTask.error, @"Error while fetching list from s3: %@", responseTask.error);
    XCTAssertNotNil(responseTask.result, @"Empty response from s3 for folder:%@ in bucket:%@", folder, bucket);
    
    AWSS3ListObjectsOutput *listOutput = task.result;
    *result = listOutput.contents;
}


-(void)checkResource:(NSString *)resource
              inList:(NSDictionary *)list
           packNamed:(NSString *)packName
              result:(NSMutableDictionary *)result
{
    if (resource == nil) return;
    XCTAssertNotNil(list);
    XCTAssertNotNil(packName);
    XCTAssertNotNil(result);
    NSString *key = [NSString stringWithFormat:@"packages/%@/%@", packName, resource];
    NSLog(@"checking %@", key);
    if (list[key] == nil) result[key] = @YES;
}


#pragma mark - General data tests
/**
 *  Parsed data exists?
 */
-(void)testData {
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];
    
    // Ensure json data is available.
    XCTAssertNotNil(_json);
}


#pragma mark - Resources on s3
/**
 * Test that all zipped files for all packs available on s3
 */
-(void)testZippedPackagesAvailability {

    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    for (NSDictionary *pack in _json[@"packages"]) {
        // Ensure package has a zipped package file name
        NSString *zipName = pack[@"zipped_package_file_name"];
        XCTAssertNotNil(zipName, @"Missing zipped_package_file_name for pack: %@", pack[@"name"]);
        
        // Make sure name of the pack in part of the name of the zipped package file.
        XCTAssert([zipName containsString:pack[@"name"]], @"wrong zipped package file name:%@ in pack:%@", zipName, pack[@"name"]);
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"s3 response"];
    NSArray *list;
    [self listFolder:@"zipped_packages/"
            inBucket:_json[@"bucket_name"]
         expectation:expectation
              result:&list];
    XCTAssertNotNil(list, @"List of zipped packages returned as nil from s3.");
    NSMutableDictionary *zippedPackagesFiles = [NSMutableDictionary new];
    for (AWSS3Object *zippedPackageKey in list) {
        zippedPackagesFiles[zippedPackageKey.key] = @YES;
    }
    
    // Check if any of the packages files are missing.
    NSMutableDictionary *missingFiles = [NSMutableDictionary new];
    for (NSDictionary *pack in _json[@"packages"]) {
        NSString *keyString = [NSString stringWithFormat:@"zipped_packages/%@", pack[@"zipped_package_file_name"]];
        if (zippedPackagesFiles[keyString] == nil) {
            missingFiles[keyString] = @YES;
        }
    }
    if (missingFiles.count > 0) {
        XCTFail(@"some zipped packages files are missing in s3: %@", missingFiles.allKeys);
    }
}


-(void)testAllResourcesAvailability
{
    [self ensureDataAvailable];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if(error) XCTFail(@"%s Failed with error: %@", __PRETTY_FUNCTION__, error);
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"s3 resources response"];
    NSArray *list;
    [self listFolder:@"packages/"
            inBucket:_json[@"bucket_name"]
         expectation:expectation
              result:&list];
    XCTAssertNotNil(list, @"List of resources for packs returned as nil from s3.");
    NSMutableDictionary *resourceFiles = [NSMutableDictionary new];
    for (AWSS3Object *resourceFile in list) {
        resourceFiles[resourceFile.key] = @YES;
    }

    NSMutableDictionary *missingResources = [NSMutableDictionary new];
    for (NSDictionary *pack in _json[@"packages"]) {
        NSString *packName = pack[@"name"];
        
        // Ensure icons references and files exist.
        NSString *iconName = pack[@"icon_name"];
        XCTAssertNotNil(iconName, @"Missing icon name for pack: %@", packName);
        [self checkResource:[NSString stringWithFormat:@"%@@2x.png", iconName] inList:resourceFiles packNamed:packName result:missingResources];
        [self checkResource:[NSString stringWithFormat:@"%@@3x.png", iconName] inList:resourceFiles packNamed:packName result:missingResources];
        
        // Check resources defined in defaults.
        NSDictionary *emuDefaults = pack[@"emuticons_defaults"];
        [self checkResource:emuDefaults[@"source_back_layer"] inList:resourceFiles packNamed:packName result:missingResources];
        [self checkResource:emuDefaults[@"source_front_layer"] inList:resourceFiles packNamed:packName result:missingResources];
        [self checkResource:emuDefaults[@"source_user_layer_mask"] inList:resourceFiles packNamed:packName result:missingResources];
        
        // Check resources for all emus in each pack.
        for (NSDictionary *emu in pack[@"emuticons"]) {
            [self checkResource:emu[@"source_back_layer"] inList:resourceFiles packNamed:packName result:missingResources];
            [self checkResource:emu[@"source_front_layer"] inList:resourceFiles packNamed:packName result:missingResources];
            [self checkResource:emu[@"source_user_layer_mask"] inList:resourceFiles packNamed:packName result:missingResources];
        }
    }
    if (missingResources.count > 0) {
        XCTFail(@"Some resource files are missing in s3: %@", missingResources.allKeys);
    }

}


@end
