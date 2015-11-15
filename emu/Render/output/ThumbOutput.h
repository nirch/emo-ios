//
//  VideoOutput.h
//  RenderTest
//
//  Created by Tomer Harry on 2/11/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HrRendererLib/HrOutput/HrOutputI.h"

#define HM_THUMB_TYPE_PNG        0
#define HM_THUMB_TYPE_JPG        1

class ThumbOutput : public CHrOutputI
{
public:
    ThumbOutput(
                NSURL *thumbOutputUrl,
                NSInteger frameNumber,
                NSInteger thumbType
                );
    virtual int	WriteFrame( image_type *im, int iFrame );
	virtual int Close();
    
private:
    NSURL *thumbOutputUrl;
    NSInteger frameNumber;
    BOOL thumbWasCreated;
    NSInteger thumbType;
    image_type *referenceToLatestFrame;
};

