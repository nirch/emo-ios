//
//  EMRenderManager.m
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMRenderManager"

#import "EMRenderManager.h"
#import "EMDB.h"
#import "EMRenderer.h"
#import "EMFiles.h"

@implementation EMRenderManager

#pragma mark - Initialization
// A singleton
+(EMRenderManager *)sharedInstance
{
    static EMRenderManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMRenderManager alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMRenderManager *)sh
{
    return [EMRenderManager sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        [EMFiles ensureOutputPathExists];
    }
    return self;
}

#pragma mark - Rendering
-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef
{
    HMLOG(TAG,
          DBG,
          @"Starting to render emuticon named:%@ for preview. %@ frames. User footage frames: %@",
          emuDef.name,
          emuDef.framesCount,
          footage.framesCount
          );
    
    // Render in a background thread.
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self _renderPreviewForFootage:(UserFootage *)footage
                            withEmuDef:(EmuticonDef *)emuDef];
    });
}

-(void)_renderPreviewForFootage:(UserFootage *)footage
                     withEmuDef:(EmuticonDef *)emuDef
{
    // Create a render object.
    EMRenderer *renderer = [EMRenderer new];
    renderer.emuticonDefOID = emuDef.oid;
    renderer.footageOID = footage.oid;
    renderer.backLayerPath = [emuDef pathForBackLayer];
    renderer.userImagesPath = [footage pathForUserImages];
    renderer.userMaskPath = [emuDef pathForUserLayerMask];
    renderer.frontLayerPath = [emuDef pathForFrontLayer];
    renderer.numberOfFrames = [emuDef.framesCount integerValue];
    renderer.duration = emuDef.duration.doubleValue;
    renderer.outputOID = [[NSUUID UUID] UUIDString];
    
    // Execute the rendering.
    [renderer render];
    
    HMLOG(TAG, DBG, @"Finished rendering preview %@", renderer.outputOID);
    
    // Finished rendering
    // Post a notification to the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create an object in the model for the rendered preview.
        Emuticon *emu = [Emuticon previewWithOID:renderer.outputOID
                                      footageOID:renderer.footageOID
                                  emuticonDefOID:renderer.emuticonDefOID
                                         context:EMDB.sh.context];

        // Post the notification with the render info.
        NSDictionary *info = @{emkEmuticonOID:emu.oid};
        [[NSNotificationCenter defaultCenter] postNotificationName:hmkRenderingFinishedPreview
                                                            object:self
                                                          userInfo:info];
        
        HMLOG(TAG, DBG, @"Notified main thread about preview %@", renderer.outputOID);
    });
}


@end
