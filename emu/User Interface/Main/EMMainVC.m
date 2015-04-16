//
//  EMMainVCViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//


#define TAG @"EMMainVC"

#import "EMMainVC.h"
#import "EMRecorderVC.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import "EMBackend.h"
#import "EmuCell.h"
#import "EMEmuticonScreenVC.h"
#import "EMRenderManager.h"
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

@interface EMMainVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    EMRecorderDelegate,
    UIGestureRecognizerDelegate,
    EMPackageSelectionDelegate,
    EMInterfaceDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiNavView;
@property (weak, nonatomic) IBOutlet UIView *guiPackagesSelectionContainer;
@property (weak, nonatomic) IBOutlet UIView *guiTutorialContainer;
@property (weak, nonatomic) IBOutlet UILabel *guiTagLabel;

@property (weak, nonatomic) EMSplashVC *splashVC;

@property (weak, nonatomic) EMTutorialVC *kbTutorialVC;

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic) Package *selectedPackage;

@property (nonatomic) NSMutableDictionary *triedToReloadResourcesForEmuOID;

@property (nonatomic, weak) EMPackagesVC *packagesBarVC;

@property (nonatomic, weak) EMAlertsPermissionVC *alertsPermissionVC;

@property (nonatomic) BOOL refetchDataAttempted;

@end

@implementation EMMainVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.refetchDataAttempted = NO;
    self.triedToReloadResourcesForEmuOID = [NSMutableDictionary new];
    self.guiTagLabel.alpha = 0;
    REMOTE_LOG(@"MainVC view did load");
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.guiCollectionView.userInteractionEnabled = YES;
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

#pragma mark - Memory warnings
-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Log remotely
    REMOTE_LOG(@"EMMainVC Memory warning");
    
    // Go boom on a test application.
    //[HMPanel.sh explodeOnTestApplicationsWithInfo:nil];
}


#pragma mark - initializations
+(EMMainVC *)mainVCWithInfo:(NSDictionary *)info
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EMMainVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"main vc"];
    return vc;
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On background detection information received.
    [nc addUniqueObserver:self
                 selector:@selector(onRenderingFinished:)
                     name:hmkRenderingFinished
                   object:nil];
    
    
    // Backend refreshed information about packages
    [nc addUniqueObserver:self
                 selector:@selector(onPackagesDataRefresh:)
                     name:emkUIDataRefreshPackages
                   object:nil];
    
    // Backend downloaded (or failed to download) missing resources for emuticon.
    [nc addUniqueObserver:self
                 selector:@selector(onDownloadedResourcesForEmuticon:)
                     name:emkUIDownloadedResourcesForEmuticon
                   object:nil];
    

    // Need to choose another package
    [nc addUniqueObserver:self
                 selector:@selector(onShouldShowPackage:)
                     name:emkUIMainShouldShowPackage
                   object:nil];

}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkRenderingFinished];
    [nc removeObserver:emkUIDataRefreshPackages];
    [nc removeObserver:emkUIDownloadedResourcesForEmuticon];
    [nc removeObserver:emkUIMainShouldShowPackage];
}

#pragma mark - Observers handlers
-(void)onRenderingFinished:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    NSString *oid = info[@"emuticonOID"];
    NSString *packageOID = info[@"packageOID"];
    
    // Make sure this is related to the currently displayed package.
    if (![packageOID isEqualToString:self.selectedPackage.oid]) {
        // Ignore notifications about emus related to packages not on screen.
        return;
    }
    
    // Make sure indexpath is in the range of the fetched results controller.
    if (indexPath.item >= self.fetchedResultsController.fetchedObjects.count) {
        // Ignore of item out of range of the currently displayed data.
        return;
    }

    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // ignore notifications not relating to emus visible on screen.
    if (![[self.guiCollectionView indexPathsForVisibleItems] containsObject:indexPath]) return;
    if (![emu.oid isEqualToString:oid]) return;
    
    // The cell is on screen, refresh it.
    [self.guiCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
}


-(void)onPackagesDataRefresh:(NSNotification *)notification
{
    self.refetchDataAttempted = YES;
    [self.packagesBarVC refresh];

    // Update latest published package
    Package *latestPublishedPackage = [Package latestPublishedPackageInContext:EMDB.sh.context];
    if (latestPublishedPackage == nil) return;
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.latestPackagePublishedOn = latestPublishedPackage.firstPublishedOn;
    
    // Handle the flow
    [self handleFlow];
}

-(void)onDownloadedResourcesForEmuticon:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info == nil) return;
    
    NSIndexPath *indexPath = info[@"indexPath"];
    NSString *emuOID = info[@"emuticonOID"];

    if (indexPath.item >= self.fetchedResultsController.fetchedObjects.count) return;
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (emu == nil || ![emu.oid isEqualToString:emuOID]) return;
    
    [self.guiCollectionView reloadItemsAtIndexPaths:@[indexPath]];
}

-(void)onShouldShowPackage:(NSNotification *)notification
{
    NSString *packageOID = notification.userInfo[@"packageOID"];
    if (packageOID == nil) return;
    
    Package *package = [Package findWithID:packageOID context:EMDB.sh.context];
    if (package == nil) return;
    
    [self.packagesBarVC selectThisPackage:package];
}

#pragma mark - The data
-(NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    if (self.selectedPackage == nil) return nil;
    
    HMLOG(TAG, EM_DBG, @"Showing emuticons for package named:%@", self.selectedPackage.name);
    REMOTE_LOG(@"Showing emuticons for package: %@", self.selectedPackage.name);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPreview=%@ AND emuDef.package=%@", @NO, self.selectedPackage];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"emuDef.order" ascending:YES] ];
    fetchRequest.fetchBatchSize = 20;
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:EMDB.sh.context
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:@"Root"];
    _fetchedResultsController = frc;
    return frc;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
}

#pragma mark - Flow
-(void)handleFlow
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (!appCFG.onboardingPassed.boolValue) {
        if (!self.refetchDataAttempted) {
            return;
        }
        
        /**
         *  Open the recorder for the first time.
         */
        Package *package = [appCFG packageForOnboarding];
        if (package == nil) {
            NSString *errorMessage = @"Critical error - no package for onboarding selected";
            HMLOG(TAG, EM_ERR, @"%@", errorMessage);
            REMOTE_LOG(@"%@", errorMessage);
            [self initPackageForOnboarding];
            return;
        }
        [self openRecorderForFlow:EMRecorderFlowTypeOnboarding
                             info:@{emkPackage:package}];
        REMOTE_LOG(@"Opening recorder for the first time");

    } else {

        /**
         *  User finished onboarding in the past.
         *  just show the main screen of the app.
         */
        
        REMOTE_LOG(@"The main screen");
        
        // Refresh
        [self resetFetchedResultsController];
        [self.guiCollectionView reloadData];
        
        // Never viewed the kb tutorial?
        // It is time to show it.
        if (!appCFG.userViewedKBTutorial.boolValue) {
            [self showKBTutorial];
        }
    }
}


-(void)initPackageForOnboarding
{
    NSString *onboardingLocalFileName = AppManagement.sh.isTestApp? @"onboarding_package_test":@"onboarding_package_prod";
    NSString *path = [[NSBundle mainBundle] pathForResource:onboardingLocalFileName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error || json==nil) {
        [self epicFail:[error description]];
        return;
    }
    [EMBackend.sh parseOnboardingPackages:json];
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

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.fetchedResultsController.fetchedObjects.count;
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
    CGFloat size = (self.view.bounds.size.width-10.0) / 2.0;
    return CGSizeMake(size, size);
}



#pragma mark - Cell
-(void)configureCell:(EmuCell *)cell
        forIndexPath:(NSIndexPath *)indexPath
{
    Emuticon *emu = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if (emu == nil) return;
    
    NSDictionary *info = @{
                           @"indexPath":indexPath,
                           @"emuticonOID":emu.oid,
                           @"packageOID":emu.emuDef.package.oid
                           };
    
    cell.guiFailedImage.hidden = YES;
    cell.guiFailedLabel.hidden = YES;
    cell.animatedGifURL = nil;
    
    if (emu.wasRendered.boolValue) {
        
        //
        // Emu already rendered. Just display it.
        //
        [cell.guiActivity stopAnimating];
        cell.animatedGifURL = [emu animatedGifURL];
        
    } else if ([emu.emuDef allResourcesAvailable]) {
        
        //
        // Need to render and we have all required resources to do so.
        //
        [cell.guiActivity startAnimating];
        cell.animatedGifURL = nil;
        
        UserFootage *mostPrefferedFootage = [emu mostPrefferedUserFootage];
        if (mostPrefferedFootage != nil) {
            [EMRenderManager.sh renderingRequiredForEmu:emu info:info];
        } else {
            [self failedCell:cell];
        }
        
    } else if (self.triedToReloadResourcesForEmuOID[emu.oid] == nil) {

        //
        // Missing resources for this emu.
        //
        [cell.guiActivity startAnimating];
        cell.animatedGifURL = nil;
        
        // Download missing resources for emuticon
        self.triedToReloadResourcesForEmuOID[emu.oid] = @YES;
        [EMBackend.sh downloadResourcesForEmu:emu
                                         info:info];
        
    } else {
        
        //
        // Missing resources and failed downloading resources for this emu.
        //
        [self failedCell:cell];
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



#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [self.splashVC hideAnimated:YES];
        [HMPanel.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
    }];
    
    // Handle what to do next, depending on the flow of the dismissed recorder.
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (flowType == EMRecorderFlowTypeOnboarding && !appCFG.userViewedKBTutorial.boolValue) {
        [self showKBTutorial];
    } else {
        [self handleFlow];
    }
}

-(void)showKBTutorial
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (self.kbTutorialVC == nil || appCFG.userViewedKBTutorial.boolValue) return;
    appCFG.userViewedKBTutorial = @YES;
    [EMDB.sh save];
    
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
    UIAlertController *alert = [UIAlertController new];
    alert.title = LS(@"RETAKE_CHOICE_TITLE");
    alert.message = LS(@"RETAKE_CHOICE_MESSAGE");
    
    // Retake them all!
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"RETAKE_CHOICE_ALL")
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                                // Analytics
                                                HMParams *params = [HMParams new];
                                                [params addKey:AK_EP_RETAKE_OPTION valueIfNotNil:@"all"];
                                                [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
                                                                         info:params.dictionary];
                                                
                                                // Retake
                                                [self retakeAll];
                                            }]];

    // Retake current package.
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"RETAKE_CHOICE_PACKAGE")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                // Analytics
                                                HMParams *params = [HMParams new];
                                                [params addKey:AK_EP_RETAKE_OPTION valueIfNotNil:@"package"];
                                                [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.selectedPackage.name];
                                                [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.selectedPackage.oid];
                                                [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
                                                                         info:params.dictionary];
                                                // Retake
                                                [self retakeCurrentPackage];
                                            }]];
    
    // Cancel
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"CANCEL")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                                // Analytics
                                                HMParams *params = [HMParams new];
                                                [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.selectedPackage.name];
                                                [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.selectedPackage.oid];
                                                [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_CANCELED
                                                                         info:params.dictionary];
                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}

-(void)retakeAll
{
    if (self.selectedPackage == nil)
        return;

    /**
     *  Open the recording for retaking all emuticons.
     */
    [self openRecorderForFlow:EMRecorderFlowTypeRetakeAll
                         info:@{emkPackage:self.selectedPackage}];
    REMOTE_LOG(@"Retake all selected. selected package: %@", self.selectedPackage.name);
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
        if (emu.prefferedFootageOID) {
            [emu cleanUp];
            emu.prefferedFootageOID = nil;
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
    UIAlertController *alert = [UIAlertController new];
    alert.title = LS(@"USER_CHOICE_TITLE");
    
    // Enable notifications
    UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (notificationSettings.types == UIUserNotificationTypeNone) {
        [alert addAction:[UIAlertAction actionWithTitle:LS(@"NOTIFICATIONS_ENABLE")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self openAppSettingsWithReason:@"enable notifications"];
                                                }]];
    }
    
    // Reset emuticons to use the same footage.
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"USER_CHOICE_RESET_PACK")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self resetPack];
                                            }]];
    
    // Debugging stuff
    if (AppManagement.sh.isTestApp) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Clean and render"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
                                                    [self debugCleanAndRender];
                                                }]];
    }
    
    // Cancel
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"CANCEL")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                                [HMPanel.sh analyticsEvent:AK_E_ITEMS_USER_NAV_SELECTION_CANCEL];
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
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
    
    [EMDB ensureDirPathExists:package.resourcesPath];
    
    // Make sure emuticons instances created for this package
    [package createMissingEmuticonObjects];
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (![appCFG isPackageUsedForOnboarding:package]) {
        // Not an onboarding package.
        
        // Check if user was asked about auto updates/background fetches.
        // (tweak: counts the number of packages the user viewed and show question
        // after tweaked threshold reached)
        NSInteger numberOfViewedPackagesBeforeAlertsQuestion = HMPanelTweakValue(@"number of viewed packages before alerts question", 1);
        NSInteger numberOfViewedPackages = [Package countNumberOfViewedPackagesInContext:EMDB.sh.context];
        if (!appCFG.userAskedInMainScreenAboutAlerts.boolValue) {
            // Never asked.
            // Ask the user if interested in background fetches / auto updates.
            if (numberOfViewedPackages > numberOfViewedPackagesBeforeAlertsQuestion)
                [self askUserAboutAlerts];
        }
        
        // If package never viewed before by the user, count the event.
        if (!package.viewedByUser.boolValue) {
            [HMPanel.sh reportCountedSuperParameterForKey:AK_S_NUMBER_OF_PACKAGES_NAVIGATED];
            [HMPanel.sh reportSuperParameterKey:AK_S_DID_EVER_NAVIGATE_TO_ANOTHER_PACKAGE value:@YES];
        }
    }
    
    // Mark package as viewed.
    package.viewedByUser = @YES;
    [EMDB.sh save];
    
    // Reload if selected another package.
    if ([self.selectedPackage.oid isEqualToString:package.oid]) {
        [self.guiCollectionView reloadData];
        return;
    }
    
    BOOL shouldAnimate = self.selectedPackage != nil;
    self.selectedPackage = package;
    [self resetFetchedResultsController];

    // Tell manager to prioritize current selected package.
    EMRenderManager.sh.prioritizedPackageOID = package.oid;
    
    if (shouldAnimate) {
        __weak EMMainVC *weakSelf = self;

        self.guiTagLabel.text = [package tagLabel];
        self.guiTagLabel.alpha = 1.0;
        self.guiTagLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
        [UIView animateWithDuration:0.7 animations:^{
            weakSelf.guiTagLabel.alpha = 0;
            weakSelf.guiTagLabel.transform = CGAffineTransformIdentity;
        }];

        
        [UIView animateWithDuration:0.15 animations:^{
            weakSelf.guiCollectionView.alpha = 0;
            weakSelf.guiCollectionView.transform = CGAffineTransformMakeScale(0.90, 0.90);
        } completion:^(BOOL finished) {
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
        }];
    } else {
        [self.guiCollectionView reloadData];
    }
    
    REMOTE_LOG(@"Did select package: %@", self.selectedPackage.name);
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
            [self.guiTutorialContainer removeFromSuperview];
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

- (IBAction)onSwipedLeftCollectionView:(id)sender
{
    HMLOG(TAG, EM_DBG, @"Swipe left");
    [UIView animateWithDuration:0.15 animations:^{
        if ([self.packagesBarVC canSelectNext]) self.guiCollectionView.alpha = 0;
        self.guiCollectionView.transform = CGAffineTransformMakeTranslation(-40, 0);
    } completion:^(BOOL finished) {
        if (![self.packagesBarVC canSelectNext]) {
            [UIView animateWithDuration:0.3 animations:^{
                self.guiCollectionView.transform = CGAffineTransformIdentity;
            }];
        } else {
            [self.packagesBarVC selectNext];
        }
    }];
}

- (IBAction)onSwipedRightCollectionView:(id)sender
{
    HMLOG(TAG, EM_DBG, @"Swipe right");
    [UIView animateWithDuration:0.15 animations:^{
        if ([self.packagesBarVC canSelectPrevious]) self.guiCollectionView.alpha = 0;
        self.guiCollectionView.transform = CGAffineTransformMakeTranslation(40, 0);
    } completion:^(BOOL finished) {
        if (![self.packagesBarVC canSelectPrevious]) {
            [UIView animateWithDuration:0.3 animations:^{
                self.guiCollectionView.transform = CGAffineTransformIdentity;
            }];
        } else {
            [self.packagesBarVC selectPrevious];
        }
    }];
}


@end
