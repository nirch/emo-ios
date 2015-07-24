//
//  EMMainVCViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//


#define TAG @"EMFeedVC"

#import "EMFeedVC.h"
#import "EMRecorderVC.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMBackend.h"
#import "EmuCell.h"
#import "EMEmuticonScreenVC.h"
#import "EMPackagesVC.h"
#import "EMInterfaceDelegate.h"
#import "EMTutorialVC.h"
#import "EMNotificationCenter.h"
#import "EMSplashVC.h"
#import "EMUISound.h"
#import "AppManagement.h"
#import "EMAlertsPermissionVC.h"
#import "AppDelegate.h"
#import "HMPanel.h"
#import "HMServer.h"
#import "EMHolySheet.h"
#import "EMActionsArray.h"
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
#import "EMCaches.h"
#import "EMShareMail.h"

#import "EMRenderManager.h"
#import "EMRenderManager2.h"
#import "EMDownloadsManager2.h"


@interface EMFeedVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    EMRecorderDelegate,
    UIGestureRecognizerDelegate,
    EMPackageSelectionDelegate,
    EMInterfaceDelegate,
    EMShareDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiNavView;
@property (weak, nonatomic) IBOutlet UIView *guiPackagesSelectionContainer;
@property (weak, nonatomic) IBOutlet UIView *guiTutorialContainer;
@property (weak, nonatomic) IBOutlet UILabel *guiTagLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *guiSwipeLeftRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *guiSwipeRightRecognizer;

@property (weak, nonatomic) IBOutlet UIButton *guiOptionsButton;
@property (weak, nonatomic) IBOutlet UIButton *guiRetakeButton;
@property (weak, nonatomic) IBOutlet UIButton *guiBackToFBMButton;

@property (nonatomic) EMShare *sharer;

@property (weak, nonatomic) EMSplashVC *splashVC;

@property (weak, nonatomic) EMTutorialVC *kbTutorialVC;

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) Package *selectedPackage;

@property (nonatomic) NSMutableDictionary *triedToReloadResourcesForEmuOID;

@property (nonatomic, weak) EMPackagesVC *packagesBarVC;

@property (nonatomic, weak) EMAlertsPermissionVC *alertsPermissionVC;

@property (nonatomic) BOOL refetchDataAttempted;

@property (nonatomic) BOOL guiInitialized;

@end

@implementation EMFeedVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Cache in memory server side localized strings
    // (if exist in local storage)
    [AppManagement.sh updateLocalizedStrings];
    
    self.guiInitialized = NO;
    self.refetchDataAttempted = NO;
    self.triedToReloadResourcesForEmuOID = [NSMutableDictionary new];
    
    dispatch_after(DTIME(2.5), dispatch_get_main_queue(), ^{
        [self.guiActivity stopAnimating];
        if (self.guiCollectionView.alpha == 0) {
            self.guiCollectionView.alpha = 1;
        }
    });
    [self.guiActivity startAnimating];
    [self initScrollGesturesFixes];
    REMOTE_LOG(@"MainVC view did load");
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initExperiments];

    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];

    // Show the splash screen if needs to open the recorder
    // for the onboarding experience.
    if (!appCFG.onboardingPassed.boolValue) {
        [self showSplashAnimated:NO];
    }
    
    // Init observers
    [self initObservers];
    
    // Refresh data if required
    [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages
                                                        object:self
                                                      userInfo:nil];
    
    [self handleFlow];
    [self updateFBMessengerExperienceState];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.guiCollectionView.userInteractionEnabled = YES;
    dispatch_after(DTIME(1), dispatch_get_main_queue(), ^{
        [self handleVisibleCells];
    });
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self removeObservers];
}

-(void)dealloc
{
    self.guiCollectionView.delegate = nil;
    self.guiCollectionView.dataSource = nil;
}

#pragma mark - Layout
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutGUI];
}

#pragma mark - GUI init
-(void)layoutGUI
{
    // Updates
    
    // Initializations on first GUI layout updates.
    if (!self.guiInitialized) {
        self.guiTagLabel.alpha = 0;
        self.guiRetakeButton.alpha = 0;
        self.guiBackToFBMButton.alpha = 0;
        self.guiCollectionView.alpha = 0;

        CALayer *nl = self.guiNavView.layer;
        nl.shadowColor = [UIColor blackColor].CGColor;
        nl.shadowRadius = 2;
        nl.shadowOpacity = 0.15;
        nl.shadowOffset = CGSizeMake(0, 4);
        nl.shadowPath = [UIBezierPath bezierPathWithRect:nl.bounds].CGPath;
        
        // Mark as initialized
        self.guiInitialized = YES;
    }
}

#pragma mark - Experiments
-(void)initExperiments
{
    NSString *iconName = [HMPanel.sh stringForKey:VK_ICON_NAME_NAV_RETAKE fallbackValue:@"retakeIcon"];
    UIImage *icon = [UIImage imageNamed:iconName];
    [self.guiRetakeButton setImage:icon forState:UIControlStateNormal];
    [self.guiRetakeButton setImage:icon forState:UIControlStateSelected];
    [self.guiRetakeButton setImage:icon forState:UIControlStateHighlighted];
}


#pragma mark - Memory warnings
-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Log remotely
    REMOTE_LOG(@"EMMainVC Memory warning");
}


#pragma mark - initializations
+(EMFeedVC *)mainVCWithInfo:(NSDictionary *)info
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EMFeedVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"main vc"];
    return vc;
}

-(void)initScrollGesturesFixes
{
    // Recognize horizontal swipes, even while the collection view is vertically scrolled.
    NSArray *recognizers = self.guiCollectionView.gestureRecognizers;
    for (UIGestureRecognizer *recognizer in recognizers) {
        if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            UIPanGestureRecognizer *r = (UIPanGestureRecognizer *)recognizer;
            [r requireGestureRecognizerToFail:self.guiSwipeLeftRecognizer];
            [r requireGestureRecognizerToFail:self.guiSwipeRightRecognizer];
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
    
    // Backend refreshed information about packages
    [nc addUniqueObserver:self
                 selector:@selector(onPackagesDataRefresh:)
                     name:emkUIDataRefreshPackages
                   object:nil];
    
    // Need to choose another package
    [nc addUniqueObserver:self
                 selector:@selector(onShouldShowPackage:)
                     name:emkUIMainShouldShowPackage
                   object:nil];

    // App did become active.
    [nc addUniqueObserver:self
                 selector:@selector(onAppDidBecomeActive:)
                     name:emkAppDidBecomeActive
                   object:nil];

}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkRenderingFinished];
    [nc removeObserver:emkUIDataRefreshPackages];
    [nc removeObserver:hmkDownloadResourceFinished];
    [nc removeObserver:emkUIMainShouldShowPackage];
    [nc removeObserver:emkAppDidBecomeActive];
}

#pragma mark - Observers handlers
-(void)onEmuStateUpdated:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    NSString *oid = info[@"emuticonOID"];
    NSString *packageOID = info[@"packageOID"];
    
    // Make sure this is related to the currently displayed package.
    // (skip check if in the mixed screen)s
    if (self.selectedPackage != nil && ![packageOID isEqualToString:self.selectedPackage.oid]) {
        // Ignore notifications about emus related to packages not on screen.
        return;
    }
    
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


-(void)onPackagesDataRefresh:(NSNotification *)notification
{
    // Cache in memory server side localized strings
    // (if exist in local storage)
    [AppManagement.sh updateLocalizedStrings];

    // Did the refetch
    self.refetchDataAttempted = YES;
    
    // Update UI
    [self.packagesBarVC refresh];
    if (self.guiCollectionView.alpha < 1) {
        [self.guiActivity stopAnimating];
        [UIView animateWithDuration:0.2 animations:^{
            self.guiCollectionView.alpha = 1;
        }];
    }

    // Update latest published package
    Package *latestPublishedPackage = [Package latestPublishedPackageInContext:EMDB.sh.context];

    if (latestPublishedPackage != nil) {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        appCFG.latestPackagePublishedOn = latestPublishedPackage.firstPublishedOn;
    }
    
    if (notification.userInfo[@"forced_reload"]) {
        [self debugCleanAndRender];
    }
    
    // Handle the flow
    [self handleFlow];
}

-(void)onShouldShowPackage:(NSNotification *)notification
{
    NSString *packageOID = notification.userInfo[@"packageOID"];
    if (packageOID == nil) return;
    
    Package *package = [Package findWithID:packageOID context:EMDB.sh.context];
    if (package == nil) return;
    
    [self.packagesBarVC selectThisPackage:package originUI:nil];
}


-(void)onAppDidBecomeActive:(NSNotification *)notification
{
    [self updateFBMessengerExperienceState];
}


#pragma mark - FB Messenger experience
-(void)updateFBMessengerExperienceState
{
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    BOOL inFBContext = app.fbContext != nil;
    self.guiBackToFBMButton.hidden = NO;
    self.guiRetakeButton.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiBackToFBMButton.alpha = inFBContext? 1:0;
        self.guiRetakeButton.alpha = inFBContext? 0:1;
    }];
}


-(void)backToFBM
{
    if ([FBSDKMessengerSharer messengerPlatformCapabilities] & FBSDKMessengerPlatformCapabilityOpen) {
        [FBSDKMessengerSharer openMessenger];
    }
}

#pragma mark - The data
-(NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate;
    NSArray *sortDescriptors;
    
    if (self.selectedPackage) {
        // A specific package.
        predicate = [NSPredicate predicateWithFormat:@"isPreview=%@ AND emuDef.package=%@", @NO, self.selectedPackage];

        sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.order" ascending:YES] ];
        
        HMLOG(TAG, EM_DBG, @"Showing emuticons for package named:%@", self.selectedPackage.name);
        REMOTE_LOG(@"Showing emuticons for package: %@", self.selectedPackage.name);
    } else {
        // The mixed screen.
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
       
        NSArray *emus = appCFG.mixedScreenEmus;
        assert(emus);
        predicate = [NSPredicate predicateWithFormat:@"isPreview=%@ AND emuDef.oid in %@", @NO, emus];
        sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.mixedScreenOrder" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"emuDef.package.oid" ascending:YES] ];
        
        HMLOG(TAG, EM_DBG, @"Showing emuticons for mixed screen");
        REMOTE_LOG(@"Showing emuticons for mixed screen");
        
//        predicate = [NSPredicate predicateWithFormat:@"isPreview=%@", @NO];
//        sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.order" ascending:YES] ];
        
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = sortDescriptors;
    fetchRequest.fetchBatchSize = 20;
//    fetchRequest.fetchLimit = 40;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:@"Main"];
    _fetchedResultsController = frc;
    return frc;
}

-(void)resetFetchedResultsController
{
    [NSFetchedResultsController deleteCacheWithName:@"Main"];
    _fetchedResultsController = nil;
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleVisibleCells];
        });
    }
}

#pragma mark - Flow
-(void)handleFlow
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (!appCFG.onboardingPassed.boolValue) {
        // Try to fetch data from server at least once, before starting onboarding.
        if (!self.refetchDataAttempted) return;
        
        /**
         *  Open the recorder for the first time.
         */
        NSArray *prefferedEmus = [HMPanel.sh listForKey:VK_ONBOARDING_EMUS_FOR_PREVIEW_LIST
                                          fallbackValue:nil];
        EmuticonDef *emuticonDefForOnboarding = [appCFG emuticonDefForOnboardingWithPrefferedEmus:prefferedEmus];
        
        
        if (emuticonDefForOnboarding == nil) {
            REMOTE_LOG(@"CRITICAL ERROR: couldn't use onboarding data bundled on device!");
        }
        REMOTE_LOG(@"Opening recorder for the first time");
        REMOTE_LOG(@"Using emuticon named:%@ for onboarding.", emuticonDefForOnboarding.name);
        [self openRecorderForFlow:EMRecorderFlowTypeOnboarding
                             info:@{
                                    emkEmuticonDefOID:emuticonDefForOnboarding.oid,
                                    emkEmuticonDefName:emuticonDefForOnboarding.name
                                    }];

    } else {

        /**
         *  User finished onboarding in the past.
         *  just show the main screen of the app.
         */
        
        REMOTE_LOG(@"The main screen");
        
        // Refresh on first appearance
        [self resetFetchedResultsController];
        [self.guiCollectionView reloadData];
        
        // Never viewed the kb tutorial?
        // It is time to show it.
        if (!appCFG.userViewedKBTutorial.boolValue) {
            [self showKBTutorial];
        }
    }
}


-(void)epicFail:(NSString *)errorMessage
{
    UIAlertController *alert = [UIAlertController new];
    alert.title = LS(@"ALERT_REFRESHING_INFO_TITLE");
    alert.message = LS(@"ALERT_CHECK_INTERNET_MESSAGE");
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"ALERT_TRY_AGAIN_ACTION")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                                // Refresh data if required
                                                [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages
                                                                                                    object:self
                                                                                                  userInfo:nil];
                                            }]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

#pragma mark - splash
-(void)showSplashAnimated:(BOOL)animated
{
    if (self.splashVC == nil) {
        self.splashVC = [EMSplashVC splashVCInParentVC:self];
        NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
        [self.splashVC setText:build];
    }
    [self.splashVC showAnimated:animated];
}

#pragma mark - Alerts question
-(void)showAlertsPermissionScreenAnimated:(BOOL)animated
{
    if (self.alertsPermissionVC == nil) {
        self.alertsPermissionVC = [EMAlertsPermissionVC alertsPermissionVCInParentVC:self];
    }
    [self.alertsPermissionVC showAnimated:animated];
}

#pragma mark - VC preferences
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"emuticon screen segue"]) {
        // Get the emuticon object we want to see.
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        // Pass the emuticon oid to the destination view controller.
        EMEmuticonScreenVC *vc = segue.destinationViewController;
        vc.emuticonOID = emu.oid;
        
        // Analytics
        HMParams *params = [HMParams new];
        [params addKey:AK_EP_EMUTICON_NAME valueIfNotNil:emu.emuDef.name];
        [params addKey:AK_EP_EMUTICON_OID valueIfNotNil:emu.emuDef.oid];
        [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:emu.emuDef.package.name];
        [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:emu.emuDef.package.oid];
        [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_SELECTED_ITEM info:params.dictionary];
        
    } else if ([segue.identifier isEqualToString:@"packages bar segue"]) {
        EMPackagesVC *vc = segue.destinationViewController;
        self.packagesBarVC = vc;
        vc.delegate = self;
        vc.showMixedPackage = YES;
        vc.shouldAnimateScroll = YES;
        vc.scrollSelectedToCenter = YES;
        
    } else if ([segue.identifier isEqualToString:@"tutorial segue"]) {
        EMTutorialVC *vc = segue.destinationViewController;
        self.kbTutorialVC = vc;
        vc.delegate = self;
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"tutorial segue"]) {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        if (appCFG.userViewedKBTutorial.boolValue) {
            return NO;
        }
    }
    return YES;
}

-(void)updateContentInsetsForObjectsCount:(NSInteger)count
{
    if (count <= 6) {
        CGSize vSize = self.guiCollectionView.bounds.size;
        CGFloat padding = 0;
        if (vSize.height == 736) padding = 16;
        if (vSize.height == 667) padding = 10;
        self.guiCollectionView.contentInset = UIEdgeInsetsMake(padding, 0, 0, 0);
    } else {
        self.guiCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }

}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    NSInteger count;
    if (section == 0) {
        count = self.fetchedResultsController.fetchedObjects.count;
    } else {
        count = 30;
    }

    [self updateContentInsetsForObjectsCount:count];
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"emu cell";
    static NSString *tagCellIdentifier = @"tag cell";
    EmuCell *cell;
    
    if (indexPath.section == 0) {
        cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        [self configureCell:cell forIndexPath:indexPath];    } else {
        cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:tagCellIdentifier forIndexPath:indexPath];
        [self configureTagCell:cell forIndexPath:indexPath];
    }
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        CGFloat size = (self.view.bounds.size.width-10.0) / 2.0;
        return CGSizeMake(size, size);
    } else {
        CGFloat size = (self.view.bounds.size.width-10.0) / 2.0;
        return CGSizeMake(size, size/2.0);
    }
}



#pragma mark - Cell
-(void)configureCell:(EmuCell *)cell
        forIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if (emu == nil) return;
    
    NSDictionary *info = @{
                           @"for":@"emu",
                           @"indexPath":indexPath,
                           @"emuticonOID":emu.oid,
                           @"packageOID":emu.emuDef.package.oid,
                           };
    
    cell.guiFailedImage.hidden = YES;
    cell.guiFailedLabel.hidden = YES;
    [cell.guiActivity stopAnimating];
    
    cell.guiDebugLabel.text = [SF:@"%@>>%@", @(indexPath.item), emu.emuDef.name];
    
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
        
    } else if ([emu.emuDef allResourcesAvailable]) {
        //
        // Emu not rendered yet, but all resources available.
        // We can render this emu.
        //
        cell.animatedGifURL = nil;
        UserFootage *mostPrefferedFootage = [emu mostPrefferedUserFootage];
        if (mostPrefferedFootage != nil) {
            cell.animatedGifURL = nil;
            [cell setAnimatedGifNamed:@"rendering"];
            [EMRenderManager2.sh enqueueEmu:emu indexPath:nil userInfo:info];
        } else {
            [self failedCell:cell];
        }
        
    } else {
        cell.animatedGifURL = nil;
        [cell setAnimatedGifNamed:@"downloading"];
        cell.guiThumbView.hidden = YES;
    }
    cell.guiLock.alpha = emu.prefferedFootageOID? 0.2 : 0.0;
}

-(void)failedCell:(EmuCell *)cell
{
    [cell.guiActivity stopAnimating];
    cell.animatedGifURL = nil;
    cell.guiFailedImage.hidden = NO;
    cell.guiFailedLabel.hidden = NO;
}

#pragma mark - Tag cells
-(void)configureTagCell:(EmuCell *)cell
        forIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor greenColor];
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];
    
    EmuCell *cell = (EmuCell *)[self.guiCollectionView cellForItemAtIndexPath:indexPath];
    
    self.guiCollectionView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.1 animations:^{
        cell.alpha = 0.6;
        cell.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            cell.alpha = 1;
            cell.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
            if (emu == nil) return;
            
            if (self.triedToReloadResourcesForEmuOID[emu.oid]) {
                [self.triedToReloadResourcesForEmuOID removeAllObjects];
                self.guiCollectionView.userInteractionEnabled = YES;
                [self.guiCollectionView reloadData];
                return;
            }
            
            
            [self performSegueWithIdentifier:@"emuticon screen segue" sender:indexPath];
            dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
                self.guiCollectionView.userInteractionEnabled = YES;
            });
        }];
    }];
}

#pragma mark - Scrolling
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    HMLOG(TAG, EM_VERBOSE, @"Finished scrolling (after deceleration)");
    [self handleVisibleCells];
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [self handleVisibleCells];
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //self.isScrolling = YES;
    HMLOG(TAG, EM_VERBOSE, @"Begin scrolling");
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        // Will not decelerate after dragging, so scrolling just ended.
        [self handleVisibleCells];
        HMLOG(TAG, EM_VERBOSE, @"Finished scrolling A");
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
        
        // We don't need the resources because the emu is already rendered.
        if (emu.wasRendered.boolValue) continue;
        
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

#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [self.splashVC hideAnimated:YES];
        [HMPanel.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
        
        if (flowType == EMRecorderFlowTypeOnboarding) {
            // Onboarding finished goals
            [self onboardingFinishedGoalsWithInfo:info];
        } else {
            [self retakeFinishedGoalWithInfo:info];
        }
    }];
        
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (flowType == EMRecorderFlowTypeOnboarding && !appCFG.userViewedKBTutorial.boolValue) {
        [self _handleChangeToMixScreen];
        [self showKBTutorial];
    } else {
        [self handleFlow];
    }
}

-(void)onboardingFinishedGoalsWithInfo:(NSDictionary *)info
{
    [HMPanel.sh experimentGoalEvent:GK_ONBOARDING_FINISHED];
    NSNumber *latestBackgroundMark = info[AK_EP_LATEST_BACKGROUND_MARK];
    if ([latestBackgroundMark isKindOfClass:[NSNumber class]] && latestBackgroundMark.integerValue == 1) {
        [HMPanel.sh experimentGoalEvent:GK_ONBOARDING_FINISHED_WITH_GOOD_BACKGROUND];
    }
}


-(void)retakeFinishedGoalWithInfo:(NSDictionary *)info
{
    [HMPanel.sh experimentGoalEvent:GK_RETAKE_NEW];
    NSNumber *latestBackgroundMark = info[AK_EP_LATEST_BACKGROUND_MARK];
    if ([latestBackgroundMark isKindOfClass:[NSNumber class]] && latestBackgroundMark.integerValue == 1) {
        [HMPanel.sh experimentGoalEvent:GK_RETAKE_NEW_WITH_GOOD_BACKGROUND];
    }
}



-(void)showKBTutorial
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    //if (self.kbTutorialVC == nil || appCFG.userViewedKBTutorial.boolValue) return;
    appCFG.userViewedKBTutorial = @YES;
    [EMDB.sh save];
    
    if (self.kbTutorialVC == nil) {
        self.kbTutorialVC = [EMTutorialVC tutorialVCInParentVC:self];
        [self addChildViewController:self.kbTutorialVC];
        [self.guiTutorialContainer addSubview:self.kbTutorialVC.view];
        self.kbTutorialVC.view.frame = self.guiTutorialContainer.bounds;
    }
    
    self.guiPackagesSelectionContainer.hidden = YES;
    self.guiTutorialContainer.hidden = NO;
    self.guiTutorialContainer.alpha = 0;
    self.guiNavView.alpha = 0.3;
    self.guiNavView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiTutorialContainer.alpha = 1;
    } completion:^(BOOL finished) {
        [self.kbTutorialVC start];
    }];
    
}

-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [self.splashVC hideAnimated:YES];
        [HMPanel.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
    }];

    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
}


#pragma mark - Opening recorder
-(void)openRecorderForFlow:(EMRecorderFlowType)flowType
                      info:(NSDictionary *)info
{
    EMRecorderVC *recorderVC = [EMRecorderVC recorderVCForFlow:flowType info:info];
    recorderVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    recorderVC.delegate = self;
    [self presentViewController:recorderVC animated:YES completion:^{
        [self.splashVC hideAnimated:NO];
    }];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

#pragma mark - Opening the recorder
-(void)askUserToChooseWhatToRetake
{
    EMActionsArray *actionsMapping = [EMActionsArray new];
    
    //
    // Retake options
    //
    NSString *title = LS(@"RETAKE_CHOICE_TITLE");
    if (self.selectedPackage && ![self.selectedPackage doAllEmusHaveSpecificTakes]) {
        [actionsMapping addAction:@"RETAKE_CHOICE_PACKAGE" text:LS(@"RETAKE_CHOICE_PACKAGE") section:0];
    }
    [actionsMapping addAction:@"RETAKE_CHOICE_ALL" text:LS(@"RETAKE_CHOICE_ALL") section:0];
    EMHolySheetSection *section1 = [EMHolySheetSection sectionWithTitle:title message:nil buttonTitles:[actionsMapping textsForSection:0] buttonStyle:JGActionSheetButtonStyleDefault];
    
    //
    // Cancel
    //
    EMHolySheetSection *cancelSection = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:@[LS(@"CANCEL")] buttonStyle:JGActionSheetButtonStyleCancel];

    //
    // Sections
    //
    NSMutableArray *sections = [NSMutableArray arrayWithArray:@[section1, cancelSection]];
    
    //
    // Holy sheet
    //
    EMHolySheet *sheet = [EMHolySheet actionSheetWithSections:sections];
    [sheet setButtonPressedBlock:^(JGActionSheet *sender, NSIndexPath *indexPath) {
        [sender dismissAnimated:YES];
        [self handleRetakeChoiceWithIndexPath:indexPath actionsMapping:actionsMapping];
    }];
    [sheet setOutsidePressBlock:^(JGActionSheet *sender) {
        [sender dismissAnimated:YES];
        [self cancelRetake];
    }];
    [sheet showInView:self.view animated:YES];

}

-(void)handleRetakeChoiceWithIndexPath:(NSIndexPath *)indexPath actionsMapping:(EMActionsArray *)actionsMapping
{
    NSString *actionName = [actionsMapping actionNameForIndexPath:indexPath];
    if (actionName == nil) return;
    
    if ([actionName isEqualToString:@"RETAKE_CHOICE_ALL"]) {
        
        // Analytics
        HMParams *params = [HMParams new];
        [params addKey:AK_EP_RETAKE_OPTION valueIfNotNil:@"all"];
        [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
                              info:params.dictionary];
        
        // Retake them all
        [self retakeAll];

    } else if ([actionName isEqualToString:@"RETAKE_CHOICE_PACKAGE"]) {
        
        // Analytics
        HMParams *params = [HMParams new];
        [params addKey:AK_EP_RETAKE_OPTION valueIfNotNil:@"package"];
        [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.selectedPackage.name];
        [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.selectedPackage.oid];
        [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
                                 info:params.dictionary];
        // Retake
        [self retakeCurrentPackage];
        
    } else {
        
        // Cancel
        [self cancelRetake];
        
    }
}

-(void)retakeAll
{
    /**
     *  Open the recording for retaking all emuticons.
     */
    if (self.selectedPackage) {
        [self openRecorderForFlow:EMRecorderFlowTypeRetakeAll
                             info:@{emkPackage:self.selectedPackage}];
        REMOTE_LOG(@"Retake all selected. selected package: %@", self.selectedPackage.name);
        
    } else {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        EmuticonDef *emuticonDefForOnboarding = [appCFG emuticonDefForOnboarding];
        [self openRecorderForFlow:EMRecorderFlowTypeRetakeAll
                             info:@{
                                    emkEmuticonDefOID:emuticonDefForOnboarding.oid,
                                    emkEmuticonDefName:emuticonDefForOnboarding.name
                                    }];
        REMOTE_LOG(@"Retake all selected (mixed screen). Preview emu named: %@", emuticonDefForOnboarding.name);
        
    }
    
    
}

-(void)retakeCurrentPackage
{
    if (self.selectedPackage == nil)
        return;
    
    /**
     *  Open the recording for retaking emuticons for current selected package.
     */
    [self openRecorderForFlow:EMRecorderFlowTypeRetakeForPackage
                         info:@{emkPackage:self.selectedPackage}];
    REMOTE_LOG(@"Retake current package. selected package: %@", self.selectedPackage.name);
}

-(void)cancelRetake
{
    // Analytics
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.selectedPackage.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.selectedPackage.oid];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_CANCELED
                          info:params.dictionary];
}

-(void)resetPack
{
    if (self.selectedPackage == nil) return;
    
    Package *package = self.selectedPackage;
    
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:package.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:package.oid];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_NAV_SELECTION_RESET_PACK info:params.dictionary];

    // Reset
    NSArray *emus = [Emuticon allEmuticonsInPackage:package];
    for (Emuticon *emu in emus) {
        [emu cleanUp];
        if (emu.prefferedFootageOID) {
            UserFootage *footage = [UserFootage findWithID:emu.prefferedFootageOID context:EMDB.sh.context];
            if (footage) [footage deleteAndCleanUp];
            emu.prefferedFootageOID = nil;
        }
    }
    
    if (package.prefferedFootageOID) {
        UserFootage *footage = [UserFootage findWithID:package.prefferedFootageOID context:EMDB.sh.context];
        if (footage) {
            [footage deleteAndCleanUp];
            package.prefferedFootageOID = nil;
        }
    }
    [package recountRenders];
    [EMDB.sh save];

    // Reload (and resend some emus to rendering)
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
    
    REMOTE_LOG(@"Reset package. selected package: %@", self.selectedPackage.name);
}

-(void)debugCleanAndRender
{
    for (Package *package in [Package allPackagesInContext:EMDB.sh.context]) {
        NSArray *emus = [Emuticon allEmuticonsInPackage:package];
        for (Emuticon *emu in emus) {
            [emu cleanUp];
        }
        [package recountRenders];
    }
    [self.guiCollectionView reloadData];
    [EMDB.sh save];
}

#pragma mark - Registering to notifications
-(void)openAppSettingsWithReason:(NSString *)reason
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];

    HMParams *params = [HMParams new];
    [params addKey:AK_EP_REASON value:reason];
}

#pragma mark - More user choices
-(void)userChoices
{
    EMActionsArray *actionsMapping = [EMActionsArray new];
    NSInteger sect = 0;

    //
    // Pack options
    //
    EMHolySheetSection *section1 = nil;
    if (self.selectedPackage) {
        NSString *title = [SF:LS(@"USER_CHOICE_TITLE"), [self.selectedPackage localizedLabel]];
        if (![self.selectedPackage doAllEmusHaveSpecificTakes]) {
            [actionsMapping addAction:@"USER_CHOICE_RETAKE_PACK" text:LS(@"USER_CHOICE_RETAKE_PACK") section:sect];
        }
        if ([self.selectedPackage hasEmusWithSpecificTakes] || self.selectedPackage.prefferedFootageOID) {
            [actionsMapping addAction:@"USER_CHOICE_RESET_PACK" text:LS(@"USER_CHOICE_RESET_PACK") section:sect];
        }
        section1 = [EMHolySheetSection sectionWithTitle:title message:nil buttonTitles:[actionsMapping textsForSection:sect] buttonStyle:JGActionSheetButtonStyleDefault];
        sect++;
    }
    
    //
    // More options
    //
    UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (notificationSettings.types == UIUserNotificationTypeNone) {
        [actionsMapping addAction:@"NOTIFICATIONS_ENABLE" text:LS(@"NOTIFICATIONS_ENABLE") section:sect];
    }
    [actionsMapping addAction:@"USER_CHOICE_SHARE_APP" text:LS(@"USER_CHOICE_SHARE_APP") section:sect];
    [actionsMapping addAction:@"USER_CHOICE_ABOUT_KB" text:LS(@"USER_CHOICE_ABOUT_KB") section:sect];
    [actionsMapping addAction:@"USER_CHOICE_ABOUT" text:LS(@"USER_CHOICE_ABOUT") section:sect];
    EMHolySheetSection *section2 = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:[actionsMapping textsForSection:sect] buttonStyle:JGActionSheetButtonStyleDefault];
    sect++;
    
    //
    // Debugging options.
    //
    EMHolySheetSection *debugSection = nil;
    if (AppManagement.sh.isTestApp) {
        NSString *title = [SF:@"DEV APPLICATION - %@", EMBackend.sh.server.serverURL];
        NSString *message = [SF:@"Data: %@", EMBackend.sh.server.usingPublicDataBase? @"PUBLIC":@"SCRATCHPAD"];
        [actionsMapping addAction:@"CLEAN_AND_RENDER" text:@"Clean and render" section:sect];
        [actionsMapping addAction:@"RELOAD_ALL" text:@"Reload all data & Render" section:sect];
        [actionsMapping addAction:@"DEBUG_SCREEN" text:@"Debug screen" section:sect];
        debugSection = [EMHolySheetSection sectionWithTitle:title
                                                    message:message
                                               buttonTitles:[actionsMapping textsForSection:sect]
                                                buttonStyle:JGActionSheetButtonStyleRed];
        sect++;
    }
    
    //
    // Extra sections
    //
    EMHolySheetSection *cancelSection = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:@[LS(@"CANCEL")] buttonStyle:JGActionSheetButtonStyleCancel];
    NSMutableArray *sections = [NSMutableArray new];
    if (section1) [sections addObject:section1];
    if (section2) [sections addObject:section2];
    if (debugSection) [sections addObject:debugSection];
    [sections addObject:cancelSection];

    //
    // Holy sheet
    //
    EMHolySheet *sheet = [EMHolySheet actionSheetWithSections:sections];
    [sheet setButtonPressedBlock:^(JGActionSheet *sender, NSIndexPath *indexPath) {
        [sender dismissAnimated:YES];
        [self handleUserChoiceWithIndexPath:indexPath actionsMapping:actionsMapping];
    }];
    [sheet setOutsidePressBlock:^(JGActionSheet *sender) {
        [sender dismissAnimated:YES];
    }];
    [sheet showInView:self.view animated:YES];
}


-(void)handleUserChoiceWithIndexPath:(NSIndexPath *)indexPath actionsMapping:(EMActionsArray *)actionsMapping
{
    NSString *actionName = [actionsMapping actionNameForIndexPath:indexPath];
    if (actionName == nil) return;
    
    if ([actionName isEqualToString:@"USER_CHOICE_RETAKE_PACK"]) {
        
        // Retake the current package.
        [self retakeCurrentPackage];
        
    } else if ([actionName isEqualToString:@"USER_CHOICE_RESET_PACK"]) {
        
        // Clears all emus in this package that have specific footage.
        // Will rerender emus in the package using the footage defined for the package.
        [self resetPack];

    } else if ([actionName isEqualToString:@"CLEAN_AND_RENDER"]) {
        
        // Clean all and resend to rendering.
        [self debugCleanAndRender];

    } else if ([actionName isEqualToString:@"RELOAD_ALL"]) {

        // Reload data
        [[NSNotificationCenter defaultCenter] postNotificationName:emkDataRequiredPackages
                                                            object:self
                                                          userInfo:@{@"forced_reload":@YES}];

    } else if ([actionName isEqualToString:@"DEBUG_SCREEN"]) {
        
        // Debug screen
        [self performSegueWithIdentifier:@"debug screen segue" sender:nil];

    } else if ([actionName isEqualToString:@"USER_CHOICE_SHARE_APP"]) {

        [self shareApp];
        
    } else if ([actionName isEqualToString:@"USER_CHOICE_ABOUT"]) {
        
        // About message.
        [self aboutMessage];

    } else if ([actionName isEqualToString:@"NOTIFICATIONS_ENABLE"]) {
        
        // Go to the application settings screen.
        [self openAppSettingsWithReason:@"enable notifications"];
        
    } else if ([actionName isEqualToString:@"USER_CHOICE_ABOUT_KB"]) {
        
        // Show the keyboard tutorial again.
        [self showKBTutorial];
        
    }
}

#pragma mark - Share app
-(void)shareApp
{
    NSString *subjectString = [HMPanel.sh stringForKey:VK_TEXT_SHARE_APP_SUBJECT fallbackValue:@"Emu - Animated Selfie Stickers"];

    NSURL *htmlURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"shareapp" ofType:@"html"]];
    NSString *defaultHTMLBody = [NSString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:nil];
    NSString *htmlBody = [HMPanel.sh stringForKey:VK_HTML_SHARE_APP_BODY fallbackValue:defaultHTMLBody];
    
    self.sharer = [EMShareMail new];
    self.sharer.objectToShare = @{
                                  @"subject":subjectString,
                                  @"body":htmlBody
                                  };
    self.sharer.shareOption = emkShareHTML;
    self.sharer.viewController = self;
    self.sharer.view = self.view;
    self.sharer.delegate = self;
    [self.sharer share];
}


#pragma mark - EMShareDelegate
// Sharing did happen.
-(void)sharerDidShareObject:(id)sharedObject withInfo:(NSDictionary *)info
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_SENDER_UI value:@"main"];
    [params addKey:AK_EP_SHARE_METHOD value:@"mail"];
    [HMPanel.sh analyticsEvent:AK_E_SHARE_APP info:params.dictionary];
}

// Sharing was cancelled.
-(void)sharerDidCancelWithInfo:(NSDictionary *)info
{
}

// Sharing failed.
-(void)sharerDidFailWithInfo:(NSDictionary *)info
{
}

// An optional call, just for finishing up when required.
-(void)sharerDidFinishWithInfo:(NSDictionary *)info
{
}

#pragma mark - About message
-(void)aboutMessage
{
    // TODO: Move this from here to somewhere else that can be used from other places in the app
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    UIAlertController *alert = [[UIAlertController alloc] init];
    
    alert.title = [SF:LS(@"ABOUT_EMU_TITLE"), build];
    alert.message = LS(@"ABOUT_EMU_MESSAGE");

    [alert addAction:[UIAlertAction actionWithTitle:LS(@"ALERT_OK_ACTION")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - EMPackageSelectionDelegate
-(void)packageWasSelected:(Package *)package
{
    [self.triedToReloadResourcesForEmuOID removeAllObjects];
    
    // If selected package is the same as current package, just reload.
    if ((self.selectedPackage == nil && package == nil) || [self.selectedPackage.oid isEqualToString:package.oid]) {
        [self.guiCollectionView reloadData];
        return;
    }
    
    // A specific package or mixed screen?
    if (package != nil) {
        // A specific packge.
        [self _handleChangeToPackage:package];
        [HMPanel.sh userFeedbackDialoguesPoint];
    } else {
        // Mix screen
        [self _handleChangeToMixScreen];
    }

    // Store reference to selected package (nil if mixed screen)
    // And reset the fetched results controller so relevant data will be displayed.
    self.selectedPackage = package;
    [self resetFetchedResultsController];
    
    // Reveal/Hide Transitions.
    [self transitionToPackage:package];
    
    REMOTE_LOG(@"Did select package: %@", self.selectedPackage.name);
}


-(void)_handleChangeToMixScreen
{
//    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
//    [appCFG createMissingEmuticonObjectsForMixedScreen];
//    [EMCaches.sh cacheGifsForEmus:self.fetchedResultsController.fetchedObjects];
}

-(void)_handleChangeToPackage:(Package *)package {
    [EMDB ensureDirPathExists:package.resourcesPath];
    
    // Make sure emuticons instances created for this package
    [package createMissingEmuticonObjects];
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];

    NSInteger numberOfViewedPackagesBeforeAlertsQuestion = [AppCFG tweakedInteger:@"number_of_viewed_packages_before_alerts_question" defaultValue:0];
    NSInteger numberOfViewedPackages = [Package countNumberOfViewedPackagesInContext:EMDB.sh.context];
    if (!appCFG.userAskedInMainScreenAboutAlerts.boolValue) {
        // Never asked.
        // Ask the user if interested in background fetches / auto updates.
        if (numberOfViewedPackages >= numberOfViewedPackagesBeforeAlertsQuestion)
            [self askUserAboutAlerts];
    }
    
    // If package never viewed before by the user, count the event.
    if (!package.viewedByUser.boolValue) {
        [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_PACKAGES_NAVIGATED];
        [HMPanel.sh reportSuperParameterKey:AK_S_DID_EVER_NAVIGATE_TO_ANOTHER_PACKAGE value:@YES];
    }
    
    // Mark package as viewed.
    package.viewedByUser = @YES;
    [EMDB.sh save];
}


-(void)transitionToPackage:(Package *)package
{
    __weak EMFeedVC *weakSelf = self;
    
    self.guiTagLabel.text = [package tagLabel];
    self.guiTagLabel.alpha = 1.0;
    self.guiTagLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
    [UIView animateWithDuration:0.7 animations:^{
        weakSelf.guiTagLabel.alpha = 0;
        weakSelf.guiTagLabel.transform = CGAffineTransformIdentity;
    }];

    weakSelf.guiCollectionView.alpha = 0;
    weakSelf.guiCollectionView.transform = CGAffineTransformMakeScale(0.90, 0.90);
    [self.guiCollectionView performBatchUpdates:^{
        [weakSelf.guiCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             weakSelf.guiCollectionView.alpha = 1;
                             weakSelf.guiCollectionView.transform = CGAffineTransformIdentity;
                         } completion:^(BOOL finished) {
                             
                         }];
    }];
}


-(void)askUserAboutAlerts
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.userAskedInMainScreenAboutAlerts = @YES;
    [EMDB.sh save];
    dispatch_after(DTIME(2), dispatch_get_main_queue(), ^{
        [self showAlertsPermissionScreenAnimated:YES];
    });
}

-(void)packagesAvailableCount:(NSInteger)numberOfPackages
{
    self.guiPackagesSelectionContainer.alpha = numberOfPackages>1? 1:0;
}

#pragma mark - EMInterfaceDelegate
-(void)controlSentActionNamed:(NSString *)actionName info:(NSDictionary *)info
{
    if ([actionName isEqualToString:@"keyboard tutorial should be dismissed"]) {
        self.guiPackagesSelectionContainer.hidden = NO;
        self.guiNavView.userInteractionEnabled = YES;
        self.guiCollectionView.hidden = NO;
        [self.kbTutorialVC finish];
        [UIView animateWithDuration:0.3 animations:^{
            self.guiTutorialContainer.alpha = 0;
            self.guiCollectionView.alpha = 1;
            self.guiNavView.alpha = 1;
        } completion:^(BOOL finished) {
            self.guiTutorialContainer.hidden = YES;
            //[self.guiTutorialContainer removeFromSuperview];
            [self.kbTutorialVC.view removeFromSuperview];
            [self.kbTutorialVC removeFromParentViewController];
            self.kbTutorialVC = nil;
        }];
    }
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRetakeButton:(id)sender
{
    [self askUserToChooseWhatToRetake];
    
    //
    // Analytics
    //
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.selectedPackage.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.selectedPackage.oid];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_PRESSED_RETAKE_BUTTON];
}

- (IBAction)onPressedNavButton:(id)sender
{
    [self userChoices];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_PRESSED_NAV_BUTTON];
}

- (IBAction)onPressedEmuButton:(id)sender
{
    [self aboutMessage];
    [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_PRESSED_APP_BUTTON];
}

- (IBAction)onPressedBackToFBMButton:(id)sender
{
    [self backToFBM];
}


- (IBAction)onSwipedLeftCollectionView:(id)sender
{
    HMLOG(TAG, EM_DBG, @"Swipe left");
    if ([self.packagesBarVC isEmpty]) return;
    [UIView animateWithDuration:0.1 animations:^{
        self.guiCollectionView.alpha = 0;
        self.guiCollectionView.transform = CGAffineTransformMakeTranslation(-40, 0);
    } completion:^(BOOL finished) {
        [self.packagesBarVC selectNext];
    }];
    [EMUISound.sh playSoundNamed:SND_SWIPE];
}

- (IBAction)onSwipedRightCollectionView:(id)sender
{
    HMLOG(TAG, EM_DBG, @"Swipe right");
    if ([self.packagesBarVC isEmpty]) return;
    [UIView animateWithDuration:0.1 animations:^{
        self.guiCollectionView.alpha = 0;
        self.guiCollectionView.transform = CGAffineTransformMakeTranslation(40, 0);
    } completion:^(BOOL finished) {
        [self.packagesBarVC selectPrevious];
    }];
    [EMUISound.sh playSoundNamed:SND_SWIPE];
}


@end
