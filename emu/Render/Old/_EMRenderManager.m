//
//  EMRenderManager.m
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
//  --------- --------- --------- --------- --------- --------- --------- ---------
//  NOTE: This render manager will be deprecated in coming versions (probably 1.8)
//  --------- --------- --------- --------- --------- --------- --------- ---------

#define TAG @"EMRenderManager"

#import "EMRenderManager.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMRenderer.h"
#import "AppManagement.h"
#import "EMNotificationCenter.h"
#import "EMRenderManager2.h"

@interface EMRenderManager()

@property (atomic) BOOL isRendering;
@property (atomic) dispatch_queue_t renderingQueue;
@property NSMutableDictionary *requiredRendersPerPackageOID;

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
        self.isRendering = NO;
        self.requiredRendersPerPackageOID = [NSMutableDictionary new];
        [self initRenderingQueue];
        [self initObservers];
    }
    return self;
}

-(void)initRenderingQueue
{
    self.renderingQueue = EMRenderManager2.sh.renderingQueue;
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // Backend downloaded (or failed to download) missing resources for emuticon.
    [nc addUniqueObserver:self
                 selector:@selector(onDownloadedResourcesForEmuticon:)
                     name:emkUIDownloadedResourcesForEmuticon
                   object:nil];

}

#pragma mark - Observers handlers
-(void)onDownloadedResourcesForEmuticon:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if ([info[@"for"] isEqualToString:@"preview"]) {
        NSString *emuDefOID = info[@"emuDefOID"];
        NSString *footageOID = info[@"footageOID"];
        EmuticonDef *emuDef = [EmuticonDef findWithID:emuDefOID context:EMDB.sh.context];
        if ([emuDef allResourcesAvailable]) {
            UserFootage *footage = [UserFootage findWithID:footageOID context:EMDB.sh.context];
            [self renderPreviewForFootage:footage withEmuDef:emuDef];
        }
    }
}

#pragma mark - Rendering management
-(void)renderingRequiredForEmu:(Emuticon *)emu
                          info:(NSDictionary *)info
{
    Package *package = emu.emuDef.package;
    NSString *packageOID = package.oid;

    NSMutableDictionary *emusInPackage = self.requiredRendersPerPackageOID[packageOID];
    if (emusInPackage == nil) {
        emusInPackage = [NSMutableDictionary new];
        self.requiredRendersPerPackageOID[packageOID] = emusInPackage;
    }
    if (emusInPackage[emu.oid] == nil) {
        emusInPackage[emu.oid] = info;
    }
    [self manageRendering];
}

-(void)doneWithEmu:(Emuticon *)emu
{
    Package *package = emu.emuDef.package;
    NSString *packageOID = package.oid;
    NSMutableDictionary *emusInPackage = self.requiredRendersPerPackageOID[packageOID];
    if (emusInPackage == nil) return;
    if (emusInPackage[emu.oid]) {
        [emusInPackage removeObjectForKey:emu.oid];
        if (emusInPackage.count == 0) {
            [self.requiredRendersPerPackageOID removeObjectForKey:packageOID];
        }
    }
}

-(void)manageRendering
{
    if (self.isRendering) return;
    
    NSMutableDictionary *emusInPackage;
    if (self.prioritizedPackageOID == nil) {
        // Any package will do
        emusInPackage = [self.requiredRendersPerPackageOID.allValues firstObject];
    } else {
        emusInPackage = self.requiredRendersPerPackageOID[self.prioritizedPackageOID];
        
        // Didn't find in prioritized package? Any package will do.
        if (emusInPackage == nil)
            emusInPackage = [self.requiredRendersPerPackageOID.allValues firstObject];
    }
    
    // Nothing to render? Do nothing.
    if (emusInPackage == nil) return;
    
    NSDictionary *info = [emusInPackage.allValues firstObject];
    Emuticon *emu = [Emuticon findWithID:info[@"emuticonOID"] context:EMDB.sh.context];
    if (emu) {
        [self enqueueEmu:emu info:info];
    }
}

#pragma mark - Rendering
-(void)enqueueEmu:(Emuticon *)emu info:(NSDictionary *)info
{
    if (self.isRendering) return;
    
    self.isRendering = YES;
    EmuticonDef *emuDef = emu.emuDef;
    UserFootage *footage = [emu mostPrefferedUserFootage];
    
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
    renderer.userDynamicMaskPath = [emuDef pathForUserLayerDynamicMask];
    renderer.frontLayerPath = [emuDef pathForFrontLayer];
    renderer.numberOfFrames = [emuDef.framesCount integerValue];
    renderer.duration = emuDef.duration.doubleValue;
    renderer.outputOID = emu.oid;
    renderer.paletteString = emuDef.palette;
    renderer.outputPath = [EMDB outputPath];
    renderer.shouldOutputGif = YES;
    renderer.effects = emuDef.effects;
    
    // Dispatch the renderer on the rendering queue
    __weak EMRenderManager *weakSelf = self;
    dispatch_async(self.renderingQueue, ^(void){
        //
        // Render in a background thread.
        //
        [renderer render];
        HMLOG(TAG, EM_VERBOSE, @"Finished rendering emuticon %@", renderer.outputOID);
        
        // Update model in main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            emu.wasRendered = @YES;
            emu.renderedSampleUploaded = @NO;
            
            NSInteger count = emu.emuDef.package.rendersCount.integerValue;
            emu.emuDef.package.rendersCount = @(count+1);
            
            count = emu.rendersCount.integerValue;
            emu.rendersCount = @(count+1);
            
            [weakSelf doneWithEmu:emu];
            self.isRendering = NO;
            [EMDB.sh save];
            
            // Notify main thread about rendered emu.
            [[NSNotificationCenter defaultCenter] postNotificationName:hmkRenderingFinished
                                                                object:self
                                                              userInfo:info];
            [self manageRendering];
        });
        
    });
}



-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef
{
//    HMLOG(TAG,
//          EM_DBG,
//          @"Starting to render emuticon named:%@ for preview. %@ frames. User footage frames: %@",
//          emuDef.name,
//          emuDef.framesCount,
//          footage.framesCount
//          );
//    
//    NSDictionary *info = @{
//                           @"for":@"preview",
//                           @"emuDefOID":emuDef.oid,
//                           @"footageOID":footage.oid,
//                           @"packageOID":emuDef.package.oid,
//                           };
//
//    
//    BOOL allResourcesAvailable = [emuDef allResourcesAvailable];
//    if (allResourcesAvailable) {
//        // Render in a background thread.
//        dispatch_async(self.renderingQueue, ^(void){
//            [self _renderPreviewForFootage:(UserFootage *)footage
//                                withEmuDef:(EmuticonDef *)emuDef];
//        });
//    } else {
//        //[EMBackend.sh downloadResourcesForEmuDef:emuDef info:info];
//        return;
//    }
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
    renderer.userDynamicMaskPath = [emuDef pathForUserLayerDynamicMask];
    renderer.frontLayerPath = [emuDef pathForFrontLayer];
    renderer.numberOfFrames = [emuDef.framesCount integerValue];
    renderer.duration = emuDef.duration.doubleValue;
    renderer.outputOID = [[NSUUID UUID] UUIDString];
    renderer.paletteString = emuDef.palette;
    renderer.outputPath = [EMDB outputPath];
    renderer.shouldOutputGif = YES;
    renderer.effects = emuDef.effects;

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



-(void)renderVideoForEmu:(Emuticon *)emu
       requiresWaterMark:(BOOL)requiresWaterMark
         completionBlock:(void (^)(void))completionBlock
               failBlock:(void (^)(void))failBlock
{
    EmuticonDef *emuDef = emu.emuDef;
    UserFootage *footage = [emu mostPrefferedUserFootage];
    HMLOG(TAG,
          EM_DBG,
          @"Starting to render temp video file for emu named:%@. %@ frames.",
          emuDef.name,
          emuDef.framesCount
          );
    
    EMRenderer *renderer = [EMRenderer new];
    renderer.emuticonDefOID = emuDef.oid;
    renderer.footageOID = footage.oid;
    renderer.backLayerPath = [emuDef pathForBackLayer];
    renderer.userImagesPath = [footage pathForUserImages];
    renderer.userMaskPath = [emuDef pathForUserLayerMask];
    renderer.userDynamicMaskPath = [emuDef pathForUserLayerDynamicMask];
    renderer.frontLayerPath = [emuDef pathForFrontLayer];
    renderer.numberOfFrames = [emuDef.framesCount integerValue];
    renderer.duration = emuDef.duration.doubleValue;
    renderer.paletteString = emuDef.palette;
    renderer.shouldOutputGif = NO;
    renderer.effects = emuDef.effects;
    renderer.waterMarkName = requiresWaterMark?@"emuUglyWaterMark":nil;

    
    // Should output a looping video to the temp folder.
    renderer.outputPath = NSTemporaryDirectory();
    renderer.outputOID = emu.oid;
    renderer.shouldOutputVideo = YES;

    
    // Audio track (optional)
    renderer.audioFileURL = emu.audioFileURL;
    renderer.audioStartTime = emu.audioStartTime? emu.audioStartTime.doubleValue : 0;
    
    
    // Video settings (optional, use defaults if not defined)
    renderer.videoFXLoopsCount = emu.videoLoopsCount && emu.videoLoopsCount.integerValue>0? emu.videoLoopsCount.integerValue : EMU_DEFAULT_VIDEO_LOOPS_COUNT;
    renderer.videoFXLoopEffect = emu.videoLoopsEffect? emu.videoLoopsEffect.integerValue : EMU_DEFAULT_VIDEO_LOOPS_FX;
    
    
    // Render
    dispatch_async(self.renderingQueue, ^(void){
        [renderer render];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Callback on the main thread.
            if (emu.videoURL) {
                completionBlock();
            } else {
                failBlock();
            }
        });
    });
}

@end
