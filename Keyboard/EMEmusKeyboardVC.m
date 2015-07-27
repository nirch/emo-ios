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
#import "EMShareSaveToCameraRoll.h"
#import "HMPanel.h"
#import "EMAlphaNumericKeyboard.h"
#import "EmuSectionReusableView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "EMPackagesVC.h"
#import "NSNotificationCenter+Utils.h"

#import "EMKBOptionsDrawer.h"
#import "EMInterfaceDelegate.h"
#import <Toast/UIView+Toast.h>

#import "EMDownloadsManager2.h"
#import "EMRenderManager2.h"
#import "AppManagement.h"
#import <AWSS3.h>


#define TAG @"EMEmusKeyboardVC"

@interface EMEmusKeyboardVC()<
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    EMShareDelegate,
    EMKeyboardContainerDelegate,
    EMPackageSelectionDelegate,
    EMInterfaceDelegate
> {
    CGFloat cellW;
    CGFloat cellH;
}

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

@property (weak, nonatomic) IBOutlet UIImageView *guiDisabledKBLogo;
@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessError;
@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessInstructions;
@property (weak, nonatomic) IBOutlet UIView *guiAlphaNumericKBContainer;

@property (weak, nonatomic) IBOutlet UIButton *guiOptionsButton;
@property (weak, nonatomic) IBOutlet UIView *guiOptionsDrawerContainer;

@property (weak, nonatomic) IBOutlet UIView *guiHowToMessage;
@property (weak, nonatomic) IBOutlet UIView *guiPackagesBarContainer;

@property (nonatomic) BOOL shareVideoSupported;

@property (weak, nonatomic) EMPackagesVC *packagesVC;
@property (weak, nonatomic) EMKBOptionsDrawer *kbOptionsDrawer;
@property (nonatomic) Package *selectedPackage;
@property (nonatomic) BOOL initializedData;
@property (nonatomic) EMShare *sharer;
@property (nonatomic) NSInteger focusedOnIndex;

@property (nonatomic) BOOL isFullAccessGranted;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, readonly) CGFloat screenWidth;

@property (nonatomic, weak) EMAlphaNumericKeyboard *abKBVC;

@property (nonatomic, readonly) AWSS3TransferManager *transferManager;

@property (nonatomic) NSTimer *ticker;

@property (atomic) BOOL isScrolling;

@end

@implementation EMEmusKeyboardVC

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize transferManager = _transferManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.initializedData = NO;
    self.isScrolling = NO;
    self.shareVideoSupported = NO;

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _screenWidth = MIN(screenRect.size.width, screenRect.size.height);
    
    [self initGUI];
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
        [self initKBBackend];
        [self initTimers];
    }
    [self updateGUI];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
    [self invalidateTimers];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}


-(void)initKBBackend
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSString *bucketName = appCFG.bucketName;
    if (bucketName == nil) bucketName = AppManagement.sh.isTestApp?@"homage-emu-test":@"homage-emu-prod";
    EMDownloadsManager2.sh.bucketName = bucketName;
    EMDownloadsManager2.sh.transferManager = self.transferManager;
}

-(AWSS3TransferManager *)transferManager
{
    if (_transferManager) return _transferManager;
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:S3_UPLOAD_ACCESS_KEY secretKey:S3_UPLOAD_SECRET_KEY];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    _transferManager = [AWSS3TransferManager defaultS3TransferManager];
    HMLOG(TAG, EM_DBG, @"Started s3 transfer manager");
    return _transferManager;
}

#pragma mark - Timers
-(void)initTimers
{
    [self invalidateTimers];
    self.ticker = [NSTimer scheduledTimerWithTimeInterval:0.7
                                                   target:self
                                                 selector:@selector(onTick:)
                                                 userInfo:nil
                                                  repeats:YES];
}

-(void)invalidateTimers
{
    if (self.ticker) {
        [self.ticker invalidate];
    }
}

-(void)onTick:(NSTimer *)timer
{
    if (self.isScrolling) return;
    NSInteger i=0;
    for (EmuKBCell *cell in self.guiCollectionView.visibleCells) {
        if (cell.pendingAnimatedGifURL) {
            i++;
            [cell showPendingGifURL];
            if (i>=2 || self.isScrolling) {
                return;
            }
        }
    }
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
    } else if ([segue.identifier isEqualToString:@"kb options drawer segue"]) {
        self.kbOptionsDrawer = segue.destinationViewController;
        self.kbOptionsDrawer.delegate = self;
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
    self.guiOptionsButton.layer.cornerRadius = 8.0;
    
    CALayer *l = self.guiOptionsDrawerContainer.layer;
    l.shadowColor = [UIColor blackColor].CGColor;
    l.shadowRadius = 2;
    l.shadowOpacity = 0.15;
    l.shadowOffset = CGSizeMake(0, -2);
    l.shadowPath = [UIBezierPath bezierPathWithRect:l.bounds].CGPath;
    
    if (!self.shareVideoSupported) {
        self.guiOptionsButton.hidden = YES;
        self.guiOptionsDrawerContainer.hidden = YES;
    }
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
        
        // Selected package.
        self.selectedPackage = [appCFG packageForOnboarding];
        
        // kb drawer options state.
        [self.kbOptionsDrawer initializeState];
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
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package.priority" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package.oid" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"emuDef.order" ascending:YES] ];
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
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    [cell layoutIfNeeded];
    
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    cellH = (self.view.bounds.size.height-self.guiPackagesBarContainer.bounds.size.height)/2.0;
    
    // lower limit
    cellH = MAX(83, cellH);

    cellW = cellH;
}

#pragma mark - Layout & Sizes
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(cellW, cellH);
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
    cell.animatedGifURL = nil;

    if (emu.wasRendered.boolValue) {
        //
        // Emu already rendered. Just display it.
        // (Display thumb first and load animated gif in background thread)
        //
        NSURL *gifURL = [emu animatedGifURL];
        cell.guiThumbView.image = [UIImage imageWithContentsOfFile:[emu thumbPath]];
        cell.guiThumbView.hidden = NO;
        cell.guiThumbView.alpha = 1;
        cell.pendingAnimatedGifURL = gifURL;
        [cell.guiActivity stopAnimating];
    } else {
        [cell.guiActivity startAnimating];
        cell.animatedGifURL = nil;
        cell.guiThumbView.hidden = YES;
        cell.guiThumbView.alpha = 0;
        cell.guiThumbView.image = nil;
        
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
    
    if ([self isOptionsDrawerOpen]) {
        [self closeOptionsDrawerAnimated:YES];
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
    if (self.kbOptionsDrawer.prefferedRenderMediaType == EMMediaDataTypeVideo && self.shareVideoSupported) {
        [self saveVideoToCRForEmu:emu];
    } else {
        [self copyAnimatedGifForEmu:emu];
    }
}

-(void)copyAnimatedGifForEmu:(Emuticon *)emu
{
    // Info about the share
    HMParams *params = [self paramsForEmuticon:emu];
    [params addKey:AK_EP_SHARE_METHOD value:@"copy"];
    [params addKey:AK_EP_SENDER_UI valueIfNotNil:@"keyboard"];
    [params addKey:AK_EP_SHARED_MEDIA_TYPE value:@"gif"];
    [HMPanel.sh analyticsEvent:AK_E_KB_USER_PRESSED_ITEM info:params.dictionary];
    
    self.sharer = [EMShareCopy new];
    self.sharer.objectToShare = emu;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.delegate = self;
    self.sharer.shareOption = emkShareOptionAnimatedGif;
    self.sharer.info = [NSMutableDictionary dictionaryWithDictionary:params.dictionary];
    self.sharer.selectionMessage = LS(@"SHARE_TOAST_COPIED_KB");
    [self.sharer share];
}

-(void)saveVideoToCRForEmu:(Emuticon *)emu
{
    if (emu.videoURL) {
        // We have the file. Save to CR.
        [self _saveVideoToCRForEmu:emu];
    } else {
        // No video file? Render it!
        [self renderVideoBeforeCopyForEmu:emu];
    }
}

-(void)_saveVideoToCRForEmu:(Emuticon *)emu
{
    // Info about the share
    HMParams *params = [self paramsForEmuticon:emu];
    [params addKey:AK_EP_SHARE_METHOD value:@"savetocm"];
    [params addKey:AK_EP_SENDER_UI valueIfNotNil:@"keyboard"];
    [params addKey:AK_EP_SHARED_MEDIA_TYPE value:@"video"];
    [HMPanel.sh analyticsEvent:AK_E_KB_USER_PRESSED_ITEM info:params.dictionary];
    
    self.sharer = [EMShareSaveToCameraRoll new];
    self.sharer.objectToShare = emu;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.delegate = self;
    self.sharer.shareOption = emkShareOptionVideo;
    self.sharer.info = [NSMutableDictionary dictionaryWithDictionary:params.dictionary];
    self.sharer.selectionMessage = LS(@"SHARE_TOAST_SAVED");
    [self.sharer share];
}

-(void)renderVideoBeforeCopyForEmu:(Emuticon *)emu
{
    self.guiCollectionView.alpha = 0.4;
    self.guiCollectionView.userInteractionEnabled = NO;
    [EMRenderManager2.sh renderVideoForEmu:emu
                         requiresWaterMark:YES
                           completionBlock:^{
                               // If we are here, emu.videoURL points to the rendered video.
                               [self _saveVideoToCRForEmu:emu];
                               self.guiCollectionView.alpha = 1;
                               self.guiCollectionView.userInteractionEnabled = YES;
                           } failBlock:^{
                               // Failed :-(
                               // No rendered video available.
                               self.sharer = nil;
                               [self.view makeToast:LS(@"SHARE_TOAST_FAILED")];
                               self.guiCollectionView.alpha = 1;
                               self.guiCollectionView.userInteractionEnabled = YES;
                           }];
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
    
    if ([self isOptionsDrawerOpen]) {
        [self closeOptionsDrawerAnimated:YES];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.isScrolling = NO;
    [self handleVisibleCells];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.isScrolling = YES;
    HMLOG(TAG, EM_VERBOSE, @"Begin scrolling");
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        // Will not decelerate after dragging, so scrolling just ended.
        self.isScrolling = NO;
        [self handleVisibleCells];
    }
}


#pragma mark - Required downloads
-(void)handleVisibleCells
{
    NSArray *visibleIndexPaths = self.guiCollectionView.indexPathsForVisibleItems;
    BOOL anyEnqueued = NO;
    NSMutableDictionary *prioritizedOID = [NSMutableDictionary new];
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (emu.wasRendered.boolValue) continue;
        
        // Handle unrendered emus:
        NSDictionary *userInfo = @{
                                   @"for":@"emu",
                                   @"indexPath":indexPath,
                                   @"emuticonOID":emu.oid,
                                   @"packageOID":emu.emuDef.package.oid,
                                   };
        
        prioritizedOID[emu.oid] = @YES;
        NSArray *missingResourcesNames = [emu.emuDef allMissingResourcesNames];
        if (missingResourcesNames.count>0) {
            [EMDownloadsManager2.sh enqueueResourcesForOID:emu.oid
                                                     names:missingResourcesNames
                                                      path:emu.emuDef.package.name
                                                  userInfo:userInfo];
        }
        anyEnqueued = YES;
    }
    if (anyEnqueued) {
        [EMRenderManager2.sh updatePriorities:prioritizedOID];
        [EMDownloadsManager2.sh updatePriorities:prioritizedOID];
        [EMDownloadsManager2.sh manageQueue];
    }
}

#pragma mark - options drawer
-(void)toggleOptionsDrawerAnimated:(BOOL)animated
{
    if ([self isOptionsDrawerOpen]) {
        [self closeOptionsDrawerAnimated:animated];
    } else {
        [self openOptionsDrawerAnimated:animated];
    }
}

-(BOOL)isOptionsDrawerOpen
{
    return !CGAffineTransformIsIdentity(self.guiOptionsButton.transform);
}

-(void)closeOptionsDrawerAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self closeOptionsDrawerAnimated:NO];
        }];
        return;
    }
    
    CGAffineTransform t = CGAffineTransformIdentity;
    self.guiOptionsDrawerContainer.transform = t;
    self.guiOptionsButton.transform = t;
    self.guiOptionsButton.selected = NO;
    self.guiCollectionView.alpha = 1.0;
    self.guiCollectionView.transform = t;
}

-(void)openOptionsDrawerAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [self openOptionsDrawerAnimated:NO];
        }];
        return;
    }
    CGFloat h = self.guiOptionsDrawerContainer.bounds.size.height;
    CGAffineTransform t = CGAffineTransformMakeTranslation(0, -h);
    self.guiOptionsDrawerContainer.transform = t;
    self.guiOptionsButton.transform = t;
    self.guiOptionsButton.selected = YES;
    self.guiCollectionView.alpha = 0.6;
    self.guiCollectionView.transform = CGAffineTransformMakeScale(0.95, 0.95);
}

#pragma mark - EMInterfaceDelegate
-(void)controlSentActionNamed:(NSString *)actionName info:(NSDictionary *)info
{
    if ([actionName isEqualToString:@"ok"]) {
        [self closeOptionsDrawerAnimated:YES];
    } else if ([actionName isEqualToString:@"show whatsapp tutorial"]) {
        [self showTutorialMessage];
    }
}


#pragma mark - Tutorial message
-(void)showTutorialMessage
{
    CGFloat height = self.view.bounds.size.height;
    self.guiHowToMessage.alpha = 0;
    self.guiHowToMessage.hidden = NO;
    self.guiHowToMessage.transform = CGAffineTransformMakeTranslation(0, -height);
    [UIView animateWithDuration:0.7
                          delay:0
         usingSpringWithDamping:0.44
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.guiHowToMessage.alpha = 1;
                         self.guiHowToMessage.transform = CGAffineTransformIdentity;
                     } completion:nil];

}

-(void)hideTutorialMessage
{
    [UIView animateWithDuration:0.3 animations:^{
        self.guiHowToMessage.alpha = 0;
    } completion:^(BOOL finished) {
        self.guiHowToMessage.hidden = YES;
    }];
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

- (IBAction)onPressedDrawerToggleButton:(UIButton *)sender
{
    [self toggleOptionsDrawerAnimated:YES];
}

- (IBAction)OnSwipeUp:(id)sender
{
    if ([self isOptionsDrawerOpen]) return;
    [self openOptionsDrawerAnimated:YES];
}

- (IBAction)onSwipeDown:(id)sender
{
    if (![self isOptionsDrawerOpen]) return;
    [self closeOptionsDrawerAnimated:YES];
}

- (IBAction)onMessageGotIt:(UIButton *)sender
{
    [self hideTutorialMessage];
}

@end
