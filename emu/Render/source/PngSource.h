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
    PngSource(NSArray *pngFiles);
    
    virtual int	ReadFrame( int iFrame, image_type **im );
    
	virtual int Close();
private:
    NSArray *m_pngFiles;
};
