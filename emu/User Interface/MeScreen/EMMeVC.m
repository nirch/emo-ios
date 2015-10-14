//
//  EMMeVC.m
//  emu
//
//  Created by Aviv Wolf on 10/11/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMMeVC.h"
#import "EMNavBarVC.h"
#import "EMMeNavigationCFG.h"
#import "EMEmusPickerVC.h"
#import "EMDB.h"
#import "EMEmuticonScreenVC.h"
#import "EMUINotifications.h"
#import "EMFootagesVC.h"

@interface EMMeVC () <
    EMNavBarDelegate,
    EMInterfaceDelegate
>

@property (nonatomic, weak) EMEmusPickerVC *favoritesListVC;
@property (nonatomic, weak) EMEmusPickerVC *recentlySharedListVC;
@property (nonatomic, weak) EMEmusPickerVC *recentlyViewedListVC;

// Navigation bar
@property (weak, nonatomic) EMNavBarVC *navBarVC;
@property (nonatomic) id<EMNavBarConfigurationSource> navBarCFG;

// Footages VC
@property (nonatomic, weak) EMFootagesVC *footagesVC;

@property (nonatomic) BOOL alreadyInitializedOnAppearance;

@end

@implementation EMMeVC

@synthesize currentState = _currentState;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initState];
    [self initNavigationBar];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUIOnAppearance];
}

#pragma mark - Initializations
-(void)initGUIOnAppearance
{
    UserFootage *masterFootage = [UserFootage masterFootage];
    UIImage *thumb = [masterFootage thumbImage];

    if (!self.alreadyInitializedOnAppearance) {
        // init here stuff to be initialized only on first appearance.
        self.alreadyInitializedOnAppearance = YES;
        dispatch_after(DTIME(2.0), dispatch_get_main_queue(), ^{
            if (thumb) [self.navBarVC showImageAsLogo:thumb];
        });

    } else {
        [self.favoritesListVC refreshLocalData];
        [self.recentlySharedListVC refreshLocalData];
        [self.recentlyViewedListVC refreshLocalData];
        if (thumb) [self.navBarVC showImageAsLogo:thumb];
    }


    
    // Show the tabs
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIShouldShowTabsBar
                                                        object:self
                                                      userInfo:@{emkUIAnimated:@YES}];

    
    [self.navBarVC bounce];
}

-(void)initNavigationBar
{
    self.navBarVC = [EMNavBarVC navBarVCInParentVC:self themeColor:[EmuStyle colorThemeMe]];
    self.navBarVC.delegate = self;
    
    self.navBarCFG = [EMMeNavigationCFG new];
    self.navBarVC.configurationSource = self.navBarCFG;
    [self.navBarVC updateUIByCurrentState];
}

-(void)initState
{
    _currentState = EMMeStateNormal;
}

#pragma mark - Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"favorites segue"]) {

        // --------------
        // Favorites
        // --------------
        EMEmusPickerVC *vc = segue.destinationViewController;
        [vc configureForFavoriteEmus];
        vc.identifier = emkUIFavorites;
        vc.delegate = self;
        vc.placeHolderMessageWhenEmpty = LS(@"ME_NO_FAVORITES");
        self.favoritesListVC = vc;
        
    } else if ([segue.identifier isEqualToString:@"recently shared segue"]) {

        // ------------------
        // Recently shared
        // ------------------
        EMEmusPickerVC *vc = segue.destinationViewController;
        [vc configureForRecentlySharedEmus];
        vc.identifier = emkUIRecentlyShared;
        vc.delegate = self;
        vc.placeHolderMessageWhenEmpty = LS(@"ME_NO_RECENT_SHARED");
        self.recentlySharedListVC = vc;
        
    } else if ([segue.identifier isEqualToString:@"recently viewed segue"]) {
        
        // ------------------
        // Recently viewed
        // ------------------
        EMEmusPickerVC *vc = segue.destinationViewController;
        [vc configureForRecentlyViewedEmus];
        vc.identifier = emkUIRecentlyViewed;
        vc.delegate = self;
        vc.placeHolderMessageWhenEmpty = LS(@"ME_NO_FAVORITES");
        self.recentlyViewedListVC = vc;
        
    }
}

#pragma mark - Other screens / VC
-(void)navigateToEmuticonOID:(NSString *)emuticonOID
{
    if (emuticonOID == nil) return;
    Emuticon *emu = [Emuticon findWithID:emuticonOID context:EMDB.sh.context];
    if (emu == nil) return;
    
    EMEmuticonScreenVC *vc = [EMEmuticonScreenVC emuticonScreenForEmuticonOID:emuticonOID];
    vc.themeColor = [EmuBaseStyle colorThemeMe];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)openFooatgesScreen
{
    // Present the footages screen
    EMFootagesVC *footagesVC = [EMFootagesVC footagesVCForFlow:EMFootagesFlowTypeMangementScreen];
    footagesVC.delegate = self;
    footagesVC.themeColor = self.navBarVC.themeColor;
    self.footagesVC = footagesVC;
    [self presentViewController:footagesVC animated:YES completion:^{
    }];
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
    if ([actionName isEqualToString:EMK_NAV_ACTION_MY_TAKES]) {
        [self openFooatgesScreen];
    }
}

#pragma mark - EMInterfaceDelegate
-(void)controlSentActionNamed:(NSString *)actionName info:(NSDictionary *)info
{
    if ([actionName isEqualToString:emkUIActionPickedEmu]) {
        NSString *emuticonOID = info[emkEmuticonOID];
        self.view.userInteractionEnabled = NO;
        dispatch_after(DTIME(0.3), dispatch_get_main_queue(), ^{
            [self navigateToEmuticonOID:emuticonOID];
            self.view.userInteractionEnabled = YES;
        });
    } else if ([actionName isEqualToString:emkUIFootagesManageDone]) {
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========


@end
