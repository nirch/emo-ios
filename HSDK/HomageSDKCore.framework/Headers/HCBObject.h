//
//  HCBObject.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 22/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Base background processing object.
 */
@interface HCBObject : NSObject

/**
 *  The version of the HSDK API and lower level image processing engine.
 *
 *  <MAJOR_SDK_VERSION_NUMBER>.<MINOR_SDK_VERSION_NUMBER>.<CV_BUILD_NUMBER>
 *
 *  @return NSString with version info.
 */
-(NSString *)version;


@end
