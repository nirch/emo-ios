//
//  HCImageTools.h
//  HomageSDKCore
//
//  Objective-c Public wrapper of a subset of the functionality in ImageTools.
//  This can be used in higher levels of the SDK. This wrapper received and returns
//  only managed/ARC UIKit objects and
//  (for example: it doesn't and shouldn't receive or return unmanaged pointers to image_type)
//
//  Created by Aviv Wolf on 14/03/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Objective-c Public wrapper of a subset of the functionality in ImageTools.
 This can be used in higher levels of the SDK. This wrapper received and returns
 only managed/ARC UIKit objects and
 (for example: it doesn't and shouldn't receive or return unmanaged pointers to image_type)
 */
@interface HCImageTools : NSObject

/**
 *  Calculates and returns the distance between two UIImage objects.
 *  Assumes the images are of the same size (returns -1 if they differ in size).
 *
 *  @param img1 The first UIImage object
 *  @param img2 The second UIImage object
 *
 *  @return distance between the images as CGFloat
 */
+(CGFloat)distanceOfImage:(UIImage *)img1 fromImage:(UIImage *)img2;

@end
