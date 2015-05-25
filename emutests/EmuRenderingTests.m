//
//  EmuRenderingTests.m
//  emu
//
//  Created by Aviv Wolf on 5/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMRenderer.h"

@interface EmuRenderingTests : XCTestCase

@end

@implementation EmuRenderingTests

#pragma mark - setup
- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark - helpers
-(NSArray *)arrayOfFakeUserFrames:(NSInteger)framesCount
{
    NSMutableArray *array = [NSMutableArray new];
    NSInteger i = 0;
    while (i<framesCount) {
        NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"fake-user-take" withExtension:@"png"];
        NSString *path = [url path];
        [array addObject:path];
        i++;
    }
    return array;
}

-(EMRenderer *)simpleRendererToOutput:(NSString *)outputName
{
    NSURL *urlForFG = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-fg" withExtension:@"gif"];
    XCTAssertNotNil(urlForFG);
    
    NSURL *urlForBG = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-bg" withExtension:@"gif"];
    XCTAssertNotNil(urlForBG);
    
    NSURL *urlForMask = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-mask" withExtension:@"jpg"];
    XCTAssertNotNil(urlForMask);
    
    EMRenderer *renderer = [EMRenderer new];
    renderer.emuticonDefOID = @"test emu";
    renderer.footageOID = @"test footage";
    
    renderer.backLayerPath = [urlForBG path];
    renderer.userImagesPathsArray = [self arrayOfFakeUserFrames:25];
    renderer.userMaskPath = [urlForMask path];
    renderer.frontLayerPath = [urlForFG path];
    
    renderer.numberOfFrames = 25;
    renderer.duration = 2;
    
    renderer.outputOID = outputName;
    renderer.outputPath = [EMDB outputPath];
    return renderer;
}


#pragma mark - tests
- (void)testASingleRender
{
    NSString *outputName = [[NSUUID UUID] UUIDString];
    EMRenderer *renderer = [self simpleRendererToOutput:outputName];
    renderer.shouldOutputGif = YES;
    renderer.shouldOutputVideo = NO;
    [renderer render];
}


/**
 *  Measure performance of outputting gifs.
 */
- (void)testPerformanceOfRenderGifs {
    // Create output folder
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"YYYY_M_d_HHmmss"];
    NSString *tempFolderName = [dateFormat stringFromDate:now];
    NSString *path = [NSString stringWithFormat:@"%@/%@", [EMDB outputPath], tempFolderName];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    [self measureBlock:^{
        NSString *uuid = [[NSUUID UUID] UUIDString];
        for (NSInteger i=0;i<10;i++) {
            NSString *outputName = [NSString stringWithFormat:@"%@/%@_%@", tempFolderName, uuid, @(i)];
            EMRenderer *renderer = [self simpleRendererToOutput:outputName];
            renderer.shouldOutputGif = YES;
            renderer.shouldOutputVideo = NO;
            [renderer render];
        }
    }];
    
    // Delete output folder
    //[fm removeItemAtPath:path error:nil];
}

/**
 *  Measure performance of outputting video.
 */
- (void)testPerformanceOfRenderVideo {
    // Create output folder
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"YYYY_M_d_HHmmss"];
    NSString *tempFolderName = [dateFormat stringFromDate:now];
    NSString *path = [NSString stringWithFormat:@"%@/%@", [EMDB outputPath], tempFolderName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    XCTAssertNil(error, @"Error. Couldn't create output path when rendering video. %@", error);
    
    // Audio file
    NSURL *audioFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"audio_test"
                                                                   withExtension:@"mp3"];
    
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *outputName = [NSString stringWithFormat:@"%@/%@", tempFolderName, uuid];
    EMRenderer *renderer = [self simpleRendererToOutput:outputName];
    renderer.shouldOutputGif = NO;
    renderer.shouldOutputVideo = YES;
    renderer.videoFXLoopsCount = 10;
    renderer.videoFXLoopPingPong = YES;
    renderer.audioFileURL = audioFileURL;
    [renderer render];
    
    [fm removeItemAtPath:path error:nil];
}

@end
