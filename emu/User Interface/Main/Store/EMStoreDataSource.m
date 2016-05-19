//
//  EMStoreDataSource.m
//  emu
//
//  Created by Aviv Wolf on 17/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMStoreDataSource.h"
#import "EMStoreCell.h"
#import "EMBackend+AppStore.h"
#import "EMDB.h"

@interface EMStoreDataSource()

@property (nonatomic) NSMutableArray *validProducts;

@end

@implementation EMStoreDataSource

-(void)reloadData
{
    self.validProducts = [NSMutableArray new];
    
    // Get info all validated items (in correct order)
    for (NSString *pid in EMBackend.sh.productsOrderedPID) {
        NSDictionary *info = EMBackend.sh.productsInfo[pid];
        if (info == nil) continue;
        if (![info[@"valid"] isEqualToNumber:@YES]) continue;
        [self.validProducts addObject:info];
    }
}

-(NSString *)productIdentifierAtIndex:(NSInteger)index
{
    if (index<self.validProducts.count) {
        NSDictionary *info = self.validProducts[index];
        return info[@"pid"];
    }
    return nil;
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.validProducts.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"store cell";
    EMStoreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSDictionary *itemInfo = [self itemInfoForIndexPath:indexPath];
    Feature *relatedFeature = [Feature findWithOID:itemInfo[@"related_feature_oid"] context:EMDB.sh.context];
    [cell updateWithIndexPath:indexPath];
    [cell updateWithItemInfo:itemInfo];
    [cell updateWithFeature:relatedFeature];
    [cell updateGUI];
    return cell;
}

-(NSDictionary *)itemInfoForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= self.validProducts.count) return nil;
    return self.validProducts[indexPath.item];
}

@end
