//
//  PngSource.m
//  RenderTest
//
//  Created by Tomer Harry on 2/10/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import "SolidColorSource.h"
#import <UIKit/UIKit.h>
#import "Gpw/Vtool/Vtool.h"

SolidColorSource::SolidColorSource(UIColor *color, CGSize targetSize)
{
    UIGraphicsBeginImageContext(targetSize);
    UIBezierPath* rPath = [UIBezierPath bezierPathWithRect:CGRectMake(0., 0., targetSize.width, targetSize.height)];
    [color setFill];
    [rPath fill];
    UIImage *solidColorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Store the single solid color image that will be used on all frames.
    solidImage = CVtool::DecomposeUIimage(solidColorImage);
}

int	SolidColorSource::ReadFrame( int iFrame, image_type **im )
{
    // Always return the same solid color image.
    *im = solidImage;
    return 1;
}

int SolidColorSource::Close()
{
    // Destory the solid color image.
    if (solidImage != NULL) {
        image_destroy(solidImage, 1);
    }
    return 1;
}


