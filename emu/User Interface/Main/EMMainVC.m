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

//@property (weak, nonatomic) UIImageView *splashView;
@property (weak, nonatomic) EMSplashVC *splashVC;

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic)Package *selectedPackage;

@property (nonatomic) NSMutableDictionary *triedToReloadResourcesForEmuOID;

@property (nonatomic, weak) EMPackagesVC *packagesBarVC;

@property (nonatomic) BOOL refetchDataAttempted;

@end

@implementation EMMainVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refetchDataAttempted = NO;
    self.triedToReloadResourcesForEmuOID = [NSMutableDictionary new];
    
//    // enable slide-back
//    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
//        self.navigationController.interactivePopGestureRecognizer.delegate = self;
//    }
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

#pragma mark - Memory warnings
-(void)didReceiveMemoryWarning
{
    // Log remotely
    REMOTE_LOG(@"EMMainVC Memory warning");
    
    // Go boom on a test application.
    //[HMReporter.sh explodeOnTestApplicationsWithInfo:nil];
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
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkRenderingFinished];
    [nc removeObserver:emkUIDataRefreshPackages];
    [nc removeObserver:emkUIDownloadedResourcesForEmuticon];
}

#pragma mark - Observers handlers
-(void)onRenderingFinished:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    NSString *oid = info[@"emuticonOID"];
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // ignore notifications not relating to emus on screen
    if (![[self.guiCollectionView indexPathsForVisibleItems] containsObject:indexPath]) return;
    if (![emu.oid isEqualToString:oid]) return;
    
    // The cell is on screen, refresh it
    [self.guiCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
}


-(void)onPackagesDataRefresh:(NSNotification *)notification
{
    self.refetchDataAttempted = YES;
    [self.packagesBarVC refresh];
    [self handleFlow];
}

-(void)onDownloadedResourcesForEmuticon:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info == nil) return;
    
    NSIndexPath *indexPath = info[@"indexPath"];
    NSString *emuOID = info[@"emuticonOID"];

    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (emu == nil || ![emu.oid isEqualToString:emuOID]) return;
    
    [self.guiCollectionView reloadItemsAtIndexPaths:@[indexPath]];
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
            [self epicFail:errorMessage];
            return;
        }
        [self openRecorderForFlow:EMRecorderFlowTypeOnboarding
                             info:@{emkPackage:package}];
    } else {

        /**
         *  User finished onboarding in the past.
         *  just show the main screen of the app.
         */
        
        // If no package selected, choose first.
        if (self.selectedPackage == nil) {
            [self.packagesBarVC selectPackageAtIndex:0];
        }
        
        // Refresh
        [self resetFetchedResultsController];
        [self.guiCollectionView reloadData];
    }
}

-(void)epicFail:(NSString *)errorMessage
{
    UIAlertController *alert = [UIAlertController new];
    alert.title = @"Refreshing info";
    alert.message = @"Something went wrong.\nCheck your internet connectivity and try again.";
    [alert addAction:[UIAlertAction actionWithTitle:@"Try again"
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
        [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_SELECTED_ITEM info:params.dictionary];
        
    } else if ([segue.identifier isEqualToString:@"packages bar segue"]) {
        EMPackagesVC *vc = segue.destinationViewController;
        self.packagesBarVC = vc;
        vc.delegate = self;
    } else if ([segue.identifier isEqualToString:@"tutorial segue"]) {
        EMTutorialVC *vc = segue.destinationViewController;
        vc.delegate = self;
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
    Emuticon *emu = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSDictionary *info = @{
                           @"indexPath":indexPath,
                           @"emuticonOID":emu.oid
                           };
    
    cell.guiFailedImage.hidden = YES;
    cell.guiFailedLabel.hidden = YES;
    
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
        [EMRenderManager.sh enqueueEmu:emu
                                  info:info];
        
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
        [cell.guiActivity stopAnimating];
        cell.animatedGifURL = nil;
        cell.guiFailedImage.hidden = NO;
        cell.guiFailedLabel.hidden = NO;
    }
    
    cell.guiLock.alpha = emu.prefferedFootageOID? 0.2 : 0.0;
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
            if (self.triedToReloadResourcesForEmuOID[emu.oid]) {
                [self.triedToReloadResourcesForEmuOID removeObjectForKey:emu.oid];
                [self.guiCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
                self.guiCollectionView.userInteractionEnabled = YES;
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
        [HMReporter.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
    }];
    
    // Handle what to do next, depending on the flow of the dismissed recorder.
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
    
//    if (flowType == EMRecorderFlowTypeOnboarding) {
//        [self showTutorial];
//    } else {
//        [self handleFlow];
//    }
    [self handleFlow];
}

-(void)showTutorial
{
    self.guiCollectionView.hidden = YES;
    self.guiPackagesSelectionContainer.hidden = YES;
    self.guiTutorialContainer.hidden = NO;
    self.guiTutorialContainer.alpha = 0;
    self.guiNavView.alpha = 0.3;
    self.guiNavView.userInteractionEnabled = NO;
    [UIView animateWithDuration:2.0 animations:^{
        self.guiTutorialContainer.alpha = 1;
    }];
}

-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [self.splashVC hideAnimated:YES];
        [HMReporter.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
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
                                                [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
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
                                                [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_OPTION
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
                                                [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_RETAKE_CANCELED
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
}

-(void)resetPack
{
    if (self.selectedPackage == nil) return;
    
    Package *package = self.selectedPackage;
    
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:package.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:package.oid];
    [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_NAV_SELECTION_RESET_PACK info:params.dictionary];

    // Reset
    NSArray *emus = [Emuticon allEmuticonsInPackage:package];
    for (Emuticon *emu in emus) {
        if (emu.prefferedFootageOID) {
            [emu cleanUp];
            emu.prefferedFootageOID = nil;
        }
    }
    [EMDB.sh save];

    // Reload (and resend some emus to rendering)
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
}

-(void)debugCleanAndRender
{
    for (Package *package in [Package allPackagesInContext:EMDB.sh.context]) {
        NSArray *emus = [Emuticon allEmuticonsInPackage:package];
        for (Emuticon *emu in emus) {
            [emu cleanUp];
        }
    }
    [self.guiCollectionView reloadData];
    [EMDB.sh save];
}

#pragma mark - More user choices
-(void)userChoices
{
    UIAlertController *alert = [UIAlertController new];
    alert.title = LS(@"USER_CHOICE_TITLE");
    
    // Reset emuticons to use the same footage.
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"USER_CHOICE_RESET_PACK")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self resetPack];
                                            }]];
    
    // Debugging stuff
    if (IS_TEST_APP) {
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
                                                [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_NAV_SELECTION_CANCEL];
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - About message
-(void)aboutMessage
{
    // TODO: Move this from here to somewhere else that can be used from other places in the app
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    UIAlertController *alert = [[UIAlertController alloc] init];
    
    alert.title = [SF:@"About Emu - V%@", build];
    
    alert.message = [SF:@"Emu is a fun free app for iOS, where in just seconds you can create your own personal video stickers we call Emus.\n\nEmu - because you are what you send. \n\n© Homage Technology Ltd. 2015"];

    [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - EMPackageSelectionDelegate
-(void)packageWasSelected:(Package *)package
{
    [EMDB ensureDirPathExists:package.resourcesPath];
    
    // Make sure emuticons instances created for this package
    [package createMissingEmuticonObjects];
    
    // Reload
    self.selectedPackage = package;
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
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
        [UIView animateWithDuration:0.3 animations:^{
            self.guiTutorialContainer.alpha = 0;
            self.guiCollectionView.alpha = 1;
            self.guiNavView.alpha = 1;
        } completion:^(BOOL finished) {
            self.guiTutorialContainer.hidden = YES;
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
    [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_PRESSED_RETAKE_BUTTON];
}

- (IBAction)onPressedNavButton:(id)sender
{
    [self userChoices];
    [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_PRESSED_NAV_BUTTON];
}

- (IBAction)onPressedEmuButton:(id)sender
{
    [self aboutMessage];
    [HMReporter.sh analyticsEvent:AK_E_ITEMS_USER_PRESSED_APP_BUTTON];
}

@end
