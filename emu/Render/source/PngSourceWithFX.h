//
//  PngSourceWithFX.h
//

#import <Foundation/Foundation.h>
#import "MattingLib/HomageRenderer/HrSourceI.h"



class PngSourceWithFX : public CHrSourceI
{
public:
    PngSourceWithFX(NSArray *pngFiles);
    
    virtual int	ReadFrame( int iFrame, image_type **im );
    
	virtual int Close();
private:
    NSArray *m_pngFiles;
};
