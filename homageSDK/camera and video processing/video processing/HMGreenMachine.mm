//
//  HMGreenMachine.m
//  emu
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"HMGreenMachine"

#import "HMGreenMachine.h"
#import "HMBackgroundMarks.h"
#import "HMGMError.h"

#import "HMImageTools.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"
#import "ImageType/ImageTool.h"

@interface HMGreenMachine() {
    
    //int counter;
    CUniformBackground *m_foregroundExtraction;

    // The original captured image
    image_type *m_original_image;
    image_type* image_to_inspect;
    
    // The mask is the result of the algorithm
    // (the result of CUniformBackground -> Process() )
    // It contains the information seperating the user from the background.
    image_type *m_mask;
    image_type *m_background_image;

    // Image sent to display
    image_type *m_display_image;
    
    // Image sent to output
    image_type *m_output_image;
    
    // A processed sample buffer
    //CMSampleBufferRef latestProcessedSampleBuffer;
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
@synthesize outputQueue = _outputQueue;

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
            NSString *errorMessage = [NSString stringWithFormat:@"Missing background image file of name %@", bgImageFilename];
            *error = [[HMGMError alloc] initWithErrorType:HMGMErrorTypeMissingResource
                                             errorMessage:errorMessage
                                                 userInfo:nil];
            return nil;
        }
        self.size = self.backgroundImage.size;

        //
        // Init contour file.
        //
        self.contourFileName = [[NSBundle mainBundle] pathForResource:contourFileName ofType:@"ctr"];
        if (self.contourFileName == nil) {
            // Missing contour file.
            NSString *errorMessage = [NSString stringWithFormat:@"Missing contour file of name %@", contourFileName];
            *error = [[HMGMError alloc] initWithErrorType:HMGMErrorTypeMissingResource
                                             errorMessage:errorMessage
                                                 userInfo:nil];
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
        
    int result = m_foregroundExtraction->Init((char*)self.paramsXMLFileName.UTF8String,
                                              (char*)self.contourFileName.UTF8String,
                                              self.size.height,
                                              self.size.width);

    if (result == -1) {
        // Errors on initializing CUniformBackground
        NSString *errorMessage = [SF:@"FG extraction init failed. Something wrong with ctr or xml file? %@, %@",
                                  self.paramsXMLFileName,
                                  self.contourFileName];

        *error = [[HMGMError alloc] initWithErrorType:HMGMErrorTypeInitializationFailed
                                         errorMessage:errorMessage
                                             userInfo:nil];
        return;
    }
    
    // Initializing background image
    image_type *background_image4 = CVtool::DecomposeUIimage(self.backgroundImage);
    m_background_image = image3_from(background_image4, NULL);
    image_destroy(background_image4, 1);
    
    // Initializing background detection
    self.bgMarks = [HMBackgroundMarks new];
}

-(void)dealloc
{
    if (image_to_inspect) {
        image_destroy(image_to_inspect, 1);
        image_to_inspect = NULL;
    }
    HMLOG(TAG, EM_DBG, @"Dealloced green machine.");
}

#pragma mark - Processing
-(void)prepareFrame:(CMSampleBufferRef)sampleBuffer
{
    // Image buffer to the sample buffer.
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Converting the given PixelBuffer to image_type (and then converting it to BGR)
    // Currently hard coded resizing and cropping 640x480 -> 480x480
    // TODO: make this configurable using the SDK API.
    m_original_image = CVtool::CVPixelBufferRef_to_image_crop(pixelBuffer,
                                                              0, 80, 480, 480,
                                                              m_original_image);
}

-(CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer
{
    image_type* original_bgr_image = image3_to_BGR(m_original_image, NULL);
    
    // Where the magic happens. Process the frame and extract the foreground.
    m_foregroundExtraction->Process(original_bgr_image, 1, &m_mask);
    
    // Stitching the foreground and the background together (and then converting to RGB)
    m_display_image = m_foregroundExtraction->GetImage(m_background_image, m_display_image);
    
    // Convert display image from bgr to rgb
    image3_bgr2rgb(m_display_image);

    // Taking care of the output image.
    CMTime output_t = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.outputQueue) {
        dispatch_async(self.outputQueue, ^{
            // static int i = 0; i++; [HMImageTools saveImageType3:original_bgr_image withName:[SF:@"OriginalBad-%@",@(i)]];
            
            //
            // Using the mask we got from UB->Process()
            // Set pixels recognized as background as alpha with maximum transparency.
            m_output_image = imageA_set_alpha_inversed_mask(original_bgr_image,  // The The original image taken (cropped)
                                                            255,                 // The alpha amount to add to the pixels marked in the mask.
                                                            m_mask,              // The mask calculated by the algorithm ->Process method.
                                                            m_output_image);     // The output image.
            m_output_image->timeStamp = output_t.value;

            // Destroying the temp image
            image_destroy(original_bgr_image, 1);
        });
    }

    // Converting the result of the algo into CVPixelBuffer
    CVImageBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_display_image);
    
    // Getting the sample timing info from the sample buffer
    CMSampleTimingInfo sampleTimingInfo = kCMTimingInfoInvalid;
    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &sampleTimingInfo);

    // Add info to the frame.
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, processedPixelBuffer, &videoInfo);
    
    // Create the processed sample buffer with all
    // needed info and return it.
    CMSampleBufferRef processedSampleBuffer = NULL;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                       processedPixelBuffer,
                                       true,
                                       NULL,
                                       NULL,
                                       videoInfo,
                                       &sampleTimingInfo,
                                       &processedSampleBuffer);
    CFRelease(processedPixelBuffer);

    // Store the latest processed sample buffer.
    return processedSampleBuffer;
}


-(void)inspectFrame
{
    // If we don't have a frame to inspect, skip.
    if (m_original_image == NULL) return;
    
    image_to_inspect = image3_to_BGR(m_original_image, image_to_inspect);

    // Get the background detection mark for this frame.
    HMBGMark bgMark = (HMBGMark)m_foregroundExtraction->ProcessBackground(image_to_inspect, 1);
    HMLOG(TAG, EM_VERBOSE, @"Background mark: %@", @(bgMark));
    
    if (bgMark == HMBGMarkGood && _bgMarkWeight < 1) {
        // Good background (Still under threshold)
        _bgMarkWeight = MIN(_bgMarkWeight + BG_MARK_WEIGHT_DELTA*2, 1);
        self.lastBGMark = bgMark;
        [self postBGMark];
        return;
    } else if (bgMark != HMBGMarkGood) {
        // Bad background
        _bgMarkWeight = MAX(_bgMarkWeight - BG_MARK_WEIGHT_DELTA, 0);
        self.lastBGMark = bgMark;
        [self postBGMark];
        return;
    }
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
    HMLOG(TAG, EM_VERBOSE, @"BGMark:%@ weight:%@", @(self.lastBGMark), @(self.bgMarkWeight));
    
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

-(void)cleanUp
{
    self.bgMarkWeight = 0;
    self.lastBGMark = HMBGMarkUnrecognized;
}


-(void *)latestOutputImage
{
    return m_output_image;
}

@end
