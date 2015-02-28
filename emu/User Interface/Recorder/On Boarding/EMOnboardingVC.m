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
    [self initGUI];
    
    //NSLayoutConstraint *c = self.guiPagerView.constraints.lastObject;
    //c.constant = 80;
}

-(void)viewDidAppear:(BOOL)animated
{
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
    [self update];
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

#pragma mark - Restarting
-(void)restart
{
    self.stage = 0;
    [self update];
    [self.delegate onboardingDidGoBackToStageNumber:0];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedEmuButton:(UIButton *)sender
{
    [self restart];
}

- (IBAction)onPressedRestartButton:(UIButton *)sender
{
    [self restart];
}

@end
