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
#import "EMRenderManager.h"
#import "EMUISound.h"
#import <JDFTooltips.h>
#import "EMRenderManager.h"
#import "EMHolySheet.h"
#import "EMActionsArray.h"
#import "AppDelegate.h"
#import "EMNotificationCenter.h"

@interface EMEmuticonScreenVC () <
    EMShareDelegate,
    EMRecorderDelegate,
    MPMediaPickerControllerDelegate
>

#define AUDIO_DURATION 20.0f

@property (nonatomic) Emuticon *emuticon;

// Emu player
@property (weak, nonatomic) IBOutlet UIView *guiEmuContainer;
@property (weak, nonatomic) EMAnimatedGifPlayer *gifPlayerVC;
@property (weak, nonatomic) EMShareVC *shareVC;

// Layout
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintPlayerLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintPlayerRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *guiConstraintPlayerTop;

@property (weak, nonatomic) IBOutlet UIButton *guiRetakeButton;
@property (weak, nonatomic) IBOutlet UIView *guiShareContainer;
@property (weak, nonatomic) IBOutlet UIView *guiShareMainIconPosition;

// Tutorial
@property (strong, nonatomic) JDFSequentialTooltipManager *tooltipManager;

// Rendering type
@property (weak, nonatomic) IBOutlet UISegmentedControl *guiRenderingTypeSelector;

// Audio/Video
@property (weak, nonatomic) IBOutlet UIButton *guiAudioButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiAudioView;
@property (weak, nonatomic) IBOutlet UIButton *guiAudioOKButton;
@property (weak, nonatomic) IBOutlet UIButton *guiAudioRemoveButton;
@property (weak, nonatomic) IBOutlet UISlider *guiAudioTrimSlider;
@property (weak, nonatomic) UIView *audioPlayPositionView;
@property (nonatomic) BOOL showSelectedAudioUI;

@property (nonatomic) NSString *playIdentifier;
@property (nonatomic) AVPlayer *player;

@end

@implementation EMEmuticonScreenVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    [self refreshEmu];
    [self initGUI];
    [self updateAudioSelectionUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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
    [self audioStop];
}


-(void)initGUI
{
    [self.guiAudioTrimSlider setThumbImage:[UIImage imageNamed:@"audioTrimThumb"] forState:UIControlStateNormal];
    [self.guiAudioTrimSlider setThumbImage:[UIImage imageNamed:@"audioTrimThumb"] forState:UIControlStateHighlighted];
}

-(void)initData
{
    self.emuticon = [Emuticon findWithID:self.emuticonOID
                                 context:EMDB.sh.context];
}


-(void)refreshEmu
{
    NSURL *url = [self.emuticon animatedGifURL];
    self.gifPlayerVC.locked = self.emuticon.prefferedFootageOID != nil;

    if (url) {
        // Show the animated gif
        self.gifPlayerVC.animatedGifURL = url;
    } else {
        self.gifPlayerVC.animatedGifURL = nil;
    }
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
    
    // On background detection information received.
    [nc addUniqueObserver:self
                 selector:@selector(onRenderingFinished:)
                     name:hmkRenderingFinished
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
    [nc removeObserver:emkAppDidBecomeActive];
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


-(void)onAppDidBecomeActive:(NSNotification *)notification
{
    [self updateFBMessengerExperienceState];
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
    [EMRenderManager.sh enqueueEmu:self.emuticon
                              info:@{@"emuticonOID":self.emuticon.oid}];

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
    NSDictionary *info = @{emkEmuticon:self.emuticon};
    EMRecorderVC *recorderVC = [EMRecorderVC recorderVCForFlow:EMRecorderFlowTypeRetakeForSpecificEmuticons
                                                          info:info];
    recorderVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    recorderVC.delegate = self;
    [self presentViewController:recorderVC animated:YES completion:nil];

}

#pragma mark - Render
-(void)resetEmu
{
    NSDictionary *info = @{
                           @"emuticonOID":self.emuticon.oid,
                           @"packageOID":self.emuticon.emuDef.package.oid
                           };
    self.emuticon.prefferedFootageOID = nil;
    [EMRenderManager.sh renderingRequiredForEmu:self.emuticon info:info];
    [self refreshEmu];
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
    [actionsMapping addAction:@"EMU_SCREEN_CHOICE_RETAKE_EMU" text:LS(@"EMU_SCREEN_CHOICE_RETAKE_EMU") section:0];
    // Retake footage.
    if (self.emuticon.prefferedFootageOID) {
        [actionsMapping addAction:@"EMU_SCREEN_CHOICE_RESET_EMU" text:LS(@"EMU_SCREEN_CHOICE_RESET_EMU") section:0];
    }
    EMHolySheetSection *section1 = [EMHolySheetSection sectionWithTitle:nil message:nil buttonTitles:[actionsMapping textsForSection:0] buttonStyle:JGActionSheetButtonStyleDefault];
    
    
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
    
    if ([actionName isEqualToString:@"EMU_SCREEN_CHOICE_RETAKE_EMU"]) {

        // Retake
        [params addKey:AK_EP_CHOICE_TYPE value:@"retake"];
        [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE info:params.dictionary];
        [self retake];
        
    } else if ([actionName isEqualToString:@"EMU_SCREEN_CHOICE_RESET_EMU"]) {
        
        // Reset
        [params addKey:AK_EP_CHOICE_TYPE value:@"reset"];
        [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE info:params.dictionary];
        [self resetEmu];
        
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
    if (self.renderingType == EMMediaDataTypeGIF) {
        self.guiAudioButton.hidden = YES;
        self.guiAudioOKButton.hidden = YES;
        self.guiAudioRemoveButton.hidden = YES;
        self.guiAudioView.hidden = YES;
        self.guiAudioTrimSlider.hidden = YES;
        return;
    }
    
    // When rendering type is video, show the UI for adding audio to the video.
    // (or the UI allowing the user to hear the audio and trim it)
    if (self.showSelectedAudioUI) {
        // Editing selected audio trimming
        // And allow user to hear the selected trimmed audio.
        self.guiAudioButton.hidden = YES;
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


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedBackButton:(UIButton *)sender
{
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_PRESSED_BACK_BUTTON
                             info:[self paramsForCurrentEmuticon].dictionary];
    
    // Go back
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPressedRetakeButton:(id)sender
{
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_PRESSED_RETAKE_BUTTON
                             info:[self paramsForCurrentEmuticon].dictionary];

    // Retake
    [self retake];
}

- (IBAction)onSwipedRight:(id)sender
{
    // Analytics
    [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_PRESSED_BACK_BUTTON
                             info:[self paramsForCurrentEmuticon].dictionary];
    
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
    self.emuticon.audioFilePath = nil;
    self.emuticon.audioStartTime = nil;
    self.showSelectedAudioUI = NO;
    [self audioStop];
    [self updateAudioSelectionUI];
}

@end
