//
//  EMRenderManager.m
//  emu
//
//  Singleton by choice.
//  Use as singleton within the app and use instances in unit tests.
//  Initialize with a seperate db instance / context when unit testing.
//
//  Created by Aviv Wolf on 6/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMRenderManager"
#define MAX_CONCURRENT_RENDERS 4

#import "EMRenderManager.h"
#import "EMRenderer.h"
#import "AppManagement.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMDownloadsManager.h"

@interface EMRenderManager()

@property EMDB *db;

// renderingQueue - a concurent queue for rendering emus.
@property (atomic) dispatch_queue_t renderingQueue;

// An unordered pool of emus that require rendering.
@property (nonatomic) NSMutableDictionary *readyForRenderEmusPool;
@property (nonatomic) NSMutableDictionary *renderingEmusPool;
@property (nonatomic) NSString *silhouetteImagesPath;
@property (nonatomic) EMDownloadsManager *downloadsManager;
@property (nonatomic) AFHTTPSessionManager *session;


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
        [sharedInstance finalizeInitializations];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMRenderManager *)sh
{
    return [EMRenderManager sharedInstance];
}

-(void)finalizeInitializations
{
    [self initData];
    [self initDownloadsManager];
    [self initResources];
    [self initQueues];
    [self initObservers];
    if (self.db == nil) self.db = EMDB.sh;
}

-(instancetype)initWithDB:(EMDB *)db session:(AFHTTPSessionManager *)session;
{
    self = [super init];
    if (self) {
        self.db = db;
        self.session = session;
        [self finalizeInitializations];
    }
    return self;
}


-(void)initData
{
    self.readyForRenderEmusPool = [NSMutableDictionary new];
    self.renderingEmusPool = [NSMutableDictionary new];
}

-(void)initQueues
{
    self.renderingQueue = AppManagement.sh.renderingQueue;
}

-(void)initResources
{
    NSString *silhouettePath = [[NSBundle mainBundle] pathForResource:@"sil-1" ofType:@"png"];
    self.silhouetteImagesPath = silhouettePath;
}

-(void)initDownloadsManager
{
    self.downloadsManager = [EMDownloadsManager new];
}

#pragma mark - Observers
-(void)initObservers
{
    
}


#pragma mark - Managing rendering queues
-(void)enqueueEmuOID:(NSString *)emuOID withInfo:(NSDictionary *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _enqueueEmuOID:emuOID withInfo:info];
    });
}

/**
 This method accesses EMDB. Call this only on the main thread!
 */
-(void)_enqueueEmuOID:(NSString *)emuOID withInfo:(NSDictionary *)info
{
    NSAssert(emuOID != nil, @"nil emuOID passed to _enqueueEmuOID");
    NSAssert(info != nil, @"nil info passed to _enqueueEmuOID");
    
    // If emu already has all required local recources, put the emu on the idle queue
    // and it will wait there for concurrent rendering.
    Emuticon *emu = [Emuticon findWithID:emuOID context:self.db.context];
    if ([emu.emuDef allResourcesAvailable]) {
        //
        self.readyForRenderEmusPool[emu.oid] = info;
    } else {
        // Not all resources are available for this emu.
        // enqueue it for download.
        [self.downloadsManager enqueueEmuOIDForDownload:emuOID withInfo:info];
    }
    [self manageQueues];
}

/**
 This method accesses EMDB. Call this only on the main thread!
 */
-(void)manageQueues
{
    //
    // Rendering emus that already have all required resources locally.
    //
    if (self.readyForRenderEmusPool.count < MAX_CONCURRENT_RENDERS && self.readyForRenderEmusPool.count>0) {
        [self popEmuFromIdleEmusPoolAndRender];
    }
}


/**
 This method accesses EMDB. Call this only on the main thread!
 */
-(void)popEmuFromIdleEmusPoolAndRender
{
    // Get the emu
    NSEnumerator *enumerator = [self.readyForRenderEmusPool keyEnumerator];
    NSString *emuOID = [enumerator nextObject];
    Emuticon *emu = [Emuticon findWithID:emuOID context:self.db.context];
    
    // Remove the emu from the idle pool
    NSDictionary *info = self.readyForRenderEmusPool[emuOID];
    [self.readyForRenderEmusPool removeObjectForKey:emuOID];
    HMLOG(TAG, EM_DBG, @"Emu:%@/%@ will send for rendering.", emu.emuDef.package.name, emu.emuDef.name);

    // Put on rendering pool.
    self.renderingEmusPool[emu.oid] = info;

    __weak EMRenderManager *weakSelf = self;
    [self renderEmu:emu completionBlock:^{
        //
        // Succesffuly rendered emu.
        //
        Emuticon *renderedEmu = [Emuticon findWithID:emuOID context:self.db.context];
        [weakSelf.renderingEmusPool removeObjectForKey:renderedEmu.oid];
        renderedEmu.wasRendered = @YES;
        [self.db save];
        [weakSelf manageQueues];
        HMLOG(TAG, EM_VERBOSE, @"Rendered emu: %@", renderedEmu.emuDef.name);
    } failBlock:^{
        //
        // Failed rendering emu.
        //
        Emuticon *failedEmu = [Emuticon findWithID:emuOID context:self.db.context];
        [weakSelf.renderingEmusPool removeObjectForKey:failedEmu.oid];
        failedEmu.wasRendered = @NO;
        [self.db save];
        [weakSelf manageQueues];
        HMLOG(TAG, EM_VERBOSE, @"Failed rendering emu: %@", failedEmu.emuDef.name);
    }];
}


#pragma mark - A single render with completion blocks
-(void)renderEmu:(Emuticon *)emu
 completionBlock:(void (^)(void))completionBlock
       failBlock:(void (^)(void))failBlock
{
    EMRenderer *renderer = [self rendererForEmu:emu];
    renderer.shouldOutputGif = YES;
    renderer.shouldOutputThumb = YES;
    renderer.outputPath = [EMDB outputPath];
    
    // Validate settings
    NSError *error;
    [renderer validateSetupWithError:&error];
    if (error) {
        failBlock();
        return;
    }
    
    // Render
    dispatch_async(self.renderingQueue, ^(void){
        [renderer render];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            [renderer validateSetupWithError:&error];
            if (error) {
                failBlock();
            } else {
                completionBlock();
            }
        });
    });
}

-(void)renderVideoForEmu:(Emuticon *)emu
         completionBlock:(void (^)(void))completionBlock
               failBlock:(void (^)(void))failBlock
{
    EMRenderer *renderer = [self rendererForEmu:emu];
    renderer.shouldOutputVideo = YES;
    
    // Should output a looping video to the temp folder.
    renderer.outputPath = NSTemporaryDirectory();
    
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
            NSError *error = nil;
            [renderer validateSetupWithError:&error];
            if (error) {
                failBlock();
            } else {
                completionBlock();
            }
        });
    });
}

-(EMRenderer *)rendererForEmu:(Emuticon *)emu
{
    EmuticonDef *emuDef = emu.emuDef;
    EMRenderer *renderer = [EMRenderer new];
    renderer.emuticonDefOID = emuDef.oid;
    renderer.backLayerPath = [emuDef pathForBackLayer];
    renderer.userMaskPath = [emuDef pathForUserLayerMask];
    renderer.frontLayerPath = [emuDef pathForFrontLayer];
    renderer.numberOfFrames = [emuDef.framesCount integerValue];
    renderer.duration = emuDef.duration.doubleValue;
    renderer.paletteString = emuDef.palette;
    renderer.outputOID = emu.oid;
    
    // User footage layer
    UserFootage *footage = [emu mostPrefferedUserFootage];
    if (footage) {
        renderer.footageOID = footage.oid;
        renderer.userImagesPath = [footage pathForUserImages];
    } else {
        renderer.footageOID = @"sil";
        NSMutableArray *arr = [NSMutableArray new];
        for (int i=0;i<emu.emuDef.framesCount.integerValue;i++) {
            [arr addObject:self.silhouetteImagesPath];
        }
        renderer.userImagesPathsArray = arr;
    }
    
    // Defaults. Override this as required.
    renderer.shouldOutputGif = NO;
    renderer.shouldOutputThumb = NO;
    renderer.shouldOutputVideo = NO;
    
    return renderer;
}



-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef
{
    
}

@end
