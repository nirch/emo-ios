//
//  EmuRenderingTests.m
//  emu
//
//  Created by Aviv Wolf on 5/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import AVFoundation;

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMRenderer.h"
#import "EMTestsResources.h"
#import "EMImageInspector.h"
#import <FLAnimatedImage.h>

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

#pragma mark - tests
- (void)testRenderSingleGif
{
    NSString *outputName = [[NSUUID UUID] UUIDString];
    EMRenderer *renderer = [self simpleRendererToOutput:outputName];
    renderer.shouldOutputGif = YES;
    [renderer render];
    NSError *error = nil;
    [renderer validateOutputResultsWithError:&error];
    XCTAssertNil(error, @"Error while rendering a single gif: %@", [error localizedDescription]);
}

- (void)testRenderSingleThumb
{
    NSString *outputName = [[NSUUID UUID] UUIDString];
    EMRenderer *renderer = [self simpleRendererToOutput:outputName];
    renderer.shouldOutputThumb = YES;
    renderer.thumbOfFrame = @24;
    [renderer render];
    NSError *error = nil;
    [renderer validateOutputResultsWithError:&error];
    XCTAssertNil(error, @"Error while rendering a single thumb: %@", [error localizedDescription]);
}

- (void)testRenderSingleVideo
{
    NSString *outputName = [[NSUUID UUID] UUIDString];
    EMRenderer *renderer = [self simpleRendererToOutput:outputName];
    renderer.shouldOutputVideo = YES;
    [renderer render];
    NSError *error = nil;
    [renderer validateOutputResultsWithError:&error];
    XCTAssertNil(error, @"Error while rendering a single video: %@", [error localizedDescription]);
}


-(void)testRenderOfAllTypesAndRenderValidation
{
    NSString *outputName = [[NSUUID UUID] UUIDString];
    
    // Setup to render all media types in a single request
    EMRenderer *renderer = [self simpleRendererToOutput:outputName];
    renderer.shouldOutputGif = YES;
    renderer.shouldOutputVideo = YES;
    renderer.shouldOutputThumb = YES;
    
    // Check renderer
    NSError *error;
    [renderer validateSetupWithError:&error];
    XCTAssertNil(error, @"Error on validating render setup: %@", [error localizedDescription]);
    
    // Render
    [renderer render];
    
    // Check results
    [renderer validateOutputResultsWithError:&error];
    XCTAssertNil(error, @"Output error: %@", [error localizedDescription]);    
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
        for (NSInteger i=0;i<5;i++) {
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
    NSString *tempFolderName = [self createTempOutputFolder];
    
    // Audio file
    NSURL *audioFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"audio_test"
                                                                   withExtension:@"mp3"];
    
    [self measureBlock:^{
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSString *outputName = [NSString stringWithFormat:@"%@/%@", tempFolderName, uuid];
        EMRenderer *renderer = [self simpleRendererToOutput:outputName];
        renderer.shouldOutputGif = NO;
        renderer.shouldOutputVideo = YES;
        renderer.videoFXLoopsCount = 5;
        renderer.videoFXLoopEffect = 1;
        renderer.audioFileURL = audioFileURL;
        [renderer render];
        
        // Validate results
        NSError *error;
        [renderer validateOutputResultsWithError:&error];
        XCTAssertNil(error, @"Output error: %@", [error localizedDescription]);
    }];
    
    //[fm removeItemAtPath:path error:nil];
}

-(void)testImageInspector
{
    //
    // If a test could test tests, how many tests would a test test?
    //
    
    // Just checking that the helper methods used in some tests are working and thread safe.
    
    NSArray *pointsToCheck = @[
                               @[@30,@30],
                               @[@230,@10],
                               @[@149,@162],
                               @[@140,@40],
                               @[@130,@220],
                               @[@180,@50]
                               ];
    
    [self measureBlock:^{
        UIImage *image = [EMTestsResources imageNamed:@"expected-result" ofType:@"jpg"];
        EMImageInspector *inspector = [[EMImageInspector alloc] initWithImage:image];
        // Expected colors
        NSMutableDictionary *expectedColorsAtPoints = [NSMutableDictionary new];
        for (NSArray *pArr in pointsToCheck) {
            UIColor *color = [inspector colorAtPointArr:pArr];
            expectedColorsAtPoints[pArr] = color;
        }
    }];
}

/**
 * Test that colors of rendered outputs are correct 
 * ( assert no RGB<->BGR bugs exist )
 */
-(void)testOutputColorChannelsRelatedBugs
{
    NSString *tempFolderName = [self createTempOutputFolder];
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *outputName = [NSString stringWithFormat:@"%@/%@", tempFolderName, uuid];
    EMRenderer *renderer = [self simpleRendererToOutput:outputName];
    renderer.shouldOutputGif = YES;
    renderer.shouldOutputVideo = YES;
    renderer.shouldOutputVideo = YES;
    [renderer render];

    // Validate results
    NSError *error;
    [renderer validateOutputResultsWithError:&error];
    XCTAssertNil(error, @"Output error: %@", [error localizedDescription]);

    // Sample a few points
    NSArray *pointsToCheck = @[
                               @[@30,@30],
                               @[@230,@10],
                               @[@149,@162],
                               @[@140,@40],
                               @[@130,@220],
                               @[@180,@50]
                               ];

    // Expected image.
    UIImage *image = [EMTestsResources imageNamed:@"expected-result" ofType:@"jpg"];
    XCTAssertNotNil(image, @"Missing expected image");
    EMImageInspector *inspector = [[EMImageInspector alloc] initWithImage:image];

    // Expected colors
    NSMutableDictionary *expectedColorsAtPoints = [NSMutableDictionary new];
    for (NSArray *pArr in pointsToCheck) {
        UIColor *color = [inspector colorAtPointArr:pArr];
        expectedColorsAtPoints[pArr] = color;
    }
    
    CGFloat threshold = 0.15f;
    
    // Compare to the thumb image.
    NSString *outputThumbPath = [renderer filePathForOutputOfKind:HM_K_OUTPUT_THUMB];
    UIImage *thumb = [UIImage imageWithContentsOfFile:outputThumbPath];
    XCTAssertNotNil(thumb, @"Missing thumb image");
    inspector = [[EMImageInspector alloc] initWithImage:thumb];
    for (NSArray *pArr in expectedColorsAtPoints.allKeys) {
        UIColor *color = [inspector colorAtPointArr:pArr];
        UIColor *expectedColor = expectedColorsAtPoints[pArr];
        CGFloat distance = [self distanceOfColor:color fromColor:expectedColor];
        XCTAssert(distance < threshold, @"Unexpected color for thumb at point:%@", pArr);
    }
    
    // Compare to the last frame in the rendered video
    NSString *outputVideoPath = [renderer filePathForOutputOfKind:HM_K_OUTPUT_VIDEO];
    UIImage *imageFromVideo = [self imageFromVideoAtPath:outputVideoPath];
    XCTAssertNotNil(imageFromVideo, @"Missing grabbed image from video file");
    inspector = [[EMImageInspector alloc] initWithImage:imageFromVideo];
    for (NSArray *pArr in expectedColorsAtPoints.allKeys) {
        UIColor *color = [inspector colorAtPointArr:pArr];
        UIColor *expectedColor = expectedColorsAtPoints[pArr];
        CGFloat distance = [self distanceOfColor:color fromColor:expectedColor];
        XCTAssert(distance < threshold, @"Unexpected color for video at point:%@", pArr);
    }
    
    // Compare to the last frame in the rendered gif
    NSString *outputGifPath = [renderer filePathForOutputOfKind:HM_K_OUTPUT_GIF];
    NSData *animGifData = [NSData dataWithContentsOfFile:outputGifPath];
    FLAnimatedImage *animatedGif = [[FLAnimatedImage alloc] initWithAnimatedGIFData:animGifData];
    UIImage *imageFromAnimatedGif = [animatedGif posterImage];
    XCTAssertNotNil(imageFromAnimatedGif, @"Missing image from animated gif file");
    inspector = [[EMImageInspector alloc] initWithImage:imageFromAnimatedGif];
    for (NSArray *pArr in expectedColorsAtPoints.allKeys) {
        UIColor *color = [inspector colorAtPointArr:pArr];
        UIColor *expectedColor = expectedColorsAtPoints[pArr];
        CGFloat distance = [self distanceOfColor:color fromColor:expectedColor];
        XCTAssert(distance < threshold, @"Unexpected color for animated gif at point:%@", pArr);
    }
}


-(void)testCVBugFirstFrameTrailsInAnimatedGif
{
    NSString *outputName = [[NSUUID UUID] UUIDString];
    
    NSURL *urlForFG = [[NSBundle bundleForClass:[self class]] URLForResource:@"gif-transp" withExtension:@"gif"];
    XCTAssertNotNil(urlForFG, @"Missing test-fg resource?");
    
    NSURL *urlForBG = [[NSBundle bundleForClass:[self class]] URLForResource:@"gif-bg-16" withExtension:@"gif"];
    XCTAssertNotNil(urlForBG,  @"Missing test-bg resource?");
    
    // Setup renderer.
    EMRenderer *renderer = [EMRenderer new];
    renderer.emuticonDefOID = @"test emu";
    renderer.footageOID = @"test footage";
    renderer.backLayerPath = [urlForBG path];
    renderer.frontLayerPath = [urlForFG path];
    renderer.userImagesPathsArray = [self arrayOfFakeUserFrames:16];
    renderer.numberOfFrames = 16;
    renderer.duration = 5;
    renderer.outputOID = outputName;
    renderer.outputPath = [EMDB outputPath];
    renderer.shouldOutputGif = YES;
    
    // Validate renderer setup
    NSError *error = nil;
    [renderer validateSetupWithError:&error];
    XCTAssertNil(error, @"Error while setting up renderer. %@", [error localizedDescription]);

    // Render gif
    [renderer render];

    // Validate output
    error = nil;
    [renderer validateOutputResultsWithError:&error];
    XCTAssertNil(error, @"No gif output found after rendering. %@", [error localizedDescription]);
    
    // Analyse result and check if the bug exists.
    
}




#pragma mark - Helpers
-(NSString *)createTempOutputFolder
{
    // Create output folder
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"YYYY_M_d_HHmmss"];
    NSString *tempFolderName = [dateFormat stringFromDate:now];
    
    // Create the folder.
    NSString *path = [NSString stringWithFormat:@"%@/%@", [EMDB outputPath], tempFolderName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    XCTAssertNil(error, @"Error. Couldn't create temp output path. %@", error);
    return tempFolderName;
}

-(CGFloat)distanceOfColor:(UIColor *)color1 fromColor:(UIColor *)color2
{
    const CGFloat* rgb1 = CGColorGetComponents( color1.CGColor );
    const CGFloat* rgb2 = CGColorGetComponents( color2.CGColor );
    CGFloat rd = pow(rgb1[0]-rgb2[0],2);
    CGFloat gd = pow(rgb1[1]-rgb2[1],2);
    CGFloat bd = pow(rgb1[2]-rgb2[2],2);
    return rd+gd+bd;
}


-(UIImage *)imageFromVideoAtPath:(NSString *)videoPath
{
    NSURL *sourceURL = [NSURL fileURLWithPath:videoPath];
    AVAsset *asset = [AVAsset assetWithURL:sourceURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = CMTimeMake(1, 1);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return thumbnail;
}


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
    XCTAssertNotNil(urlForFG, @"Missing test-fg resource?");
    
    NSURL *urlForBG = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-bg" withExtension:@"gif"];
    XCTAssertNotNil(urlForBG,  @"Missing test-bg resource?");
    
    NSURL *urlForMask = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-mask" withExtension:@"jpg"];
    XCTAssertNotNil(urlForMask,  @"Missing test-mask resource?");
    
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
    
    renderer.shouldOutputGif = NO;
    renderer.shouldOutputVideo = NO;
    renderer.shouldOutputThumb = NO;
    
    return renderer;
}


@end
