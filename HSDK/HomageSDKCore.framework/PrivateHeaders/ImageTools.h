//
//  ImageTools.h
//  HomageSDKCore
//
//  Some utils functions for woring with Homage CV image_type
//
//  This should be private and used in internally in HSDKCore only
//  Don't use this static methods in higher level libs of the SDK
//
//  Created by Aviv Wolf on 30/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

// CV Imports
struct image_type;

@class UIImage;
@class NSString;
@class UIColor;

/// ImageTools - a bunch of static classes for raw images manipulation.
class ImageTools
{
public:
    ImageTools();
    virtual ~ImageTools();

    /**
     *  Convert UIImage to image_type.
     *
     *  @param uiImage UIImage source image
     *  @param im      output image_type (allows to give results in place of already allocated memory)
     *
     *  @return image_type
     */
    static image_type* UIImageToRawImage(UIImage *uiImage,
                                         image_type *im);
    
    /**
     *  Convert UIImage to image_type.
     *
     *  @param uiImage UIImage source image
     *  @param depth   The depth of the result image_type.
     *  @param im      output image_type (allows to give results in place of already allocated memory)
     *
     *  @return image_type
     */
    static image_type* UIImageToRawImage(UIImage *image,
                                         int depth,
                                         image_type *im);
    
    /**
     *  Convert a single channel image to an image with 4 channels.
     *  All three RGB channels will get the same values as the single channel.
     *  The alpha channel will get a zero value for all pixels.
     *
     *  @param im1 The single channel image_type
     *  @param im4 (optional) pointer to 4 channel image_type for reusing allocated memory.
     *
     *  @return image_type 4 channel image.
     */
    static image_type* Image4MaskFromImage1(image_type *im1, image_type *im4);
    
    static image_type* ImageMasked(image_type *sim, image_type *mask, image_type *im);
    
    /**
     *  Convert UIImage to image_type and crop it.
     *
     *  @param uiImage UIImage source image
     *  @param x       crop starting position x
     *  @param y       starting position y
     *  @param width   cropped result width
     *  @param height  cropped result height
     *  @param im      output image_type (allows to give results in place of already allocated memory)
     *
     *  @return image_type
     */
    static image_type* UIImageToRawImageCropped(UIImage *uiImage,
                                                int x,
                                                int y,
                                                int width,
                                                int height,
                                                image_type *im);
    
    
    /**
     *  Create a new image_type image in given size with provided color as solid background.
     *
     *  @param color  UIColor solid color background.
     *  @param width  int width of the image.
     *  @param height int height of the image.
     *
     *  @return image_type new image in given size filled with provided color.
     */
    static image_type* CreateRawSolidColorImage(UIColor *color,
                                                int width,
                                                int height);
    
    
    static image_type* CreateRawImageFromBytesArray(GLubyte *byteArray,
                                                    int width,
                                                    int height,
                                                    image_type *im);
    
    /**
     *  Save UIImage object as png file.
     *  Will be saved to default app documents folder.
     *
     *  @param uiImage UIImage to saves
     *  @param name    The name of the png file (without extenstion)
     */
    static void UIImageSaveAsPNG(UIImage *uiImage, NSString *name);
    
    /**
     *  Save UIImage object as png file in a given path.
     *
     *  @param uiImage UIImage to save
     *  @param path    Path to save the png image to.
     *  @param name    The name of the png file (without extension)
     */
    static void UIImageSaveAsPNG(UIImage *uiImage, NSString *path, NSString *name);
    
    /**
     *  Create a UIImage from image_type data.
     *  Ignores alpha channel even if exists in imageData.
     *
     *  @param imageData image_type with image data.
     *
     *  @return new UIImage object.
     */
    static UIImage* CreateUIImage(image_type *imageData);
    
    /**
     *  Create a UIImage from image_type data.
     *
     *  @param imageData    image_type with image data.
     *  @param includeAlpha BOOL indicating if to include the alpha channel or not if available.
     *
     *  @return new UIImage object.
     */
    static UIImage* CreateUIImage(image_type *imageData, BOOL includeAlpha);
    
    /**
     *  <#Description#>
     *
     *  @param imageData      <#imageData description#>
     *  @param originalBuffer <#originalBuffer description#>
     *
     *  @return <#return value description#>
     */
    static CMSampleBufferRef SampleBufferFromRawImage(void *imageData, CMSampleBufferRef originalBuffer);
    
    /**
     *  Calculates and returns the distance between two images.
     *
     *  @param img1 First UIImage object.
     *  @param img2 Second UIImage object.
     *
     *  @return The distance between the images as CGFloat
     */
    static CGFloat DistanceBetweenTwoImages(UIImage *img1, UIImage *img2);
};

