//
//  EmuCaptureTests.m
//  emu
//
//  Created by Aviv Wolf on 7/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "HMSDK.h"
#import "Gpw/Vtool/Vtool.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "HMBackgroundMarks.h"

@interface EmuCaptureTests : XCTestCase

@end

@implementation EmuCaptureTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


//-(void)testBackgroundDetection
//{
//    XCTestExpectation *expectation = [self expectationWithDescription:@"bg detection tests"];
//    
//    // Resource files.
//    NSURL *movieURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"output480" withExtension:@"mov"];
//    NSString *paramsXML = [[NSBundle bundleForClass:[self class]] pathForResource:@"uniformBGParams" ofType:@"xml"];
//    NSString *ctrFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"emuDefaultContour480" ofType:@"ctr"];
//
//    // Video asset
//    AVAsset *movieAsset = [AVAsset assetWithURL:movieURL];
//    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
//
//    // Use these frame
//    NSMutableArray *timesArray = [NSMutableArray new];
//    NSInteger framesCount = 1000;
//    for (NSInteger i=0;i<framesCount;i++) {
//        CMTime t = CMTimeMake((movieAsset.duration.value/(double)framesCount)*i, movieAsset.duration.timescale);
//        [timesArray addObject:[NSValue valueWithCMTime:t]];
//    }
//    
//    // Initialize background detection.
//    __block image_type *image_to_inspect = NULL;
//    __block NSInteger inspectedCount = 0;
//    CUniformBackground *m_foregroundExtraction = new CUniformBackground();
//    int result = m_foregroundExtraction->Init((char*)paramsXML.UTF8String,
//                                              (char*)ctrFile.UTF8String,
//                                              480,
//                                              480);
//    XCTAssert(result == 1, @"Failed initializing CUniformBackground. %@", @(result));
//    
//    
//    [generator generateCGImagesAsynchronouslyForTimes:timesArray completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
//        XCTAssertNil(error, @"Error while extracting images from video asset: %@", [error localizedDescription]);
//        
//        if (result == AVAssetImageGeneratorSucceeded) {
//            UIImage *uiImage = [UIImage imageWithCGImage:image];
//            CVtool::SavePng(uiImage);
//            
////            image_to_inspect = CVtool::UIimage_to_image(uiImage, image_to_inspect);
////            inspectedCount++;
////            m_foregroundExtraction->ProcessBackground(image_to_inspect, 1);
////            if (inspectedCount >= timesArray.count) [expectation fulfill];
//        }
//    }];
//    
//    // Wait for async results.
//    [self waitForExpectationsWithTimeout:1000 handler:^(NSError *error) {
//        XCTAssertNil(error, @"Error in testBackgroundDetection: %@", [error localizedDescription]);
//    }];
//}










//- (void)testBackgroundDetection {
//    NSError *error;
//    HMBackgroundRemoval *vp = [HMBackgroundRemoval backgroundRemovalWithBGImageFileName:@""
//                                                                        contourFileName:@""
//                                                                                  error:&error];
//    XCTAssertNotNil(error, @"Error while init video processor: %@", [error localizedDescription]);
//    
//
//}


//#pragma mark - Helpers
//- (CVPixelBufferRef)newPixelBufferFromCGImage:(UIImage *)image
//{
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
//                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
//                             nil];
//    
//    
//    CVPixelBufferRef pxbuffer = NULL;
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                          image.size.width,
//                                          image.size.height,
//                                          kCVPixelFormatType_32ARGB,
//                                          (CFDictionaryRef)CFBridgingRetain(options),
//                                          &pxbuffer);
//    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
//    
//    CVPixelBufferLockBaseAddress(pxbuffer, 0);
//    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
//    NSParameterAssert(pxdata != NULL);
//    
//    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
//                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
//                                                 kCGImageAlphaNoneSkipFirst);
//    NSParameterAssert(context);
//    CGContextConcatCTM(context, frameTransform);
//    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
//                                           CGImageGetHeight(image)), image);
//    CGColorSpaceRelease(rgbColorSpace);
//    CGContextRelease(context);
//    
//    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
//    
//    return pxbuffer;
//}

@end
