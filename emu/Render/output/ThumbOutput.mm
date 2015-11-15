//
//  VideoOutput.m
//  RenderTest
//
//  Created by Tomer Harry on 2/11/15.
//  Copyright (c) 2015 Mac Gyver. All rights reserved.
//
#define TAG @"ThumbOutput"

#import "ThumbOutput.h"
#import "HMImageTools.h"


ThumbOutput::ThumbOutput(
                         NSURL *thumbOutputUrl,
                         NSInteger frameNumber,
                         NSInteger thumbType
                         )
{
    this->thumbOutputUrl = thumbOutputUrl;
    this->frameNumber = frameNumber;
    this->thumbType = thumbType;
}

//im = image_bgr2rgb(im, im);
//UIImage *thumbImage = [HMImageTools createUIImageFromImageType:im withAlpha:NO];
//NSData *imageData = UIImagePNGRepresentation(thumbImage);
//NSError *error;
//
//NSURL *root = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//NSURL *url = [root URLByAppendingPathComponent:[SF:@"src_%@.png", @(iFrame)]];
//[imageData writeToURL:url options:NSDataWritingAtomic error:&error];


int	ThumbOutput::WriteFrame( image_type *im , int iFrame)
{
    if (iFrame != 18) return 1;
    
    // Create the thumb image
    im = image_bgr2rgb(im, im);
    
    NSData *imageData;
    if (thumbType == HM_THUMB_TYPE_PNG) {
        // Write it to a PNG file.
        UIImage *thumbImage = [HMImageTools createUIImageFromImageType:im withAlpha:YES];
        imageData = UIImagePNGRepresentation(thumbImage);
    } else {
        // Write it to a JPG file.
        UIImage *thumbImage = [HMImageTools createUIImageFromImageType:im withAlpha:NO];
        imageData = UIImageJPEGRepresentation(thumbImage, 1);
    }
    
    // Write to file.
    NSError *error;
    [imageData writeToURL:thumbOutputUrl options:NSDataWritingAtomic error:&error];
    if (error) {
        HMLOG(TAG, EM_DBG, @"Error writing thumb image: %@", [error localizedDescription]);
        return -1;
    }
    return 1;
}

int ThumbOutput::Close()
{
    return 1;
}