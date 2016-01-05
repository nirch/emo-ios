//
//  HCBackground.h
//  HomageSDKCore
//
//  Created by Aviv Wolf on 22/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import "HCBObject.h"
#import "HCBGError.h"


@class UIImage;


#pragma mark - Resolutions & Silhouette types
/**
 *  Supported resolutions / sizes of frames to be processed
 *  and / or inspected by the HCBackground object.
 */
typedef NS_ENUM(NSInteger, hcbResolution) {
    /**
     *  Square 1:1 240x240
     */
    hcbResolutionSquare240      = 240,
    
    /**
     *  Square 1:1 480x480
     */
    hcbResolutionSquare480      = 480,
    
    /**
     *  Square 1:1 720x720
     */
    hcbResolutionSquare720      = 720,
    
    /**
     *  Wide screen 16:9 640x360
     */
    hcbResolutionWide360        = 169360,
    
    /**
     *  Wide screen 16:9 1280x720
     */
    hcbResolutionWide720        = 169720,
    
    /**
     *  Wide screen 16:9 1920x1080
     */
    hcbResolutionWide1080       = 1691080,
    
    /**
     *  Custom resolution defined by the user.
     *  (will require the user of the API to provide custom contour files)
     */
    hcbResolutionCustom         = 666
};

/**
 *  Silhouette types.
 */
typedef NS_ENUM(NSInteger, hcbSilhouetteType) {
    /**
     *  When passing this parameter (or when not set), 
     *  will use the default silhouette: HeadAndShoulders.
     */
    hcbSilhouetteTypeDefault                = 0,
    /**
     *  Closeup. <br />
     *  See: https://s3.amazonaws.com/docs-resources/homage_sdk/sil-closeup.png
     */
    hcbSilhouetteTypeCloseup                = 1000,
    /**
     *  Head and shoulders. <br />
     *  See: https://s3.amazonaws.com/docs-resources/homage_sdk/sil-head-and-shoulders.png
     */
    hcbSilhouetteTypeHeadAndShoulders       = 2000,
    /**
     *  Head and chest. <br />
     *  See: https://s3.amazonaws.com/docs-resources/homage_sdk/sil-head-and-chest.png
     */
    hcbSilhouetteTypeHeadAndChest           = 3000,
    /**
     *  Torso. <br />
     *  See: https://s3.amazonaws.com/docs-resources/homage_sdk/sil-torso.png
     */
    hcbSilhouetteTypeTorso                  = 4000,
    /**
     *  American shot. <br />
     *  See: https://s3.amazonaws.com/docs-resources/homage_sdk/sil-american-shot.png
     */
    hcbSilhouetteTypeAmericanShot           = 5000,
    
    
    /**
     *  Custom silhouette provided by a 3rd party / user of the SDK.
     */
    hcbSilhouetteTypeCustom                 = 666
};


#pragma mark - BG Marks
/**
 *  Background detection marks.
 */
typedef NS_ENUM(NSInteger, hcbMark){
    
    /**
     *  An unknown / new mark.
     */
    hcbMarkUnrecognized = -9999,
    
    /**
     *  Noisy background.
     *  A more uniform BG should be used.
     */
    hcbMarkNoisy = -11,
    
    /**
     *  Very low light.
     *  User should shoot in well lit areas.
     */
    hcbMarkDark = -10,
    
    /**
     *  User is out of the silhouette.
     */
    hcbMarkSilhouette = -5,
    
    /**
     *  Head is missing.
     */
    hcbMarkHeadMissing = -6,
    
    /**
     *  A shadow was detected behind the user.
     */
    hcbMarkShadow = -4,
    
    /**
     *  The user's is wearing something that is too
     *  similar to the background.
     */
    hcbMarkCloth = -2,
    
    /**
     *  Good uniform background. Hazah!
     */
    hcbMarkGood = 1,
};

/**
 Background processing.
 API for extracting uniform background behind users' images
 and inspecting images for the quality of the uniform background behind the users.

 The basic workflow with this object:

 - Instantiate the object using the predefined settings provided with the SDK or using custom advanced settings.
 - Send frames for inspection one by one of you are just interested in the uniform background quality mark.
 - To get the BG Mark that is the result of the frame inspection, check the read only latestBGMark property.
 - Send frames for processing one by one if you are interested in actually extracting the user from the background (sets an alpha mask on the background).
 - To get the processed image result, use one of the methods: latestProcessedUIImage, latestProcessedRawImage etc.

 **Important**:

 - The methods of this object are blocking and should be used serially and from the same thread.
 - It is a good idea to always use this object as background work / from a background thread.
 - If you want to process / inspect frames in parallel from more than one thread, create a different instance of the object per thread.
 
 Code Example:

    HCBackground *hcb = [HCBackground new];
    UIImage *image = [UIImage imageNamed:"test-selfie.png"];
    [hcb inspectUIImage:image];
    NSLog(@"The BG Mark of this image is %@", @(hcb.latestBGMark));
    if (hcb.latestBGMark == hcbMarkGood) {
        [hcb processLastInspectedImage];
    }
 */
@interface HCBackground : HCBObject


#pragma mark - Initializations
/**  @name Initialization & Configuration */

/**
 Initialize the BG object with default settings.
 Just calls initWithSilhouetteType:resolutionType: with the following parameters:
 hcbSilhouetteTypeDefault, hcbResolutionSquare480
 
 @return A new instance of the HCBackground object
 
 **Code example**:
 
    HCBackground *hcb = [[HCBackground alloc] init];
 
 or just:
 
    HCBackground *hcb = [HCBackground new];

 */
-(instancetype)init;

/**
 Initialize the BG object for supported resolution and silhouette.
 If you want to instantiate the object with your own custom resolution and ctr file that is not
 provided with the SDK, please use this method initWithCustomSize:
    
 @param silhouetteType hcbSilhouetteType A silhouette type (a related contour file is provided with the SDK).
 @param resolutionType hcbResolution A supported resolution that the SDK provides silhouette files for.
 @param bgImage UIImage (optional) image for the replaced background.
 
 @return A new instance of the HCBackground object

 **Code example**:
 
    HCBackground *hcb = [[HCBackground alloc] initWithSilhouetteType:hcbSilhouetteTypeDefault
                                                      resolutionType:hcbResolutionWide360
                                                             bgImage:[UIImage imageNamed:"clearBG"]];

 */
-(instancetype)initWithSilhouetteType:(hcbSilhouetteType)silhouetteType
                       resolutionType:(hcbResolution)resolutionType
                              bgImage:(UIImage *)bgImage;

/**
 Initialize the BG object for supported resolution and silhouette.
 If you want to instantiate the object with your own custom resolution and ctr file that is not
 provided with the SDK, please use this method initWithCustomSize:
 
 @param silhouetteType hcbSilhouetteType A silhouette type (a related contour file is provided with the SDK).
 @param resolutionType hcbResolution A supported resolution that the SDK provides silhouette files for.
 
 @return A new instance of the HCBackground object
 
 **Code example**:
 
 HCBackground *hcb = [[HCBackground alloc] initWithSilhouetteType:hcbSilhouetteTypeDefault
                                                   resolutionType:hcbResolutionWide360];
 
 */
-(instancetype)initWithSilhouetteType:(hcbSilhouetteType)silhouetteType
                       resolutionType:(hcbResolution)resolutionType;

/**
 *  Initialize the BG object with a custom sized resolution and custom silhouette file.
 *
 *  @param size               CGSize a custom resolution size.
 *  @param ctrFilePath        A local storage file path to a custom ctr file.
 *
 *  @return A new instance of the HCBackground object;
 */
-(instancetype)initWithCustomSize:(CGSize)size
                      ctrFilePath:(NSString *)ctrFilePath;

#pragma mark - BG Mark
/**
 *  Return a default text in english for a bg mark.
 *
 *  @param mark hcbMark
 *
 *  @return NSString of a key that can be mapped to a localized string of the app.
 */
-(NSString *)textForBGMark:(hcbMark)mark;

/**
 *  Return a text key related to a bg mark, that you can map to localized texts of the app.
 *  Use this for testing or example apps.
 *  It is better to use textKeyForBGMark: in real implementations and map the keys to localized strings of the app.
 *
 *  @param mark hcbMark
 *
 *  @return A text message related to the bg mark.
 */
-(NSString *)textKeyForBGMark:(hcbMark)mark;


#pragma mark - Configuration

/**
 *  The actual size of processed images.
 *  (the size of SDK defined resolution types or when a custom size is used).
 */
@property (nonatomic, readonly) CGSize size;


/**
 *  The resolution type. See hcbResolution
 */
@property (nonatomic, readonly) hcbResolution resolutionType;

/**
 *  The path to a required ctr file.
 *  This is mendatory. If a ctr file is missing, an error will be raised during configuration.
 */
@property (nonatomic, readonly) NSString *ctrFilePath;

/**
 *  The path to a required XML file defining extra configuration 
 *  info for the bg removal algorithm.
 *  By default, this will use xml files provided internally with the SDK.
 */
@property (nonatomic, readonly) NSString *paramsXMLFilePath;

/**
 *  The silhouette type (defined in sdk or custom).
 */
@property (nonatomic, readonly) hcbSilhouetteType silhouetteType;

/**
 *  Latest background removal / detection error.
 */
@property (nonatomic, readonly) HCBGError *error;

/**
 *  Returns actual CGSize for a resolutionType.
 *  The CGSize for hcbResolutionCustom is undefined.
 *
 *  @param resolutionType hcbResolution type.
 *
 *  @return CGSize with width and height of the resolution type.
 */
+(CGSize)sizeForResolutionType:(hcbResolution)resolutionType;

/**
 *  Background image (used for camera preview / real time display).
 */
@property (nonatomic, readwrite) UIImage *bgImage;

#pragma mark - Preparing a frame
/**  @name Preparing a frame */

/**
 *  Prepare a frame from CMSampleBufferRef according to settings.
 *  The frame will be cropped or resized if required according to settings.
 *  Will not inspect or process the frame just yet.
 *  To inspect the prepared frame, call inspectFrame
 *  To process the prepared frame, call processFrame
 *
 *  @param sampleBuffer The sample buffer with frame data.
 */
-(void)prepareFrameFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;


#pragma mark - Inspecting (background detection)
/**  @name Inspecting (background detection) */

/**
 *  Inspect the latest prepared frame. sb
 */
-(void)inspect;

/**
 *  Checks the quality of the uniform background on the passed raw image object.
 *  This operation is more light weight compared to processRawImage and it will only
 *  update the background detection mark. It will not produce a processed image as a result.
 *
 *  It is possible to call processLastInspectedImage after this call to actually process this image.
 *
 *  The raw image **must** be exactly in the expected size defined when HCBackground was initialized.
 *
 *  @param rawImage void* pointer to raw image_type object to inspect.
 */
-(void)inspectRawImage:(void *)rawImage;

/**
 *  Converts the passed sample buffer to a raw image_type and calls inspectRawImage:
 *
 *  If the image size is bigger than what was defined when HCBackground was initialized, the image will be cropped to the defined size.
 *  If the image size is smaller than what was defined when HCBackground was initialized, this call will be ignored and an error will be raised.
 *
 *  @param sampleBuffer sampleBuffer CMSampleBufferRef reference to a buffer to inspect.
 */
-(void)inspectSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 *  Converts the passed iOS uiImage object to a raw image_type and calls inspectRawImage:
 *
 *  If the image size is bigger than what was defined when HCBackground was initialized, the image will be cropped to the defined size.
 *  If the image size is smaller than what was defined when HCBackground was initialized, this call will be ignored and an error will be raised.
 *
 *  @param uiImage UIImage iOS image object to inspect.
 */
-(void)inspectUIImage:(UIImage *)uiImage;

/**
 *  Returns the latest BG Mark (of the frame sent for inspection with inspectUIImage:, inspectSampleBuffer:, inspectRawImage: etc.
 */
@property (atomic, readonly) hcbMark latestBGMark;


#pragma mark - Processing (background removal)
/**  @name Processing (background removal) */

/**
 * Process the latest prepared frame.
 */
-(void)process;

/**
 *  Process a frame passed as a raw image_type object.
 *  Stores the processed image data internally.
 *
 *  Use latestProcessedUIImage, latestProcessedRawImage etc to fetch the processed image data.
 *  This method is blocking and calls to processImage will always be called serially.
 *  If you want to process in parallel, make more than a single instance of HCBackground.
 *
 *  @param rawImage void* pointer to raw image_type object to process.
 */
-(void)processRawImage:(void *)rawImage;

/**
 *  Process a frame passed as a CMSampleBufferRef object reference.
 *  Just converts the buffer to a raw image type and calls processRawImage:
 *
 *  @param sampleBuffer CMSampleBufferRef reference to a buffer to process.
 */
-(void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 *  Process a frame passed as a UIImage object.
 *  Just converts the UIImage to a raw image type and calls processRawImage:
 *
 *  @param uiImage UIImage object to process.
 *
 *  @discussion
 *  The UIImage will not include a related timestamp so this can't be used
 *  if time related info doesn't need to be associated with the processed frames.
 *  If time stamp is required (like when creating a video from a series of frames
 *  using AVFoundation) it is best to use prepareFrameFromSampleBuffer: before processing.
 */
-(void)processUIImage:(UIImage *)uiImage;

#pragma mark - Results
/**  @name Getting results */

/**
 *  The time stamp of the latest processed frame.
 *
 *  @return long long Latest processed frame time stamp.
 */
-(long long)timeStamp;

/**
 *  Get the original image sent for processing / bg detection as UIImage.
 *  The image before it was sent to the algorithm, but after it was resized/cropped according to HCBackground configuration.
 *
 *  @return Prepared image for processing as UIImage.
 */
-(UIImage *)preparedUIImage;

/**
 *  Get the original image sent for processing / bg detection as Raw Image.
 *  The image before it was sent to the algorithm, but after it was resized/cropped according to HCBackground configuration.
 *
 *  @return Prepared image for processing as image_type.
 */
-(void *)preparedRawImage;

/**
 *  Get the original image sent for processing / bg detection as CMSampleBufferRef.
 *  The image before it was sent to the algorithm, but after it was resized/cropped according to HCBackground configuration.
 *
 *  @return Prepared image for processing as CMSampleBufferRef.
 */
-(CMSampleBufferRef)preparedSampleBuffer;

/**
 *  Get the latest resulted mask as UIImage.
 *
 *  @return UIImage of the process result mask.
 */
-(UIImage *)resultMaskUIImage;

/**
 *  Get the latest resulted mask as Raw Image.
 *
 *  @return image_type of the process result mask.
 */
-(void *)resultMaskRawImage;

/**
 *  Get the latest resulted mask as CMSampleBufferRef.
 *
 *  @return CMSampleBufferRef of the process result mask.
 */
-(CMSampleBufferRef)resultMaskSampleBuffer;

/**
 *  The result image, including alpha, after the background was removed by the algorithm.
 *
 *  @return UIImage of the background removal result.
 */
-(UIImage *)resultUIImage;

/**
 *  The result image, including alpha, after the background was removed by the algorithm.
 *
 *  @return image_type of the background removal result.
 */
-(void *)resultRawImage;

/**
 *  The result image, after background was removed and replaced with another background.
 *
 *  @return UIImage of the result with the background replaced.
 */
-(UIImage *)resultBGReplacedUIImage;

/**
 *  The result image, after background was removed and replaced with another background.
 *
 *  @return image_type of the result with the background replaced.
 */
-(void *)resultBGReplacedRawImage;

/**
 *  The result image, after background was removed and replaced with another background.
 *
 *  @return CMSampleBufferRef of the result with the background replaced.
 */
-(CMSampleBufferRef)resultBGReplacedSampleBuffer;


/**
 *  Save result files for debugging purposes.
 *  (saved to the app documents directory)
 */
-(void)debugSave;

@end
