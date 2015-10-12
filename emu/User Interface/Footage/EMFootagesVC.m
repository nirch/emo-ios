//
//  EMFootageSelectorVC.m
//  emu
//
//  Created by Aviv Wolf on 10/1/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@import AudioToolbox;

#import "EMFootagesVC.h"
#import "EMFootagesDataSource.h"
#import "EMNavBarVC.h"
#import "EMFlowButton.h"
#import "EMUISound.h"
#import "EMFootageCell.h"
#import "EMFootagesNavigationCFG.h"
#import "EMUINotifications.h"
#import "UIView+CommonAnimations.h"
#import "EMRecorderVC.h"
#import "EMDB.h"

@interface EMFootagesVC () <
    EMNavBarDelegate,
    EMRecorderDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiNegativeButton;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiPositiveButton;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;

@property (weak, nonatomic) IBOutlet UIView *guiManageTakesBar;
@property (weak, nonatomic) IBOutlet UIView *guiApplyChoiceBar;

@property (weak, nonatomic) IBOutlet UIImageView *guiAddIcon;
@property (weak, nonatomic) IBOutlet UIImageView *guiDeleteIcon;
@property (weak, nonatomic) IBOutlet EMButton *guiSetAsDefaultButton;


@property (nonatomic, readwrite) EMFootagesFlowType flowType;

@property (nonatomic) BOOL alreadyInitializedOnAppearance;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;
@property (nonatomic) id<EMNavBarConfigurationSource> navBarCFG;

@property (nonatomic) EMFootagesDataSource *dataSource;

@end

@implementation EMFootagesVC

@synthesize flowType = _flowType;
@synthesize currentState = _currentState;

+(EMFootagesVC *)footagesVCForFlow:(EMFootagesFlowType)flowType
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Footages" bundle:nil];
    EMFootagesVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"footages vc"];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    vc.flowType = flowType;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataSource];
    [self initGUIOnLoad];
    [self initNavigationBar];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUIOnAppearance];
}

#pragma mark - Initializations
-(void)initDataSource
{
    self.dataSource = [EMFootagesDataSource new];
    self.guiCollectionView.dataSource = self.dataSource;
}

-(void)initGUIOnLoad
{
    self.guiNegativeButton.positive = NO;
    [self.navBarVC hideTitleAnimated:NO];
    if (self.currentState == EMFootagesFlowTypeChooseFootage) {
        self.guiPositiveButton.alpha = 0.2;
        self.guiPositiveButton.userInteractionEnabled = NO;
        self.guiApplyChoiceBar.hidden = NO;
        self.guiManageTakesBar.hidden = YES;
    } else if (self.currentState == EMFootagesFlowTypeMangementScreen) {
        self.guiApplyChoiceBar.hidden = YES;
        self.guiManageTakesBar.hidden = NO;
    }
}

-(void)initGUIOnAppearance
{
    if (!self.alreadyInitializedOnAppearance) {
        self.alreadyInitializedOnAppearance = YES;
    } else {
        [self.dataSource reset];
        [self.guiCollectionView reloadData];
    }
}

-(void)initNavigationBar
{
    UIColor *navBarColor = self.themeColor?self.themeColor:[EmuStyle colorThemeFeed];
    self.navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:navBarColor];
    self.navBarVC.delegate = self;
    
    // Configure the nav bar
    if (self.currentState == EMFootagesFlowTypeChooseFootage) {
        [self.navBarVC updateTitle:LS(@"TAKES_CHOOSE_TAKE")];
        dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
            [self.navBarVC showTitleAnimated:YES];
        });
    }
    
    self.navBarCFG = [EMFootagesNavigationCFG new];
    self.navBarVC.configurationSource = self.navBarCFG;
    [self.navBarVC updateUIByCurrentState];
}

-(NSInteger)currentState
{
    return self.flowType;
}

#pragma mark - Collection view Layout
-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat size = (self.view.bounds.size.width-10.0) / 3.0;
    return CGSizeMake(size, size);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(44, 0, 64, 0);
    return edgeInsets;
}

#pragma mark - Status bar
-(BOOL)prefersStatusBarHidden
{
    return YES;
}


#pragma mark - Collection View Delegate
-(void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [EMUISound.sh playSoundNamed:SND_SOFT_CLICK];
    [self.dataSource selectIndexPath:indexPath
                    inCollectionView:collectionView];
    
    if (self.flowType == EMFootagesFlowTypeChooseFootage) {
        
        // Chosen a take and allow to apply it.
        [self.navBarVC hideTitleAnimated:YES];
        self.guiPositiveButton.alpha = 1;
        self.guiPositiveButton.userInteractionEnabled = YES;
        
    } else if (self.flowType == EMFootagesFlowTypeMangementScreen) {
        
        [self.navBarVC hideTitleAnimated:YES];
        
    }
}

#pragma mark - EMNavigationBarDelegate
-(void)navBarOnTitleButtonPressed:(UIButton *)sender
{
    
}

-(void)navBarOnUserActionNamed:(NSString *)actionName
                        sender:(id)sender
                         state:(NSInteger)state
                          info:(NSDictionary *)info
{
    if ([actionName isEqualToString:EMK_NAV_ACTION_FOOTAGES_DONE]) {
        [self.delegate controlSentActionNamed:emkUIFootagesManageDone info:nil];
    }
}

-(void)noneSelected
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self.navBarVC showTitleAnimated:YES];
    [self.navBarVC updateTitle:LS(@"TAKES_CHOOSE_TAKE")];
}

#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedAfterFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.dataSource reset];
        [self.guiCollectionView reloadData];
    }];
}

-(void)recorderCanceledByTheUserInFlow:(EMRecorderFlowType)flowType info:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - Footage operations
-(void)chooseSelectedAsDefaultFootage
{
    NSString *footageOID = [self.dataSource selectedFootageOID];
    
    if (footageOID) {
        AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
        appCFG.prefferedFootageOID = footageOID;
    }
    
    [self.dataSource unselect];
    [self.dataSource reset];
    [self.guiCollectionView reloadData];
}

-(void)deleteSelectedFootage
{
    NSString *footageOID = [self.dataSource selectedFootageOID];
    NSArray *emus = [Emuticon allEmuticonsUsingFootageOID:footageOID inContext:EMDB.sh.context];
    for (Emuticon *emu in emus) {
        emu.prefferedFootageOID = nil;
    }
    UserFootage *footageToRemove = [UserFootage findWithID:footageOID context:EMDB.sh.context];
    [EMDB.sh.context deleteObject:footageToRemove];

    [UIView animateWithDuration:0.3 animations:^{
        self.guiCollectionView.alpha = 0;
        
    } completion:^(BOOL finished) {
        [EMDB.sh save];
        [self.dataSource reset];
        [self.guiCollectionView reloadData];
        [UIView animateWithDuration:0.3 animations:^{
            self.guiCollectionView.alpha = 1;
        }];
    }];
    
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNegativeButton:(id)sender
{
    if (self.delegate == nil) return;
    
    [self.delegate controlSentActionNamed:emkUIFootageSelectionCancel info:nil];
}

- (IBAction)onPressedPositiveButton:(id)sender
{
    if (self.dataSource.selectedIndexPath == nil) return;
    
    // Gather info about selected footage.
    NSMutableDictionary *info = [NSMutableDictionary new];
    NSString *selectedOID = [self.dataSource selectedFootageOID];
    if (selectedOID) info[emkFootageOID] = selectedOID;
    if (self.selectedEmusOID) info[emkEmuticonOID] = self.selectedEmusOID;
    
    // Send the info about the selection to the delegate.
    [self.delegate controlSentActionNamed:emkUIFootageSelectionApply info:info];
}

- (IBAction)onAddButtonPressed:(id)sender
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    NSArray *prefferedEmus = [HMPanel.sh listForKey:VK_ONBOARDING_EMUS_FOR_PREVIEW_LIST fallbackValue:nil];
    EmuticonDef *emuticonDefForOnboarding = [appCFG emuticonDefForOnboardingWithPrefferedEmus:prefferedEmus];
    
    NSDictionary *configInfo =@{
                                emkEmuticonDefOID:emuticonDefForOnboarding.oid,
                                emkEmuticonDefName:emuticonDefForOnboarding.name
                                };
    
    EMRecorderVC *recorderVC = [EMRecorderVC recorderVCWithConfigInfo:configInfo];
    recorderVC.delegate = self;
    [self presentViewController:recorderVC animated:YES completion:nil];

    [self.guiAddIcon animateQuickPopIn];

}

- (IBAction)onDefaultButtonPressed:(id)sender
{
    if (self.dataSource.selectedIndexPath == nil) {
        [self noneSelected];
        return;
    }
    [self.guiSetAsDefaultButton animateQuickPopIn];
    [self chooseSelectedAsDefaultFootage];
}

- (IBAction)onDeleteButtonPressed:(id)sender
{
    if (self.dataSource.selectedIndexPath == nil) {
        [self noneSelected];
        return;
    }
    
    NSString *footageOID = [self.dataSource selectedFootageOID];
    NSString *masterFootageOID = [UserFootage masterFootage].oid;
    if ([footageOID isEqualToString:masterFootageOID]) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        [self.navBarVC showTitleAnimated:YES];
        [self.navBarVC updateTitle:LS(@"TAKES_CANNOT_DELETE_DEFAULT_FOOTAGE")];
        return;
    }
    
    [self.guiDeleteIcon animateQuickPopIn];
    [self deleteSelectedFootage];
}


@end
