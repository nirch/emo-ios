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
#import "HMImageTools.h"


PngSourceWithFX::PngSourceWithFX(NSArray *pngFiles, CGSize targetSize)
{
    _pngFiles = pngFiles;
    _image = NULL;
    _targetSize = targetSize;
}

int	PngSourceWithFX::ReadFrame( int iFrame, long long timeStamp, image_type **im )
{
    if (iFrame < _pngFiles.count)
    {
        // Get the image
        NSString *imagePath = [_pngFiles objectAtIndex:iFrame];
        UIImage* uiImage = [UIImage imageWithContentsOfFile:imagePath];
        
        // Need to scale image to requested target size.
        uiImage = [HMImageTools image:uiImage scaledProportionallyToSize:_targetSize];
        
        if (uiImage == nil) {
            return -1;
        }
        
        _image = CVtool::UIimage_to_image(uiImage, _image);
        *im = _image;

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
    if (_image != NULL) {
        image_destroy(_image, 1);
    }
    return 1;
}