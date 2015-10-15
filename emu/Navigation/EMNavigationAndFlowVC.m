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
//      - Shows kb tutorial after onboarding (should be deprecated after new onboarding implementation)
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
#import "EMTutorialVC.h"
#import <PINRemoteImage/PINRemoteImageManager.h>
#define TAG @"EMMainNavigationVC"

@interface EMNavigationAndFlowVC () <
    EMRecorderDelegate,
    EMInterfaceDelegate
>

// IB Outlets
@property (weak, nonatomic) IBOutlet UIView *guiTabsBar;

// Child VC
@property (nonatomic, weak) EMTabsBarVC *tabsBarVC;
@property (weak, nonatomic) EMSplashVC *splashVC;

// State
@property (nonatomic) BOOL alreadyAttemptedDataRefetch;

// Keyboard tutorial (should be deprecated after new onboarding implementation)
@property (weak, nonatomic) EMTutorialVC *kbTutorialVC;

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
    
    // -----------------------------------------------------------
    // Hack for now until implementing RTL navigation correctly
    // Force LTR navigation on iOS9+
    //
    if(([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) && [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]){
        [[UIView appearance] setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];}
    // -----------------------------------------------------------
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
    
    // Packages data refresh
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
    
    // A request from the user's UI to open recorder
    // This will be ignored if the current state is not "user in control"
    [nc addUniqueObserver:self
                 selector:@selector(onRequestToOpenRecorder:)
                     name:emkUIUserRequestToOpenRecorder
                   object:nil];
    
    // On user selected pack
    [nc addUniqueObserver:self
                 selector:@selector(onUserSelectedPack:)
                     name:emkUIUserSelectedPack
                   object:nil];

    // On update about unhiding packs (success or failure)
    [nc addUniqueObserver:self
                 selector:@selector(onHidingPackagesUpdate:)
                     name:emkDataUpdatedUnhidePackages
                   object:nil];

}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkUIDataRefreshPackages];
    [nc removeObserver:emkUIShouldHideTabsBar];
    [nc removeObserver:emkUIShouldShowTabsBar];
    [nc removeObserver:emkUIUserRequestToOpenRecorder];
    [nc removeObserver:emkUIUserSelectedPack];
}

#pragma mark - Observers handlers
/**
 *  A notification was posted indicating that the tabs bar should be hidden.
 *  hides the tabs bar.
 *
 *  @param notification the posted NSNotification
 */
-(void)onShouldHideTabs:(NSNotification *)notification
{
    BOOL animated = [notification.userInfo[emkUIAnimated] isEqualToNumber:@YES];
    [self hideTabsBarAnimated:animated];
}

/**
 *  A notification was posted indicating that the tabs bar should be shown.
 *  show the tabs bar.
 *
 *  @param notification the posted NSNotification
 */
-(void)onShouldShowTabs:(NSNotification *)notification
{
    BOOL animated = [notification.userInfo[emkUIAnimated] isEqualToNumber:@YES];
    [self showTabsBarAnimated:animated];
}

/**
 *  A notification was 
 *
 *  @param notification <#notification description#>
 */
-(void)onPackagesDataRefresh:(NSNotification *)notification
{
    // Mark that attempted a refetch.
    self.alreadyAttemptedDataRefetch = YES;
    
    // Handle the flow
    [self handleFlow];
}


-(void)onRequestToOpenRecorder:(NSNotification *)notification
{
    // User interaction with the UI resulted in a request to open
    // the recorder. Will be ignored if the user is not currently in control
    // of the application flow.
    if (self.flowState != EMNavFlowStateUserControlsNavigation) return;
    
    // Update state and handle the opening of the recorder flow.
    [self updateFlowState:EMNavFlowStateOpenRecorderForNewTake];
    [self handleFlowWithInfo:notification.userInfo];
}

-(void)onUserSelectedPack:(NSNotification *)notification
{
    if ([self.tabsBarVC currentTabIndex] != EMTabNameFeed) {
        // If user selects a pack,
        // will navigte to the feed and show that pack.
        [self.tabsBarVC navigateToTabAtIndex:EMTabNameFeed animated:YES info:notification.userInfo];
    }
}

-(void)onHidingPackagesUpdate:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info[@"message"]) {
        [self showUnhideMessageToUserWithInfo:info];
    }
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
 *  States:
 *      - SPLASH SCREEN
 *      - USER IN CONTROL
 *      - OPEN RECORDER ONBOARDING
 *      - OPEN RECORDER NEW TAKE
 *      - RECORDER DISMISSAL ONBOARDING
 *      - RECORDER DISMISSAL NEW TAKE
 *      -
 *      -
 *      -
 *      -
 *
 *
 *  @param info NSDictionary with extra info about the state to handle..
 */
-(void)handleFlowWithInfo:(NSDictionary *)info
{
    if (self.flowState == EMNavFlowStateSplashScreen) {
        /**
         *
         *  --- SPLASH SCREEN ---
         *
         *  The splash screen is still shown.
         */
        REMOTE_LOG(@"Flow state: Splash screen");
        [self _stateSplashScreen];
        
    } else if (self.flowState == EMNavFlowStateUserControlsNavigation) {
        /**
         *
         *  --- USER IN CONTROL ---
         *
         *  User is in control of the app's navigation flow.
         *  no need to do anything.
         */
        REMOTE_LOG(@"Flow state: User controls navigation");
        
    } else if (self.flowState == EMNavFlowStateOpenRecorderForOnBoarding) {
        /**
         *
         *  --- OPEN RECORDER ONBOARDING ---
         *
         *  Open the recorder for the first time
         */
        REMOTE_LOG(@"Flow state: Will open recorder for onboarding");
        [self _stateOpenRecorderForOnboarding];
        
    } else if (self.flowState == EMNavFlowStateOpenRecorderForNewTake) {
        /**
         *
         *  --- OPEN RECORDER NEW TAKE ---
         *
         *  Open the recorder for a new take (with some info about what the new take is for).
         */
        REMOTE_LOG(@"Flow state: Will open recorder for new take");
        [self _stateOpenRecorderForNewTakeWithInfo:info];

    } else if (self.flowState == EMNavFlowStateWaitForRecorderDismissalAfterOnboarding) {
        /**
         *
         *  --- RECORDER DISMISSAL ONBOARDING ---
         *
         *  Recorder dismissal after the recorder was opened for onboarding.
         */
        REMOTE_LOG(@"Flow state: Recorder dismissal after onboarding, will continue flow.");
        [self _stateRecroderDismissalAfterOnboardingWithInfo:info];

    } else if (self.flowState == EMNavFlowStateWaitForRecorderDismissalAfterNewTake) {
        /**
         *
         *  --- RECORDER DISMISSAL NEW TAKE ---
         *
         *  Recorder dismissal after the recorder was opened for new take.
         */
        REMOTE_LOG(@"Flow state: Recorder dismissal after new take, will continue flow.");
        [self _stateRecroderDismissalAfterNewTakeWithInfo:info];
        
    } else {
        // This shouldn't happen!
        // If it does, it is a bug in the state machine of this VC.
        REMOTE_LOG(@"EMMainNavigationVC on wrong flow state %@", @(self.flowState));
        [HMPanel.sh explodeOnTestApplicationsWithInfo:@{@"flowState":@(self.flowState)}];
        
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
    [self handleFlow];
}

/**
 *  Open the recorder for onboarding.
 *
 *  EMNavFlowStateOpenRecorderForOnBoarding ==> EMNavFlowStateWaitForRecorderDismissalAfterOnboarding
 */
-(void)_stateOpenRecorderForOnboarding
{
    /**
     *  Open the recorder for the first time.
     */
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    
    // Get preffered emus and open the recorder
    NSArray *prefferedEmus = [HMPanel.sh listForKey:VK_ONBOARDING_EMUS_FOR_PREVIEW_LIST fallbackValue:nil];
    EmuticonDef *emuticonDefForOnboarding = [appCFG emuticonDefForOnboardingWithPrefferedEmus:prefferedEmus];
    REMOTE_LOG(@"Opening recorder for the first time. Using emuticon named:%@ for onboarding.", emuticonDefForOnboarding.name);
    [self openRecorderWithConfigInfo:@{
                                       emkFirstTake:@YES,
                                       emkEmuticonDefOID:emuticonDefForOnboarding.oid,
                                       emkEmuticonDefName:emuticonDefForOnboarding.name
                                       }];

    // Update the flow state
    [self updateFlowState:EMNavFlowStateWaitForRecorderDismissalAfterOnboarding];
}

-(void)_stateOpenRecorderForNewTakeWithInfo:(NSDictionary *)info
{
    // Update the flow state
    [self openRecorderWithConfigInfo:info];
    
    // Update the flow state
    [self updateFlowState:EMNavFlowStateWaitForRecorderDismissalAfterNewTake];
}


/**
 *  Handle the flow after the finishing recorder onboarding.
 * 
 *  - Navigates to the main feed screen.
 *  - Currently will also display the keyboard tutorial (will be deprecated when app onboarding is implemented).
 *
 *  EMNavFlowStateWaitForRecorderDismissalAfterOnboarding ==> EMNavFlowStateUserControlsNavigation
 *
 *  @param info Info received from the recorder about recorder flow.
 */
-(void)_stateRecroderDismissalAfterOnboardingWithInfo:(NSDictionary *)info
{
    if (info == nil) return;

    // Navigate to the main feed.
    [self.tabsBarVC navigateToTabAtIndex:1 animated:NO];
    
    // Show KB tutorial
    [self showKBTutorial];
    
    // Update the flow state
    [self updateFlowState:EMNavFlowStateUserControlsNavigation];
}

-(void)_stateRecroderDismissalAfterNewTakeWithInfo:(NSDictionary *)info
{
    // Update the flow state
    [self updateFlowState:EMNavFlowStateUserControlsNavigation];
}

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

#pragma mark - KB Tutorial
-(void)showKBTutorial
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.userViewedKBTutorial = @YES;
    [EMDB.sh save];
    
    if (self.kbTutorialVC == nil) {
        EMTutorialVC *kbTutorialVC = [EMTutorialVC tutorialVCInParentVC:self];
        self.kbTutorialVC = kbTutorialVC;
        [self presentViewController:kbTutorialVC animated:YES completion:nil];
        [self.kbTutorialVC start];
    }
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
-(void)openRecorderWithConfigInfo:(NSDictionary *)info
{
    // Open the recorder and make this VC the delegate of the recorder.
    EMRecorderVC *recorderVC = [EMRecorderVC recorderVCWithConfigInfo:info];
    recorderVC.delegate = self;
    [self presentViewController:recorderVC animated:YES completion:nil];
}

#pragma mark - EMInterfaceDelegate
-(void)controlSentActionNamed:(NSString *)actionName info:(NSDictionary *)info
{
    if ([actionName isEqualToString:@"keyboard tutorial should be dismissed"]) {
        [self.splashVC hideAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            self.kbTutorialVC = nil;
        }];
    }
}

#pragma mark - Unhiding packs
-(void)showUnhideMessageToUserWithInfo:(NSDictionary *)info
{
    NSString *code = info[@"code"];
    NSString *message = info[@"message"];
    NSString *title = info[@"title"];
    if (message == nil || title == nil) return;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title
                                                                message:message
                                                         preferredStyle:UIAlertControllerStyleAlert];
    
    NSDictionary *packagesInfo = info[@"packagesInfo"];

    for (NSDictionary *packOID in packagesInfo.allKeys) {
        NSDictionary *packInfo = packagesInfo[packOID];
        [ac addAction:[UIAlertAction actionWithTitle:packInfo[@"label"]?packInfo[@"label"]:packInfo[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // Analytics
            HMParams *params = [HMParams new];
            [params addKey:AK_EP_CODE valueIfNotNil:code];
            [params addKey:AK_EP_USER_CHOICE valueIfNotNil:packInfo[@"name"]];
            [params addKey:AK_EP_LINK_TYPE valueIfNotNil:@"unhide packs"];
            [HMPanel.sh analyticsEvent:AK_E_DEEP_LINK_ALERT_USER_CHOICE info:params.dictionary];
            
            // Notify that a pack was selected.
            NSDictionary *info = @{emkPackageOID:packOID};
            [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserSelectedPack
                                                                object:self
                                                              userInfo:info];
        }]];
    }

    [ac addAction:[UIAlertAction actionWithTitle:LS(@"CANCEL") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // Analytics
        HMParams *params = [HMParams new];
        [params addKey:AK_EP_CODE valueIfNotNil:code];
        [params addKey:AK_EP_USER_CHOICE valueIfNotNil:@"cancel"];
        [params addKey:AK_EP_LINK_TYPE valueIfNotNil:@"unhide packs"];
        [HMPanel.sh analyticsEvent:AK_E_DEEP_LINK_ALERT_USER_CHOICE info:params.dictionary];
    }]];
    
    dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
        [self presentViewController:ac animated:NO completion:nil];
    });
}


#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [HMPanel.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
        
        if (flowType == EMRecorderFlowTypeOnboarding) {
            // Onboarding finished goals
            [self onboardingFinishedGoalsWithInfo:info];
        } else {
            [self retakeFinishedGoalWithInfo:info];
        }
    }];

    // Continue the flow
    [self handleFlowWithInfo:info];
}

-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:^{
        [HMPanel.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
    }];
    
    // Continue the flow
    [self handleFlowWithInfo:info];
}

#pragma mark - A/B testing goals
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

//-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
//{
//    // Dismiss the recorder
//    [self dismissViewControllerAnimated:YES completion:^{
//        [self.splashVC hideAnimated:YES];
//        [HMPanel.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
//        
//        if (flowType == EMRecorderFlowTypeOnboarding) {
//            // Onboarding finished goals
//            [self onboardingFinishedGoalsWithInfo:info];
//        } else {
//            [self retakeFinishedGoalWithInfo:info];
//        }
//    }];
//    
//    //    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
//    //    if (flowType == EMRecorderFlowTypeOnboarding && !appCFG.userViewedKBTutorial.boolValue) {
//    //        [self _handleChangeToMixScreen];
//    //        [self showKBTutorial];
//    //    } else {
//    //        [self handleFlow];
//    //    }
//}
//
//-(void)onboardingFinishedGoalsWithInfo:(NSDictionary *)info
//{
//    [HMPanel.sh experimentGoalEvent:GK_ONBOARDING_FINISHED];
//    NSNumber *latestBackgroundMark = info[AK_EP_LATEST_BACKGROUND_MARK];
//    if ([latestBackgroundMark isKindOfClass:[NSNumber class]] && latestBackgroundMark.integerValue == 1) {
//        [HMPanel.sh experimentGoalEvent:GK_ONBOARDING_FINISHED_WITH_GOOD_BACKGROUND];
//    }
//}
//
//
//-(void)retakeFinishedGoalWithInfo:(NSDictionary *)info
//{
//    [HMPanel.sh experimentGoalEvent:GK_RETAKE_NEW];
//    NSNumber *latestBackgroundMark = info[AK_EP_LATEST_BACKGROUND_MARK];
//    if ([latestBackgroundMark isKindOfClass:[NSNumber class]] && latestBackgroundMark.integerValue == 1) {
//        [HMPanel.sh experimentGoalEvent:GK_RETAKE_NEW_WITH_GOOD_BACKGROUND];
//    }
//}
//
//
//
//-(void)showKBTutorial
//{
//    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
//    //if (self.kbTutorialVC == nil || appCFG.userViewedKBTutorial.boolValue) return;
//    appCFG.userViewedKBTutorial = @YES;
//    [EMDB.sh save];
//    
//    if (self.kbTutorialVC == nil) {
//        self.kbTutorialVC = [EMTutorialVC tutorialVCInParentVC:self];
//        [self addChildViewController:self.kbTutorialVC];
//        [self.guiTutorialContainer addSubview:self.kbTutorialVC.view];
//        self.kbTutorialVC.view.frame = self.guiTutorialContainer.bounds;
//    }
//    
//    self.guiPackagesSelectionContainer.hidden = YES;
//    self.guiTutorialContainer.hidden = NO;
//    self.guiTutorialContainer.alpha = 0;
//    self.guiNavView.alpha = 0.3;
//    self.guiNavView.userInteractionEnabled = NO;
//    [UIView animateWithDuration:0.3 animations:^{
//        self.guiTutorialContainer.alpha = 1;
//    } completion:^(BOOL finished) {
//        [self.kbTutorialVC start];
//    }];
//    
//}
//
//-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
//{
//    // Dismiss the recorder
//    [self dismissViewControllerAnimated:YES completion:^{
//        [self.splashVC hideAnimated:YES];
//        [HMPanel.sh analyticsEvent:AK_E_REC_WAS_DISMISSED info:info];
//    }];
//    
//    [self resetFetchedResultsController];
//    [self.guiCollectionView reloadData];
//}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========


@end
