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
    if ( m_foregroundExtraction == NULL ) {
        // Foreground extraction not set yet.
        // Skip processing and return untouched sample buffer.
        return sampleBuffer;
    }
    
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Converting the given PixelBuffer to image_type (and then converting it to BGR)
    m_original_image = CVtool::CVPixelBufferRef_to_image_sample2(pixelBuffer, m_original_image);
    //m_original_image = CVtool::CVPixelBufferRef_to_image(pixelBuffer, m_original_image);
    image_type* original_bgr_image = image3_to_BGR(m_original_image, NULL);
        
        // Extracting the foreground
        
        //    // SAVING IMAGE TO DISK
        //    static int counter = 0;
        //    counter++;
        //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        //    NSString *path = [NSString stringWithFormat:@"/%d.jpg" , counter];
        //    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:path];
        //    image_type *image = image4_from(original_bgr_image, NULL);
        //    UIImage *bgImage = CVtool::CreateUIImage(image);
        //    [UIImageJPEGRepresentation(bgImage, 1.0) writeToFile:dataPath atomically:YES];
        //    image_destroy(image, 1);
        
        //[self saveImageType3:original_bgr_image];
        
        
    m_foregroundExtraction->Process(original_bgr_image, 1, &m_foreground_image);
    
    // Stitching the foreground and the background together (and then converting to RGB)
    m_output_image = m_foregroundExtraction->GetImage(m_background_image, m_output_image);
    image3_bgr2rgb(m_output_image);
    
    // Destroying the temp image
    image_destroy(original_bgr_image, 1);
    
    //[self saveImageType3:m_output_image withName:@"before"];
    
    // Converting the result of the algo into CVPixelBuffer
    CVImageBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_output_image);
    
    //image_type *processedImageType = CVtool::CVPixelBufferRef_to_image(processedPixelBuffer, NULL);
    //[self savePixelBuffer:processedPixelBuffer withName:@"afterPixel"];
    //[self saveImageType3:processedImageType withName:@"afterImageType"];
    
    // Getting the sample timing info from the sample buffer
    CMSampleTimingInfo sampleTimingInfo = kCMTimingInfoInvalid;
    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &sampleTimingInfo);
    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, processedPixelBuffer, &videoInfo);
    
    CMSampleBufferRef processedSampleBuffer = NULL;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, processedPixelBuffer, true, NULL, NULL, videoInfo, &sampleTimingInfo, &processedSampleBuffer);
    
    CFRelease(processedPixelBuffer);
    //CFRelease(videoInfo);
    
    return processedSampleBuffer;
        
        // Updating the current pixelbuffer with the new foreground/background image
        //[self updatePixelBuffer:pixelBuffer fromImageType:m_output_image];
}

-(void)prepareForVideoProcessing
{
    // The background image.
    m_foregroundExtraction = new CUniformBackground();
    image_type *background_image4 = CVtool::DecomposeUIimage(self.backgroundImage);
    m_background_image = image3_from(background_image4, NULL);
    image_destroy(background_image4, 1);
    
    // Read the contour file.
    NSString *contourFile = [[NSBundle mainBundle] pathForResource:self.contourFileName ofType:@"ctr"];
    m_foregroundExtraction->ReadMask(
                                     (char*)contourFile.UTF8String,
                                     self.backgroundImage.size.width, self.backgroundImage.size.height
                                     );
    
    // Initialize instance vars
    m_original_image = NULL;
    m_foreground_image = NULL;
    m_output_image = NULL;
}



@end
