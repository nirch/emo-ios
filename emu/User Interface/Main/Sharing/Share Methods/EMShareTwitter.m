//
//  EMShareTwitter.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import Social;
@import Accounts;

#import "EMShareTwitter.h"
#import <Toast/UIView+Toast.h>
#import "AppDelegate.h"

@interface EMShareTwitter()

@end

@implementation EMShareTwitter


-(instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


#pragma mark - Share
-(void)share
{
    [super share];
    [self shareSelection];
}


-(void)shareAnimatedGif
{
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *gifData = [emu animatedGifData];
    
    // Get Twitter account
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *twitterType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSDictionary *postOptions = nil;

    // Attempt to post the postMessage
    [account requestAccessToAccountsWithType:twitterType
                                     options:postOptions
                                  completion:^(BOOL accessGranted, NSError *error) {
                                      if (!accessGranted || error) {
                                          [self failed];
                                          return;
                                      }
                                      NSArray *accountsList = [account accountsWithAccountType:twitterType];
                                      if (accountsList == nil || accountsList.count < 1) {
                                          [self failed];
                                          return;
                                      }
                                      [self shareMediaData:gifData
                                            twitterAccount:accountsList.lastObject
                                                 mediaType:@"image/gif"
                                             fileExtension:@"gif"];
                                  }];
}

-(void)shareVideo
{
    // Get the data of the animated gif.
    Emuticon *emu = self.objectToShare;
    NSData *videoData = [emu videoData];
    
    // Get Twitter account
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *twitterType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSDictionary *postOptions = nil;
    
    // Attempt to post the postMessage
    [account requestAccessToAccountsWithType:twitterType
                                     options:postOptions
                                  completion:^(BOOL accessGranted, NSError *error) {
                                      if (!accessGranted || error) {
                                          [self failed];
                                          return;
                                      }
                                      NSArray *accountsList = [account accountsWithAccountType:twitterType];
                                      if (accountsList == nil || accountsList.count < 1) {
                                          [self failed];
                                          return;
                                      }
                                      [self shareMediaData:videoData
                                            twitterAccount:accountsList.lastObject
                                                 mediaType:@"public.mpeg-4"
                                             fileExtension:@"mp4"];
                                  }];
}

-(void)failed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:LS(@"SHARE_TOAST_TWITTER_FAILED")];
        [self.delegate sharerDidFailWithInfo:self.info];
        self.view.alpha = 1;
    });
}

-(void)success
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:LS(@"SHARE_TOAST_SHARED")];
        [self.delegate sharerDidShareObject:self.objectToShare withInfo:self.info];
        self.view.alpha = 1;
    });
}


-(void)shareMediaData:(NSData *)data
       twitterAccount:(ACAccount *)account
            mediaType:(NSString *)mediaType
        fileExtension:(NSString *)fileExtension
{
    // Create the upload post request
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"] parameters:nil];
    
    // Add image to post
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [postRequest addMultipartData:data withName:@"media" type:mediaType filename:[SF:@"%@.%@", uuid, fileExtension]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:LS(@"SHARE_TOAST_UPLOADING_TO_TWITTER")];
    });
    
    // Execute the post
    [postRequest setAccount:account];
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        // Post code block
        if (error) {
            [self failed];
            return;
        }
        [self success];
    }];
}

@end
