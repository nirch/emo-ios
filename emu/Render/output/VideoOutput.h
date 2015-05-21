//
//  VideoOutput.h
//  RenderTest
//
//  Created by Tomer Harry on 2/11/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HrRendererLib/HrOutput/HrOutputI.h"
#import "EMVideoMaker.h"

class VideoOutput : public CHrOutputI
{
public:
    VideoOutput(
                CMVideoDimensions dimensions,
                float bitsPerPixel,
                NSURL *videoOutputUrl,
                int framesPerSec
                );
    
    virtual int	WriteFrame( image_type *im, int iFrame );
	virtual int Close();
    
    // Effects on video output
    void AddLoopEffect(int loopsCount, BOOL pingPong);
    
private:
    EMVideoMaker *videoMaker;
    image_type* m_image = NULL;
};

