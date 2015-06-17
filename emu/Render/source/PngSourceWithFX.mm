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


PngSourceWithFX::PngSourceWithFX(NSArray *pngFiles)
{
    m_pngFiles = pngFiles;
}

int	PngSourceWithFX::ReadFrame( int iFrame, image_type **im )
{
    if (iFrame < m_pngFiles.count)
    {
        NSString *imagePath = [m_pngFiles objectAtIndex:iFrame];
        UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
        *im = CVtool::UIimage_to_image(image, *im);
        image_bgr2rgb(*im, *im);
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
    return 1;
}