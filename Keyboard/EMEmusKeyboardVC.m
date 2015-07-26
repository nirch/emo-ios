//
//  EMKeyboardVC.m
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMEmusKeyboardVC.h"
#import "EMDB.h"
#import "EmuKBCell.h"
#import "EMShareCopy.h"
#import "HMPanel.h"
#import "EMAlphaNumericKeyboard.h"
#import "EmuSectionReusableView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "EMPackagesVC.h"
#import "NSNotificationCenter+Utils.h"

#import "EMDownloadsManager2.h"
#import "EMRenderManager2.h"

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

@property (nonatomic, readonly) CGFloat screenWidth;

@property (nonatomic, weak) EMAlphaNumericKeyboard *abKBVC;

@end

@implementation EMEmusKeyboardVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.initializedData = NO;

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _screenWidth = MIN(screenRect.size.width, screenRect.size.height);
    
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
        [self initObservers];
    }
    [self updateGUI];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}


#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On background detection information received.
    [nc addUniqueObserver:self
                 selector:@selector(onEmuStateUpdated:)
                     name:hmkRenderingFinished
                   object:nil];
    
    // Backend downloaded (or failed to download) missing resources for emuticon.
    [nc addUniqueObserver:self
                 selector:@selector(onEmuStateUpdated:)
                     name:hmkDownloadResourceFinished
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkRenderingFinished];
    [nc removeObserver:hmkDownloadResourceFinished];
}

#pragma mark - Observers handlers
-(void)onEmuStateUpdated:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    NSString *oid = info[@"emuticonOID"];
    
    // Make sure indexpath is in the range of the fetched results controller.
    if (indexPath.item >= self.fetchedResultsController.fetchedObjects.count) {
        // Ignore if item out of range of the currently displayed data.
        return;
    }
    
    // ignore notifications not relating to emus visible on screen.
    if (![[self.guiCollectionView indexPathsForVisibleItems] containsObject:indexPath]) return;
    
    // ignore if the rendered emu isn't where expected.
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (![emu.oid isEqualToString:oid])
    {
        return;
    }
    
    // The cell is on screen, refresh it.
    if ([self.guiCollectionView numberOfItemsInSection:0] == self.fetchedResultsController.fetchedObjects.count) {
        [self.guiCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
    } else {
        [self.guiCollectionView reloadData];
    }
}

#pragma mark - segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embed alpha numeric keyboard"])
    {
        EMAlphaNumericKeyboard *alphaNumericKeyboard = segue.destinationViewController;
        alphaNumericKeyboard.delegate = self;
        self.abKBVC = alphaNumericKeyboard;
        [self.abKBVC refresh];
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
    [HMPanel.sh reportSuperParameterKey:AK_S_DID_KEYBOARD_EVER_APPEAR value:[HMPanel.sh didEverCountedKey:AK_S_NUMBER_OF_KB_APPEARANCES_COUNT]];
    [HMPanel.sh personDetails:@{
                                AK_PD_DID_KEYBOARD_EVER_APPEAR:[HMPanel.sh counterValueNamed:AK_S_NUMBER_OF_KB_APPEARANCES_COUNT],
                                AK_PD_NUMBER_OF_KB_APPEARANCES_COUNT:[HMPanel.sh didEverCountedKey:AK_S_NUMBER_OF_KB_APPEARANCES_COUNT]
                                }];
    [HMPanel.sh analyticsForceSend];

    // Experiments Goal
    [HMPanel.sh experimentGoalEvent:GK_KEYBOARD_OPENED];
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
    
    if (self.fetchedResultsController.fetchedObjects.count<1) {
        [self showAlphaNumericKBAnimated:NO];
    }
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
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPreview=%@ AND emuDef.package.isActive=%@", @NO, @YES];
    
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
    static NSString *cellIdentifier = @"emu kb cell";
    EmuKBCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                      forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = self.screenWidth/3.0 - 25;
    CGFloat height = self.guiCollectionView.bounds.size.height/2.0;

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
-(void)configureCell:(EmuKBCell *)cell
        forIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSDictionary *info = @{
                           @"for":@"emu",
                           @"indexPath":indexPath,
                           @"emuticonOID":emu.oid,
                           @"packageOID":emu.emuDef.package.oid,
                           };
    
    cell.transform = CGAffineTransformIdentity;
    cell.alpha = 1;
    cell.backgroundColor = [UIColor clearColor];
    if (emu.wasRendered.boolValue) {
        //
        // Emu already rendered. Just display it.
        // (Display thumb first and load animated gif in background thread)
        //
        NSURL *gifURL = [emu animatedGifURL];
        cell.guiThumbView.image = [UIImage imageWithContentsOfFile:[emu thumbPath]];
        cell.guiThumbView.hidden = NO;
        cell.guiThumbView.alpha = 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.animatedGifURL = gifURL;
        });
        [cell.guiActivity stopAnimating];
    } else {
        [cell.guiActivity startAnimating];
        cell.animatedGifURL = nil;
        
        if ([emu.emuDef allResourcesAvailable]) {
            // Not rendered, but all resources are available.
            [EMRenderManager2.sh enqueueEmu:emu
                                  indexPath:indexPath
                                   userInfo:info];
        }
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
    [params addKey:AK_EP_EMUTICON_INSTANCE_OID valueIfNotNil:emuticon.oid];
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
    self.sharer.info = [NSMutableDictionary dictionaryWithDictionary:params.dictionary];
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
    
    HMParams *params = [HMParams new];
    [params addKey:AK_PD_NUMBER_OF_KB_COPY_EMU_COUNT value:[HMPanel.sh counterValueNamed:AK_S_NUMBER_OF_KB_COPY_EMU_COUNT]];
    [HMPanel.sh personDetails:params.dictionary];

    // Experiments Goal
    [HMPanel.sh experimentGoalEvent:GK_SHARE_KB];
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
    if (self.isUserContentAvailable) {
      [self hideAlphaNumericKBAnimated:YES];
    } 
}

-(BOOL)isUserContentAvailable
{
    if (self.fetchedResultsController == nil) return NO;
    return self.fetchedResultsController.fetchedObjects.count>0;
}

-(void)keyboardShouldDismissAlphaNumericWithInfo:(NSDictionary *)info
{
    [self hideAlphaNumericKBAnimated:YES];
    if (info[@"package"]) {
        Package *package = info[@"package"];
        [self.packagesVC selectThisPackage:package originUI:@"kb alphanumeric"];
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
    
    [self.abKBVC refresh];
    self.guiAlphaNumericKBContainer.transform = CGAffineTransformIdentity;
    self.guiAlphaNumericKBContainer.alpha = 1;
    [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_ALPHA_NUMERIC_KB_APPEARANCES_COUNT];
    [HMPanel.sh analyticsEvent:AK_E_KB_ALPHA_NUMERIC_KB_SHOWN];
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
