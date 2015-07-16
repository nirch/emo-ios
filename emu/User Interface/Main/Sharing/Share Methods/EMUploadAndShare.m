//
//  EMUploadAndShare.m
//  emu
//
//  Created by Aviv Wolf on 7/13/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMUploadAndShare"

#import "EMUploadAndShare.h"
#import <Toast/UIView+Toast.h>
#import "EMBackend.h"
#import "AppManagement.h"

#import <AWSS3.h>

@interface EMUploadAndShare()

@end

@implementation EMUploadAndShare

#pragma mark - AWS
 -(void)uploadBeforeSharing
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Ensure gif exists
    Emuticon *emu = self.objectToShare;
    NSURL *url = [emu animatedGifURL];
    if (![fm fileExistsAtPath:url.path]) {
        [self failed];
        return;
    }
    
    // Start the progress for the upload.
    [self.delegate sharerDidStartLongOperation:self.info label:@"Uploading..."];

    __weak EMUploadAndShare *weakSelf = self;
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = appCFG.bucketName;

    NSString *oid = [emu generateOIDForUpload];
    NSString *key = [emu s3KeyForUploadForOID:oid];
    NSString *name = [emu.emuDef name];

    if (AppManagement.sh.isTestApp) {
        self.sharedLink = [SF:@"http://play-test.emu.im/giftest/%@?r=ios&n=%@", oid, name];
    } else {
        self.sharedLink = [SF:@"http://play.emu.im/gif/%@?r=ios&n=%@", oid, name];
    }
    
    uploadRequest.key = key;
    
    NSURL *localURL = [emu animatedGifURL];
    uploadRequest.body = localURL;
    
    uploadRequest.contentType = @"image/gif";
    uploadRequest.metadata = [emu metaDataForUpload];
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        HMLOG(TAG, EM_VERBOSE, @"Upload: %@ / %@", @(totalBytesSent), @(totalBytesExpectedToSend));
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate sharerDidProgress:totalBytesSent/totalBytesExpectedToSend info:weakSelf.info];
        });
    };
    
    
    AWSTask *uploadTask = [EMBackend.sh.transferManager upload:uploadRequest];
    [uploadTask continueWithExecutor:[AWSExecutor defaultExecutor] withBlock:^id(AWSTask *task) {
        HMLOG(TAG, EM_DBG, @"upload task: %@", task);
        if (task.completed && task.error == nil) {
            HMLOG(TAG, EM_DBG, @"Uploaded gif to s3: %@", key);
            [self success];
        } else if (task.completed && task.error) {
            HMLOG(TAG, EM_DBG, @"Error while uploading gif to s3.");
            [self failed];
        }
        return nil;
    }];
}


-(void)shareAfterUploaded
{
    // Implement this in the derived class.
}

#pragma mark - Results
-(void)failed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        [self.delegate sharerDidFinishWithInfo:self.info];
    });
}

-(void)success
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:LS(@"SHARE_TOAST_UPLOADED")];
        [self shareAfterUploaded];
    });
}

@end
