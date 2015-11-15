//
//  WaterMarkSource.h
//
//  Created by Aviv Wolf on 4/18/15.
//

#import <Foundation/Foundation.h>
#import "HrRendererLib/HrSource/HrSourceI.h"

class WaterMarkSource : public CHrSourceI
{
public:
    WaterMarkSource(NSString *imageName, NSInteger width, NSInteger height);
    virtual int	ReadFrame( int iFrame, image_type **im );
    virtual int Close();
private:
    image_type *image;
};
