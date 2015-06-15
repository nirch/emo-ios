//
//  EMFeedDataSource.h
//  emu
//
//  Created by Aviv Wolf on 6/11/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@import CoreData;

@interface EMFeedDataSource : NSObject<
    UICollectionViewDataSource,
    NSFetchedResultsControllerDelegate
>

@property (nonatomic, weak) UICollectionView *collectionView;

-(void)refreshData;
-(void)reloadLocalData;

@end
