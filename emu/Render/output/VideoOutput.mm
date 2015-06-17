//
//  VideoOutput.m
//  RenderTest
//
//  Created by Tomer Harry on 2/11/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import "VideoOutput.h"

VideoOutput::VideoOutput(
                         CMVideoDimensions dimensions,
                         float bitsPerPixel,
                         NSURL *videoOutputUrl,
                         int framesPerSec
                         )
{
    // Basic configuration.
    m_image = NULL;
    videoMaker = [EMVideoMaker new];
    videoMaker.dimensions = dimensions;
    videoMaker.bitsPerPixel = bitsPerPixel;
    videoMaker.videoOutputURL = videoOutputUrl;
    videoMaker.fps = framesPerSec;
}

int	VideoOutput::WriteFrame( image_type *im , int iFrame)
{
    m_image = image3_from_image4(im, m_image);
    image_bgr2rgb(m_image, m_image);
    [videoMaker addImageFrame:m_image];
    return 1;
}

int VideoOutput::Close()
{
    [videoMaker finishUp];
    videoMaker = NULL;
    return 1;
}


void VideoOutput::AddLoopEffect(NSInteger loopsCount, BOOL pingPong)
{
    videoMaker.fxLoops = loopsCount;
    videoMaker.fxPingPong = pingPong;
}

void VideoOutput::AddAudio(NSURL *audioFileURL, NSTimeInterval audioStartTime)
{
    videoMaker.audioFileURL = audioFileURL;
    videoMaker.audioStartTime = audioStartTime;
}

VideoOutput::~VideoOutput()
{
    Close();
}

