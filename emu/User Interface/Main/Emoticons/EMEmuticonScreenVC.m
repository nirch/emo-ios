//
//  EMEmuticonScreen.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
@import MediaPlayer;
@import AVFoundation;
#define TAG @"EMEmuticonScreen"

#import <Toast/UIView+Toast.h>
#import "EMEmuticonScreenVC.h"
#import "EMDB.h"
#import "EMAnimatedGifPlayer.h"
#import "EMShareVC.h"
#import "EMRecorderVC.h"
#import "EMUISound.h"
#import <JDFTooltips.h>
#import "EMRenderManager2.h"
#import "EMDownloadsManager2.h"
#import "EMHolySheet.h"
#import "EMActionsArray.h"
#import "AppDelegate.h"
#import "EMNotificationCenter.h"
#import "EMVideoSettingsPopover.h"
#import "EMProductPopover.h"
#import "EMUINotifications.h"
#import "EMFootagesVC.h"
#import "EMInterfaceDelegate.h"
#import "EMBackend+AppStore.h"
#import "EMFullScreenGifPlayer.h"


@interface EMEmuticonScreenVC () <
    EMShareDelegate,
    EMRecorderDelegate,
    MPMediaPickerControllerDelegate,
    EMInterfaceDelegate
>

#define AUDIO_DURATION 20.0f

@property (nonatomic) Emuticon *emuticon;

@property (nonatomic) BOOL guiInitialized;
@property (weak, nonatomic) IBOutlet UIView *guiNavView;

// Emu player
@property (weak, nonatomic) IBOutlet UIView *guiEmuContainer;
@property (weak, nonatomic) EMAnimatedGifPlayer *gifPlayerVC;
@property (weak, nonatomic) EMShareVC *shareVC;
@property (weak, nonatomic) IBOutlet UILabel *guiResolutionLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiFullScreenButton;

// Layout
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintPlayerLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintPlayerRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *guiConstraintPlayerTop;

@property (weak, nonatomic) IBOutlet UIButton *guiRetakeButton;
@property (weak, nonatomic) IBOutlet UIView *guiShareContainer;
@property (weak, nonatomic) IBOutlet UIView *guiShareMainIconPosition;

// Options bar buttons
@property (weak, nonatomic) IBOutlet UIButton *guiFavButton;
@property (weak, nonatomic) IBOutlet UIButton *guiHDToggleButton;
@property (weak, nonatomic) IBOutlet UIView *guiEmuOptionsBar;


// Tutorial
@property (strong, nonatomic) JDFSequentialTooltipManager *tooltipManager;

// Rendering type
@property (weak, nonatomic) IBOutlet UISegmentedControl *guiRenderingTypeSelector;

// Audio/Video
@property (weak, nonatomic) IBOutlet UIButton *guiAudioButton;
@property (weak, nonatomic) IBOutlet UIButton *guiVideoSettingsButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiAudioView;
@property (weak, nonatomic) IBOutlet UIButton *guiAudioOKButton;
@property (weak, nonatomic) IBOutlet UIButton *guiAudioRemoveButton;
@property (weak, nonatomic) IBOutlet UISlider *guiAudioTrimSlider;
@property (weak, nonatomic) UIView *audioPlayPositionView;
@property (nonatomic) BOOL showSelectedAudioUI;

@property (nonatomic) NSString *playIdentifier;
@property (nonatomic) AVPlayer *player;

@property (nonatomic) BOOL alreadyInitializedGUIOnAppearance;

// Footages screen
@property (weak, nonatomic) EMFootagesVC *footagesVC;

@end

@implementation EMEmuticonScreenVC

+(EMEmuticonScreenVC *)emuticonScreenForEmuticonOID:(NSString *)emuticonOID
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EMEmuticonScreenVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"emuticon vc"];
    vc.emuticonOID = emuticonOID;
    return vc;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    [self refreshEmu];
    [self initGUI];
    [self initLocalization];
    [self updateAudioSelectionUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Also post a notification that the tabs bar (if shown) should be hidden.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldHideTabsBar
                                                        object:self
                                                      userInfo:@{emkUIAnimated:@YES}];

    
    // Experiments
    [self initExperiments];
    
    // Only iPhone4s needs special treatment of the layout
    [self layoutFixesIfRequired];
    
    // Init observers
    [self initObservers];
    
    // The FMB experience
    [self updateFBMessengerExperienceState];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (!appCFG.userViewedEmuScreenTutorial.boolValue) {
        [self showEmuTutorial];
        appCFG.userViewedEmuScreenTutorial = @YES;
    }
    
    if (self.emuticon) {
        self.emuticon.lastTimeViewed = [NSDate date];
    }
    [EMDB.sh save];
    
    if (!self.alreadyInitializedGUIOnAppearance) {
        self.alreadyInitializedGUIOnAppearance = YES;
    } else {
        [self refreshEmu];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Finish up
    [self.audioPlayPositionView.layer removeAllAnimations];
    [self audioStop];
    
    // Remove observers
    [self removeObservers];
}

-(void)dealloc
{
    [self deleteUnrequiredHDContentAndResources];
    [self audioStop];
}


-(void)initGUI
{
    self.guiInitialized = NO;
    
    // Audtio trim slider
    [self.guiAudioTrimSlider setThumbImage:[UIImage imageNamed:@"audioTrimThumb"] forState:UIControlStateNormal];
    [self.guiAudioTrimSlider setThumbImage:[UIImage imageNamed:@"audioTrimThumb"] forState:UIControlStateHighlighted];

    // Theme color (if not set, default color is used)
    if (self.themeColor) self.guiNavView.backgroundColor = self.themeColor;
    
    [self updateEmuOptionsBar];
}

#pragma mark - GUI init
-(void)layoutGUI
{
    // Updates
    
    // Initializations on first GUI layout updates.
    if (!self.guiInitialized) {
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


-(void)initLocalization
{
    [self.guiRenderingTypeSelector setTitle:LS(@"ANIM_GIF") forSegmentAtIndex:0];
    [self.guiRenderingTypeSelector setTitle:LS(@"VIDEO") forSegmentAtIndex:1];
}

-(void)initData
{
    self.emuticon = [Emuticon findWithID:self.emuticonOID
                                 context:EMDB.sh.context];
}

-(void)showEmuOptionsBar
{
    self.guiEmuOptionsBar.userInteractionEnabled = YES;
    if (self.guiEmuOptionsBar.alpha < 1.0 || !CGAffineTransformIsIdentity(self.guiEmuOptionsBar.transform)) {
        [UIView animateWithDuration:0.2 animations:^{
            self.guiEmuOptionsBar.alpha = 1.0;
            self.guiEmuOptionsBar.transform = CGAffineTransformIdentity;
        }];
    }
}

-(void)hideEmuOptionsBar
{
    if (self.guiEmuOptionsBar.alpha > 0.2) {
        [UIView animateWithDuration:0.2 animations:^{
            self.guiEmuOptionsBar.alpha = 0.2;
            self.guiEmuOptionsBar.transform = CGAffineTransformMakeScale(0.95, 0.95);
        }];
    }
    self.guiEmuOptionsBar.userInteractionEnabled = NO;
}

-(void)refreshEmu
{
    Emuticon *emu = self.emuticon;
    if (emu == nil) return;

    // Resolution (showed only when the aspect ratio is not 1:1
    if ([emu.emuDef aspectRatio] != 1.0f) {
        self.guiResolutionLabel.hidden = NO;
        self.guiFullScreenButton.hidden = NO;
        self.guiResolutionLabel.text = [emu resolutionLabel];
    } else {
        self.guiResolutionLabel.hidden = YES;
        self.guiFullScreenButton.hidden = YES;
    }
    
    // Favorite YES/NO
    if (self.emuticon.isFavorite.boolValue) {
        [self.guiFavButton setImage:[UIImage imageNamed:@"favIconOn"] forState:UIControlStateNormal];
    } else {
        [self.guiFavButton setImage:[UIImage imageNamed:@"favIconOff"] forState:UIControlStateNormal];
    }
    
    // HD or not
    BOOL inHD = [self.emuticon shouldItRenderInHD];
    if ([self.emuticon boolWasRenderedInHD:inHD]) {
        // Was rendered.
        NSURL *url = [self.emuticon animatedGifURLInHD:inHD];
        self.gifPlayerVC.animatedGifURL = url;
        [self showEmuOptionsBar];
        return;
    } else {
        self.guiFullScreenButton.hidden = YES;
        [self hideEmuOptionsBar];
    }
    
    // Not rendered yet.
    BOOL allResourcesAvailableForRequiredResolution = [self.emuticon.emuDef allResourcesAvailableInHD:inHD];
    if (allResourcesAvailableForRequiredResolution) {
        // Send for rendering (with highest priority)
        [self.gifPlayerVC setAnimatedGifNamed:@"rendering"];
        EMRenderManager2 *rm = EMRenderManager2.sh;
        [rm updatePriorities:@{emu.oid:@YES}];
        [rm enqueueEmu:emu
             indexPath:[NSIndexPath indexPathForItem:0 inSection:0]
              userInfo:@{@"emuticonOID":emu.oid, @"inHD":@(inHD)}
                  inHD:inHD];
        return;
    }
    
    // Need to render but some resources are missing.
    // Download the required resources with high priority.
    [self.gifPlayerVC setAnimatedGifNamed:@"downloading"];
    EMDownloadsManager2 *dm = EMDownloadsManager2.sh;

    EmuticonDef *emuDef = emu.emuDef;
    [dm clear];
    [dm updatePriorities:@{emu.oid:@YES}];
    [dm enqueueResourcesForOID:emu.oid
                         names:[emuDef allMissingResourcesNamesInHD:inHD]
                          path:emuDef.package.name
                      userInfo:@{@"emuticonOID":emu.oid}];
    [dm manageQueue];
}

#pragma mark - Emu options bar
-(void)updateEmuOptionsBar
{
    // HD button (show only if HD available)
    BOOL hdAvailable = self.emuticon.emuDef.hdAvailable?self.emuticon.emuDef.hdAvailable.boolValue:NO;
    self.guiHDToggleButton.hidden = !hdAvailable;
    if (hdAvailable) {
        BOOL shouldRenderAsHD = self.emuticon.shouldRenderAsHDIfAvailable?self.emuticon.shouldRenderAsHDIfAvailable.boolValue:NO;
        if (shouldRenderAsHD) {
            [self.guiHDToggleButton setImage:[UIImage imageNamed:@"hdOptionOn"] forState:UIControlStateNormal];
        } else {
            [self.guiHDToggleButton setImage:[UIImage imageNamed:@"hdOptionOff"] forState:UIControlStateNormal];
        }
    }
    
    // Gif / Video
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    EMMediaDataType predderedRenderingType = appCFG.userPrefferedShareType.integerValue;
    self.guiRenderingTypeSelector.selectedSegmentIndex = predderedRenderingType==0?0:1;
    [self.shareVC update];
}

#pragma mark - Tutorial
-(void)showEmuTutorial
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (appCFG.userViewedEmuScreenTutorial.boolValue) return;

    JDFSequentialTooltipManager *tooltipManager = [[JDFSequentialTooltipManager alloc] initWithHostView:self.view];
    self.tooltipManager = tooltipManager;
    tooltipManager.showsBackdropView = YES;
    
    [tooltipManager addTooltipWithTargetView:self.guiRetakeButton hostView:self.view tooltipText:LS(@"TIP_EMU_SCREEN_RETAKE_BUTTON") arrowDirection:JDFTooltipViewArrowDirectionUp width:200.0f];
    [tooltipManager addTooltipWithTargetView:self.guiEmuContainer hostView:self.view tooltipText:LS(@"TIP_EMU_SCREEN_EMU_BUTTON") arrowDirection:JDFTooltipViewArrowDirectionUp width:200.0f];
    [tooltipManager addTooltipWithTargetView:self.guiShareMainIconPosition hostView:self.view tooltipText:LS(@"TIP_EMU_SCREEN_MESSAGE_BUTTON") arrowDirection:JDFTooltipViewArrowDirectionDown width:200.0f];

    [tooltipManager setBackgroundColourForAllTooltips:[EmuStyle colorKBKeyBG]];
    tooltipManager.backdropColour = [UIColor blackColor];
    tooltipManager.backdropAlpha = 0.3;
    tooltipManager.backdropTapActionEnabled = YES;
    [tooltipManager setFontForAllTooltips:[UIFont fontWithName:[EmuStyle.sh fontNameForStyle:@"regular"] size:16]];
    
    [tooltipManager showNextTooltip];
}



#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On rendering finished update
    [nc addUniqueObserver:self
                 selector:@selector(onRenderingFinished:)
                     name:hmkRenderingFinished
                   object:nil];
    
    // On download resources update
    [nc addUniqueObserver:self
                 selector:@selector(onResourceDownloadFinished:)
                     name:hmkDownloadResourceFinished
                   object:nil];
    
    
    // App did become active.
    [nc addUniqueObserver:self
                 selector:@selector(onAppDidBecomeActive:)
                     name:emkAppDidBecomeActive
                   object:nil];
    
    // Rendering progres.
    [nc addUniqueObserver:self
                 selector:@selector(onRenderingProgressReport:)
                     name:emkUIRenderProgressReport
                   object:nil];
    

    // Store transactions handled.
    [nc addUniqueObserver:self
                 selector:@selector(onHandledStoreTransactions:)
                     name:emkDataProductsHandledTransactions
                   object:nil];

    
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:hmkRenderingFinished];
    [nc removeObserver:emkAppDidBecomeActive];
    [nc removeObserver:emkUIRenderProgressReport];
}

#pragma mark - Observers handlers
-(void)onRenderingFinished:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *oid = info[@"emuticonOID"];
    
    // ignore notifications not relating to emus on screen
    if (![self.emuticon.oid isEqualToString:oid]) return;
    
    // Show the animated gif
    [self refreshEmu];
}

-(void)onResourceDownloadFinished:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *oid = info[@"emuticonOID"];
    
    // ignore notifications not relating to emus on screen
    if (![self.emuticon.oid isEqualToString:oid]) return;
    
    // Update and render.
    __weak EMEmuticonScreenVC *weakSelf = self;
    dispatch_after(DTIME(0.2), dispatch_get_main_queue(), ^{
        if ([weakSelf.emuticon.emuDef allResourcesAvailable])
            [weakSelf refreshEmu];
    });
}


-(void)onAppDidBecomeActive:(NSNotification *)notification
{
    [self updateFBMessengerExperienceState];
}

-(void)onHandledStoreTransactions:(NSNotification *)notification
{
    [self refreshEmu];
}

-(void)onRenderingProgressReport:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSNumber *progressNumber = info[@"progress"];
    if (progressNumber == nil) return;

    float progress = progressNumber.floatValue;
    [self.shareVC updateProgress:progress animated:NO];
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

#pragma mark - FB Messenger experience
-(void)updateFBMessengerExperienceState
{
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    BOOL inFBContext = app.fbContext != nil;
    self.shareVC.allowFBExperience = inFBContext;
}

#pragma mark - Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embed emu player"]) {
        
        self.gifPlayerVC = segue.destinationViewController;
        
    } else if ([segue.identifier isEqualToString:@"embed share"]) {
      
        self.shareVC = segue.destinationViewController;
        self.shareVC.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"full screen gif player segue"]) {
        
        BOOL inHD = [self.emuticon shouldItRenderInHD];
        NSURL *gifURL = [self.emuticon animatedGifURLInHD:inHD];
        EMFullScreenGifPlayer *vc = segue.destinationViewController;
        vc.gifURL = gifURL;
        
    }
}

#pragma mark - Layout
-(void)layoutFixesIfRequired
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    if (screenHeight > 480.0) return;
    
    // Fu@#$%ing iPhone 4s needs special treatment of the layout.
    self.constraintPlayerLeft.constant = 15;
    self.constraintPlayerRight.constant = -15;
    self.guiConstraintPlayerTop.constant = 15;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutGUI];
}


#pragma mark - VC prefferences
-(BOOL)prefersStatusBarHidden
{
    return YES;
}


#pragma mark - UICollectionViewDelegate

#pragma mark - EMShareDelegate
-(NSString *)shareObjectIdentifier
{
    return self.emuticonOID;
}


-(EMMediaDataType)sharerDataTypeToShare
{
    return [self renderingType];
}

#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Stop animating the gif
    [self.gifPlayerVC stopAnimating];
    [self.gifPlayerVC startActivity];
    
    // Will need to send the emuticon to rendering
    [EMRenderManager2.sh enqueueEmu:self.emuticon
                          indexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                           userInfo:@{@"emuticonOID":self.emuticon.oid}
                               inHD:NO];

    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    // Dismiss the recorder
    [self dismissViewControllerAnimated:YES completion:nil];

    // Recorder canceled. Nothing to do here.
}


#pragma mark - Retake
-(void)retake
{
    // Recorder should be opened to retake this specific emu.
    NSMutableDictionary *requestInfo = [NSMutableDictionary new];
    requestInfo[emkRetakeEmuticonsOID] = @[self.emuticonOID];
    
    // Notify main navigation controller that the recorder should be opened.
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserRequestToOpenRecorder
                                                        object:self
                                                      userInfo:requestInfo];
}

#pragma mark - Replace take
-(void)replaceTakeForEmu
{
    // Present the footages screen
    EMFootagesVC *footagesVC = [EMFootagesVC footagesVCForFlow:EMFootagesFlowTypeChooseFootage];
    footagesVC.delegate = self;
    footagesVC.selectedEmusOID = @[self.emuticonOID];
    self.footagesVC = footagesVC;
    [self presentViewController:footagesVC animated:YES completion:^{
    }];

}

-(void)controlSentActionNamed:(NSString *)actionName info:(NSDictionary *)info
{
    if ([actionName isEqualToString:emkUIFootageSelectionApply]) {
        NSString *footageOID = info[emkFootageOID];
        [self.emuticon cleanUp:YES andRemoveResources:NO];
        self.emuticon.prefferedFootageOID = footageOID;
        [EMDB.sh save];
        [self dismissViewControllerAnimated:YES completion:^{
            [self refreshEmu];
        }];
    } else if ([actionName isEqualToString:emkUIFootageSelectionCancel]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if ([actionName isEqualToString:emkUIPurchaseHDContent]) {
        [self purchaseHDContent];
    }
}

#pragma mark - Analytics
-(HMParams *)paramsForCurrentEmuticon
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_EMUTICON_NAME valueIfNotNil:self.emuticon.emuDef.name];
    [params addKey:AK_EP_EMUTICON_OID valueIfNotNil:self.emuticon.emuDef.oid];
    [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:self.emuticon.emuDef.package.name];
    [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:self.emuticon.emuDef.package.oid];
    return params;
}


#pragma mark - Emu options
-(void)showEmuOptions
{
    EMActionsArray *actionsMapping = [EMActionsArray new];
    
    //
    // Emu options
    //
    
    // ---------
    // Favorites
    // ---------
    
    // Toggle Add to favorites / Remove from favorites
    if (self.emuticon.isFavorite.boolValue) {
        [actionsMapping addAction:@"EMU_SCREEN_CHOICE_REMOVE_FROM_FAV" text:LS(@"REMOVE_FROM_FAVORITES") section:0];
    } else {
        [actionsMapping addAction:@"EMU_SCREEN_CHOICE_ADD_TO_FAV" text:LS(@"ADD_TO_FAVORITES") section:0];
    }
    EMHolySheetSection *section1 = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:[actionsMapping textsForSection:0] buttonStyle:JGActionSheetButtonStyleDefault];


    
    // ------------------------
    // Retakes / Replace takes
    // ------------------------
    
    // Always allow a new retake
    [actionsMapping addAction:@"EMU_SCREEN_CHOICE_RETAKE_EMU" text:LS(@"EMU_SCREEN_CHOICE_RETAKE_EMU") section:1];
    // If atleast two avaiable footages
    if ([UserFootage multipleAvailableInContext:EMDB.sh.context]) {
        [actionsMapping addAction:@"EMU_SCREEN_CHOICE_REPLACE_TAKE" text:LS(@"EMU_SCREEN_CHOICE_REPLACE_TAKE") section:1];
    }
    EMHolySheetSection *section2 = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:[actionsMapping textsForSection:1] buttonStyle:JGActionSheetButtonStyleDefault];
    
    //
    // Cancel
    //
    EMHolySheetSection *cancelSection = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:@[LS(@"CANCEL")] buttonStyle:JGActionSheetButtonStyleCancel];
    
    
    //
    // Sections
    //
    NSMutableArray *sections = [NSMutableArray arrayWithArray:@[section1, section2, cancelSection]];
    
    //
    // Holy sheet
    //
    EMHolySheet *sheet = [EMHolySheet actionSheetWithSections:sections];
    [sheet setButtonPressedBlock:^(JGActionSheet *sender, NSIndexPath *indexPath) {
        [sender dismissAnimated:YES];
        [self handleEmuOptionsChoice:indexPath actionsMapping:actionsMapping];
    }];
    [sheet setOutsidePressBlock:^(JGActionSheet *sender) {
        [sender dismissAnimated:YES];
        // Cancel
        HMParams *params = [self paramsForCurrentEmuticon];
        [params addKey:AK_EP_CHOICE_TYPE value:@"cancel"];
        [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE info:params.dictionary];
    }];
    [sheet showInView:self.view animated:YES];
    
}

-(void)handleEmuOptionsChoice:(NSIndexPath *)indexPath actionsMapping:(EMActionsArray *)actionsMapping
{
    HMParams *params = [self paramsForCurrentEmuticon];

    NSString *actionName = [actionsMapping actionNameForIndexPath:indexPath];
    if (actionName == nil) return;

    if ([actionName isEqualToString:@"EMU_SCREEN_CHOICE_ADD_TO_FAV"]) {

        self.emuticon.isFavorite = @YES;
        [self refreshEmu];

    } else if ([actionName isEqualToString:@"EMU_SCREEN_CHOICE_REMOVE_FROM_FAV"]) {

        self.emuticon.isFavorite = @NO;
        [self refreshEmu];
        
    } else if ([actionName isEqualToString:@"EMU_SCREEN_CHOICE_RETAKE_EMU"]) {

        // Retake
        [params addKey:AK_EP_CHOICE_TYPE value:@"retake"];
        [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE info:params.dictionary];
        [self retake];
        
    } else if ([actionName isEqualToString:@"EMU_SCREEN_CHOICE_REPLACE_TAKE"]) {
        
        // Replace take
        [self replaceTakeForEmu];
        
    } else {
        
        // Cancel
        [params addKey:AK_EP_CHOICE_TYPE value:@"cancel"];
        [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE info:params.dictionary];
        
    }
}

#pragma mark - Rendering type
-(EMMediaDataType)renderingType
{
    if (self.guiRenderingTypeSelector.selectedSegmentIndex == 0) {
        return EMMediaDataTypeGIF;
    } else {
        return EMMediaDataTypeVideo;
    }
}


#pragma mark - Audio & Video
-(void)updateAudioSelectionUI
{
    // If GIF rendering selected, hide all UI elements related to audio.
    // Also hide audio related UI, if the audio feature is not enabled.
    BOOL isVideoRenderingWithAudioAllowed = [HMPanel.sh boolForKey:VK_FEATURE_VIDEO_RENDER_WITH_AUDIO fallbackValue:NO];
    BOOL isVideoExtraSettingsAllowed = [HMPanel.sh boolForKey:VK_FEATURE_VIDEO_RENDER_EXTRA_USER_SETTINGS fallbackValue:NO];

    
    if (self.renderingType == EMMediaDataTypeGIF || !isVideoRenderingWithAudioAllowed) {
        self.guiAudioButton.hidden = YES;
        self.guiAudioOKButton.hidden = YES;
        self.guiAudioRemoveButton.hidden = YES;
        self.guiAudioView.hidden = YES;
        self.guiAudioTrimSlider.hidden = YES;
        self.guiVideoSettingsButton.hidden = YES;
        return;
    }
    
    // When rendering type is video, show the UI for adding audio to the video.
    // (or the UI allowing the user to hear the audio and trim it)
    if (self.showSelectedAudioUI) {
        // Editing selected audio trimming
        // And allow user to hear the selected trimmed audio.
        self.guiAudioButton.hidden = YES;
        self.guiVideoSettingsButton.hidden = YES;
        self.guiAudioOKButton.hidden = NO;
        self.guiAudioRemoveButton.hidden = NO;
        self.guiRenderingTypeSelector.hidden = YES;
        self.guiAudioView.hidden = NO;
        self.guiAudioTrimSlider.hidden = NO;
        [self updateAudioTrimmingSlider];
    } else {
        // Hide audio trimming UI (return to displaying the rendering type selector (GIF/Video)
        self.guiAudioButton.hidden = NO;
        self.guiAudioOKButton.hidden = YES;
        self.guiAudioRemoveButton.hidden = YES;
        self.guiRenderingTypeSelector.hidden = NO;
        self.guiAudioView.hidden = YES;
        self.guiAudioTrimSlider.hidden = YES;
        self.guiAudioButton.selected = self.emuticon.audioFileURL? YES:NO;
        self.guiVideoSettingsButton.hidden = !isVideoExtraSettingsAllowed;
    }
}


-(void)selectAudio
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO; // this is the default
    [self presentViewController:picker animated:YES completion:nil];
}


-(void)audioStop
{
    [self.player pause];
    self.player = nil;
}


-(void)playSelectedAudio
{
    NSURL *url = self.emuticon.audioFileURL;
    if (url == nil) return;
    
    // New player
    AVPlayerItem *audioItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [[AVPlayer alloc] initWithPlayerItem:audioItem];
    NSString *playUUID = [[NSUUID UUID] UUIDString];
    self.playIdentifier = [NSString stringWithString:playUUID];
    
    // Seek and play
    CMTime seekTime = [self seekTimeForSelectedAudio];
    [self.player seekToTime:seekTime];
    [self.player play];
    
    // Stop when duration ends.
    __weak EMEmuticonScreenVC *weakSelf = self;
    dispatch_after(DTIME(AUDIO_DURATION), dispatch_get_main_queue(), ^{
        if ([playUUID isEqualToString:weakSelf.playIdentifier]) {
            [weakSelf.player pause];
            weakSelf.audioPlayPositionView.hidden = YES;
        }
    });
    
    // Play seek indicator animation
    [self restartPlaySeekAnimation];
}


-(void)restartPlaySeekAnimation
{
    UIView *posView = self.audioPlayPositionView;
    UIView *sv = self.guiAudioTrimSlider.subviews[2];
    if (self.audioPlayPositionView == nil) {
        posView = [UIView new];
        posView.userInteractionEnabled = NO;
        posView.backgroundColor = [EmuStyle colorButtonBGNegative];
        self.audioPlayPositionView = posView;
        [sv addSubview:posView];
    }

    [posView.layer removeAllAnimations];
    
    CGFloat x1 = 0;
    CGFloat x2 = sv.bounds.size.width;
    CGRect f1 = CGRectMake(x1+3, 4, 3, self.guiAudioView.bounds.size.height-8);
    CGRect f2 = CGRectMake(x2-8, 4, 3, self.guiAudioView.bounds.size.height-8);
    posView.frame = f1;
    posView.hidden = NO;
    [UIView animateWithDuration:AUDIO_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         posView.frame = f2;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             posView.hidden = YES;
                         }
                     }];
}


-(CMTime)seekTimeForSelectedAudio
{
    // The duration of the audio resource.
    CMTime duration = self.player.currentItem.asset.duration;
    
    // The duration of the audio resource, in seconds
    NSTimeInterval durationInSeconds = CMTimeGetSeconds(duration);
    if (durationInSeconds < AUDIO_DURATION) {
        return CMTimeMake(0, duration.timescale);
    }
    
    duration = CMTimeAdd(duration, CMTimeMakeWithSeconds(-AUDIO_DURATION, duration.timescale));
    CMTime seekTime = CMTimeMake(duration.value * self.guiAudioTrimSlider.value, duration.timescale);
    return seekTime;
}


-(void)updateAudioTrimmingSlider
{
    NSURL *url = self.emuticon.audioFileURL;
    if (url == nil) return;
    
    if (self.emuticon.audioStartTime == nil) {
        self.guiAudioTrimSlider.value = 0.5;
        return;
    }
    
    // Get start time
    AVPlayerItem *audioItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [[AVPlayer alloc] initWithPlayerItem:audioItem];
    NSTimeInterval startTime = self.emuticon.audioStartTime.doubleValue;
    
    // Get % out of duration
    CMTime duration = self.player.currentItem.asset.duration;
    NSTimeInterval durationInSeconds = CMTimeGetSeconds(duration);
    float pos = MAX(MIN(startTime/durationInSeconds,1.0),0.0);
    self.guiAudioTrimSlider.value = pos;
}


-(void)audioRemoveOptions
{
    EMActionsArray *actionsMapping = [EMActionsArray new];
    
    //
    // Retake options
    //
    NSString *title = LS(@"AUDIO_OPTIONS_TITLE");
    [actionsMapping addAction:@"AUDIO_REMOVE" text:LS(@"AUDIO_REMOVE") section:0];
    [actionsMapping addAction:@"AUDIO_REPLACE" text:LS(@"AUDIO_REPLACE") section:0];
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
        [self handleAudioRemoveIndexPath:indexPath actionsMapping:actionsMapping];
    }];
    [sheet setOutsidePressBlock:^(JGActionSheet *sender) {
        [sender dismissAnimated:YES];
    }];
    [sheet showInView:self.view animated:YES];
}

-(void)handleAudioRemoveIndexPath:(NSIndexPath *)indexPath actionsMapping:(EMActionsArray *)actionsMapping
{
    NSString *actionName = [actionsMapping actionNameForIndexPath:indexPath];
    if (actionName == nil) return;
    
    if ([actionName isEqualToString:@"AUDIO_REMOVE"]) {
        [self audioRemove];
    } else if ([actionName isEqualToString:@"AUDIO_REPLACE"]) {
        [self audioStop];
        [self selectAudio];
    }
}

-(void)audioRemove
{
    self.emuticon.audioFilePath = nil;
    self.emuticon.audioStartTime = nil;
    self.showSelectedAudioUI = NO;
    [self audioStop];
    [self updateAudioSelectionUI];
}

#pragma mark - MPMediaPickerControllerDelegate
-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (mediaItemCollection.count<1) return;
    
    MPMediaItem *item = (MPMediaItem *)[mediaItemCollection.items objectAtIndex:0];
    NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    self.emuticon.audioFilePath = [url absoluteString];
    
    // Check for DRM related errors.
    if (url == nil) {
        [self.view makeToast:LS(@"DRM_ERROR")];
        self.showSelectedAudioUI = NO;
        self.emuticon.audioFilePath = nil;
        return;
    }
    
    self.showSelectedAudioUI = YES;
    [self updateAudioSelectionUI];
    [self playSelectedAudio];
}

#pragma mark - Buy content
-(void)purchaseHDContent
{
    [self hideEmuOptionsBar];
    Package *package = self.emuticon.emuDef.package;
    [EMBackend.sh buyProductWithIdentifier:package.hdProductID];
}

#pragma mark - Cleanup
-(void)deleteUnrequiredHDContentAndResources
{
    if (self.emuticon.emuDef.hdAvailable.boolValue) {
        // Always delete the HD resources. Will be redownloaded if required.
        [self.emuticon.emuDef removeAllHDResources];
        if (![self.emuticon shouldItRenderInHD]) {
            [self.emuticon cleanUpHDOutputGif];
        }
    }
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedBackButton:(UIButton *)sender
{
    // Go back
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPressedRetakeButton:(id)sender
{
    // Retake
    [self retake];
}

- (IBAction)onSwipedRight:(id)sender
{
    // Go back
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPressedEmuButton:(id)sender
{
    [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_PRESSED_EMU info:[[self paramsForCurrentEmuticon] dictionary]];
    
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];
    [self showEmuOptions];
    
    [UIView animateWithDuration:0.1 animations:^{
        self.guiEmuContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.2
              initialSpringVelocity:3.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.guiEmuContainer.transform = CGAffineTransformIdentity;
                            } completion:nil];
    }];
}


- (IBAction)onPressedSoundButton:(UIButton *)sender
{
    if (self.emuticon.audioFileURL) {
        self.showSelectedAudioUI = YES;
        [self updateAudioTrimmingSlider];
        [self updateAudioSelectionUI];
    } else {
        [self selectAudio];
    }
}


- (IBAction)onChangedRenderType:(UISegmentedControl *)sender
{
    [self updateAudioSelectionUI];
    [self.shareVC update];
    
    // Store user preference
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    appCFG.userPrefferedShareType = @([self renderingType]);
}


- (IBAction)onChangedAudioSeekValue:(UISlider *)sender
{
    [self playSelectedAudio];
}


- (IBAction)onDraggedAudioSeek:(UISlider *)sender
{
    self.audioPlayPositionView.hidden = YES;
}


- (IBAction)onAudioSelectionOK:(id)sender
{
    NSTimeInterval audioStartTime = CMTimeGetSeconds([self seekTimeForSelectedAudio]);
    self.emuticon.audioStartTime = @(audioStartTime);
    self.showSelectedAudioUI = NO;
    [self audioStop];
    [self updateAudioSelectionUI];
}


- (IBAction)onAudioSelectionRemove:(id)sender
{
    [self audioRemoveOptions];
}

- (IBAction)onPressedVideoSettingsButton:(UIButton *)sender
{
    EMVideoSettingsPopover *vc = [[EMVideoSettingsPopover alloc] init];
    vc.preferredContentSize = CGSizeMake(210, 140);
    vc.emu = self.emuticon;

    UIPopoverPresentationController *po = vc.popoverPresentationController;
    po.sourceView = sender; //The view containing the anchor rectangle for the popover.
    po.sourceRect = sender.bounds; //The rectangle in the specified view in which to anchor the popover.
    po.permittedArrowDirections = UIPopoverArrowDirectionDown;

    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)onPressedFavButton:(id)sender
{
    if (self.emuticon.isFavorite.boolValue) {
        self.emuticon.isFavorite = @NO;
    } else {
        self.emuticon.isFavorite = @YES;

        // Analytics
        Emuticon *emu = self.emuticon;
        HMParams *params = [HMParams new];
        [params addKey:AK_EP_EMUTICON_NAME valueIfNotNil:emu.emuDef.name];
        [params addKey:AK_EP_EMUTICON_OID valueIfNotNil:emu.emuDef.oid];
        [params addKey:AK_EP_PACKAGE_NAME valueIfNotNil:emu.emuDef.package.name];
        [params addKey:AK_EP_PACKAGE_OID valueIfNotNil:emu.emuDef.package.oid];
        [params addKey:AK_EP_ORIGIN_UI valueIfNotNil:self.originUI];
        [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_FAVORITE info:params.dictionary];

        [HMPanel.sh reportCountedSuperParameterForKey:AK_S_MARKED_AS_FAV_COUNT];
        [HMPanel.sh reportSuperParameterKey:AK_S_DID_EVER_MARKED_ANY_EMU_AS_FAV value:@YES];
    }
    [self refreshEmu];
}

- (IBAction)onHDToggleButtonPressed:(UIButton *)sender
{
    Package *package = self.emuticon.emuDef.package;
    if (package.hdUnlocked.boolValue || package.hdProductID == nil) {
        // Already unlocked this product.
        // User can toggle HD on or off at will.
        [self.emuticon toggleShouldRenderAsHDIfAvailable];
        [self updateEmuOptionsBar];
        [self refreshEmu];
    } else if (package.hdProductValidated.boolValue) {
        // User still didn't unlock the HD feature of this pack.
        // And the product is a validated one.
        EMProductPopover *vc = [[EMProductPopover alloc] init];
        vc.preferredContentSize = CGSizeMake(240, 240);
        vc.packageOID = package.oid;
        vc.delegate = self;
        
        UIPopoverPresentationController *po = vc.popoverPresentationController;
        po.sourceView = sender;
        po.sourceRect = sender.bounds;
        po.permittedArrowDirections = UIPopoverArrowDirectionDown;
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (IBAction)onPressedFullScreenButton:(UIButton *)sender
{
    BOOL inHD = [self.emuticon shouldItRenderInHD];
    if ([self.emuticon boolWasRenderedInHD:inHD]) {
        [self performSegueWithIdentifier:@"full screen gif player segue" sender:sender];
    }
}

@end
