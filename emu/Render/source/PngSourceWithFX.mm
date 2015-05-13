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
        //if (m_lastImage) image_destroy(m_lastImage, 1);
        m_lastImage = CVtool::DecomposeUIimage(image);
        ProcessEffect(m_lastImage, iFrame, im);
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

#pragma mark - Image pickers effects
