//
//  EMFeaturedPacksVC.m
//  emu
//
//  Created by Aviv Wolf on 05/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMFeaturedPacksVC.h"
#import "EMFeaturedCell.h"
#import "EMDB.h"
#import <iCarousel.h>
#import "EMUINotifications.h"
#import "EMNotificationCenter.h"


@interface EMFeaturedPacksVC ()<
    iCarouselDataSource,
    iCarouselDelegate
>

@property (weak) iCarousel *guiCarousel;
@property (nonatomic) BOOL guiAlreadyInitializedOnAppearance;
@property (nonatomic) NSArray *featuredData;
@property (nonatomic) CGRect posterFrame;

@end

@implementation EMFeaturedPacksVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initGUIOnAppearance];
    [self initObservers];
    
    self.guiCarousel.userInteractionEnabled = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

-(void)initGUIOnAppearance
{
    if (!self.guiAlreadyInitializedOnAppearance) {
        self.guiAlreadyInitializedOnAppearance = YES;
        
        [self refreshLocalData];
        iCarousel *carousel = [[iCarousel alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:carousel];
        carousel.dataSource = self;
        carousel.delegate = self;
        carousel.type = iCarouselTypeInvertedCylinder;
        [carousel reloadData];
        self.guiCarousel = carousel;
        
        CGSize size = CGSizeMake(self.view.bounds.size.width * 0.65,0);
        size.height = size.width * 0.5714f;
        self.posterFrame = CGRectMake(0, 0, size.width, size.height);
    } else {
        [self refreshLocalData];
        [self.guiCarousel reloadData];
    }
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On packages data refresh required.
    [nc addUniqueObserver:self
                 selector:@selector(onUpdatedData:)
                     name:emkDataUpdatedPackages
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:emkDataUpdatedPackages];
}

#pragma mark - Observers handlers
-(void)onUpdatedData:(NSNotification *)notification
{
    [self refreshLocalData];
    [self.guiCarousel reloadData];
}

#pragma mark - Data
-(void)refreshLocalData
{
    // Initialize the data
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_PACKAGE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@ AND isFeatured=%@ AND (isHidden=nil OR isHidden=%@)", @YES, @YES, @NO];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"oid" ascending:YES]];
    NSArray *packs = [EMDB.sh.context executeFetchRequest:fetchRequest error:nil];
    
    // Get the info about the packs
    NSMutableArray *data = [NSMutableArray new];
    for (Package *pack in packs) {
        if (pack.posterName == nil || pack.label == nil) continue;
        
        // Gather the info
        HMParams *params = [HMParams new];
        [params addKey:@"posterURL" valueIfNotNil:[pack urlForPackagePoster]];
        [params addKey:@"thumbForAnimatedPosterURL" valueIfNotNil:[pack urlForAnimatedPosterThumb]];
        [params addKey:@"posterOverlayURL" valueIfNotNil:[pack urlForPackagePosterOverlay]];
        [params addKey:@"debugLabel" valueIfNotNil:[pack urlForPackagePoster]];
        [params addKey:@"packOID" valueIfNotNil:pack.oid];
        [params addKey:@"packLabel" valueIfNotNil:pack.label];
        [params addKey:emkPackageOID valueIfNotNil:pack.oid];
        [params addKey:@"packName" valueIfNotNil:pack.name];
        [data addObject:params.dictionary];
    }
    self.featuredData = data;
}


#pragma mark - iCarouselDataSource
-(NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    NSInteger count = [self.featuredData count];
    return count;
}

-(UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    EMFeaturedCell *cell = (EMFeaturedCell *)view;
    if (cell == nil) {
        cell = [[EMFeaturedCell alloc] initWithFrame:self.posterFrame];
    }
    
    // Get the info
    NSDictionary *info = self.featuredData[index];
    
    // Configure the cell using info about the pack
    cell.posterURL = info[@"posterURL"];
    cell.animatedPosterThumbURL = info[@"thumbForAnimatedPosterURL"];
    cell.posterOverlayURL = info[@"posterOverlayURL"];
    cell.debugLabel = [info[@"debugLabel"] description];
    cell.label = info[@"packLabel"];
    cell.name = info[@"packName"];
    
    // Update the cell UI
    [cell updateGUI];
    
    return cell;
}

#pragma mark - iCarouselDelegate
-(CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing) {
        return 1.1;
    }
    return value;
}

-(void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    __weak EMFeaturedPacksVC *wSelf = self;
    if (index == carousel.currentItemIndex) {
        carousel.userInteractionEnabled = NO;
        EMFeaturedCell *cell = (EMFeaturedCell *)[carousel itemViewAtIndex:index];
        [cell tappedWithCompletionBlock:^{
            [wSelf navigateToPackAtIndex:index];
        }];
    }
}

-(void)navigateToPackAtIndex:(NSInteger)index
{
    NSDictionary *info = self.featuredData[index];
    self.guiCarousel.userInteractionEnabled = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:emkUIUserSelectedPack
                                                        object:self
                                                      userInfo:info];
}

@end
