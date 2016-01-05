//
//  SolidColorSource.h
//
//  Created by Aviv Wolf on 4/18/15.
//

#import <Foundation/Foundation.h>
#import "HrRendererLib/HrSource/HrSourceI.h"

class SolidColorSource : public CHrSourceI
{
public:
    SolidColorSource(UIColor *color, CGSize targetSize);
    int	ReadFrame( int iFrame, long long timeStamp, image_type **im );
    int Close();
private:
    image_type *solidImage;
};
