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

#define TAG @"EMShareVC"

@interface EMShareVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    EMShareDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

@property (nonatomic) NSArray *shareMethods;
@property (nonatomic) NSDictionary *shareIcons;
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
}

#pragma mark - Data
-(void)initData
{
    // A priorized list of share methods.
    self.shareMethods = @[
                          @(emkShareMethodAppleMessages),
                          //@(emkShareMethodWhatsapp),
                          //@(emkShareMethodFacebookMessanger),
                          //@(emkShareMethodFacebook),
                          @(emkShareMethodMail),
                          @(emkShareMethodSaveToCameraRoll),
                          @(emkShareMethodCopy)
                          ];
    
    self.shareIcons = @{
                        @(emkShareMethodAppleMessages):      @"iMessage",
                        @(emkShareMethodWhatsapp):           @"whatsapp",
                        @(emkShareMethodFacebookMessanger):  @"facebookm",
                        @(emkShareMethodFacebook):           @"facebook",
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
    NSString *shareMethod = self.shareMethods[indexPath.item];
    NSString *buttonImageName = self.shareIcons[shareMethod];
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

#pragma mark - Sharing
-(void)shareEmuticonUsingMethodAtIndex:(NSInteger)index
{
    NSString *emuticonOID = [self.delegate shareObjectIdentifier];
    Emuticon *emu = [Emuticon findWithID:emuticonOID context:EMDB.sh.context];
    
    EMKShareMethod shareMethod = [self.shareMethods[index] integerValue];
    [self shareEmuticon:emu usingMethod:shareMethod];
}

-(void)shareEmuticon:(Emuticon *)emu usingMethod:(EMKShareMethod)method
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
        self.sharer.shareOption = emkShareOptionBoth;
        
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
    [self.sharer share];
}

#pragma mark - EMShareDelegate
-(void)sharerDidShareObject:(id)sharedObject
                   withInfo:(NSDictionary *)info
{
    self.sharer = nil;
}

-(void)sharerDidCancelWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
}

-(void)sharerDidFailWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedShareButton:(UIButton *)sender
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


@end
