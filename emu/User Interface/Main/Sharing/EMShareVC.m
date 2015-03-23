//
//  EMShareViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import MobileCoreServices;

#import "EMShareVC.h"
#import "EMShareProtocol.h"
#import "EMShareCell.h"
#import "EMLabel.h"
#import "EMDB.h"

// Share methods
#import "EMShareCopy.h"
#import "EMShareSaveToCameraRoll.h"
#import "EMShareMail.h"
#import "EMShareAppleMessage.h"
#import "EMShareFBMessanger.h"

#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>

#define TAG @"EMShareVC"

@interface EMShareVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    EMShareDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiFBMButtonContainer;

@property (nonatomic, weak) UIButton *fbmButton;
@property (nonatomic, weak) UIButton *fbmSmallerButton;

@property (nonatomic) NSArray *shareMethods;
@property (nonatomic) NSDictionary *shareNames;
@property (nonatomic) NSDictionary *shareMethodsNames;
@property (nonatomic) EMShare *sharer;

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
    [self hideExtraShareOptionsAnimated:NO];
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
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat buttonWidth = 90;
    if (screenHeight <= 480.0) {
        buttonWidth = 70;
    }

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
    CGFloat x = self.view.bounds.size.width;
    self.guiCollectionView.transform = CGAffineTransformIdentity;

    self.guiFBMButtonContainer.transform = CGAffineTransformMakeTranslation(-x, 0);
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


#pragma mark - Data
-(void)initData
{
    // A priorized list of share methods.
    self.shareMethods = @[
                          @(emkShareMethodFacebookMessanger),
                          //@(emkShareMethodFacebook),
                          //@(emkShareMethodAppleMessages),
                          //@(emkShareMethodWhatsapp),
                          @(emkShareMethodMail),
                          @(emkShareMethodSaveToCameraRoll),
                          @(emkShareMethodCopy)
                          ];
    
    self.shareNames = @{
                        @(emkShareMethodFacebookMessanger):  @"facebookm",
                        @(emkShareMethodFacebook):           @"facebook",
                        @(emkShareMethodAppleMessages):      @"iMessage",
                        @(emkShareMethodWhatsapp):           @"whatsapp",
                        @(emkShareMethodMail):               @"mail",
                        @(emkShareMethodSaveToCameraRoll):   @"savetocm",
                        @(emkShareMethodCopy):               @"copy"
                        };
    
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
    
    // Change how the share button of fb messenger looks
    // to whatever style defined by the FB Messenger SDK
    // (instead of the hardcoded image)
    if ([shareMethod isEqualToNumber:@(emkShareMethodFacebookMessanger)]) {
        if (self.fbmSmallerButton == nil) {
            UIButton *button = [FBSDKMessengerShareButton circularButtonWithStyle:FBSDKMessengerShareButtonStyleWhite
                                                                            width:58];
            button.layer.cornerRadius = 30;
            [cell addSubview:button];
            button.center = cell.guiButton.center;
            button.hidden = NO;
            button.tag = 0;
            cell.guiButton.hidden = YES;
            [button addTarget:self action:@selector(onPressedShareButton:) forControlEvents:UIControlEventTouchUpInside];
            self.fbmSmallerButton = button;
        }
    }
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
    [params addKey:AK_EP_EMUTICON_NAME valueIfNotNil:emuticon.emuDef.name];
    [params addKey:AK_EP_EMUTICON_OID valueIfNotNil:emuticon.emuDef.oid];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:emuticon.emuDef.package.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:emuticon.emuDef.package.oid];
    return params;
}

#pragma mark - Sharing
-(void)shareEmuticonUsingMethodAtIndex:(NSInteger)index
{
    NSString *emuticonOID = [self.delegate shareObjectIdentifier];
    Emuticon *emu = [Emuticon findWithID:emuticonOID context:EMDB.sh.context];
    
    // Info about the share
    EMKShareMethod shareMethod = [self.shareMethods[index] integerValue];
    HMParams *params = [self paramsForEmuticon:emu];
    [params addKey:AK_EP_SHARE_METHOD value:self.shareNames[@(shareMethod)]];
    [params addKey:AK_EP_SENDER_UI valueIfNotNil:@"shareVC"];

    // Share
    [self shareEmuticon:emu usingMethod:shareMethod info:params.dictionary];
    
    // Analytics
    [HMReporter.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_PRESSED_SHARE_BUTTON
                             info:params.dictionary];

}

-(void)shareEmuticon:(Emuticon *)emu usingMethod:(EMKShareMethod)method info:(NSDictionary *)info
{
    // Only one share operation at a time.
    if (self.sharer) return;
    
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
        // self.sharer.shareOption = emkShareOptionBoth;
        
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
    
    // Share
    self.sharer.objectToShare = emu;
    self.sharer.delegate = self;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.info = info;
    [self.sharer share];
}

#pragma mark - EMShareDelegate
-(void)sharerDidShareObject:(id)sharedObject withInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMReporter.sh analyticsEvent:AK_E_SHARE_SUCCESS info:info];
}

-(void)sharerDidCancelWithInfo:(NSDictionary *)info
{
    self.sharer = nil;

    // Analytics
    [HMReporter.sh analyticsEvent:AK_E_SHARE_CANCELED info:info];
}

-(void)sharerDidFailWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMReporter.sh analyticsEvent:AK_E_SHARE_FAILED info:info];
}

-(void)sharerDidFinishWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat x = scrollView.contentOffset.x;
    if (x<-30) [self hideExtraShareOptionsAnimated:YES];
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
    [self showExtraShareOptionsAnimated:YES];
}

- (IBAction)onSwipedLeftToShowMoreShareOptions:(id)sender
{
    [self showExtraShareOptionsAnimated:YES];
}


@end
