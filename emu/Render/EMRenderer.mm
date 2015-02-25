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

#import "EMFiles.h"

#import "MattingLib/UniformBackground/UniformBackground.h"
#import "PngSource.h"
//#import "VideoOutput.h"
#import "MattingLib/HomageRenderer/HomageRenderer.h"
#import "MattingLib/HomageRenderer/HrSourceGif.h"
#import "MattingLib/HomageRenderer/HrOutputGif.h"
#import "Gpw/Vtool/Vtool.h"

@implementation EMRenderer


-(void)render
{
    // Load the mask
    UIImage *maskImage = [UIImage imageNamed:self.userMaskPath];
    image_type *maskImageType = CVtool::DecomposeUIimage(maskImage);

    // Create an array of source images.
    // Also makes sure the number of images we get is the required amount.
    // (skips frames or drops frames as required).
    NSArray *userImages = [self imagesPathsInPath:self.userImagesPath
                                 numberOfFrames:self.numberOfFrames];
    
    //
    // Get the source PNG images and set the user mask.
    //
    CHrSourceI *userSource = new PngSource(userImages);
    userSource->SetAlpha(maskImageType);
    
    //
    // Background source.
    //
    CHrSourceGif *bgSource = new CHrSourceGif();
    bgSource->Init((char*)self.backLayerPath.UTF8String);

    //
    // Foreground source.
    //
    CHrSourceGif *fgSource = new CHrSourceGif();
    fgSource->Init((char*)self.frontLayerPathPath.UTF8String);

    
    //
    // Dimensions.
    //
    CMVideoDimensions dimensions;
    dimensions.width = 240;
    dimensions.height = 240;
    
    //
    // Output gif
    //
    NSString *outputGifPath = [EMFiles outputPathForFileName:[SF:@"%@.gif", self.outputOID]];
    CHrOutputGif *gifOutput = new CHrOutputGif();
    gifOutput->Init((char*)outputGifPath.UTF8String, dimensions.width, dimensions.height, [self msPerFrame]);
    
    
//    //
//    // Output video
//    //
//    NSString *outputVideoPath = [EMFiles outputPathForFileName:[SF:@"%@.mp4", self.outputOID]];
//    NSURL *videoOutputUrl = [[NSURL alloc] initFileURLWithPath:outputVideoPath];
//    VideoOutput *videoOutput = new VideoOutput(dimensions, 11.4, videoOutputUrl, [self fps]);

    //CHrOutputI *outputs[2] = { gifOutput, videoOutput };

    CHrOutputI *outputs[1] = { gifOutput };
    CHomageRenderer *render = new CHomageRenderer();
    render->Process(bgSource, userSource, fgSource, outputs, 1);

    gifOutput->Close();
    userSource->Close();
    bgSource->Close();
    fgSource->Close();
    
//    videoOutput->Close();
    

    // Releasing memory.
    //CFRelease(maskImageType);
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
