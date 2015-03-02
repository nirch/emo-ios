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
#import "EMBackend.h"
#import "EmuCell.h"
#import "EMEmuticonScreenVC.h"
#import "EMRenderManager.h"


@interface EMMainVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    EMRecorderDelegate,
    UIGestureRecognizerDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiNavView;

@property (weak, nonatomic) UIImageView *splashView;

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic)NSFetchedResultsController *resultsController;

@end

@implementation EMMainVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize the data
    // Currently just reads local json files.
    // TODO: implement integration with server side, when available.
    [self initData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];

    // Show the splash screen if needs to open the recorder
    // for the onboarding experience.
    if (!appCFG.onboardingPassed.boolValue) {
        [self showSplash];
    }
    
    // enable slide-back
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    // Init observers
    [self initObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (!appCFG.onboardingPassed.boolValue) {
        
        /**
         *  Open the recorder for the first time.
         */
        Package *package = [appCFG packageForOnboarding];
        if (package == nil) {
            NSString *errorMessage = @"Critical error - no package for onboarding selected";
            HMLOG(TAG, EM_ERR, @"%@", errorMessage);
            REMOTE_LOG(@"%@", errorMessage);
        }

        if (package) {
            [self openRecorderForFlow:EMRecorderFlowTypeOnboarding
                                 info:@{emkPackage:package}];
        }
        
    } else {
        
        /**
         *  User finished onboarding in the past.
         *  just show the main screen of the app.
         */
        [self resetFetchedResultsController];
        [self.guiCollectionView reloadData];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeObservers];
}

#pragma mark - Memory warnings
-(void)didReceiveMemoryWarning
{
    // Some info
    NSDictionary *info = @{
                           rkDescription:@"memory warning",
                           rkWhere:@"EMMainVC"
                           };
    
    // Log remotely
    REMOTE_LOG(@"EMMainVC Memory warning");
    
    // Analytics
    [HMReporter.sh analyticsEvent:akLowMemoryWarning info:info];
    
    // Go boom on a test application.
    [HMReporter.sh explodeOnTestApplicationsWithInfo:info];
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
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkRenderingFinished];
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

#pragma mark - The data
-(void)initData
{
    [EMBackend.sh refreshData];
    
    // Perform the fetch
    NSError *error;
    [[self fetchedResultsController] performFetch:&error];
    if (error) {
        HMLOG(TAG,
              EM_ERR,
              @"Unresolved error %@, %@",
              error,
              [error localizedDescription]);
    }
}

-(NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isPreview=%@", @NO];
    
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


#pragma mark - splash
-(void)showSplash
{
    UIImageView *splashView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.splashView = splashView;
    self.splashView.image = [UIImage imageNamed:@"splashImage"];
    self.splashView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.splashView];
}

-(void)hideSplashAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideSplashAnimated:NO];
        }];
        return;
    }
    self.splashView.alpha = 0;
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
    
    if (emu.wasRendered.boolValue) {
        [cell.guiActivity stopAnimating];
        cell.animatedGifURL = [emu animatedGifURL];
    } else {
        [cell.guiActivity startAnimating];
        cell.animatedGifURL = nil;
        [EMRenderManager.sh enqueueEmu:emu info:@{
                                                  @"indexPath":indexPath,
                                                  @"emuticonOID":emu.oid
                                                  }];
    }
    
    cell.guiLock.alpha = emu.prefferedFootageOID? 0.2 : 0.0;
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"emuticon screen segue" sender:indexPath];
}



#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [self hideSplashAnimated:YES];
    }];
    
    // Handle what to do next, depending on the flow of the dismissed recorder.
    [self resetFetchedResultsController];
    [self.guiCollectionView reloadData];
}

-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [self hideSplashAnimated:YES];
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
        [self hideSplashAnimated:NO];
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
                                                [self retakeAll];
                                            }]];

    // Retake current package.
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"RETAKE_CHOICE_PACKAGE")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self retakeCurrentPackage];
                                            }]];

//    // Reset emuticons to use the same footage.
//    [alert addAction:[UIAlertAction actionWithTitle:LS(@"RETAKE_CHOICE_RESET_PACK")
//                                              style:UIAlertActionStyleDefault
//                                            handler:^(UIAlertAction *action) {
//                                                [self resetPack];
//                                            }]];

    
    
    // Cancel
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"CANCEL")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

-(void)retakeAll
{
    /**
     *  Open the recording for retaking all emuticons.
     */
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    Package *package = [appCFG packageForOnboarding];
    [self openRecorderForFlow:EMRecorderFlowTypeRetakeAll
                         info:@{emkPackage:package}];

}

-(void)retakeCurrentPackage
{
    // TODO: finish implementation.
    
    /**
     *  Open the recording for retaking all emuticons.
     */
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    Package *package = [appCFG packageForOnboarding];
    [self openRecorderForFlow:EMRecorderFlowTypeRetakeAll
                         info:@{emkPackage:package}];
}

-(void)resetPack
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    Package *package = [appCFG packageForOnboarding];

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
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    Package *package = [appCFG packageForOnboarding];

    NSArray *emus = [Emuticon allEmuticonsInPackage:package];
    for (Emuticon *emu in emus) {
        [emu cleanUp];
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
    [alert addAction:[UIAlertAction actionWithTitle:@"Clean and render"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
                                                [self debugCleanAndRender];
                                            }]];
    
    // Cancel
    [alert addAction:[UIAlertAction actionWithTitle:LS(@"CANCEL")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - About message
-(void)aboutMessage
{
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    UIAlertController *alert = [[UIAlertController alloc] init];
    
    alert.title = [SF:@"About Emu - V%@", build];
    
    alert.message = [SF:@"Emu is a fun free keyboard app for iOS, where in just seconds you can create your own personal video stickers we call Emujis.\n\nEmu - because you are what you send. \n\n© Homage Technology Ltd. 2015"];

    [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRetakeButton:(id)sender
{
    [self askUserToChooseWhatToRetake];
}

- (IBAction)onPressedNavButton:(id)sender
{
    [self aboutMessage];
}

- (IBAction)onPressedEmuButton:(id)sender
{
    [self userChoices];
}

@end
