//
//  VideoOutput.m
//  RenderTest
//
//  Created by Tomer Harry on 2/11/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import "VideoOutput.h"
#import "Gpw/Vtool/Vtool.h"
#import "Render.h"

VideoOutput::VideoOutput(CMVideoDimensions dimensions, float bitsPerPixel, NSURL *videoOutputUrl, int framesPerSec)
{
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = @{ AVVideoCodecKey: AVVideoCodecH264,
                                                AVVideoWidthKey: [NSNumber numberWithInteger:dimensions.width],
                                                AVVideoHeightKey: [NSNumber numberWithInteger:dimensions.height],
                                                AVVideoCompressionPropertiesKey: @{ AVVideoAverageBitRateKey: [NSNumber numberWithInteger:bitsPerSecond],
                                                                                    AVVideoMaxKeyFrameIntervalKey: [NSNumber numberWithInteger:framesPerSec] }
                                                };
    NSError *error;
    m_assetWriter = [AVAssetWriter assetWriterWithURL:videoOutputUrl fileType:AVFileTypeMPEG4 error:&error];
    m_currFrameTime = CMTimeMake(0, 1000);
    m_timePerFrame = CMTimeMake(1000 / framesPerSec, 1000);
    
    
    if (!error)
    {
        if ([m_assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo])
        {
            m_assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
            m_assetWriterVideoInput.expectsMediaDataInRealTime = YES;
            m_assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:m_assetWriterVideoInput sourcePixelBufferAttributes:nil];
            if ([m_assetWriter canAddInput:m_assetWriterVideoInput])
                [m_assetWriter addInput:m_assetWriterVideoInput];
            else
            {
                NSLog(@"Couldn't add asset writer video input.");
            }
        }
        else
        {
            NSLog(@"Couldn't apply output settings to asset  writer");
        }
    }
    else
    {
        NSLog(@"Error in creating asset writer: %@", error.description);
    }
    

}

int	VideoOutput::WriteFrame( image_type *im , int iFrame)
{
    // TODO: Add background color to image
    
    // Converting the result of the algo into CVPixelBuffer
    image3_from(im, im);
    image3_bgr2rgb(im);
    CVPixelBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(im);
    
    NSError *error;    
    if ( m_assetWriter.status == AVAssetWriterStatusUnknown ) {
		// Start writing if didn't do it before
        if ([m_assetWriter startWriting]) {
            CMTime startTime = CMTimeMake(0, 1000);
			[m_assetWriter startSessionAtSourceTime:startTime];
		}
		else {
            NSLog(@"Error in creating asset writer: %@", error.description);
		}
	}
	
	if ( m_assetWriter.status == AVAssetWriterStatusWriting ) {
		
			if (m_assetWriterVideoInput.readyForMoreMediaData) {
                if ([m_assetWriterPixelBufferInput appendPixelBuffer:processedPixelBuffer withPresentationTime:m_currFrameTime]) {
                    m_currFrameTime = CMTimeAdd(m_currFrameTime, m_timePerFrame);
				}
                else {
                    NSLog(@"Error in writing frame");
                }
			}
	}

    //if (processedPixelBuffer) CFRelease(processedPixelBuffer);
    
    return 1;
}

int VideoOutput::Close()
{
    if (m_assetWriter.status == AVAssetWriterStatusWriting)
    {
        [m_assetWriter finishWritingWithCompletionHandler:^{
            NSLog(@"Finish writing video...");
        }];
    }
    else {
        NSLog(@"Trying to close a video while not writing");
    }
    
    return 1;
}

int VideoOutput::Init( char *outFile, int width, int height )
{
    return -1;
}

CVPixelBufferRef VideoOutput::pixelBufferFromCGImage(CGImageRef image)
{
    
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height,  kCVPixelFormatType_32ARGB, (CFDictionaryRef) CFBridgingRetain(options),
                                          &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
