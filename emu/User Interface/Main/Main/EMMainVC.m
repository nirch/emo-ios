//
//  EMMainVCViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMMainVC.h"
#import "EMRecorderVC.h"
#import "EMDB.h"
#import "EMBackend.h"

@interface EMMainVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    EMRecorderDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;
@property (weak, nonatomic) IBOutlet UIView *guiNavView;
@property (weak, nonatomic) UIImageView *splashView;

@end

@implementation EMMainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (!appCFG.onboardingPassed.boolValue) {
        [self showSplash];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    if (!appCFG.onboardingPassed.boolValue) {
        [self openRecorderWithInfo:nil];
    }
}

#pragma mark - splash
-(void)showSplash
{
    UIImageView *splashView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.splashView = splashView;
    self.splashView.image = [UIImage imageNamed:@"splashImage"];
    [self.view addSubview:self.splashView];
}

-(void)hideSplashAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideSplashAnimated:NO];
        }];
        return;
    }
    self.splashView.alpha = 0;
}

-(void)initData
{
    [EMBackend.sh refetchEmuticonsDefinitions];
    [EMBackend.sh refetchAppCFG];
}

#pragma mark - initializations
+(EMMainVC *)mainVCWithInfo:(NSDictionary *)info
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EMMainVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"main vc"];
    return vc;
}


#pragma mark - VC preferences
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return 30;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"emu cell";
    UICollectionViewCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                                   forIndexPath:indexPath];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat size = (self.view.bounds.size.width-10.0) / 2.0;
    return CGSizeMake(size, size);
}

#pragma mark - UICollectionViewDelegate


#pragma mark - EMRecorderDelegate
-(void)recorderWantsToBeDismissedWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self hideSplashAnimated:YES];
    }];
}

-(void)openRecorderWithInfo:(NSDictionary *)info
{
    //
    // Open recorder for onboarding.
    //
    EMRecorderVC *recorderVC = [EMRecorderVC recorderVCWithInfo:nil];
    recorderVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    recorderVC.delegate = self;
    [self presentViewController:recorderVC animated:YES completion:^{
        [self hideSplashAnimated:NO];
    }];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRetakeButton:(id)sender
{
    [self openRecorderWithInfo:nil];
}



@end
