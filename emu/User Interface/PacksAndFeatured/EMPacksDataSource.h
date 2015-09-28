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

@property (nonatomic, readonly) NSInteger packsCount;
@property (nonatomic, readonly) NSInteger lastWidePack;

-(void)reset;

@end
