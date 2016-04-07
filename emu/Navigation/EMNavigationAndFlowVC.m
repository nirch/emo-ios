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

#define TAG @"EMMainNavigationVC"

#import "EMNavigationAndFlowVC.h"
#import "EMTabsBarVC.h"
#import "EMUINotifications.h"
#import "EMSplashVC.h"
#import "EMNotificationCenter.h"
#import "EMDB.h"
#import "EMTutorialVC.h"
#import <PINRemoteImage/PINRemoteImageManager.h>
#import "EMBlockingProgressVC.h"
#import <UIView+Toast.h>
#import "emu-Swift.h"

@interface EMNavigationAndFlowVC () <
    EMRecorderDelegate,
    EMInterfaceDelegate
>

// IB Outlets
@property (weak, nonatomic) IBOutlet UIView *guiTabsBar;
@property (weak, nonatomic) IBOutlet UIView *guiTutorialContainer;

// Child VC
@property (nonatomic, weak) EMTabsBarVC *tabsBarVC;
@property (weak, nonatomic) EMSplashVC *splashVC;

// State
@property (nonatomic) BOOL alreadyAttemptedDataRefetch;

// Keyboard tutorial (should be deprecated after new onboarding implementation)
@property (weak, nonatomic) EMTutorialVC *kbTutorialVC;

// Blocking progress VC
@property (weak, nonatomic, readonly) EMBlockingProgressVC *blockingProgressVC;

@end

@implementation EMNavigationAndFlowVC

@synthesize blockingProgressVC = _blockingProgressVC;

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
    self.view.backgroundColor = [EmuStyle colorThemeFeatured];
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
    
    // Joint emu take slot
    [nc addUniqueObserver:self
                 selector:@selector(onJointEmuInviteTakeSlot:)
                     name:emkJointEmuInviteTakeSlot
                   object:nil];

    [nc addUniqueObserver:self
                 selector:@selector(onJointEmuNavigateToInviteCode:)
                     name:emkJointEmuNavigateToInviteCode
                   object:nil];

    [nc addUniqueObserver:self
                 selector:@selector(onNavigateToEmu:)
                     name:emkNavigateToEmuOID
                   object:nil];
    
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
    
    // Should show the tabs bar
    [nc addUniqueObserver:self
                 selector:@selector(onTabSelected:)
                     name:emkUINavigationTabSelected
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
    
    // On blocking progress modal view need to be shown
    [nc addUniqueObserver:self
                 selector:@selector(onNeedToShowBlockingProgress:)
                     name:emkUINavigationShowBlockingProgress
                   object:nil];
    
    // On blocking progress modal view need to update progrees
    [nc addUniqueObserver:self
                 selector:@selector(onBlockingProgressUpdate:)
                     name:emkUINavigationUpdateBlockingProgress
                   object:nil];
    

}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkUIDataRefreshPackages];
    [nc removeObserver:emkJointEmuNavigateToInviteCode];
    [nc removeObserver:emkNavigateToEmuOID];
    [nc removeObserver:emkUIDataRefreshPackages];
    [nc removeObserver:emkUIShouldHideTabsBar];
    [nc removeObserver:emkUIShouldShowTabsBar];
    [nc removeObserver:emkUINavigationTabSelected];
    [nc removeObserver:emkUIUserRequestToOpenRecorder];
    [nc removeObserver:emkUIUserSelectedPack];
    [nc removeObserver:emkDataUpdatedUnhidePackages];
    [nc removeObserver:emkUINavigationShowBlockingProgress];
    [nc removeObserver:emkUINavigationUpdateBlockingProgress];
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

-(void)onTabSelected:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    UIColor *themeColor = info[@"themeColor"];
    if (themeColor) {
        self.view.backgroundColor = themeColor;
    }
}

-(void)onJointEmuInviteTakeSlot:(NSNotification *)notification
{
    if (notification.isReportingError) {
        [self.blockingProgressVC hideAnimated:YES];
        NSError *error = notification.reportedError;
        if ([error.domain isEqualToString:NSURLErrorDomain]) {
            [self.view makeToast:LS(@"ALERT_CHECK_INTERNET_MESSAGE")];
        } else {
            [self.view makeToast:LS(@"JOINT_EMU_ERROR_SLOT_ALREADY_TAKEN")];
        }
        return;
    }
    
    // Invitation success. Will navigate to the new emu.
    NSDictionary *info = notification.userInfo;
    NSString *invitationCode = info[emkJEmuInviteCode];
    [self navigateToContentRelatedToInvitationCode:invitationCode];
}

-(void)onJointEmuNavigateToInviteCode:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *invitationCode = info[emkJEmuInviteCode];
    [self navigateToContentRelatedToInvitationCode:invitationCode];
}

-(void)onNavigateToEmu:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *emuOID = info[emkEmuticonOID];
    [self navigateToContentRelatedToToEmuOID:emuOID];
}

-(void)onPackagesDataRefresh:(NSNotification *)notification
{
    // Mark that attempted a refetch.
    self.alreadyAttemptedDataRefetch = YES;
    
    // If need to navigate to a package, navigate to it (if possible).
    if (notification.isReportingError) {
        if (self.blockingProgressVC) [self.blockingProgressVC done];
    } else {
        NSDictionary *info = notification.userInfo;
        if (info[emkPackageOID] != nil && [info[@"autoNavigateToPack"] boolValue]) {
            [self navigateIfPossibleToContentWithInfo:info];
        }
    }
    
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

-(void)onNeedToShowBlockingProgress:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    [self showBlockingProgressVC];
    NSString *title = info[@"title"];
    [self.blockingProgressVC updateTitle:title];
}

-(void)onBlockingProgressUpdate:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *title = info[@"title"];
    if ([title isKindOfClass:[NSString class]]) {
        [self.blockingProgressVC updateTitle:title];
    }
    
    NSNumber *progressNumber = info[@"progress"];
    if ([progressNumber isKindOfClass:[NSNumber class]]) {
        CGFloat progress = [progressNumber floatValue];
        [self.blockingProgressVC updateProgress:progress animated:YES];
    }
}



#pragma mark - Orientations
-(BOOL)shouldAutorotate
{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
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
    
    // Update the flow state
    [self updateFlowState:EMNavFlowStateUserControlsNavigation];
}

-(void)_stateRecroderDismissalAfterNewTakeWithInfo:(NSDictionary *)info
{
    if ([info[emkRetakeForHDEmu] boolValue]) {
        // Retake was taken specifically for hd emu
        // Update the emu and mark that it should be rendered in HD.
        NSString *emuticonOID = info[emkEmuticonOID];
        Emuticon *emu = [Emuticon findWithID:emuticonOID context:EMDB.sh.context];
        if (emu != nil && [emu.emuDef.hdAvailable boolValue]) {
            emu.shouldRenderAsHDIfAvailable = @YES;
        }
    }
    
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

#pragma mark - Blocking progress VC
-(EMBlockingProgressVC *)blockingProgressVC
{
    // Put it on top of everything.
    if (_blockingProgressVC) return _blockingProgressVC;
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *rootVC = window.rootViewController;
    EMBlockingProgressVC *vc = [EMBlockingProgressVC blockingProgressVCInParentVC:rootVC];
    _blockingProgressVC = vc;
    return vc;
}

-(void)showBlockingProgressVC
{
    [self.splashVC hideAnimated:NO];
    if (_blockingProgressVC) [_blockingProgressVC done];
    _blockingProgressVC = nil;
    [self.blockingProgressVC showAnimated:YES];
}

#pragma mark - Automatic navigations to content
-(void)navigateToContentRelatedToInvitationCode:(NSString *)invitationCode
{
    Emuticon *emu = [Emuticon findWithInvitationCode:invitationCode context:EMDB.sh.context];
    if (invitationCode == nil || emu == nil) {
        // No invitation code? Something went wrong :-(
        [self.view makeToast:LS(@"ERROR_TITLE")];
        [self.blockingProgressVC hideAnimated:YES];
        return;
    }
    
    // Emu gains focus.
    [emu gainFocus];
    [EMDB.sh save];
    
    // We have the invitation code and related emu. Navigate to that emu if possible.
    HMParams *params = [HMParams new];
    [params addKey:emkEmuticonOID valueIfNotNil:emu.oid];
    [params addKey:emkEmuticonDefOID valueIfNotNil:emu.emuDef.oid];
    [params addKey:emkPackageOID valueIfNotNil:emu.emuDef.package.oid];
    dispatch_after(DTIME(1), dispatch_get_main_queue(), ^{
        [self navigateIfPossibleToContentWithInfo:params.dictionary];
    });
}

-(void)navigateToContentRelatedToToEmuOID:(NSString *)emuOID
{
    Emuticon *emu = [Emuticon findWithID:emuOID context:EMDB.sh.context];
    if (emu == nil) {
        // No invitation code? Something went wrong :-(
        [self.view makeToast:LS(@"ERROR_TITLE")];
        [self.blockingProgressVC hideAnimated:YES];
        return;
    }
    
    // Emu gains focus.
    [emu gainFocus];
    [EMDB.sh save];
    
    // We have the invitation code and related emu. Navigate to that emu if possible.
    HMParams *params = [HMParams new];
    [params addKey:emkEmuticonOID valueIfNotNil:emu.oid];
    [params addKey:emkEmuticonDefOID valueIfNotNil:emu.emuDef.oid];
    [params addKey:emkPackageOID valueIfNotNil:emu.emuDef.package.oid];
    dispatch_after(DTIME(1), dispatch_get_main_queue(), ^{
        [self navigateIfPossibleToContentWithInfo:params.dictionary];
    });
}


-(void)navigateIfPossibleToContentWithInfo:(NSDictionary *)info
{
    NSString *packOID = info[emkPackageOID];
    Package *package = [Package findWithID:packOID context:EMDB.sh.context];
    if (package == nil) {
        if (self.blockingProgressVC) {
            [self.blockingProgressVC done];
        }
        return;
    }
    
    [self.tabsBarVC navigateToTabAtIndex:EMTabNameFeed animated:NO info:info];
    
    dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
        if (self.blockingProgressVC) {
            [self.blockingProgressVC done];
        }
    });
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
    } else if ([segue.identifier isEqualToString:@"kb tutorial segue"]) {
        self.kbTutorialVC = segue.destinationViewController;
        self.kbTutorialVC.delegate = self;
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
    return NO;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Opening recorder
-(void)openRecorderWithConfigInfo:(NSDictionary *)info
{
    // Open the recorder and make this VC the delegate of the recorder.
    EMRecorderVC2 *recorderVC = [EMRecorderVC2 recorderVCWithConfigInfo:info];
    recorderVC.delegate = self;
    
    [self presentViewController:recorderVC animated:YES completion:^{
        [self.splashVC hideAnimated:NO];
    }];
}

#pragma mark - EMInterfaceDelegate
-(void)controlSentActionNamed:(NSString *)actionName info:(NSDictionary *)info
{
    if ([actionName isEqualToString:@"keyboard tutorial should be dismissed"]) {
        self.guiTutorialContainer.hidden = YES;
        [self.kbTutorialVC removeFromParentViewController];
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

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========


@end
