//
//  EMStoreDataSource.h
//  emu
//
//  Created by Aviv Wolf on 17/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMStoreDataSource : NSObject<UICollectionViewDataSource>

-(void)reloadData;
-(NSString *)productIdentifierAtIndex:(NSInteger)index;

@end
