//
//  HMGreenMachine.m
//  emo
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"HMGreenMachine"

#import "HMGreenMachine.h"

#import "HMImageTools.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"
//#import "Image3/Image3Tool.h"
//#import "ImageType/ImageTool.h"
//#import "ImageMark/ImageMark.h"
//#import "Utime/GpTime.h"

@interface HMGreenMachine() {
    
    //int counter;
    CUniformBackground *m_foregroundExtraction;
    image_type *m_original_image;
    image_type *m_foreground_image;
    image_type *m_output_image;
    image_type *m_background_image;
}

@property (nonatomic) UIImage *backgroundImage;
@property (nonatomic) NSString *contourFileName;
@property (nonatomic) NSString *paramsXMLFileName;
@property (nonatomic) CGSize size;

@property NSInteger processCounter;

@end

@implementation HMGreenMachine

@synthesize backgroundImage = _backgroundImage;
@synthesize contourFileName = _contourFileName;
@synthesize processCounter = _processCounter;

+(HMGreenMachine *)greenMachineWithBGImageFileName:(NSString *)bgImageFilename
                                   contourFileName:(NSString *)contourFileName
                                             error:(HMGMError **)error
{
    HMGreenMachine *gm = [[HMGreenMachine alloc] initWithBGImageFileName:bgImageFilename
                                                         contourFileName:contourFileName
                                                                   error:error];
    return gm;
}

-(id)initWithBGImageFileName:(NSString *)bgImageFilename
             contourFileName:(NSString *)contourFileName
                       error:(HMGMError **)error
{
    self = [super init];
    if (self) {
        
        //
        // Initialize background image
        //
        self.backgroundImage = [UIImage imageNamed:bgImageFilename];
        if (self.backgroundImage == nil) {
            // Missing background image file.
            // Missing contour file.
            *error = [HMGMError errorOfType:HMGMErrorTypeMissingResource
                               errorMessage:[NSString stringWithFormat:@"Missing background image file of name %@", bgImageFilename]];
            return nil;
        }
        self.size = self.backgroundImage.size;

        //
        // Init contour file.
        //
        self.contourFileName = [[NSBundle mainBundle] pathForResource:contourFileName ofType:@"ctr"];
        if (self.contourFileName == nil) {
            // Missing contour file.
            *error = [HMGMError errorOfType:HMGMErrorTypeMissingResource
                               errorMessage:[NSString stringWithFormat:@"Missing contour file of name %@", contourFileName]];
            return nil;
        }
        
        // Init params xml file.
        // self.paramsXMLFileName = [[NSBundle mainBundle] pathForResource:@"uniform_bg_params" ofType:@"xml"];

        // Finish up the initialization.
        [self initializeForVideoProcessing:error];
    }
    return self;
}

//     // Link error when using m_foregroundExtraction Init
//    m_foregroundExtraction = new CUniformBackground();
//    int result = m_foregroundExtraction->Init((char*)self.paramsXMLFileName.UTF8String,
//                                              (char*)self.contourFileName.UTF8String,
//                                              self.size.height,
//                                              self.size.width);

-(void)initializeForVideoProcessing:(HMGMError **)error
{
    // Initializing fg extraction algorithm.
    m_foregroundExtraction = new CUniformBackground();
    
    // Initialize the mask/silhouette using the contour file.
    int result = m_foregroundExtraction->ReadMask((char*)self.contourFileName.UTF8String,
                                                  self.size.height,
                                                  self.size.width);
    
    
    if (result == -1) {
        // Errors on initializing CUniformBackground
        NSString *errorMessage = [SF:@"ReadMask failed. Something wrong with ctr or xml file? %@", self.contourFileName];
        *error = [HMGMError errorOfType:HMGMErrorTypeInitializationFailed errorMessage:errorMessage];
        return;
    }
    
    // Initializing background image
    image_type *background_image4 = CVtool::DecomposeUIimage(self.backgroundImage);
    m_background_image = image3_from(background_image4, NULL);
    image_destroy(background_image4, 1);
}

-(CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer
{
    // Count processed frames.
    _processCounter++;
    
    // Image buffer to the sample buffer.
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    // Converting the given PixelBuffer to image_type (and then converting it to BGR)
    m_original_image = CVtool::CVPixelBufferRef_to_image_sample2_crop(pixelBuffer, 0, 0, 240, 240, m_original_image);
    
    image_type* original_bgr_image = image3_to_BGR(m_original_image, NULL);

    // Processing! TODO: linkage problem.
    //m_foregroundExtraction->Process(original_bgr_image, 1, &m_foreground_image);
    
    // Stitching the foreground and the background together (and then converting to RGB)
    //m_output_image = m_foregroundExtraction->GetImage(m_background_image, m_output_image);
    // image3_bgr2rgb(m_output_image);
    
    
    // Converting the result of the algo into CVPixelBuffer
//    CVImageBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(original_bgr_image);

    // Destroying the temp image
    image_destroy(original_bgr_image, 1);
//
//    // Getting the sample timing info from the sample buffer
//    CMSampleTimingInfo sampleTimingInfo = kCMTimingInfoInvalid;
//    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &sampleTimingInfo);
//
//    // Clean up.
//    CMVideoFormatDescriptionRef videoInfo = NULL;
//    CMVideoFormatDescriptionCreateForImageBuffer(NULL, processedPixelBuffer, &videoInfo);
//    CMSampleBufferRef processedSampleBuffer = NULL;
//    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, processedPixelBuffer, true, NULL, NULL, videoInfo, &sampleTimingInfo, &processedSampleBuffer);
//    CFRelease(processedPixelBuffer);
    
    return sampleBuffer;
}

-(void)inspectFrame
{
    if (m_original_image == NULL)
        return;
    
    int bgMark = m_foregroundExtraction->ProcessBackground(m_original_image, 1);
    HMLOG(TAG, VERBOSE, @"Inspecting frame. Background mark:%@", @(bgMark));
    
//    CVPixelBufferRef originalPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//    // Resizing and cropping.
//    // Half the size (currently assuming 480p --> 240p)
//    // TODO: make this more general for SDK.
//    m_original_image = CVtool::CVPixelBufferRef_to_image_sample2_crop(originalPixelBuffer, 0, 0, 240, 240, m_original_image);
//    
    // Log image
    image3_bgr2rgb(m_original_image);
    UIImage *image = [self imageFromImageType3:m_original_image];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    LogImageData(TAG, VERBOSE, image.size.width, image.size.height, imageData);
}



//-(void)inspectCurrentFrame
//{
//    if (m_original_image == nil) return;
//    
//    // Process the background and get the mark.
//    int bgMark = m_foregroundExtraction->ProcessBackground(m_original_image, 1);
//    HMLOG(TAG, VERBOSE, @"background detection mark: %@", @(bgMark));
//}

-(UIImage *)imageFromImageType3:(image_type *)image3
{
    image_type* image4 = image4_from(image3, NULL);
    UIImage *image = CVtool::CreateUIImage(image4);
    return image;
}

//-(void)prepareForVideoProcessing
//{
//    // The background image.
//    CUniformBackground *ubg = new CUniformBackground();
//
//    UIImage *bgImage = self.backgroundImage;
//    image_type *background_image4 = CVtool::DecomposeUIimage(bgImage);
//    m_background_image = image3_from(background_image4, NULL);
//    image_destroy(background_image4, 1);
//    
////    // Read the contour file.
////    m_foregroundExtraction->Init((char*)self.paramsXMLFileName.UTF8String,
////                                 (char*)self.contourFileName.UTF8String,
////                                 self.backgroundImage.size.width,
////                                 self.backgroundImage.size.height);
//    
////    m_foregroundExtraction->ReadMask(
////                                     (char*)self.contourFileName.UTF8String,
////                                     self.backgroundImage.size.width, self.backgroundImage.size.height
////                                     );
//    
//    // Initialize instance vars
//    m_original_image = NULL;
//    m_foreground_image = NULL;
//    m_output_image = NULL;
//    
//    // set the foreground extraction instance var.
//    m_foregroundExtraction = ubg;
//}

@end
