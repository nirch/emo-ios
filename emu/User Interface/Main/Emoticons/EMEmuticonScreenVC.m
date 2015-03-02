//
//  EMEmuticonScreen.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMEmuticonScreenVC.h"
#import "EMDB.h"
#import "EMAnimatedGifPlayer.h"
#import "EMShareVC.h"
#import "EMRecorderVC.h"
#import "EMRenderManager.h"

@interface EMEmuticonScreenVC () <
    EMShareDelegate,
    EMRecorderDelegate
>

@property (nonatomic) Emuticon *emuticon;

// Emu player
@property (weak, nonatomic) EMAnimatedGifPlayer *gifPlayerVC;
@property (weak, nonatomic) EMShareVC *shareVC;

// Layout
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintPlayerLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintPlayerRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *guiConstraintPlayerTop;

@end

@implementation EMEmuticonScreenVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Show the animated gif
    self.gifPlayerVC.animatedGifURL = [self.emuticon animatedGifURL];
    self.gifPlayerVC.locked = self.emuticon.prefferedFootageOID != nil;
    
    // Only iPhone4s needs special treatment of the layout
    [self layoutFixesIfRequired];
    
    // Init observers
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove observers
    [self removeObservers];
}

-(void)initData
{
    self.emuticon = [Emuticon findWithID:self.emuticonOID
                                 context:EMDB.sh.context];
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
    NSString *oid = info[@"emuticonOID"];
    
    // ignore notifications not relating to emus on screen
    if (![self.emuticon.oid isEqualToString:oid]) return;
    
    // Show the animated gif
    self.gifPlayerVC.animatedGifURL = [self.emuticon animatedGifURL];
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

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedBackButton:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPressedRetakeButton:(id)sender
{
    [self retake];
}

@end
