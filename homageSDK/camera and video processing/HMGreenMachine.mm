//
//  HMGreenMachine.m
//  emo
//
//  Created by Aviv Wolf on 1/29/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMGreenMachine.h"

#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"
#import "Image3/Image3Tool.h"
#import "ImageType/ImageTool.h"
#import "ImageMark/ImageMark.h"
#import "Utime/GpTime.h"

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

@end

@implementation HMGreenMachine

@synthesize backgroundImage = _backgroundImage;
@synthesize contourFileName = _contourFileName;

+(HMGreenMachine *)greenMachineWithBGImage:(UIImage *)backgroundImage
                           contourFileName:(NSString *)contourFileName
{
    HMGreenMachine *gm = [HMGreenMachine new];
    gm.backgroundImage = backgroundImage;
    gm.contourFileName = contourFileName;
    return gm;
}


-(CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer
{
    return sampleBuffer;
//    if ( m_foregroundExtraction == NULL ) {
//        // Foreground extraction not set yet.
//        // Skip processing and return untouched sample buffer.
//        return sampleBuffer;
//    }
//
//    // Image buffer to the sample buffer.
//    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//    // Converting the given PixelBuffer to image_type (and then converting it to BGR)
//    m_original_image = CVtool::CVPixelBufferRef_to_image_sample2(pixelBuffer, m_original_image);
//    image_type* original_bgr_image = image3_to_BGR(m_original_image, NULL);
//        
//    // Process
//    m_foregroundExtraction->Process(original_bgr_image, 1, &m_foreground_image);
//
//    // Stitching the foreground and the background together (and then converting to RGB)
//    m_output_image = m_foregroundExtraction->GetImage(m_background_image, m_output_image);
//    image3_bgr2rgb(m_output_image);
//
//    // Destroying the temp image
//    image_destroy(original_bgr_image, 1);
//
//    // Converting the result of the algo into CVPixelBuffer
//    CVImageBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_output_image);
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
//    return processedSampleBuffer;
}

-(void)prepareForVideoProcessing
{
//    // The background image.
//    m_foregroundExtraction = new CUniformBackground();
//    image_type *background_image4 = CVtool::DecomposeUIimage(self.backgroundImage);
//    m_background_image = image3_from(background_image4, NULL);
//    image_destroy(background_image4, 1);
//    
//    // Read the contour file.
//    NSString *contourFile = [[NSBundle mainBundle] pathForResource:self.contourFileName ofType:@"ctr"];
//    m_foregroundExtraction->ReadMask(
//                                     (char*)contourFile.UTF8String,
//                                     self.backgroundImage.size.width, self.backgroundImage.size.height
//                                     );
//    
//    // Initialize instance vars
//    m_original_image = NULL;
//    m_foreground_image = NULL;
//    m_output_image = NULL;
}



@end
