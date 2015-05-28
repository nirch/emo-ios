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
    
    
    
    /** ==============================
        Optional effects and features.
        ============================== */
    
    // Effects on video output
    void AddLoopEffect(NSInteger loopsCount, BOOL pingPong);
    
    // Audio track
    void AddAudio(NSURL *audioFileURL, NSTimeInterval audioStartTime);
    
private:
    EMVideoMaker *videoMaker;
    image_type* m_image = NULL;
};

