//
//  EmuCaptureTests.m
//  emu
//
//  Created by Aviv Wolf on 7/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
@import CoreVideo;
#import "HMSDK.h"

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

- (void)testBackgroundDetection {
    NSError *error;
    HMBackgroundRemoval *vp = [HMBackgroundRemoval backgroundRemovalWithBGImageFileName:@""
                                                                        contourFileName:@""
                                                                                  error:&error];
    XCTAssertNotNil(error, @"Error while init video processor: %@", [error localizedDescription]);
    

}


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
