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

SolidColorSource::SolidColorSource(UIColor *color)
{
    CGSize size = CGSizeMake(240, 240);
    UIGraphicsBeginImageContext(size);
    UIBezierPath* rPath = [UIBezierPath bezierPathWithRect:CGRectMake(0., 0., size.width, size.height)];
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
    image_destroy(solidImage, 0);
    return 1;
}


