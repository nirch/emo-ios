//
//  HCRObject.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 22/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Base rendering object.
 */
@interface HCRObject : NSObject

/**
 *  The version of the HSDK API and lower level renderer engine.
 *  
 *  <MAJOR_SDK_VERSION_NUMBER>.<MINOR_SDK_VERSION_NUMBER>.<CV_BUILD_NUMBER>
 *
 *  @return NSString with version info.
 */
-(NSString *)version;

@end
