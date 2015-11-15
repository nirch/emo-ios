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
    virtual int	ReadFrame( int iFrame, image_type **im );
    virtual int Close();
private:
    image_type *solidImage;
};
