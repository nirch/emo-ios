//
//  EMKeyboardVC.m
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMEmusKeyboardVC.h"
#import "EMDB.h"
#import "EmuCell.h"
#import "EMShareCopy.h"
#import "HMPanel.h"
#import "EMAlphaNumericKeyboard.h"
#import "EmuSectionReusableView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "EMPackagesVC.h"

#define TAG @"EMEmusKeyboardVC"

@interface EMEmusKeyboardVC()<
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    EMShareDelegate,
    EMKeyboardContainerDelegate,
    EMPackageSelectionDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

@property (weak, nonatomic) IBOutlet UIImageView *guiDisabledKBLogo;
@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessError;
@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessInstructions;
@property (weak, nonatomic) IBOutlet UIView *guiAlphaNumericKBContainer;

@property (weak, nonatomic) EMPackagesVC *packagesVC;
@property (nonatomic) Package *selectedPackage;
@property (nonatomic) BOOL initializedData;
@property (nonatomic) EMShareCopy *sharer;
@property (nonatomic) NSInteger focusedOnIndex;

@property (nonatomic) BOOL isFullAccessGranted;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;


@end

@implementation EMEmusKeyboardVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.initializedData = NO;

    // Not hidden but alpha = 0
    self.guiAlphaNumericKBContainer.hidden = NO;
    [self hideAlphaNumericKBAnimated:NO];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self checkForFullAccess];
    [self updateGUI];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isFullAccessGranted) {
        [self initData];
        [self initAnalytics];
    } else {
    }
    [self updateGUI];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

#pragma mark - segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embed alpha numeric keyboard"])
    {
        EMAlphaNumericKeyboard *alphaNumericKeyboard = segue.destinationViewController;
        alphaNumericKeyboard.delegate = self;
    } else if ([segue.identifier isEqualToString:@"embed packages bar segue"]) {
        self.packagesVC = segue.destinationViewController;
        self.packagesVC.delegate = self;
    }
}

#pragma mark - Analytics
-(void)initAnalytics
{
    [HMPanel.sh initializeAnalyticsWithLaunchOptions:nil];
    [HMPanel.sh analyticsEvent:AK_E_KB_DID_APPEAR info:nil];
    [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_KB_APPEARANCES_COUNT];
    [HMPanel.sh analyticsForceSend];
}

#pragma mark - Initializations
-(void)initGUI
{
}

-(void)updateGUI
{
    // Full access error messages and instructions
    self.guiFullAccessError.hidden = self.isFullAccessGranted;
    self.guiFullAccessInstructions.hidden = self.isFullAccessGranted;
    self.guiDisabledKBLogo.hidden = self.isFullAccessGranted;
    [self.guiCollectionView reloadData];
    [self.packagesVC refresh];
}

#pragma mark - Data
-(void)initData
{
    if (!self.initializedData) {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        self.selectedPackage = [appCFG packageForOnboarding];
    }
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
}

#pragma mark - KB helpers
-(void)checkForFullAccess
{
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    if (pasteBoard == nil) {
        self.isFullAccessGranted = NO;
        return;
    }
    self.isFullAccessGranted = YES;
}

#pragma mark - Fetched results controller
-(NSFetchedResultsController *)fetchedResultsController
{
    if (!self.isFullAccessGranted) return nil;
    
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPreview=%@ AND wasRendered=%@", @NO, @YES];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package.priority" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"emuDef.order" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:@"emuDef.package"
                                                                                     cacheName:@"Root"];
    _fetchedResultsController = frc;
    
    NSError *error;
    [_fetchedResultsController performFetch:&error];
    
    return frc;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
    if (!self.isFullAccessGranted)
        return;
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (!self.isFullAccessGranted) return 0;
    return self.fetchedResultsController.sections.count;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    if (!self.isFullAccessGranted) return 0;
    
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"emu cell";
    EmuCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                      forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.guiCollectionView.bounds.size.height;
    CGFloat width = MIN(130, height);
    return CGSizeMake(width, height);
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
          viewForSupplementaryElementOfKind:(NSString *)kind
                                atIndexPath:(NSIndexPath *)indexPath
{
    if (kind != UICollectionElementKindSectionHeader) return nil;

    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][indexPath.section];
    if ([sectionInfo numberOfObjects] == 0) return nil;
    
    static NSString *sectionHeaderIdentifier = @"emus section header view";
    EmuSectionReusableView *header = [self.guiCollectionView dequeueReusableSupplementaryViewOfKind:kind
                                               withReuseIdentifier:sectionHeaderIdentifier
                                                      forIndexPath:indexPath];
    [self configureHeader:header forIndexPath:indexPath];
    return header;
}


#pragma mark - Cells & Views
-(void)configureCell:(EmuCell *)cell
        forIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.transform = CGAffineTransformIdentity;
    cell.alpha = 1;
    cell.backgroundColor = [UIColor clearColor];
    if (emu.wasRendered.boolValue) {
        [cell.guiActivity stopAnimating];
        cell.animatedGifURL = [emu animatedGifURL];
    } else {
        [cell.guiActivity startAnimating];
        cell.animatedGifURL = nil;
        //        [EMRenderManager.sh enqueueEmu:emu info:@{
        //                                                  @"indexPath":indexPath,
        //                                                  @"emuticonOID":emu.oid
        //                                                  }];
    }
    
}

-(void)configureHeader:(EmuSectionReusableView *)header
          forIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    Package *package = emu.emuDef.package;
    [header setLabelTitle:[package tagLabel]];
    
    NSURL *url = [package urlForPackageIcon];
    [header.guiIcon sd_setImageWithURL:url
                    placeholderImage:nil
                             options:SDWebImageRetryFailed|SDWebImageHighPriority
                           completed:nil];

}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self copyEmu:emu];
    
    UICollectionViewCell *cell = [self.guiCollectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
        cell.layer.zPosition = 1000;
        [UIView animateWithDuration:0.5 animations:^{
            cell.transform = CGAffineTransformMakeScale(1.3, 1.3);
            cell.alpha = 0.7;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5
                                  delay:0
                 usingSpringWithDamping:0.6
                  initialSpringVelocity:0.9 options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 cell.layer.zPosition = 0;
                                 cell.transform = CGAffineTransformIdentity;
                                 cell.alpha = 1.0;
                             } completion:nil];
        }];
    }

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
-(void)copyEmu:(Emuticon *)emu
{
    if (emu == nil || self.sharer != nil) return;
    
    
    // Info about the share
    HMParams *params = [self paramsForEmuticon:emu];
    [params addKey:AK_EP_SHARE_METHOD value:@"copy"];
    [params addKey:AK_EP_SENDER_UI valueIfNotNil:@"keyboard"];
    [HMPanel.sh analyticsEvent:AK_E_KB_USER_PRESSED_ITEM info:params.dictionary];
    
    self.sharer = [EMShareCopy new];
    self.sharer.objectToShare = emu;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.delegate = self;
    self.sharer.info = params.dictionary;
    self.sharer.selectionMessage = LS(@"SHARE_TOAST_COPIED_KB");
    [self.sharer share];
}

#pragma mark - EMShareDelegate
-(void)sharerDidShareObject:(id)sharedObject withInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_SHARE_SUCCESS info:info];
    [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_KB_COPY_EMU_COUNT];
    [HMPanel.sh analyticsForceSend];
}

-(void)sharerDidFailWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_SHARE_FAILED info:info];
    [HMPanel.sh analyticsForceSend];
}


-(void)sharerDidCancelWithInfo:(NSDictionary *)info
{
    self.sharer = nil;
    
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_SHARE_CANCELED info:info];
    [HMPanel.sh analyticsForceSend];
}


#pragma mark - EMKeyboardContainerDelegate
-(void)keyboardShouldAdadvanceToNextInputMode
{
    [self.delegate keyboardShouldAdadvanceToNextInputMode];
}

-(void)keyboardShouldDeleteBackward
{
    [self.delegate keyboardShouldDeleteBackward];
}

-(void)keyboardTypedString:(NSString *)typedString
{
    [self.delegate keyboardTypedString:typedString];
}

-(BOOL)keyboardFullAccessWasGranted
{
    return self.isFullAccessGranted;
}


-(void)keyboardShouldDismissAlphaNumeric
{
    [self hideAlphaNumericKBAnimated:YES];
}

-(void)keyboardShouldDismissAlphaNumericWithInfo:(NSDictionary *)info
{
    [self hideAlphaNumericKBAnimated:YES];
    if (info[@"package"]) {
        Package *package = info[@"package"];
        [self.packagesVC selectThisPackage:package];
    }
}

#pragma mark - Alpha Numeric KB show/hide
-(void)showAlphaNumericKBAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self showAlphaNumericKBAnimated:NO];
        }];
        return;
    }
    
    self.guiAlphaNumericKBContainer.transform = CGAffineTransformIdentity;
    self.guiAlphaNumericKBContainer.alpha = 1;
    [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_ALPHA_NUMERIC_KB_APPEARANCES_COUNT];
}

-(void)hideAlphaNumericKBAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self hideAlphaNumericKBAnimated:NO];
        }];
        return;
    }
    
    self.guiAlphaNumericKBContainer.transform = CGAffineTransformMakeTranslation(0, 40);
    self.guiAlphaNumericKBContainer.alpha = 0;
}

#pragma mark - EMPackageSelectionDelegate
-(void)packageWasSelected:(Package *)package
{
    NSArray *sections = self.fetchedResultsController.sections;
    for (int i=0;i<sections.count;i++) {
        id <NSFetchedResultsSectionInfo> sectionInfo = sections[i];
        if ([sectionInfo numberOfObjects] == 0) continue;
        Emuticon *emu = sectionInfo.objects[0];
        if ([emu.emuDef.package.oid isEqualToString:package.oid]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:i];
            [self.guiCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
            
            CGPoint offset = self.guiCollectionView.contentOffset;
            CGFloat x = MAX(0, offset.x-50);
            CGRect rect = CGRectMake(x, offset.y, 50, 50);
            [self.guiCollectionView scrollRectToVisible:rect animated:NO];
        }
    }
}

-(void)packagesAvailableCount:(NSInteger)numberOfPackages
{
}

-(BOOL)packagesDataIsNotAvailable
{
    if (!self.isFullAccessGranted) return YES;
    return NO;
}

#pragma mark - Scroll
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGSize size = self.guiCollectionView.bounds.size;
    CGPoint center = CGPointMake(size.width/2+self.guiCollectionView.contentOffset.x, size.height/2);
    NSIndexPath *indexPath = [self.guiCollectionView indexPathForItemAtPoint:center];
    if (indexPath == nil) return;
    NSInteger sectionIndex = indexPath.section;
    if (sectionIndex != self.focusedOnIndex) {
        [self.packagesVC selectPackageAtIndex:sectionIndex highlightOnly:YES];
        self.focusedOnIndex = sectionIndex;
    }
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNextKBButton:(id)sender
{
    [self.delegate keyboardShouldAdadvanceToNextInputMode];
    [HMPanel.sh analyticsEvent:AK_E_KB_USER_PRESSED_NEXT_INPUT_BUTTON];
}

- (IBAction)onPressedAlphaNumericButton:(id)sender
{
    [self showAlphaNumericKBAnimated:YES];
}


- (IBAction)onPressedBackButton:(id)sender
{
    [self.delegate keyboardShouldDeleteBackward];
    [HMPanel.sh analyticsEvent:AK_E_KB_USER_PRESSED_BACK_BUTTON];
}

@end
