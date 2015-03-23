//
//  EMOnBoardingVC.m
//  emu
//
//  Created by Aviv Wolf on 2/9/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMOnboardingVC.h"
#import "EMOBCell.h"
#import "EMPagerView.h"

@interface EMOnboardingVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
>


@property (weak, nonatomic) IBOutlet UIButton *guiEmuButton;
@property (weak, nonatomic) IBOutlet UIButton *guiRestartButton;
@property (weak, nonatomic) IBOutlet UIButton *guiCancelButton;

// A changing title depending on current stage of the flow
@property (weak, nonatomic) IBOutlet UICollectionView *guiCollectionView;

// Custom pager showing what stage the user is in the flow
@property (weak, nonatomic) IBOutlet EMPagerView *guiPagerView;

// Onboarding stage
@property (nonatomic, readwrite) EMOnBoardingStage stage;
@property (nonatomic) NSInteger shownIndex;

// Texts
@property (nonatomic) NSArray *textsKeys;
@property (nonatomic) NSArray *subTextsKeys;

@end

@implementation EMOnboardingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initContent];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.3 animations:^{
        self.guiPagerView.alpha = 1;
    }];
}

-(void)initContent
{
    self.shownIndex = 0;
    self.textsKeys = @[@"ONBOARDING_TITLE_WELCOME",
                       @"ONBOARDING_TITLE_ALIGN",
                       @"ONBOARDING_TITLE_EXTRACTION_PREVIEW",
                       @"ONBOARDING_TITLE_RECORDING",
                       @"ONBOARDING_TITLE_FINISHING_UP",
                       @"ONBOARDING_TITLE_REVIEW"
                       ];
    
    self.subTextsKeys = @[[NSNull null],
                          [NSNull null],
                          [NSNull null],
                          [NSNull null],
                          [NSNull null],
                          [NSNull null]
                          ];
}

-(void)initGUI
{
    self.guiPagerView.pagesCount = EMOB_STAGES-1;
    self.guiPagerView.alpha = 0;
    self.guiRestartButton.alpha = 0;
    [self update];
    
    // Depending on flow type
    if (self.flowType == EMRecorderFlowTypeOnboarding) {
        self.guiEmuButton.hidden = NO;
        self.guiCancelButton.hidden = YES;
        self.guiPagerView.hidden = NO;
    } else {
        self.guiPagerView.hidden = YES;
        self.guiEmuButton.hidden = YES;
        self.guiCancelButton.hidden = NO;
    }
}

#pragma mark - Update
-(void)update
{
    [self.guiCollectionView reloadData];
}


#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.stage + 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ob cell";
    EMOBCell *cell = [self.guiCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                              forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(EMOBCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *textKey = self.textsKeys[indexPath.item];
    cell.guiLabel.text = LS(textKey);
}

#pragma mark - UICollectionViewDelegateFlowLayout
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.guiCollectionView.bounds.size;
}

#pragma mark - Onboarding Stage
-(void)setOnBoardingStage:(EMOnBoardingStage)stage animated:(BOOL)animated
{
    self.stage = stage;
    [self.guiCollectionView reloadData];
    [self scrollToStage:stage animated:animated];
    [self handleStage];
}

-(void)handleStage
{
    if (self.stage >= EMOnBoardingStageRecording) {
        self.guiCancelButton.alpha = 0;
    } else {
        self.guiCancelButton.alpha = 1;
    }

    if (self.stage == EMOnBoardingStageExtractionPreview) {
        self.guiRestartButton.alpha = 1;
    } else {
        self.guiRestartButton.alpha = 0;
    }
}

-(void)scrollToStage:(EMOnBoardingStage)stage animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:stage inSection:0];
    [self.guiCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    [self updatePageIndicatorToIndex:stage];
}

-(NSInteger)updatePageIndicator
{
    NSInteger currentPage = (self.guiCollectionView.contentOffset.x) / self.guiCollectionView.frame.size.width;
    self.guiPagerView.currentPage = currentPage;
    return currentPage;
}

-(void)updatePageIndicatorToIndex:(NSInteger)index
{
    self.guiPagerView.currentPage = index-1;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger currentPage = [self updatePageIndicator];
    if (currentPage < self.stage) {
        self.stage = currentPage;
        [self update];
        [self.delegate onboardingDidGoBackToStageNumber:currentPage];
    }
}

#pragma mark - About message
-(void)aboutMessage
{
    // TODO: Move this from here to somewhere else that can be used from other places in the app
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    UIAlertController *alert = [[UIAlertController alloc] init];
    
    alert.title = [SF:@"About Emu - V%@", build];
    
    alert.message = [SF:@"Emu is a fun free app for iOS, where in just seconds you can create your own personal video stickers we call Emus.\n\nEmu - because you are what you send. \n\n© Homage Technology Ltd. 2015"];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Restarting
-(void)restart
{
    self.stage = 0;
    [self update];
    [self.delegate onboardingDidGoBackToStageNumber:0];
}

#pragma mark - Canceling
-(void)cancel
{
    [self.delegate onboardingUserWantsToCancel];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedEmuButton:(UIButton *)sender
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_STAGE value:@(self.stage)];
    [HMReporter.sh analyticsEvent:AK_E_REC_USER_PRESSED_APP_BUTTON
                             info:params.dictionary];
    [self aboutMessage];
}

- (IBAction)onPressedRestartButton:(UIButton *)sender
{
    [HMReporter.sh analyticsEvent:AK_E_REC_USER_PRESSED_RESTART_BUTTON];
    [self restart];
}

- (IBAction)onPressedCancelButton:(UIButton *)sender
{
    HMParams *params = [HMParams new];
    [params addKey:AK_EP_STAGE value:@(self.stage)];
    [HMReporter.sh analyticsEvent:AK_E_REC_USER_PRESSED_CANCEL_BUTTON
                             info:params.dictionary];
    [self cancel];
}

@end
