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

#define TAG @"EMShareVC"

@interface EMShareVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

@property (nonatomic) NSArray *shareMethods;
@property (nonatomic) NSDictionary *shareIcons;

@end

@implementation EMShareVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
}

#pragma mark - Data
-(void)initData
{
    // A priorized list of share methods.
    self.shareMethods = @[
                          @(emShareMethodAppleMessages),
                          @(emShareMethodWhatsapp),
                          @(emShareMethodFacebookMessanger),
                          @(emShareMethodFacebook),
                          @(emShareMethodMail),
                          @(emShareMethodSaveToCameraRoll),
                          @(emShareMethodCopy)
                          ];
    
    self.shareIcons = @{
                        @(emShareMethodAppleMessages):      @"iMessage",
                        @(emShareMethodWhatsapp):           @"whatsapp",
                        @(emShareMethodFacebookMessanger):  @"facebookm",
                        @(emShareMethodFacebook):           @"facebook",
                        @(emShareMethodMail):               @"mail",
                        @(emShareMethodSaveToCameraRoll):   @"savetocm",
                        @(emShareMethodCopy):               @"copy"
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

#pragma mark - Sharing
-(void)shareEmuticonUsingMethodAtIndex:(NSInteger)index
{
    NSString *emuticonOID = [self.delegate shareObjectIdentifier];
    Emuticon *emu = [Emuticon findWithID:emuticonOID context:EMDB.sh.context];
   
   
    /**
    NSURL *url = [emu animatedGifURL];

//    UIImage *image = [UIImage imageWithData:data];
//    [UIPasteboard generalPasteboard].image = image;
    
//    NSData *data = [NSData dataWithContentsOfURL:url];
//    UIPasteboard *pasteBoard=[UIPasteboard generalPasteboard];
//    [pasteBoard setData:data forPasteboardType:(NSString *)kUTTypeGIF];

    NSData *gifData = [[NSData alloc] initWithContentsOfFile:[[emu animatedGifURL] path]];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    [pasteboard setData:gifData forPasteboardType:@"com.compuserve.gif"];
    
    // HMLOG(TAG, DBG, @"Will share emu %@", emuticonOID);
     */
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
