//
//  PngSource.m
//  RenderTest
//
//  Created by Tomer Harry on 2/10/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import "WaterMarkSource.h"
#import <UIKit/UIKit.h>
#import "Gpw/Vtool/Vtool.h"
#import "ImageType/ImageTool.h"

WaterMarkSource::WaterMarkSource(NSString *imageName)
{
    UIImage *wmImage = [UIImage imageNamed:imageName];
    image = CVtool::DecomposeUIimage(wmImage);
//    image_bgr2rgb(image, image);
}

int	WaterMarkSource::ReadFrame( int iFrame, image_type **im )
{
    // Always return the same water mark image.
    *im = image;
    return 1;
}

int WaterMarkSource::Close()
{
    // Destory the solid color image.
    if (image != NULL) {
        image_destroy(image, 1);
    }
    return 1;
}


