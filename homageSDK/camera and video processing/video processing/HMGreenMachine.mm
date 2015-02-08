//
//  HMGreenMachine.m
//  emo
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"HMGreenMachine"

#import "HMGreenMachine.h"
#import "HMBackgroundMarks.h"

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
@property (nonatomic) HMBackgroundMarks *bgMarks;
@property (nonatomic) HMBGMark lastBGMark;

// The weight is a value between 0 (bad backgrounds) and 1 (good background)
@property (nonatomic) CGFloat bgMarkWeight;
#define BG_MARK_WEIGHT_DELTA 0.1

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
        self.paramsXMLFileName = [[NSBundle mainBundle] pathForResource:@"uniformBGParams" ofType:@"xml"];

        // BG marks
        self.lastBGMark = HMBGMarkUnrecognized;
        self.bgMarkWeight = BG_MARK_WEIGHT_DELTA;
        
        // Finish up the initialization.
        [self initializeForVideoProcessing:error];
    }
    return self;
}

-(void)initializeForVideoProcessing:(HMGMError **)error
{
    // Initializing fg extraction algorithm.
    m_foregroundExtraction = new CUniformBackground();
    
    // Initialize the mask/silhouette using the contour file.
    int result = m_foregroundExtraction->ReadMask((char*)self.contourFileName.UTF8String,
                                                  self.size.height,
                                                  self.size.width);
    
//    int result = m_foregroundExtraction->Init((char*)self.paramsXMLFileName.UTF8String,
//                                              (char*)self.contourFileName.UTF8String,
//                                              self.size.height,
//                                              self.size.width);

    if (result == -1) {
        // Errors on initializing CUniformBackground
        NSString *errorMessage = [SF:@"FG extraction init failed. Something wrong with ctr or xml file? %@, %@",
                                  self.paramsXMLFileName,
                                  self.contourFileName];
        *error = [HMGMError errorOfType:HMGMErrorTypeInitializationFailed errorMessage:errorMessage];
        return;
    }
    
    // Initializing background image
    image_type *background_image4 = CVtool::DecomposeUIimage(self.backgroundImage);
    m_background_image = image3_from(background_image4, NULL);
    image_destroy(background_image4, 1);
    
    // Initializing background detection
    self.bgMarks = [HMBackgroundMarks new];
}

-(void)prepareFrame:(CMSampleBufferRef)sampleBuffer
{
    // Image buffer to the sample buffer.
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Converting the given PixelBuffer to image_type (and then converting it to BGR)
    // Currently hard coded resizing and cropping 640x480 -> 480x480
    // TODO: make this configurable using the SDK API.
    m_original_image = CVtool::CVPixelBufferRef_to_image_crop(pixelBuffer,
                                                              0, 0, 480, 480,
                                                              m_original_image);
}

-(CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer
{
    image_type* original_bgr_image = image3_to_BGR(m_original_image, NULL);
    
    // Where the magic happens. Process the frame and extract the foreground.
    m_foregroundExtraction->Process(original_bgr_image, 1, &m_foreground_image);
    
    // Stitching the foreground and the background together (and then converting to RGB)
    m_output_image = m_foregroundExtraction->GetImage(m_background_image, m_output_image);
    image3_bgr2rgb(m_output_image);
    
    // Destroying the temp image
    image_destroy(original_bgr_image, 1);
    
    // Converting the result of the algo into CVPixelBuffer
    CVImageBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_output_image);
    
    // Getting the sample timing info from the sample buffer
    CMSampleTimingInfo sampleTimingInfo = kCMTimingInfoInvalid;
    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &sampleTimingInfo);    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, processedPixelBuffer, &videoInfo);
    CMSampleBufferRef processedSampleBuffer = NULL;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, processedPixelBuffer, true, NULL, NULL, videoInfo, &sampleTimingInfo, &processedSampleBuffer);
    CFRelease(processedPixelBuffer);
    
    return processedSampleBuffer;
}

-(void)inspectFrame
{
    // If we don't have a frame to inspect, skip.
    if (m_original_image == NULL) return;
    
    // Get the background detection mark for this frame.
    HMBGMark bgMark = (HMBGMark)m_foregroundExtraction->ProcessBackground(m_original_image, 1);
    
    if (bgMark == HMBGMarkGood && _bgMarkWeight < 1) {
        _bgMarkWeight = MIN(_bgMarkWeight + BG_MARK_WEIGHT_DELTA*2, 1);
        self.lastBGMark = bgMark;
        [self postBGMark];
        return;
    } else if (_bgMarkWeight > 0) {
        _bgMarkWeight = MAX(_bgMarkWeight - BG_MARK_WEIGHT_DELTA, 0);
        self.lastBGMark = bgMark;
        [self postBGMark];
        return;
    } if (bgMark != self.lastBGMark) {
        self.lastBGMark = bgMark;
        [self postBGMark];
        return;
    }

    // Log image
//    image3_bgr2rgb(m_original_image);
//    UIImage *image = [self imageFromImageType3:m_original_image];
//    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
//    LogImageData(TAG, VERBOSE, image.size.width, image.size.height, imageData);
}

-(void)postBGMark
{
    // Will be posted on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _postBGMark];
    });
    
}

-(void)_postBGMark
{
    HMLOG(TAG, VERBOSE, @"BGMark:%@ weight:%@", @(self.lastBGMark), @(self.bgMarkWeight));
    
    // Gather some info.
    NSMutableDictionary *info = [NSMutableDictionary new];

    // The current background mark.
    info[hmkInfoBGMark] = @(self.lastBGMark);
    
    // The weight of a good background mark.
    info[hmkInfoBGMarkWeight] = @(self.bgMarkWeight);
    
    // If weight is 1, we are satisfied with the background.
    if (self.bgMarkWeight == 1)
        info[hmkInfoGoodBGSatisfied] = @YES;

    // Post the notification with the info.
    [[NSNotificationCenter defaultCenter] postNotificationName:hmkNotificationBGDetectionInfo
                                                        object:self
                                                      userInfo:info];
}

-(UIImage *)imageFromImageType3:(image_type *)image3
{
    image_type* image4 = image4_from(image3, NULL);
    UIImage *image = CVtool::CreateUIImage(image4);
    return image;
}

@end
