//
//  EMShareViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMShareVC"

@import MobileCoreServices;

#import "EMShareVC.h"
#import "EMShareProtocol.h"
#import "EMShareCell.h"
#import "EMLabel.h"
#import "EMDB.h"
#import "EMShareVC.h"
#import "EMShareInputVC.h"
#import "NSString+Utilities.h"

// Share methods
#import "EMShareCopy.h"
#import "EMShareSaveToCameraRoll.h"
#import "EMShareMail.h"
#import "EMShareAppleMessage.h"
#import "EMShareFBMessanger.h"
#import "EMShareDocumentInteraction.h"
#import "EMShareTwitter.h"
#import "EMShareFacebook.h"
#import "EMShareInstoosh.h"

#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>

#import "iRate.h"

#import <Toast/UIView+Toast.h>
#import "EMRenderManager2.h"
#import "EMShareInputDelegate.h"

@interface EMShareVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    EMShareDelegate,
    EMShareInputDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiFBMButtonContainer;
@property (weak, nonatomic) IBOutlet UIView *guiRenderingView;
@property (weak, nonatomic) IBOutlet UIProgressView *guiRenderingProgress;
@property (weak, nonatomic) IBOutlet EMLabel *guiRenderingProgressLabel;

@property (nonatomic, weak) UIButton *fbmButton;
@property (nonatomic, weak) UIButton *fbmSmallerButton;

@property (nonatomic) NSArray *shareMethods;
@property (nonatomic) NSDictionary *shareNames;
@property (nonatomic) NSDictionary *shareColors;
@property (nonatomic) NSDictionary *shareMethodsNames;
@property (nonatomic) EMShare *sharer;
@property (nonatomic) EMShare *previousSharer;

@property (nonatomic) CGRect screenRect;

@end

@implementation EMShareVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initGUI];
    if (_allowFBExperience) {
        [self hideExtraShareOptionsAnimated:NO];
    } else {
        [self showExtraShareOptionsAnimated:NO];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)initGUI
{
    // The big messenger button.
    self.screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = self.screenRect.size.height;
    CGFloat buttonWidth = 90;
    if (screenHeight <= 480.0) buttonWidth -= 20;
    
    UIButton *button = [FBSDKMessengerShareButton circularButtonWithStyle:FBSDKMessengerShareButtonStyleBlue
                                                                    width:buttonWidth];
    button.tag = 0;
    [button addTarget:self action:@selector(onPressedShareButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.guiFBMButtonContainer addSubview:button];
    self.fbmButton = button;
    
    // Collection view scrolling
    self.guiCollectionView.delegate = self;
}

-(void)viewDidLayoutSubviews
{
    CGFloat x = self.guiFBMButtonContainer.bounds.size.width / 2.0;
    CGFloat y = self.guiFBMButtonContainer.bounds.size.height / 2.0;
    self.fbmButton.center = CGPointMake(x, y);
}

#pragma mark - Show/Hide all share options
-(void)showExtraShareOptionsAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self showExtraShareOptionsAnimated:NO];
        }];
        return;
    }

    self.guiCollectionView.alpha = 1;
    CGFloat width = self.view.bounds.size.width;
    self.guiCollectionView.transform = CGAffineTransformIdentity;

    self.guiFBMButtonContainer.transform = CGAffineTransformMakeTranslation(-width, 0);
    self.guiFBMButtonContainer.alpha = 0;
}

-(void)hideExtraShareOptionsAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideExtraShareOptionsAnimated:NO];
        }];
        return;
    }
    
    self.guiCollectionView.alpha = 0;
    CGFloat x = self.view.bounds.size.width;
    self.guiCollectionView.transform = CGAffineTransformMakeTranslation(x, 0);

    self.guiFBMButtonContainer.alpha = 1;
    self.guiFBMButtonContainer.transform = CGAffineTransformIdentity;
}


#pragma mark - Allow/Disallow facebook experience
-(void)setAllowFBExperience:(BOOL)allowFBExperience
{
    _allowFBExperience = allowFBExperience;
    if (!allowFBExperience && self.guiFBMButtonContainer.alpha !=0) {
        [self showExtraShareOptionsAnimated:YES];
    }
}


#pragma mark - Update
-(void)update
{
    EMMediaDataType mediaTypeToShare = [self.delegate sharerDataTypeToShare];
    
    if (mediaTypeToShare == EMMediaDataTypeGIF) {
        // A priorized list of share methods for animated gifs.
        NSMutableArray *arr = [NSMutableArray new];
        [arr addObject:@(emkShareMethodFacebookMessanger)];
        [arr addObject:@(emkShareMethodAppleMessages)];
        [arr addObject:@(emkShareMethodFacebook)];
        [arr addObject:@(emkShareMethodTwitter)];
        [arr addObject:@(emkShareMethodMail)];
        [arr addObject:@(emkShareMethodSaveToCameraRoll)];
        [arr addObject:@(emkShareMethodCopy)];
        self.shareMethods = arr;
    } else {
        // A priorized list of share methods for video.
        NSMutableArray *arr = [NSMutableArray new];
        [arr addObject:@(emkShareMethodFacebookMessanger)];
        [arr addObject:@(emkShareMethodAppleMessages)];
        [arr addObject:@(emkShareMethodDocumentInteraction)];
        [arr addObject:@(emkShareMethodInstagram)];
        [arr addObject:@(emkShareMethodMail)];
        [arr addObject:@(emkShareMethodSaveToCameraRoll)];
        [arr addObject:@(emkShareMethodCopy)];
        self.shareMethods = arr;
    }
    
    [self.guiCollectionView reloadData];
}


#pragma mark - Data
-(void)initData
{
    self.shareNames = @{
                        @(emkShareMethodFacebookMessanger):     @"facebookm",
                        @(emkShareMethodTwitter):               @"twitter",
                        @(emkShareMethodFacebook):              @"facebook",
                        @(emkShareMethodAppleMessages):         @"iMessage",
                        @(emkShareMethodWhatsapp):              @"whatsapp",
                        @(emkShareMethodMail):                  @"mail",
                        @(emkShareMethodSaveToCameraRoll):      @"savetocm",
                        @(emkShareMethodCopy):                  @"copy",
                        @(emkShareMethodDocumentInteraction):   @"sharemisc",
                        @(emkShareMethodInstagram):             @"instagram"
                        };
    
    self.shareColors = @{
                         @(emkShareMethodInstagram): [@"835A51FF" colorFromRGBAHexString],
                         @(emkShareMethodTwitter): [@"1188A5FF" colorFromRGBAHexString],
                         };
    
    [self update];
}


#pragma mark - UICollectionViewDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat w = self.screenRect.size.width/6.5;
    if (self.screenRect.size.width <= 320) w = self.screenRect.size.width/5.2;
    return CGSizeMake(w, 80);
}


#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.shareMethods.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"share cell";
    EMShareCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                          forIndexPath:indexPath];
    [self configureCell:cell
           forIndexPath:indexPath];
    return cell;
}


-(void)configureCell:(EMShareCell *)cell
       forIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *shareMethod = self.shareMethods[indexPath.item];
    NSString *buttonImageName = self.shareNames[shareMethod];
    UIImage *shareIcon = [UIImage imageNamed:buttonImageName];
    [cell.guiButton setImage:shareIcon forState:UIControlStateNormal];
    cell.guiButton.tag = indexPath.item;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    CGFloat edgeInsets = 10;
    CGFloat width = collectionView.bounds.size.width;
    CGFloat contentSize = edgeInsets + self.shareMethods.count * 70;
    if (contentSize < width) {
        edgeInsets = (width - contentSize) / 2.0;
    }
    return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets);
}

#pragma mark - Analytics
-(HMParams *)paramsForEmuticon:(Emuticon *)emuticon
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_EMUTICON_INSTANCE_OID value:emuticon.oid];
    [params addKey:AK_EP_EMUTICON_NAME valueIfNotNil:emuticon.emuDef.name];
    [params addKey:AK_EP_EMUTICON_OID valueIfNotNil:emuticon.emuDef.oid];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:emuticon.emuDef.package.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:emuticon.emuDef.package.oid];
    [params addKey:AK_EP_AUDIO_FILE_SET value:@(emuticon.audioFilePath!=nil)];
    [params addKey:AK_EP_VIDEO_LOOP_TYPE_SET valueIfNotNil:emuticon.videoLoopsEffect];
    [params addKey:AK_EP_VIDEO_LOOPS_COUNT_SET valueIfNotNil:emuticon.videoLoopsCount];
    return params;
}

#pragma mark - Sharing
-(void)shareEmuticonUsingMethodAtIndex:(NSInteger)index
{
    NSString *emuticonOID = [self.delegate shareObjectIdentifier];
    Emuticon *emu = [Emuticon findWithID:emuticonOID context:EMDB.sh.context];
    
    // What to share? gif/video
    EMMediaDataType mediaDataTypeToShare = [self.delegate sharerDataTypeToShare];
    NSString *mediaDataTypeName;
    if (mediaDataTypeToShare == EMMediaDataTypeGIF) {
        mediaDataTypeName = @"gif";
    } else {
        mediaDataTypeName = @"video";
    }
    
    // Info about the share
    EMKShareMethod shareMethod = [self.shareMethods[index] integerValue];
    HMParams *params = [self paramsForEmuticon:emu];
    [params addKey:AK_EP_SHARE_METHOD value:self.shareNames[@(shareMethod)]];
    [params addKey:AK_EP_SENDER_UI valueIfNotNil:@"shareVC"];
    [params addKey:AK_EP_SHARED_MEDIA_TYPE value:mediaDataTypeName];
    
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_PRESSED_SHARE_BUTTON
                          info:params.dictionary];

    // Share
    [self shareEmuticon:emu
          mediaDataType:mediaDataTypeToShare
            usingMethod:shareMethod
                   info:params.dictionary];
}

-(void)shareEmuticon:(Emuticon *)emu
       mediaDataType:(EMMediaDataType)mediaDataType
         usingMethod:(EMKShareMethod)method
                info:(NSDictionary *)info
{
    // Only one share operation at a time.
    if (self.sharer) return;
    
    NSMutableDictionary *shareInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    
    // Choose a sharer class.
    if (method == emkShareMethodCopy) {
        
        //
        // Copy to clipboard
        //
        self.sharer = [EMShareCopy new];
        
    } else if (method == emkShareMethodSaveToCameraRoll) {
        
        //
        // Save to camera roll
        //
        self.sharer = [EMShareSaveToCameraRoll new];
        
    } else if (method == emkShareMethodMail) {
        
        //
        // Mail client
        //
        self.sharer = [EMShareMail new];
        
    } else if (method == emkShareMethodAppleMessages) {
        
        //
        // Apple messages
        //
        self.sharer = [EMShareAppleMessage new];
        
    } else if (method == emkShareMethodFacebookMessanger) {
        
        //
        // Facebook messagenger
        //
        self.sharer = [EMShareFBMessanger new];

    } else if (method == emkShareMethodFacebook) {
        
        //
        // Facebook (uploads to s3 and shares a link to a web page)
        //
        self.sharer = [EMShareFacebook new];

    } else if (method == emkShareMethodDocumentInteraction) {
        
        //
        // Documents interaction
        //
        self.sharer = [EMShareDocumentInteraction new];
        
    } else if (method == emkShareMethodTwitter) {
        
        //
        // Twitter
        //
        self.sharer = [EMShareTwitter new];
        self.sharer.requiresUserInput = YES;
        
    } else if (method == emkShareMethodInstagram) {
    
        //
        // Instagram
        //
        self.sharer = [EMShareInstoosh new];

    } else {
        
        //
        // Unimplemented.
        //
        UIAlertController *alert = [UIAlertController new];
        alert.title = @"Unimplemented";
        alert.message = @"This share method is not implemented yet.";
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Got it"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        HMLOG(TAG, EM_ERR, @"Unimplemented share method.");
        
    }
    
    //
    // Set info for the sharer object
    //
    NSString *shareMethodName = self.shareNames[@(method)];
    NSMutableDictionary *extraCFG = [NSMutableDictionary new];
    UIColor *shareColor = self.shareColors[@(method)];
    if (shareColor) extraCFG[@"color"] = shareColor;
    UIImage *icon = [UIImage imageNamed:shareMethodName];
    if (icon) extraCFG[@"icon"] = icon;
    NSString *defaultHashTags = [emu.emuDef.package sharingHashTagsStringForShareMethodNamed:shareMethodName];
    if (defaultHashTags) extraCFG[@"sharingHashTags"] = defaultHashTags;
    
    self.sharer.info = shareInfo;
    self.sharer.extraCFG = extraCFG;
    self.sharer.objectToShare = emu;
    self.sharer.delegate = self;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.shareOption = mediaDataType == EMMediaDataTypeGIF? emkShareOptionAnimatedGif:emkShareOptionVideo;
    [self _shareEmuUsingCurrentSharer];
}

-(void)_shareEmuUsingCurrentSharer
{
    // Make sure sharer exists and object to share is an Emu
    if (self.sharer == nil || self.sharer.objectToShare == nil) return;
    if (![self.sharer.objectToShare isKindOfClass:[Emuticon class]]) return;
    Emuticon *emu = self.sharer.objectToShare;

    //
    // First, check if need to create video for this share.
    //
    if (self.sharer.shareOption == emkShareOptionVideo) {
        if (emu.videoURL == nil) {
            // Temp video file not created yet.
            // Render it before sharing.
            BOOL requiresWaterMark = YES;
            if (emu.emuDef.package.preventVideoWaterMarks.boolValue) requiresWaterMark = NO;
            if ([self.sharer isKindOfClass:[EMShareFBMessanger class]]) requiresWaterMark = NO;
            [self renderVideoBeforeShareForEmu:emu requiresWaterMark:requiresWaterMark];
            return;
        }
    }
    
    // We got the media we need. Share it.
    [self _share];
}

-(void)_share
{
    Emuticon *emu = self.sharer.objectToShare;
    if (![emu isKindOfClass:[Emuticon class]]) return;
    
    // Share (or request user input if required before sharing)
    if (self.sharer.requiresUserInput) {
        // Ask user for input before sharing.
        EMShareInputVC *shareInputVC = [EMShareInputVC shareInputVCInParentVC:self.parentViewController];
        
        // Title
        shareInputVC.titleColor = self.sharer.extraCFG[@"color"];
        shareInputVC.titleIcon = self.sharer.extraCFG[@"icon"];
        NSURL *thumbURL = emu.thumbURL;
        shareInputVC.sharedMediaIcon = thumbURL? [UIImage imageWithContentsOfFile:thumbURL.path] : nil;

        // Delegation
        shareInputVC.delegate = self;
        
        // Default hashtags (optional)
        shareInputVC.defaultHashTags = self.sharer.extraCFG[@"sharingHashTags"];
        
        [shareInputVC updateUI];
        [shareInputVC showAnimated:YES];
    } else {
        [self.sharer share];
    }
}


-(void)renderVideoBeforeShareForEmu:(Emuticon *)emu
                  requiresWaterMark:(BOOL)requiresWaterMark
{
    self.guiCollectionView.hidden = YES;
    self.guiFBMButtonContainer.hidden = YES;
    self.guiRenderingView.hidden = NO;
    self.guiRenderingProgress.progress = 0;
    self.guiRenderingProgressLabel.text = LS(@"EMUNIZING");
    
    [EMRenderManager2.sh renderVideoForEmu:emu
                         requiresWaterMark:requiresWaterMark
                           completionBlock:^{
                               // If we are here, emu.videoURL points to the rendered video.
                               [self _share];
                               self.guiRenderingView.hidden = YES;
                               self.guiCollectionView.hidden = NO;
                               self.guiFBMButtonContainer.hidden = NO;
                           } failBlock:^{
                               // Failed :-(
                               // No rendered video available.
                               self.sharer = nil;
                               [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
                               self.guiRenderingView.hidden = YES;
                               self.guiCollectionView.hidden = NO;
                               self.guiFBMButtonContainer.hidden = NO;
                           }];
}



#pragma mark - EMShareDelegate
-(void)sharerDidShareObject:(id)sharedObject withInfo:(NSDictionary *)info
{
    [self.sharer cleanUp];
    self.previousSharer = self.sharer;
    self.sharer = nil;
    NSString *emuOID = info[AK_EP_EMUTICON_INSTANCE_OID];
    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    emu.lastTimeShared = [NSDate date];
    [EMDB.sh save];
    
    // Goals acheived!
    [HMPanel.sh experimentGoalEvent:GK_SHARED];
    if ([info[AK_EP_SHARED_MEDIA_TYPE] isEqualToString:@"gif"]) [HMPanel.sh experimentGoalEvent:GK_SHARED_GIF];
    if ([info[AK_EP_SHARE_METHOD] isEqualToString:@"facebookm"]) [HMPanel.sh experimentGoalEvent:GK_SHARE_FBM];
    if ([info[AK_EP_SHARED_MEDIA_TYPE] isEqualToString:@"video"]) {
        // Any shared video.
        [HMPanel.sh experimentGoalEvent:GK_SHARED_VIDEO];
        
        // Shared video with user playing around with the settings and audio of the video.
        if ([emu engagedUserVideoSettings]) {
            [HMPanel.sh experimentGoalEvent:GK_SHARED_ENGAGING_VIDEO];
            [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_ENGAGED_VIDEO_SHARES_USING_APP_COUNT];
            [HMPanel.sh reportSuperParameterKey:AK_S_DID_EVER_SHARE_ENGAGED_VIDEO_USING_APP value:@YES];
        }
        
        // Analytics for video shares
        [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_VIDEO_SHARES_USING_APP_COUNT];
        [HMPanel.sh reportSuperParameterKey:AK_S_DID_EVER_SHARE_VIDEO_USING_APP value:@YES];
    }
    
    
    // Analytics for any share
    [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_SHARES_USING_APP_COUNT];
    [HMPanel.sh reportSuperParameterKey:AK_S_DID_EVER_SHARE_USING_APP value:@YES];
    [HMPanel.sh analyticsEvent:AK_E_SHARE_SUCCESS info:info];

    HMParams *params = [HMParams new];
    [params addKey:AK_PD_DID_EVER_SHARE_USING_APP value:[HMPanel.sh didEverCountedKey:AK_S_NUMBER_OF_SHARES_USING_APP_COUNT]];
    [params addKey:AK_PD_NUMBER_OF_SHARES_USING_APP_COUNT value:[HMPanel.sh counterValueNamed:AK_S_NUMBER_OF_SHARES_USING_APP_COUNT]];
    [HMPanel.sh personDetails:params.dictionary];
    
    // Update iRate
    iRate *irate = [iRate sharedInstance];
    NSInteger eventsCount = [irate eventCount];
    [irate setEventCount:eventsCount+1];
}

-(void)sharerDidCancelWithInfo:(NSDictionary *)info
{
    [self.sharer cleanUp];
    self.sharer = nil;

    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_SHARE_CANCELED info:info];
}

-(void)sharerDidFailWithInfo:(NSDictionary *)info
{
    [self.sharer cleanUp];
    self.sharer = nil;
    
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_SHARE_FAILED info:info];
}

-(void)sharerDidFinishWithInfo:(NSDictionary *)info
{
    self.previousSharer = self.sharer;
    self.sharer = nil;
    self.guiRenderingView.hidden = YES;
    self.guiCollectionView.hidden = NO;
    self.guiFBMButtonContainer.hidden = NO;
}

-(void)sharerDidStartLongOperation:(NSDictionary *)info label:(NSString *)label
{
    self.guiCollectionView.hidden = YES;
    self.guiFBMButtonContainer.hidden = YES;
    self.guiRenderingView.hidden = NO;
    self.guiRenderingProgress.progress = 0;
    if (label) self.guiRenderingProgressLabel.text = label;
}

-(void)sharerDidProgress:(float)progress info:(NSDictionary *)info
{
    [self updateProgress:progress animated:YES];
}

#pragma mark - EMShareInputDelegate
-(void)shareInputWasCanceled
{
    [self.sharer cleanUp];
    self.sharer = nil;
    [self.view makeToast:LS(@"SHARE_TOAST_CANCELED")];
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_SHARE_CANCELED info:self.sharer.info];
}

-(void)shareInputWasConfirmedWithText:(NSString *)text
{
    self.sharer.userInputText = text;
    [self.sharer share];
}

#pragma mark - progress
-(void)updateProgress:(float)progress animated:(BOOL)animated
{
    [self.guiRenderingProgress setProgress:progress animated:animated];
    if (progress >= 1) {
        dispatch_after(DTIME(1.5), dispatch_get_main_queue(), ^{
            self.guiRenderingView.hidden = YES;
        });
    }
}

#pragma mark - Scroll
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat x = scrollView.contentOffset.x;
    if (x<-30 && _allowFBExperience) [self hideExtraShareOptionsAnimated:YES];
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
-(IBAction)onPressedShareButton:(UIButton *)sender
{
    [self shareEmuticonUsingMethodAtIndex:sender.tag];
    [UIView animateWithDuration:0.3 animations:^{
        sender.transform = CGAffineTransformMakeScale(1.2, 1.2);
        sender.alpha = 0.8;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             sender.alpha = 1;
                             sender.transform = CGAffineTransformIdentity;
                         } completion:nil];
    }];
}

-(IBAction)onPressedMoreShareOptionsButton:(id)sender
{
    if (!_allowFBExperience) return;
    [self showExtraShareOptionsAnimated:YES];
}

- (IBAction)onSwipedLeftToShowMoreShareOptions:(id)sender
{
    if (!_allowFBExperience) return;
    [self showExtraShareOptionsAnimated:YES];
}


@end
