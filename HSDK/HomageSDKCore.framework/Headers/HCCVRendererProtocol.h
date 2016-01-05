//
//  HCCVRendererProtocol.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 16/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Internal use protocol of Homage Core SDK.
 *  Used to pass lower level pointers between c++ and Objective-C.
 */
@protocol HCCVRendererProtocol <NSObject>

/**
 *  A pointer to the Homage CV renderer C++ object.
 *  For internal use by the SDK. Don't use this in apps.
 *
 *  @return A pointer to the lower level Homage CV renderer object.
 */
-(void *)cvRenderer;

@end
