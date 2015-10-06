//
//  MainNavigationVC.m
//  emu
//
//  -----------------------------------------------------------------------
//  Responsibilities:
//      - The main VC of the application.
//      - Contains the main tabs vc of the whole app.
//      - Handles the flow of "First launch flow" / "After onboarding flow"
//      - Show/hides tabs bar as needed (based on app wide notifications)
//      - Opens and dimisses recorder when needed, according to flow state.
//  -----------------------------------------------------------------------
//
//  Created by Aviv Wolf on 9/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMNavigationAndFlowVC.h"
#import "EMTabsBarVC.h"
#import "EMUINotifications.h"
#import "EMSplashVC.h"
#import "EMNotificationCenter.h"
#import "EMDB.h"
#import "EMRecorderVC.h"

#define TAG @"EMMainNavigationVC"

@interface EMNavigationAndFlowVC ()

// IB Outlets
@property (weak, nonatomic) IBOutlet UIView *guiTabsBar;

// Child VC
@property (nonatomic, weak) EMTabsBarVC *tabsBarVC;
@property (weak, nonatomic) EMSplashVC *splashVC;

// State
@property (nonatomic) BOOL alreadyAttemptedDataRefetch;

@end

@implementation EMNavigationAndFlowVC

#pragma mark - VC lifecycle
/**
 *  On view did load:
 *      Initialize the flow state.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.splashVC showAnimated:NO];
    [self initFlowState];
}

/**
 *  On view appearance:
 *      - Initialize observers.
 */
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Init observers
    [self initObservers];
}

/**
 *  On view did appear:
 *      - handle the flow state.
 */
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self handleFlow];
}


/**
 *  On view will disappear:
 *      - Remove observers.
 *
 */
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove observers
    [self removeObservers];
}


#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // Should show the tabs bar
    [nc addUniqueObserver:self
                 selector:@selector(onPackagesDataRefresh:)
                     name:emkUIDataRefreshPackages
                   object:nil];

    // Should hide the tabs bar
    [nc addUniqueObserver:self
                 selector:@selector(onShouldHideTabs:)
                     name:emkUIShouldHideTabsBar
                   object:nil];
    
    // Should show the tabs bar
    [nc addUniqueObserver:self
                 selector:@selector(onShouldShowTabs:)
                     name:emkUIShouldShowTabsBar
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkUIDataRefreshPackages];
    [nc removeObserver:emkUIShouldHideTabsBar];
    [nc removeObserver:emkUIShouldShowTabsBar];
}

#pragma mark - Observers handlers
-(void)onShouldHideTabs:(NSNotification *)notification
{
    BOOL animated = [notification.userInfo[emkUIAnimated] isEqualToNumber:@YES];
    [self hideTabsBarAnimated:animated];
}

-(void)onShouldShowTabs:(NSNotification *)notification
{
    BOOL animated = [notification.userInfo[emkUIAnimated] isEqualToNumber:@YES];
    [self showTabsBarAnimated:animated];
}

-(void)onPackagesDataRefresh:(NSNotification *)notification
{
    // Mark that attempted a refetch.
    self.alreadyAttemptedDataRefetch = YES;
    
    // Handle the flow
    [self handleFlow];
}


#pragma mark - Flow & State
/**
 *  Initialize the state machine.
 *  Starts from the splash screen shown state.
 */
-(void)initFlowState
{
    self.alreadyAttemptedDataRefetch = NO;
    [self updateFlowState:EMNavFlowStateSplashScreen];
}

/**
 *  Update the flowState property.
 *  Don't update this property in any other way.
 *
 *  @param flowState The new flow state to change to.
 */
-(void)updateFlowState:(EMNavFlowState)flowState
{
    _flowState = flowState;
}

/**
 *  Handle the flow (no info provided).
 */
-(void)handleFlow
{
    [self handleFlowWithInfo:nil];
}

/**
 *  Handle current state (calls a state handler related to current state).
 *
 *  @param info NSDictionary with extra info about the state to handle..
 */
-(void)handleFlowWithInfo:(NSDictionary *)info
{
    if (self.flowState == EMNavFlowStateSplashScreen) {
        /**
         *  The splash screen is still shown.
         */
        [self _stateSplashScreen];
    } else if (self.flowState == EMNavFlowStateUserControlsNavigation) {
        /**
         *  User is in control of the app's navigation flow.
         *  no need to do anything.
         */
    } else if (self.flowState == EMNavFlowStateOpenRecorderForOnBoarding) {
        /**
         *  Open the recorder for the first time
         */
        [self _stateOpenRecorderForOnboarding];
    } else if (self.flowState == EMNavFlowStateOpenRecorderForNewTake) {
        /**
         *  Open the recorder for a new take (with some info about what the new take is for).
         */
        [self _stateOpenRecorderForNewTakeWithInfo:info];
    } else {
        // This shouldn't happen!
        // If it does, it is a bug in the state machine of this VC.
        REMOTE_LOG(@"EMMainNavigationVC on wrong flow state %@", @(self.flowState));
        [HMPanel.sh explodeOnTestApplicationsWithInfo:@{
                                                        @"flowState":@(self.flowState)
                                                        }];
    }
}

#pragma mark - State flow handlers
/**
 *  The splash screen is currently shown on the screen.
 *
 *  possibilities of what to do next:
 *
 *      - If the app was just launched and still didn't attempt to fetch 
 *        update from server. Do nothing for now (stay on splash screen). 
 *        Only after such an attempt succeeds/fails will return here again.
 *        EMNavFlowStateSplashScreen ==> EMNavFlowStateSplashScreen
 *
 *      - Dismiss the splash screen and check if need to show onboarding 
 *        for the first time or pass the navigation control to the user.
 *        EMNavFlowStateSplashScreen ==> EMNavFlowStateOpenRecorderForOnBoarding
 *        or
 *        EMNavFlowStateSplashScreen ==> EMNavFlowStateUserControlsNavigation
 */
-(void)_stateSplashScreen
{
    if (!self.alreadyAttemptedDataRefetch) return;
    
    // Check if need open recorder for onboarding or just let the user control navigation.
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (!appCFG.onboardingPassed.boolValue) {
        REMOTE_LOG(@"Need to open recorder for onboarding.");
        [self updateFlowState:EMNavFlowStateOpenRecorderForOnBoarding];
    } else {
        REMOTE_LOG(@"Already seen onboarding. Need to give user navigation control.");
        [self updateFlowState:EMNavFlowStateUserControlsNavigation];
        [self.splashVC hideAnimated:YES];
    }
}

-(void)_stateOpenRecorderForOnboarding
{
    /**
     *  Open the recorder for the first time.
     */
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    
    // Get preffered emus
    NSArray *prefferedEmus = [HMPanel.sh listForKey:VK_ONBOARDING_EMUS_FOR_PREVIEW_LIST fallbackValue:nil];
    EmuticonDef *emuticonDefForOnboarding = [appCFG emuticonDefForOnboardingWithPrefferedEmus:prefferedEmus];
    if (emuticonDefForOnboarding == nil) REMOTE_LOG(@"CRITICAL ERROR: couldn't use onboarding data bundled on device!");
    REMOTE_LOG(@"Opening recorder for the first time");
    REMOTE_LOG(@"Using emuticon named:%@ for onboarding.", emuticonDefForOnboarding.name);
    [self openRecorderForFlow:EMRecorderFlowTypeOnboarding
                         info:@{
                                emkEmuticonDefOID:emuticonDefForOnboarding.oid,
                                emkEmuticonDefName:emuticonDefForOnboarding.name
                                }];
}

-(void)_stateOpenRecorderForNewTakeWithInfo:(NSDictionary *)info
{
    
}

//    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
//    if (!appCFG.onboardingPassed.boolValue) {
//        // Try to fetch data from server at least once, before starting onboarding.
//        if (!self.refetchDataAttempted) return;
//
//        /**
//         *  Open the recorder for the first time.
//         */
//        NSArray *prefferedEmus = [HMPanel.sh listForKey:VK_ONBOARDING_EMUS_FOR_PREVIEW_LIST
//                                          fallbackValue:nil];
//        EmuticonDef *emuticonDefForOnboarding = [appCFG emuticonDefForOnboardingWithPrefferedEmus:prefferedEmus];
//
//
//        if (emuticonDefForOnboarding == nil) {
//            REMOTE_LOG(@"CRITICAL ERROR: couldn't use onboarding data bundled on device!");
//        }
//        REMOTE_LOG(@"Opening recorder for the first time");
//        REMOTE_LOG(@"Using emuticon named:%@ for onboarding.", emuticonDefForOnboarding.name);
//        [self openRecorderForFlow:EMRecorderFlowTypeOnboarding
//                             info:@{
//                                    emkEmuticonDefOID:emuticonDefForOnboarding.oid,
//                                    emkEmuticonDefName:emuticonDefForOnboarding.name
//                                    }];
//
//    } else {
//
//        /**
//         *  User finished onboarding in the past.
//         *  just show the main screen of the app.
//         */
//
//        REMOTE_LOG(@"The main screen");
//
//        // Refresh on first appearance
//        [self resetFetchedResultsController];
//        [self.guiCollectionView reloadData];
//
//        // Never viewed the kb tutorial?
//        // It is time to show it.
//        if (!appCFG.userViewedKBTutorial.boolValue) {
//            [self showKBTutorial];
//        }
//    }
//}

#pragma mark - splash
/**
 *  Lazy loading of the splash screen view controller.
 *
 *  @return An existing or just loaded Spash screen view controller.
 */
-(EMSplashVC *)splashVC
{
    if (_splashVC) return _splashVC;
    _splashVC = [EMSplashVC splashVCInParentVC:self];
    return _splashVC;
}

#pragma mark - Segues
/**
 * Get weak references to embedded view controllers:
 *  - tabs bar view controller
 *
 *
 */
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"tabs bar segue"]) {
        self.tabsBarVC = segue.destinationViewController;
    }
}


#pragma mark - Tabs bar
-(void)showTabsBarAnimated:(BOOL)animated
{
    if (animated) {
        self.guiTabsBar.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.guiTabsBar.transform = CGAffineTransformIdentity;
        }];
    } else {
        self.view.hidden = NO;
        self.guiTabsBar.transform = CGAffineTransformIdentity;
    }
}

-(void)hideTabsBarAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.guiTabsBar.transform = CGAffineTransformMakeTranslation(0, self.guiTabsBar.bounds.size.height);
        } completion:^(BOOL finished) {
            self.guiTabsBar.hidden = YES;
        }];
    } else {
        self.guiTabsBar.hidden = YES;
    }
}


#pragma mark - Status bar
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Opening recorder
-(void)openRecorderForFlow:(EMRecorderFlowType)flowType
                      info:(NSDictionary *)info
{
    // Notify that the recorder is about to be opened.
    // Let the backend decide what to do with that info.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkAppDidBecomeActive object:self userInfo:nil];

    // Open the recorder and make this VC the delegate of the recorder.
    EMRecorderVC *recorderVC = [EMRecorderVC recorderVCForFlow:flowType info:info];
    recorderVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    recorderVC.delegate = self;
    [self presentViewController:recorderVC animated:YES completion:^{
        [self.splashVC hideAnimated:NO];
    }];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========


@end
