//
//  VideoOutput.m
//  RenderTest
//
//  Created by Tomer Harry on 2/11/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import "VideoOutput.h"
#import "Gpw/Vtool/Vtool.h"

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
    m_image = image3_from(im, m_image);
    image3_bgr2rgb(m_image);
    CVPixelBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_image);
    
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
    
    if (m_image) image_destroy(m_image, 1);
    
    return 1;
}