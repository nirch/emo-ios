//
//  backupCode.m
//  emu
//
//  Created by Aviv Wolf on 2/12/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "backupCode.h"

@implementation backupCode
//// Get framerate
//CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
//[self calculateFramerateAtTimestamp:timestamp];
//
////		// Get frame dimensions (for onscreen display)
////		if (self.videoDimensions.width == 0 && self.videoDimensions.height == 0)
////			self.videoDimensions = CMVideoFormatDescriptionGetDimensions( formatDescription );
////
////		// Get buffer type
////		if ( self.videoType == 0 )
////			self.videoType = CMFormatDescriptionGetMediaSubType( formatDescription );

//            BOOL wasReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
//
//            if (connection == videoConnection) {
//
//                // Initialize the video input if this is not done yet
//                if (!readyToRecordVideo)
//                {
//                    CMFormatDescriptionRef processedFormatDesc = CMSampleBufferGetFormatDescription(processedSampleBuffer);
//                    readyToRecordVideo = [self setupAssetWriterVideoInput:processedFormatDesc];
//                }
//
//                // Write video data to file
//                if (readyToRecordVideo && readyToRecordAudio)
//                {
//                    //[self saveSampleBuffer:processedSampleBuffer withName:@"beforewriting"];
//                    CVPixelBufferRef processedPixelBuffer = CMSampleBufferGetImageBuffer(processedSampleBuffer);
//                    CVPixelBufferRetain(processedPixelBuffer);
//                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo withPixelBuffer:processedPixelBuffer];
//                    CVPixelBufferRelease(processedPixelBuffer);
//                }
//            }
//            else if (connection == audioConnection) {
//
//                // Initialize the audio input if this is not done yet
//                if (!readyToRecordAudio)
//                    readyToRecordAudio = [self setupAssetWriterAudioInput:formatDescription];
//
//                // Write audio data to file
//                if (readyToRecordAudio && readyToRecordVideo)
//                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio withPixelBuffer:nil];
//            }
//
//            BOOL isReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
//            if ( !wasReadyToRecord && isReadyToRecord ) {
//                recordingWillBeStarted = NO;
//                self.recording = YES;
//                [self.delegate recordingDidStart];
//            }

@end
