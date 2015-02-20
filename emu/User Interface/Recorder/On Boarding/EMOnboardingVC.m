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

-(void)initContent
{
    self.shownIndex = 0;
    self.textsKeys = @[@"ONBOARDING_TITLE_0_WELCOME",
                       @"ONBOARDING_TITLE_1_ALIGN",
                       @"ONBOARDING_TITLE_2_EXTRACTION_PREVIEW",
                       @"ONBOARDING_TITLE_3_COUNTING_DOWN",
                       @"ONBOARDING_TITLE_4_RECORDING",
                       @"ONBOARDING_TITLE_5_DONE"
                       ];
    
    self.subTextsKeys = @[[NSNull null],
                          @"ONBOARDING_MSG_1_ALIGN",
                          @"ONBOARDING_MSG_2_EXTRACTION_PREVIEW",
                          [NSNull null],
                          [NSNull null],
                          [NSNull null]
                          ];
}

-(void)initGUI
{
    //self.guiStageIndicator.numberOfPages = EMOB_STAGES;
    self.guiPagerView.pagesCount = EMOB_STAGES;
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

    NSString *subTextKey = self.subTextsKeys[indexPath.item];
    cell.guiSubLabel.text = nil;
    cell.guiSubLabel.alpha = 0;
    
    if (!isNSNull(subTextKey)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.7 animations:^{
                cell.guiSubLabel.text = LS(subTextKey);
                cell.guiSubLabel.alpha = 1;
                [cell layoutIfNeeded];
            }];
        });
    } else {
        cell.guiSubLabel.text = nil;
    }
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
    self.guiPagerView.currentPage = index;
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

@end
