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

@interface EMRenderManager()

@property (atomic) dispatch_queue_t renderingQueue;

@end

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
        [self initRenderingQueue];
    }
    return self;
}

-(void)initRenderingQueue
{
    self.renderingQueue = dispatch_queue_create("Rendering Queue",
                                                DISPATCH_QUEUE_SERIAL);
}

#pragma mark - Rendering
-(void)enqueueEmu:(Emuticon *)emu
{
    // TODO: implement correctly. Need to support long queues.
    // Currently a stupid implementation that just throws the emu to
    // rendering in a background thread.
    
    EmuticonDef *emuDef = emu.emuticonDef;
    UserFootage *footage = [emu prefferedUserFootage];
    
    HMLOG(TAG,
          EM_DBG,
          @"Starting to render emuticon named:%@. %@ frames.",
          emuDef.name,
          emuDef.framesCount
          );
    
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
    renderer.outputOID = emu.oid;

    // Render in a background thread.
    dispatch_async(self.renderingQueue, ^(void){
        [renderer render];
        HMLOG(TAG, EM_DBG, @"Finished rendering emuticon %@", renderer.outputOID);
        dispatch_async(dispatch_get_main_queue(), ^{
            emu.wasRendered = @YES;
            [EMDB.sh save];
        });
    });
}



-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef
{
    HMLOG(TAG,
          EM_DBG,
          @"Starting to render emuticon named:%@ for preview. %@ frames. User footage frames: %@",
          emuDef.name,
          emuDef.framesCount,
          footage.framesCount
          );
    
    // Render in a background thread.
    dispatch_async(self.renderingQueue, ^(void){
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
    
    HMLOG(TAG, EM_DBG, @"Finished rendering preview %@", renderer.outputOID);
    
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
        
        HMLOG(TAG, EM_DBG, @"Notified main thread about preview %@", renderer.outputOID);
    });
}


@end
