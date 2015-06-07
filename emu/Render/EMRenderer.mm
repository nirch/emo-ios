//
//  EMRender.m
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import "EMRenderer.h"

#import "MattingLib/UniformBackground/UniformBackground.h"
#import "PngSourceWithFX.h"
#import "SolidColorSource.h"
#import "HrRendererLib/HomageRenderer.h"
#import "HrRendererLib/HrSource/HrSourceGif.h"
#import "HrRendererLib/HrOutput/HrOutputGif.h"
#import "HrRendererLib/HrEffect/HrEffectMask.h"
#import "Gpw/Vtool/Vtool.h"
#import "Uigp/GpMemoryLeak.h"

#import "VideoOutput.h"
#import "ThumbOutput.h"

//#import "Uigp/GpMemoryLeak.h"

@implementation EMRenderer

-(void)render
{
    CHomageRenderer *render = new CHomageRenderer();
    
    // Create an array of source images.
    // Also makes sure the number of images we get is the required amount.
    // (skips frames or drops frames as required).
    NSArray *userImages;
    if (self.userImagesPathsArray == nil) {
        userImages = [self imagesPathsInPath:self.userImagesPath
                                     numberOfFrames:self.numberOfFrames];

        if (userImages.count > 0) {
            REMOTE_LOG(@"user images count:%@ firstImageName: %@", @(userImages.count), userImages[0]);
        } else {
            REMOTE_LOG(@"user images empty?!");
        }
    } else {
        userImages = self.userImagesPathsArray;
    }

    
    //
    // Solid color background (always white for now)
    // If required (currently if should output video)
    //
    SolidColorSource *solidBG = NULL;
    if (self.shouldOutputVideo) {
        solidBG = new SolidColorSource([UIColor whiteColor]);
        render->AddSource(solidBG);
    }
    
    //
    // Get the source PNG images.
    //
    PngSourceWithFX *userSource = new PngSourceWithFX(userImages);

    //
    // Set mask if provided.
    //
    // Load the mask
    UIImage *maskImage = [UIImage imageNamed:self.userMaskPath];
    image_type *maskImageType;
    if (maskImage) {
        maskImageType = CVtool::DecomposeUIimage(maskImage);
        CHrEffectMask *maskEffect = new CHrEffectMask();
        maskEffect->Init(maskImageType);
        userSource->AddEffect(maskEffect);
    } else {
        maskImageType = NULL;
    }

    
    //
    // Background source.
    //
    CHrSourceGif *bgSource;
    if (self.backLayerPath) {
        bgSource = new CHrSourceGif();
        bgSource->Init((char*)self.backLayerPath.UTF8String);
    } else {
        bgSource = NULL;
    }

    //
    // Foreground source.
    //
    CHrSourceGif *fgSource;
    if (self.frontLayerPath) {
        fgSource = new CHrSourceGif();
        fgSource->Init((char*)self.frontLayerPath.UTF8String);
    } else {
        fgSource = NULL;
    }
    
    //
    // Dimensions.
    //
    CMVideoDimensions dimensions;
    dimensions.width = 240;
    dimensions.height = 240;
    
    //
    // Output thumb
    //
    ThumbOutput *thumbOutput = NULL;
    if (self.shouldOutputGif || self.shouldOutputVideo) {
        NSInteger thumbFrame;
        if (self.thumbOfFrame) {
            thumbFrame = MIN(self.numberOfFrames-1, self.thumbOfFrame.integerValue);
        } else {
            thumbFrame = self.numberOfFrames-1;
        }
        
        NSString *outputThumbPath = [SF:@"%@/%@.jpg", self.outputPath, self.outputOID];;
        NSURL *thumbOutputURL = [NSURL fileURLWithPath:outputThumbPath];
        thumbOutput = new ThumbOutput(thumbOutputURL, thumbFrame, HM_THUMB_TYPE_JPG);
    }
    
    //
    // Output animated gif
    //
    CHrOutputGif *gifOutput = NULL;
    if (self.shouldOutputGif) {
        NSString *outputGifPath = [SF:@"%@/%@.gif", self.outputPath, self.outputOID];;
        gifOutput = new CHrOutputGif();
        gifOutput->Init((char*)outputGifPath.UTF8String, dimensions.width, dimensions.height, [self msPerFrame]);
        if (self.paletteString != nil) {
            NSString *paletteNSString = self.paletteString;
            const char *paletteConstString = [paletteNSString cStringUsingEncoding:NSASCIIStringEncoding];
            size_t len = strlen(paletteConstString);
            char palette[len];
            memcpy(palette, paletteConstString, len);
            gifOutput->SetPalette(palette);
        }
    }
    
    //
    // Output video
    //
    VideoOutput *videoOutput = NULL;
    if (self.shouldOutputVideo) {
        NSString *outputVideoPath = [SF:@"%@/%@.mp4", self.outputPath, self.outputOID];
        NSURL *videoURL = [NSURL fileURLWithPath:outputVideoPath];
        videoOutput = new VideoOutput(
                                      dimensions,
                                      41.0,
                                      videoURL,
                                      [self fps]);
        
        
        // Loop effects
        if (self.videoFXLoopsCount>0) {
            videoOutput->AddLoopEffect(
                                       self.videoFXLoopsCount,
                                       self.videoFXLoopEffect == 1);
        }
        
        // Audio track
        if (self.audioFileURL) {
            videoOutput->AddAudio(
                                  self.audioFileURL,
                                  self.audioStartTime
                                  );
        }
    }
    
    // Add sources.
    render->AddSource(bgSource);
    render->AddSource(userSource);
    if (fgSource != NULL) render->AddSource(fgSource);

    // Add outputs
    if (gifOutput != NULL) render->AddOutput(gifOutput);
    if (videoOutput != NULL) render->AddOutput(videoOutput);
    if (thumbOutput != NULL) render->AddOutput(thumbOutput);
    
    
    // Render!
    render->Process();
    
    // Finishing up.
    if (gifOutput != NULL)  {
        gifOutput->Close();
        delete gifOutput;
    }
    
    if (videoOutput != NULL) {
        videoOutput->Close();
        delete videoOutput;
    }
    
    if (thumbOutput != NULL) {
        thumbOutput->Close();
        delete thumbOutput;
    }
    
    
    if (solidBG != NULL) {
        solidBG->Close();
        delete solidBG;
    }
    
    if (userSource != NULL) {
        userSource->Close();
        delete userSource;
    }
    
    if (bgSource != NULL) {
        bgSource->Close();
        delete bgSource;
    }
    
    if (fgSource != NULL) {
        fgSource->Close();
        delete fgSource;
    }
    
    delete render;
    
//    gpMemory_leak_print(stdout);
}


#pragma mark - Helper methods
-(int)fps
{
    int framesPerSecond = self.numberOfFrames / self.duration;
    return framesPerSecond;
}

-(int)msPerFrame
{
    int millisecondPerFrame = 1000.0 / [self fps];
    return millisecondPerFrame;
}

-(NSArray *)imagesPathsInPath:(NSString *)path
               numberOfFrames:(NSInteger)numberOfFrames
{
    NSError *error;
    
    // Count the number of stored images.
    NSArray *storedImages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    float storedImagesCount = storedImages.count;
    
    NSMutableArray *pngs = [[NSMutableArray alloc] initWithCapacity:numberOfFrames];
    for (float i = 0;i < numberOfFrames;i+=1.0) {
        
        // Skip or repeat frames as required to produce a list
        // with the required number of frames.
        NSInteger sourceIndex = ((float)i/(float)numberOfFrames)*storedImagesCount+1;
        
        // Just to be safe, Keep index in bounds.
        sourceIndex = MIN(storedImagesCount,sourceIndex);
        
        // Populate the list with the paths to frames.
        pngs[(int)i] = [SF:@"%@/img-%ld.png", path, (long)sourceIndex];
    }
    
    // Return the list of frames.
    return pngs;
}


@end
