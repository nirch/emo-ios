/*___                             _                      _
 (  _`\                          (_ )                   ( )
 | | ) |   _    _   _   _   ___   | |    _      _ _    _| |
 | | | ) /'_`\ ( ) ( ) ( )/' _ `\ | |  /'_`\  /'_` ) /'_` |
 | |_) |( (_) )| \_/ \_/ || ( ) | | | ( (_) )( (_| |( (_| |
 (____/'`\___/'`\___x___/'(_) (_)(___)`\___/'`\__,_)`\__,_)
 
 /'\_/`\
 |     |   _ _   ___     _ _    __     __   _ __
 | (_) | /'_` )/' _ `\ /'_` ) /'_ `\ /'__`\( '__)
 | | | |( (_| || ( ) |( (_| |( (_) |(  ___/| |
 (_) (_)`\__,_)(_) (_)`\__,_)`\__  |`\____)(_)
                             ( )_) |
                              \___/'

 Created by Aviv Wolf 
 
 */
#define TAG @"EMDownloadsManager2"

#import "EMDownloadsManager2.h"
#import "EMDB+Files.h"
#import <AWSS3.h>

@interface EMDownloadsManager2()

//
// Data structures.
//
@property (atomic) NSDictionary *priorities;
@property (nonatomic, readonly) NSMutableDictionary *downloadingPool;
@property (nonatomic, readonly) NSMutableDictionary *neededDownloadsPool;
@property (nonatomic, readonly) NSMutableDictionary *pathByOID;
@property (nonatomic, readonly) NSMutableDictionary *userInfo;

@property (nonatomic, readonly) NSURL *rootURL;

@property (nonatomic, readonly) dispatch_queue_t downloadingManagementQueue;

@end

@implementation EMDownloadsManager2

@synthesize downloadingManagementQueue = _downloadingManagementQueue;

#pragma mark - Initialization
//
// A singleton
//
+(instancetype)sharedInstance
{
    static EMDownloadsManager2 *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMDownloadsManager2 alloc] init];
    });
    return sharedInstance;
}

//
// Just an alias for sharedInstance for shorter writing.
//
+(instancetype)sh
{
    return [EMDownloadsManager2 sharedInstance];
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
    _downloadingPool = [NSMutableDictionary new];
    _neededDownloadsPool = [NSMutableDictionary new];
    _userInfo = [NSMutableDictionary new];
    _pathByOID = [NSMutableDictionary new];
    
    _rootURL = [EMDB rootURL];
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
//    _rootURL = [NSURL fileURLWithPath:documentsDirectory];
}

#pragma mark - Queues
-(dispatch_queue_t)downloadingManagementQueue
{
    if (_downloadingManagementQueue) return _downloadingManagementQueue;
    
    dispatch_qos_class_t qos = DISPATCH_QUEUE_PRIORITY_BACKGROUND;
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, 0);
    _downloadingManagementQueue = dispatch_queue_create("downloading management Queue",attr);
    return _downloadingManagementQueue;
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

#pragma mark - JOB ID
-(NSString *)jobIDForOID:(NSString *)oid resourceName:(NSString *)name
{
    return [SF:@"%@/%@", oid, name];
}

#pragma mark - Adding to the queue
-(void)enqueueResourcesForOID:(NSString *)oid
                        names:(NSArray *)names
                         path:(NSString *)path
                     userInfo:(NSDictionary *)userInfo
{
    __weak EMDownloadsManager2 *wSelf = self;
    dispatch_async(self.downloadingManagementQueue, ^{
        [wSelf _enqueueResourcesForOID:oid
                                 names:names
                                  path:path
                              userInfo:userInfo];
    });
}

-(void)_enqueueResourcesForOID:(NSString *)oid
                        names:(NSArray *)names
                         path:(NSString *)path
                     userInfo:(NSDictionary *)userInfo
{
    HMLOG(TAG, EM_DBG, @"Need to download resources: %@", names);
    
    // Filter out resources already downloaded.
    NSMutableArray *resources = [NSMutableArray new];
    for (NSString *name in names) {
        NSString *jobID = [self jobIDForOID:oid resourceName:name];
        // Check if already downloading the given resource
        // If already downloading, skip this resource.
        if (self.downloadingPool[jobID]) continue;
        // Not downloading, add it to the list of resources waiting for download.
        [resources addObject:name];
    }
    
    // If no required resources, ignore this download request.
    if (resources.count < 1) return;
    
    // Put resources on the neededDownloadsPool.
    self.pathByOID[oid] = path;
    self.userInfo[oid] = userInfo;
    self.neededDownloadsPool[oid] = resources;
}

#pragma mark - Queue management
-(void)updatePriorities:(NSDictionary *)priorities
{
    __weak EMDownloadsManager2 *wSelf = self;
    dispatch_async(self.downloadingManagementQueue, ^{
        [wSelf _updatePriorities:priorities];
    });
}

// This method must always be called on the downloading management queue.
-(void)_updatePriorities:(NSDictionary *)priorities
{
    self.priorities = [NSDictionary dictionaryWithDictionary:priorities];
}

-(void)manageQueue
{
    __weak EMDownloadsManager2 *wSelf = self;
    dispatch_async(self.downloadingManagementQueue, ^{
        [wSelf _manageQueue];
    });
}

// This method must always be called on the downloading management queue.
-(void)_manageQueue
{
    while (YES) {
        BOOL jobsAvailable = [self _jobsAvailable];
        BOOL canStartMoreJobs = [self _canStartMoreJobs];
        if (!(jobsAvailable && canStartMoreJobs)) return;
        
        [self _popAndStartJob];
    }
}

-(BOOL)_jobsAvailable
{
    return self.neededDownloadsPool.count > 0;
}

-(BOOL)_canStartMoreJobs
{
    return self.downloadingPool.count < MAX_CONCURRENT_DOWNLOADS;
}

-(NSString *)_chooseOID
{
    if (self.priorities && self.priorities.count > 0) {
        for (NSString *oid in self.priorities.allKeys) {
            if (self.neededDownloadsPool[oid]) {
                return oid;
            }
        }
    }
    return self.neededDownloadsPool.allKeys.firstObject;
}

-(void)_popAndStartJob
{
    NSString *oid = [self _chooseOID];
    
    // Pop a resource to download for the chosen OID
    NSMutableArray *resources = self.neededDownloadsPool[oid];
    NSString *name = resources.lastObject;
    [resources removeLastObject];
    if (resources.count == 0) [self.neededDownloadsPool removeObjectForKey:oid];
    
    // Get the task.
    NSString *jobID = [self jobIDForOID:oid resourceName:name];
    HMLOG(TAG, EM_DBG, @"Download job: %@", jobID);
    AWSTask *downloadTask = [self newDownloadTaskForOID:oid resourceName:name];
    self.downloadingPool[jobID] = downloadTask;
    
    // Download!
    __weak EMDownloadsManager2 *wSelf = self;
    [downloadTask continueWithBlock:^id(AWSTask *task) {
        if (task.completed) {
            if (task.error) {
                HMLOG(TAG, EM_ERR, @"Failed downloading resource: %@", name);
                // Download failed
                dispatch_async(self.downloadingManagementQueue, ^{
                    [wSelf _failedJobForOID:oid resourceName:name];
                });
            } else {
                // Download successful
                dispatch_async(self.downloadingManagementQueue, ^{
                    [wSelf _finishJobForOID:oid resourceName:name];
                });
            }
        }
        return nil;
    }];
}

-(void)_failedJobForOID:(NSString *)oid resourceName:(NSString *)name
{
    [self _finishJobForOID:oid resourceName:name];
}

-(void)_finishJobForOID:(NSString *)oid resourceName:(NSString *)name
{
    NSString *jobID = [self jobIDForOID:oid resourceName:name];
    [self.downloadingPool removeObjectForKey:jobID];

    __weak EMDownloadsManager2 *wSelf = self;
    
    // Post to the UI that a render was finished.
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:hmkDownloadResourceFinished
                                                            object:self
                                                          userInfo:self.userInfo[oid]];
    });

    dispatch_async(self.downloadingManagementQueue, ^{
        [wSelf _manageQueue];
    });
}

#pragma mark - AWS Downloads
-(NSString *)s3KeyForOID:(NSString *)oid resourceName:(NSString *)name
{
    NSString *path = self.pathByOID[oid];
    return [SF:@"packages/%@/%@", path, name];
}

-(NSURL *)localURLForOID:(NSString *)oid resourceName:(NSString *)name
{
    NSString *path = self.pathByOID[oid];
    NSString *localPath = [SF:@"resources/%@", path];
    NSURL *url = [self.rootURL URLByAppendingPathComponent:localPath];

    // Make sure required folder exists.
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:url.path]) {
        NSError *error;
        [fm createDirectoryAtURL:url withIntermediateDirectories:YES
                      attributes:nil error:&error];
        if (error) {
            HMLOG(TAG, EM_ERR, @"Failed creating directory: %@", [error localizedDescription]);
        }
    }
    
    // Add the path compenent of the resource name
    url = [url URLByAppendingPathComponent:name];
    
    // Return the url the path of resources.
    return url;
}

-(AWSTask *)newDownloadTaskForOID:(NSString *)oid resourceName:(NSString *)name
{
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    downloadRequest.bucket = self.bucketName;
    
    NSString *key = [self s3KeyForOID:oid resourceName:name];
    downloadRequest.key = key;
    
    NSURL *localPathURL = [self localURLForOID:oid resourceName:name];
    downloadRequest.downloadingFileURL = localPathURL;

    AWSTask *downloadTask = [self.transferManager download:downloadRequest];
    return downloadTask;
}


@end
