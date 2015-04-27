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
    UIImage *pickedImage = PickedImage( iFrame );
    if (pickedImage == nil) return -1;
    pickedImage = EffectOnImage( pickedImage );
    *im = CVtool::UIimage_to_image(pickedImage, *im);
    MergeAlpha(*im);
    return 1;
}

int PngSourceWithFX::Close()
{
    return 1;
}

UIImage *PngSourceWithFX::PickedImage( int iFrame )
{
    if (iFrame >= m_pngFiles.count) return nil;
    NSString *imagePath = [m_pngFiles objectAtIndex:iFrame];
    UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
    return image;
}

UIImage *PngSourceWithFX::EffectOnImage( UIImage *image )
{
    return image;
}

//UIImage *PngSourceWithFX::PickedImage( int iFrame )
//{
//    int c = (int)m_pngFiles.count;
//    int f;
//    if (iFrame<c/2) {
//        f = iFrame*2;
//    } else {
//        f = (c-1) - (iFrame- c/2)*2;
//    }
//    NSLog(@">>> %@", @(f));
//    NSString *imagePath = [m_pngFiles objectAtIndex:f];
//    UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
//    return image;
//}

#pragma mark - Image pickers effects
