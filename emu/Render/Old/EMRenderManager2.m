/*
 =====================================================================
 
          ██████╗ ███████╗███╗   ██╗██████╗ ███████╗██████╗
          ██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗
          ██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝
          ██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
          ██║  ██║███████╗██║ ╚████║██████╔╝███████╗██║  ██║
          ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
 
     ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
     ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
     ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
     ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
     ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
     ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

 =====================================================================
 Emu's new render manager
 EMRenderManager2.m

 Created by Aviv Wolf on 7/16/15.
 Copyright (c) 2015 Homage. All rights reserved.
 =====================================================================
 */

#define TAG @"EMRenderManager2"

#import "EMRenderManager2.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMRenderer.h"
#import "AppManagement.h"
#import "EMNotificationCenter.h"
#import "AppManagement.h"

@interface EMRenderManager2()

//
// Data structures & state
//
@property (atomic) BOOL paused;
@property (atomic) NSDictionary *priorities;
@property (nonatomic, readonly) NSInteger maxConcurrentRenders;
@property (nonatomic, readonly) NSMutableDictionary *renderingPool;
@property (nonatomic, readonly) NSMutableDictionary *readyPool;
@property (nonatomic, readonly) NSMutableDictionary *userInfo;
@property (nonatomic, readonly) NSMutableDictionary *oidByIndexPath;

@property (nonatomic, readonly) dispatch_queue_t renderingManagementQueue;

@end

@implementation EMRenderManager2

@synthesize renderingQueue = _renderingQueue;
@synthesize renderingManagementQueue = _renderingManagementQueue;

#define MAX_CONCURENT_RENDERS_SLOW 1
#define MAX_CONCURENT_RENDERS 2

#pragma mark - Initialization
//
// A singleton
//
+(instancetype)sharedInstance
{
    static EMRenderManager2 *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMRenderManager2 alloc] init];
    });
    return sharedInstance;
}

//
// Just an alias for sharedInstance for shorter writing.
//
+(instancetype)sh
{
    return [EMRenderManager2 sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        [self initDataStructures];
        [self initObservers];
    }
    return self;
}

-(void)initDataStructures
{
    _paused = NO;
    _renderingPool = [NSMutableDictionary new];
    _readyPool = [NSMutableDictionary new];
    _userInfo = [NSMutableDictionary new];
    
    _maxConcurrentRenders = MAX_CONCURENT_RENDERS_SLOW;
    NSNumber *deviceGeneration = [AppManagement deviceGeneration];
    if (deviceGeneration) {
        NSInteger gen = deviceGeneration.integerValue;
        if (gen >= 5) {
            _maxConcurrentRenders = MAX_CONCURENT_RENDERS;
        }
    }
}

#pragma mark - Queues
-(dispatch_queue_t)renderingQueue
{
    if (_renderingQueue) return _renderingQueue;
    _renderingQueue = dispatch_queue_create("rendering Queue", DISPATCH_QUEUE_CONCURRENT);
    return _renderingQueue;
}

-(dispatch_queue_t)renderingManagementQueue
{
    if (_renderingManagementQueue) return _renderingManagementQueue;
    dispatch_qos_class_t qos = DISPATCH_QUEUE_PRIORITY_LOW;
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, 0);
    _renderingManagementQueue = dispatch_queue_create("rendering Management Queue", attr);
    return _renderingManagementQueue;
}

#pragma mark - Observers
-(void)initObservers
{
}

#pragma mark - Observers handlers

#pragma mark - Resume/Pause
-(void)resume
{
}

-(void)pause
{
}

-(void)clear
{
    dispatch_async(self.renderingManagementQueue, ^{
        _readyPool = [NSMutableDictionary new];
    });
}

#pragma mark - Adding to the queue
/**
 *  Warning: 
 *  using core data. this should always be called on the main thread.
 */
-(void)enqueueEmu:(Emuticon *)emu
        indexPath:(NSIndexPath *)indexPath
         userInfo:(NSDictionary *)userInfo
{
    #if DEBUG
    NSAssert([NSThread isMainThread], @"%s should be called on the main thread", __PRETTY_FUNCTION__);
    #endif

    NSString *oid = emu.oid;
    if (indexPath) {
        indexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:indexPath.section];
    } else {
        indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    }

    //
    // If already rendering or enqueued, ignore.
    //
    if (self.renderingPool[oid] || self.readyPool[oid]) return;
    
    //
    // If not all resources available, we can't render.
    // It is not the responsibility of the render manager
    // to manage fetching these resources.
    // Just ignore this enqueue request.
    if (![emu.emuDef allResourcesAvailable]) return;

    //
    // We should and can render this emu.
    // Enqueue it for rendering with all required information.
    __weak EMRenderManager2 *wSelf = self;
    NSDictionary *renderInfo = [emu infoForGifRender];
    dispatch_async(self.renderingManagementQueue, ^{
        wSelf.oidByIndexPath[indexPath] = oid;
        wSelf.readyPool[oid] = renderInfo;
        wSelf.userInfo[oid] = userInfo;
        [wSelf _manageQueue];
    });
}

#pragma mark - Queue management
-(void)updatePriorities:(NSDictionary *)priorities
{
    __weak EMRenderManager2 *wSelf = self;
    dispatch_async(self.renderingManagementQueue, ^{
        [wSelf _updatePriorities:priorities];
    });
}

// This method must always be called on the rendering management queue.
-(void)_updatePriorities:(NSDictionary *)priorities
{
    self.priorities = [NSDictionary dictionaryWithDictionary:priorities];
}


// This method must always be called on the rendering management queue.
-(void)_manageQueue
{
    //
    // Check if have something to render and can render it now.
    //
    if (self.readyPool.count == 0 ||
        self.renderingPool.count > MAX_CONCURENT_RENDERS)
        return;
    
    //
    // Pick next thing to render.
    // TODO: prioritize.
    //
    NSString *oid = [self _chooseOID];
    NSDictionary *renderInfo = self.readyPool[oid];
    self.renderingPool[oid] = renderInfo;
    [self.readyPool removeObjectForKey:oid];

    //
    // Render it async on render queue.
    //
    __weak EMRenderManager2 *wSelf = self;
    dispatch_async(self.renderingQueue, ^{
        // Render
        EMRenderer *renderer = [EMRenderer rendererWithInfo:renderInfo];
        [renderer render];
        [wSelf finishedRendering:oid];
    });
}

-(NSString *)_chooseOID
{
    if (self.priorities && self.priorities.count > 0) {
        for (NSString *oid in self.priorities.allKeys) {
            if (self.readyPool[oid]) {
                return oid;
            }
        }
    }
    return  self.readyPool.allKeys.lastObject;
}

-(void)finishedRendering:(NSString *)oid
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update model on the main thread.
        Emuticon *emu = [Emuticon findWithID:oid context:EMDB.sh.context];
        emu.wasRendered = @YES;
        emu.renderedSampleUploaded = @NO;
        NSInteger count = emu.emuDef.package.rendersCount.integerValue;
        emu.emuDef.package.rendersCount = @(count+1);
        count = emu.rendersCount.integerValue;
        emu.rendersCount = @(count+1);
        [EMDB.sh save];
        
        // Post to the UI that a render was finished.
        NSDictionary *userInfo = self.userInfo[oid];
        [[NSNotificationCenter defaultCenter] postNotificationName:hmkRenderingFinished
                                                            object:self
                                                          userInfo:userInfo];

        
        // Finishup & clean up rendering management.
        __weak EMRenderManager2 *wSelf = self;
        dispatch_async(self.renderingManagementQueue, ^{
            // And we are done.
            [wSelf.renderingPool removeObjectForKey:oid];
            [wSelf.userInfo removeObjectForKey:oid];
            [wSelf _manageQueue];
        });
    });
    
}

#pragma mark - Quick renders
// TODO: this is old code that should be revised.
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

    BOOL allResourcesAvailable = [emuDef allResourcesAvailable];
    if (allResourcesAvailable) {
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
        
        dispatch_async(self.renderingQueue, ^(void){
            // Render in a background thread.
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
        });
    }
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
