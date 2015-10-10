//
//  EMFootagesDataSource.h
//  emu
//
//  Created by Aviv Wolf on 10/10/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMFootagesDataSource : NSObject<
    UICollectionViewDataSource
>

#pragma mark - Selections
@property (nonatomic, readonly) NSIndexPath *selectedIndexPath;

-(void)selectIndexPath:(NSIndexPath *)indexPath
      inCollectionView:(UICollectionView *)collectionView;

-(NSString *)selectedFootageOID;

@end
