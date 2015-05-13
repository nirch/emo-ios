//
//  VideoOutput.h
//  RenderTest
//
//  Created by Tomer Harry on 2/11/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HrRendererLib/HrOutput/HrOutputI.h"
#import <AVFoundation/AVFoundation.h>



class VideoOutput : public CHrOutputI
{
public:
    VideoOutput(CMVideoDimensions dimensions, float bitsPerPixel, NSURL *videoOutputUrl , int framesPerSec);
    virtual int	WriteFrame( image_type *im, int iFrame );
    
	virtual int Close();
    
private:
    // Background Color
    AVAssetWriter *m_assetWriter;
    AVAssetWriterInput *m_assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *m_assetWriterPixelBufferInput;
    CMTime m_currFrameTime;
    CMTime m_timePerFrame;
    image_type* m_image = NULL;
};

