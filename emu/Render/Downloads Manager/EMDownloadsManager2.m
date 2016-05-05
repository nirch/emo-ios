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
#import "HMFileHash.h"
#import "HMPanel.h"
#import <AFAmazonS3Manager.h>
#import <AFAmazonS3ResponseSerializer.h>
#include <errno.h>

#define EMDownloadManagerErrorDomain @"EMDownloadsManager error"

#define ERR_MD5_COMP_FAILED 10000

@interface EMDownloadsManager2()

@property (nonatomic, readwrite) AFAmazonS3Manager *s3Manager;
@property (nonatomic, readwrite) NSString *bucketName;

//
// Data structures.
//
@property (atomic) NSDictionary *priorities;
@property (nonatomic, readonly) NSMutableDictionary<NSString *,AFHTTPRequestOperation *> *downloadingPool;
@property (nonatomic, readonly) NSMutableDictionary *neededDownloadsPool;
@property (nonatomic, readonly) NSMutableDictionary *pathByOID;
@property (nonatomic, readonly) NSMutableDictionary *taskType;
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
    _taskType = [NSMutableDictionary new];
    
    _rootURL = [EMDB rootURL];
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
//    _rootURL = [NSURL fileURLWithPath:documentsDirectory];
}

-(void)resetManagerWithBucketName:(NSString *)bucketName
{
    self.bucketName = bucketName;
    self.s3Manager = [[AFAmazonS3Manager alloc] initWithAccessKeyID:S3_ACCESS_KEY secret:S3_SECRET_KEY];
    self.s3Manager.requestSerializer.bucket = self.bucketName;
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
//    __weak EMDownloadsManager2 *wSelf = self;
    dispatch_async(self.downloadingManagementQueue, ^{
//        [wSelf.transferManager resumeAll:^(AWSRequest *request) {
//        }];
    });
}

-(void)pause
{
//    __weak EMDownloadsManager2 *wSelf = self;
    dispatch_async(self.downloadingManagementQueue, ^{
//        [wSelf.transferManager pauseAll];
    });
}

-(void)clear
{
//    __weak EMDownloadsManager2 *wSelf = self;
    dispatch_async(self.downloadingManagementQueue, ^{
//        [wSelf _clear];
    });
}

-(void)_clear
{
    // clear all work pending on queues
//    _neededDownloadsPool = [NSMutableDictionary new];
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
    [self enqueueResourcesForOID:oid
                           names:names
                            path:path
                        userInfo:userInfo
                        taskType:nil];
}

-(void)enqueueResourcesForOID:(NSString *)oid
                        names:(NSArray *)names
                         path:(NSString *)path
                     userInfo:(NSDictionary *)userInfo
                     taskType:(NSString *)taskType
{
    __weak EMDownloadsManager2 *wSelf = self;
    dispatch_async(self.downloadingManagementQueue, ^{
        [wSelf _enqueueResourcesForOID:oid
                                 names:names
                                  path:path
                              userInfo:userInfo
                              taskType:taskType];
    });
}

-(void)_enqueueResourcesForOID:(NSString *)oid
                        names:(NSArray *)names
                         path:(NSString *)path
                     userInfo:(NSDictionary *)userInfo
                      taskType:(NSString *)taskType
{
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
    if (taskType) self.taskType[oid] = taskType;
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
    // Choose an OID
    NSString *oid = [self _chooseOID];
    
    // Pop a resource to download for the chosen OID
    NSMutableArray *resources = self.neededDownloadsPool[oid];
    NSString *name = resources.lastObject;
    [resources removeLastObject];
    if (resources.count == 0) [self.neededDownloadsPool removeObjectForKey:oid];
    
    // Create a new download job for a resource related to the OID.
    NSString *jobID = [self jobIDForOID:oid resourceName:name];

    // The S3 key of the resource to download.
    NSString *key = [self s3KeyForOID:oid resourceName:name];

    // The download task.
    __weak EMDownloadsManager2 *wSelf = self;
    AFHTTPRequestOperation *dl;
    dl = [self.s3Manager getObjectWithPath:key
                                  progress:^(NSUInteger bytesRead,
                                             long long totalBytesRead,
                                             long long totalBytesExpectedToRead) {
                                      
                                      // -----------------------
                                      // Handle progress
                                      // -----------------------
                                      
                                  } success:^(id responseObject, NSData *responseData) {
                                      
                                      // -----------------------
                                      // Handle the response.
                                      // -----------------------
                                      dispatch_async(self.downloadingManagementQueue, ^{
                                          [wSelf _handleDownloadOfResponse:responseObject
                                                                      data:responseData
                                                                       oid:oid
                                                                     jobID:jobID
                                                                       key:key
                                                                      name:name];
                                      });
                                      
                                  } failure:^(NSError *error) {
                                      
                                      // -------------------------
                                      // Handle download error.
                                      // -------------------------
                                      HMLOG(TAG, EM_ERR, @"Failed downloading resource: %@", name);
                                      // Download failed
                                      dispatch_async(self.downloadingManagementQueue, ^{
                                          [wSelf _failedJobForOID:oid resourceName:name error:error];
                                      });
                                      
                                  }];
    self.downloadingPool[jobID] = dl;
}

/**
 *  AFAmazonS3Manager finished a download successfully.
 *  Handle that download: Validate what was downloaded and finish the job.
 */
-(void)_handleDownloadOfResponse:(AFAmazonS3ResponseObject *)response
                            data:(NSData *)data
                             oid:(NSString *)oid
                           jobID:(NSString *)jobID
                             key:(NSString *)key
                            name:(NSString *)name
{
    // Save to local temp path
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *tempLocalURL = [self localURLForOID:oid resourceName:name asTempFile:YES];
    [data writeToFile:tempLocalURL.path atomically:YES];
    
    // MD5 validation.
    // Compare md5 of the file to expected md5.
    NSString *expectedMD5 = response.ETag;
    NSString *md5 = [HMFileHash md5HashOfFileAtPath:tempLocalURL.path];
    if (![md5 isEqualToString:expectedMD5]) {
        // :-( that is not the md5 you were looking for.
        // Handle this as a download error.
        [fm removeItemAtURL:tempLocalURL error:nil];
        NSError *error = [[NSError alloc] initWithDomain:EMDownloadManagerErrorDomain
                                                    code:ERR_MD5_COMP_FAILED
                                                userInfo:@{NSLocalizedDescriptionKey:@"MD5 checksum failed. Probably corrupt file."}];
        dispatch_async(self.downloadingManagementQueue, ^{
            [self _failedJobForOID:oid resourceName:name error:error];
        });
        return;
    }
    
    // MD5 validated. Save the temp file to destination.
    NSError *error;
    NSURL *localURL = [self localURLForOID:oid resourceName:name asTempFile:NO];
    [fm removeItemAtURL:localURL error:nil];
    [fm moveItemAtPath:tempLocalURL.path toPath:localURL.path error:&error];
    if (error) {
        // Handle copy temp file to final destination errors.
        // Consider this as a failed download.
        [fm removeItemAtURL:tempLocalURL error:nil];
        dispatch_async(self.downloadingManagementQueue, ^{
            [self _failedJobForOID:oid resourceName:name error:error];
        });
        return;
    }
    
    // All is well. Finish the job on the download management queue.
    dispatch_async(self.downloadingManagementQueue, ^{
        [self _finishJobForOID:oid resourceName:name error:nil];
    });
}


-(void)_cancelledJobForOID:(NSString *)oid resourceName:(NSString *)name
{
    [self _finishJobForOID:oid resourceName:name error:nil];
}

-(void)_failedJobForOID:(NSString *)oid resourceName:(NSString *)name error:(NSError *)error
{
    [self _finishJobForOID:oid resourceName:name error:error];
}

-(void)_finishJobForOID:(NSString *)oid resourceName:(NSString *)name error:(NSError *)error
{
    // Finish the job
    NSString *jobID = [self jobIDForOID:oid resourceName:name];
    
    __weak EMDownloadsManager2 *wSelf = self;
    
    // Post to the UI that a download was finished.
    NSDictionary *userInfoForOID = self.userInfo[oid]?self.userInfo[oid]:@{};
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:userInfoForOID];
    if (error) {
        info[@"error"] = error;
    }
    [self.downloadingPool removeObjectForKey:jobID];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:hmkDownloadResourceFinished
                                                            object:wSelf
                                                          userInfo:info];
    });

    if (error == nil) {
        dispatch_async(self.downloadingManagementQueue, ^{
            [wSelf _manageQueue];
        });
    }
}

#pragma mark - AWS Downloads
-(NSString *)s3KeyForOID:(NSString *)oid resourceName:(NSString *)name
{
    NSString *taskType = self.taskType[oid];
    NSString *path = self.pathByOID[oid];
    if ([taskType isEqualToString:emkDLTaskTypeFootages]) {
        // Footage remote file
        return name;
    } else {
        // Emus render resources.
        return [SF:@"packages/%@/%@", path, name];
    }
}

-(NSURL *)localURLForOID:(NSString *)oid resourceName:(NSString *)name asTempFile:(BOOL)asTempFile
{
    NSString *path = self.pathByOID[oid];
    NSString *localPath = nil;
    if ([self.taskType[oid] isEqualToString:emkDLTaskTypeFootages]) {
        localPath = path;
    } else {
        localPath = [SF:@"resources/%@", path];
    }
    
    NSURL *url = [self.rootURL URLByAppendingPathComponent:localPath];


    // Add the path component of the resource name
    if (asTempFile) name = [name stringByAppendingString:@".tmp"];
    url = [url URLByAppendingPathComponent:name];

    // Make sure required folder exists.
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:url.path]) {
        NSError *error;
        [fm createDirectoryAtURL:url.URLByDeletingLastPathComponent withIntermediateDirectories:YES
                      attributes:nil error:&error];
        if (error) {
            HMLOG(TAG, EM_ERR, @"Failed creating directory: %@", [error localizedDescription]);
        }
    }
    
    // Return the url the path of resources.
    return url;
}

@end
