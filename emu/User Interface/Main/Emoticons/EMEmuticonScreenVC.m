//
//  EMEmuticonScreen.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMEmuticonScreen"

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
    EMRecorderDelegate
>

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
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

// Tutorial
@property (strong, nonatomic) JDFSequentialTooltipManager *tooltipManager;

@end

@implementation EMEmuticonScreenVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    [self refreshEmu];
    [self initStyle];
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
    
    // Remove observers
    [self removeObservers];
}

-(void)dealloc
{
    HMLOG(TAG, EM_VERBOSE, @"dealloc");
}


-(void)initStyle
{
    // set appearance style
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

//
//-(void)showEmuOptions
//{
//    UIAlertController *alert = [UIAlertController new];
//    HMParams *params = [self paramsForCurrentEmuticon];
//    
//    // Retake footage.
//    [alert addAction:[UIAlertAction actionWithTitle:LS(@"EMU_SCREEN_CHOICE_RETAKE_EMU")
//                                              style:UIAlertActionStyleDefault
//                                            handler:^(UIAlertAction *action) {
//                                                // Retake
//                                                [params addKey:AK_EP_CHOICE_TYPE value:@"retake"];
//                                                [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE
//                                                                      info:params.dictionary];
//                                                [self retake];
//                                            }]];
//
//    // Retake footage.
//    if (self.emuticon.prefferedFootageOID) {
//        [alert addAction:[UIAlertAction actionWithTitle:LS(@"EMU_SCREEN_CHOICE_RESET_EMU")
//                                                  style:UIAlertActionStyleDefault
//                                                handler:^(UIAlertAction *action) {
//                                                    // Reset
//                                                    [params addKey:AK_EP_CHOICE_TYPE value:@"reset"];
//                                                    [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE
//                                                                          info:params.dictionary];
//                                                    [self resetEmu];
//                                                }]];
//    }
//
//    // Cancel
//    [alert addAction:[UIAlertAction actionWithTitle:LS(@"CANCEL")
//                                              style:UIAlertActionStyleCancel
//                                            handler:^(UIAlertAction *action) {
//                                                // Cancel
//                                                [params addKey:AK_EP_CHOICE_TYPE value:@"cancel"];
//                                                [HMPanel.sh analyticsEvent:AK_E_ITEM_DETAILS_USER_CHOICE
//                                                                      info:params.dictionary];
//                                            }]];
//    
//    [self presentViewController:alert animated:YES completion:nil];
//}

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


@end
