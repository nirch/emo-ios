//
//  EMFootageSelectorVC.m
//  emu
//
//  Created by Aviv Wolf on 10/1/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFootagesVC.h"
#import "EMFootagesDataSource.h"
#import "EMNavBarVC.h"
#import "EMFlowButton.h"
#import "EMUISound.h"
#import "EMFootageCell.h"
#import "EMDB.h"

@interface EMFootagesVC () <
    EMNavBarDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiNegativeButton;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiPositiveButton;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;

@property (nonatomic, readwrite) EMFootagesFlowType flowType;

@property (nonatomic) BOOL alreadyInitializedOnAppearance;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;

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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUIOnAppearance];
    dispatch_after(DTIME(1.0), dispatch_get_main_queue(), ^{
        [self.navBarVC showTitleAnimated:YES];
    });
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
    self.guiPositiveButton.alpha = 0.5;
    self.guiPositiveButton.userInteractionEnabled = NO;
}

-(void)initGUIOnAppearance
{
    if (!self.alreadyInitializedOnAppearance) {        
        self.alreadyInitializedOnAppearance = YES;
    }
}

-(void)initNavigationBar
{
    self.navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeFeed]];
    self.navBarVC.delegate = self;
    [self.navBarVC updateTitle:@"Choose a take"];
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
        // Chosen a take.
        [self.navBarVC hideTitleAnimated:YES];
        self.guiPositiveButton.alpha = 1;
        self.guiPositiveButton.userInteractionEnabled = YES;
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



@end
