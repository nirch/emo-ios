//
//  EMPacksDataSource.h
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

@import UIKit;

@interface EMPacksDataSource : NSObject<
    UICollectionViewDataSource
>

/**
 *  Returns an indexpath of a pack with the provided pack oid.
 *
 *  @param packOID The pack oid to look for.
 *
 *  @return NSIndexPath of the pack if found (nil otherwise).
 */
-(NSIndexPath *)indexPathByPackOID:(NSString *)packOID;


#pragma mark - Public info about the data
@property (nonatomic, readonly) NSInteger packsCount;
@property (nonatomic, readonly) NSInteger lastWidePack;

/**
 *  Returns the pack oid related to the passed index path.
 *
 *  @param indexPath Index path of the wanted pack.
 *
 *  @return The oid of the pack at index path (nil if not found).
 */
-(NSString *)packOIDByIndexPath:(NSIndexPath *)indexPath;

/**
 *  Resets the data source.
 */
-(void)reset;

@end
