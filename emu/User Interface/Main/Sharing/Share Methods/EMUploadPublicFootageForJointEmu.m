//
//  EMUploadAndShare.m
//  emu
//
//  Created by Aviv Wolf on 7/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#import "EMUploadPublicFootageForJointEmu.h"
#import <Toast/UIView+Toast.h>
#import "EMBackend.h"
#import "AppManagement.h"
#import <AWSS3.h>

@interface EMUploadPublicFootageForJointEmu()

@property (atomic) NSMutableDictionary *progressByFile;
@property (atomic) NSInteger uploadedFilesCount;
@property (atomic) NSInteger requiredFilesToUploadCount;
@property (atomic) NSString *jeOID;

@property (atomic) NSMutableArray *uploadRequests;

@end

@implementation EMUploadPublicFootageForJointEmu

#pragma mark - AWS


 -(void)uploadBeforeSharing
{
    self.finishedSuccessfully = NO;
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    
    self.uploadRequests = [NSMutableArray new];

    // Progress
    self.progressByFile = [NSMutableDictionary new];
    self.uploadedFilesCount = 0;
    self.requiredFilesToUploadCount = 3;
    
    // Joint emu OID
    NSString *jointEmuOID = [self.emu jointEmuOID];
    self.jeOID = jointEmuOID;

    // Upload video capture
    AWSS3TransferManagerUploadRequest *uploadRequestRaw = [AWSS3TransferManagerUploadRequest new];
    uploadRequestRaw.bucket = appCFG.bucketName;
    uploadRequestRaw.body = [NSURL fileURLWithPath:self.footage.pathToUserVideo];
    uploadRequestRaw.contentType = @"video/mov";
    uploadRequestRaw.ACL = AWSS3ObjectCannedACLPublicRead;
    [self uploadRequest:uploadRequestRaw jeOID:jointEmuOID file:@"raw" ext:@"mov"];

    // Upload video mask
    AWSS3TransferManagerUploadRequest *uploadRequestMask = [AWSS3TransferManagerUploadRequest new];
    uploadRequestMask.bucket = appCFG.bucketName;
    uploadRequestMask.body = [NSURL fileURLWithPath:self.footage.pathToUserDMaskVideo];
    uploadRequestMask.contentType = @"video/mov";
    uploadRequestMask.ACL = AWSS3ObjectCannedACLPublicRead;
    [self uploadRequest:uploadRequestMask jeOID:jointEmuOID file:@"mask" ext:@"mov"];
    
    // Upload video thumb
    AWSS3TransferManagerUploadRequest *uploadRequestThumb = [AWSS3TransferManagerUploadRequest new];
    uploadRequestThumb.bucket = appCFG.bucketName;
    uploadRequestThumb.body = [NSURL fileURLWithPath:self.footage.pathToUserThumb];
    uploadRequestThumb.contentType = @"image/png";
    uploadRequestThumb.ACL = AWSS3ObjectCannedACLPublicRead;
    [self uploadRequest:uploadRequestThumb jeOID:jointEmuOID file:@"thumb" ext:@"png"];
}

-(void)shareAfterUploaded
{
}

-(void)uploadRequest:(AWSS3TransferManagerUploadRequest *)uploadRequest
               jeOID:(NSString *)jeOID
                file:(NSString *)file
                 ext:(NSString *)ext
{
    NSString *s3Key = [self.emu s3KeyForFile:file slot:self.slotIndex ext:ext];
    uploadRequest.key = s3Key;
    
    __weak EMUploadPublicFootageForJointEmu *weakSelf = self;
    uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat progress = (double)totalBytesSent/(double)totalBytesExpectedToSend;
            [weakSelf updateProgressForFile:file progressValue:progress];
            [weakSelf.delegate sharerDidProgress:self.averageProgress info:@{@"jeOID":jeOID}];
        });
    };
    
    AWSTask *uploadTask = [EMBackend.sh.transferManager upload:uploadRequest];
    [uploadTask continueWithExecutor:[AWSExecutor defaultExecutor] withBlock:^id(AWSTask *task) {
        if (task.completed && task.error == nil) {
            [self success];
        } else if (task.completed && task.error) {
            [self failed];
        }
        return nil;
    }];
    [self.uploadRequests addObject:uploadRequest];
}

-(void)updateProgressForFile:(NSString *)file progressValue:(CGFloat)progressValue
{
    self.progressByFile[file] = @(progressValue);
}

-(CGFloat)averageProgress
{
    if (self.progressByFile.count == 0) return 0.0;
    CGFloat totalProgress = 0;
    for (NSNumber *p in self.progressByFile.allValues) {
        totalProgress += [p floatValue];
    }
    return totalProgress/(double)self.progressByFile.count;
}

-(void)cancel
{
    for (AWSS3TransferManagerUploadRequest *uploadRequest in self.uploadRequests) {
        [uploadRequest cancel];
    }
    [self.uploadRequests removeAllObjects];
}

#pragma mark - Results
-(void)failed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate sharerDidFailWithInfo:@{@"uploaded":@(NO), @"jeOID":self.jeOID}];
        [self.delegate sharerDidFinishWithInfo:@{@"uploaded":@(NO), @"jeOID":self.jeOID}];
    });
}

-(void)success
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.uploadedFilesCount += 1;
        if (self.uploadedFilesCount >= self.requiredFilesToUploadCount) {
            self.finishedSuccessfully = YES;
            [self.delegate sharerDidFinishWithInfo:@{@"uploaded":@(YES), @"jeOID":self.jeOID}];
        }
    });
}

@end
