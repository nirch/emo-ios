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
#import "HrRendererLib/HomageRenderer.h"
#import "HrRendererLib/HrSource/HrSourceGif.h"
#import "HrRendererLib/HrOutput/HrOutputGif.h"
#import "HrRendererLib/HrEffect/HrEffectMask.h"
#import "Gpw/Vtool/Vtool.h"

@implementation EMRenderer




-(void)render
{
    // Create an array of source images.
    // Also makes sure the number of images we get is the required amount.
    // (skips frames or drops frames as required).
    NSArray *userImages = [self imagesPathsInPath:self.userImagesPath
                                 numberOfFrames:self.numberOfFrames];

    if (userImages.count > 0) {
        REMOTE_LOG(@"user images count:%@ firstImageName: %@", @(userImages.count), userImages[0]);
    } else {
        REMOTE_LOG(@"user images empty?!");
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
    // Output gif
    //
    NSString *outputGifPath = [SF:@"%@/%@.gif", self.outputPath, self.outputOID];;
    CHrOutputGif *gifOutput = new CHrOutputGif();
    gifOutput->Init((char*)outputGifPath.UTF8String, dimensions.width, dimensions.height, [self msPerFrame]);

    if (self.paletteString != nil) {
        NSString *paletteNSString = self.paletteString;
        const char *paletteConstString = [paletteNSString cStringUsingEncoding:NSASCIIStringEncoding];
        size_t len = strlen(paletteConstString);
        char palette[len];
        memcpy(palette, paletteConstString, len);
        gifOutput->SetPalette(palette);
    }
    

    // Add sources and render to outputs.
    CHomageRenderer *render = new CHomageRenderer();
    render->AddSource(bgSource);
    render->AddSource(userSource);
    if (fgSource != NULL) render->AddSource(fgSource);
    render->AddOutput(gifOutput);
    render->Process();
    
    // Finishing up.
    if (gifOutput != NULL)  {
        gifOutput->Close();
        delete gifOutput;
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
