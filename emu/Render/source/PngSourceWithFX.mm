//
//  PngSource.m
//  RenderTest
//
//  Created by Tomer Harry on 2/10/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import "PngSourceWithFX.h"
#import <UIKit/UIKit.h>
#import "Gpw/Vtool/Vtool.h"
#import "ImageType/ImageTool.h"
#import "ImageType/ImageType.h"


PngSourceWithFX::PngSourceWithFX(NSArray *pngFiles)
{
    m_pngFiles = pngFiles;
    image = NULL;
}

int	PngSourceWithFX::ReadFrame( int iFrame, image_type **im )
{
    if (iFrame < m_pngFiles.count)
    {
        // Get the image
        NSString *imagePath = [m_pngFiles objectAtIndex:iFrame];
        //UIImage* uiImage = [UIImage imageWithContentsOfFile:imagePath];
        UIImage* uiImage = [UIImage imageNamed:@"kim"];
        image = CVtool::UIimage_to_image(uiImage, image);
        *im = image;

        // Reverse channels on the image
        image_bgr2rgb(*im, *im);
        
        // Process effects for the image.
        ProcessEffect(*im, iFrame, im);

        return 1;
    }
    else
    {
        // index out of bounds
        return -1;
    }
}

int PngSourceWithFX::Close()
{
    if (image != NULL) {
        image_destroy(image, 1);
    }
    return 1;
}