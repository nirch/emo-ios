//
//  PngSource.m
//  RenderTest
//
//  Created by Tomer Harry on 2/10/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//

#import "PngSource.h"
#import <UIKit/UIKit.h>
#import "Gpw/Vtool/Vtool.h"


PngSource::PngSource(NSArray *pngFiles)
{
    m_pngFiles = pngFiles;

}

int	PngSource::ReadFrame( int iFrame, image_type **im )
{
    if (iFrame < m_pngFiles.count)
    {
        NSString *imagePath = [m_pngFiles objectAtIndex:iFrame];
        UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
        *im = CVtool::UIimage_to_image(image, *im);
        MergeAlpha(*im);
        return 1;
    }
    else
    {
        // index out of bounds
        return -1;
    }
}

int PngSource::Close()
{
    return 1;
}