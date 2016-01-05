//
//  PngSourceWithFX.h
//
//  Created by Aviv Wolf on 4/18/15.
//

#import <Foundation/Foundation.h>
#import "HrRendererLib/HrSource/HrSourceI.h"

class PngSourceWithFX : public CHrSourceI
{
public:
    PngSourceWithFX(NSArray *pngFiles, CGSize targetSize);
    int	ReadFrame( int iFrame, long long timeStamp, image_type **im );
    int Close();
private:
    NSArray *_pngFiles;
    image_type *_image;
    CGSize _targetSize;
};
