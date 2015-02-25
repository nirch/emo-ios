//
//  PngSource.h
//  RenderTest
//
//  Created by Tomer Harry on 2/10/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MattingLib/HomageRenderer/HrSourceI.h"



class PngSource : public CHrSourceI
{
public:
//    PngSource();
//
    PngSource(NSArray *pngFiles);
//    
//    ~PngSource();
    
    virtual int	ReadFrame( int iFrame, image_type **im );
    
	virtual int Close();
private:
    NSArray *m_pngFiles;
    image_type *m_lastImage;
};
