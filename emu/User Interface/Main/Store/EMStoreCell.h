//
//  EMStoreCell.h
//  emu
//
//  Created by Aviv Wolf on 17/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Feature;

@interface EMStoreCell : UICollectionViewCell

-(void)updateWithIndexPath:(NSIndexPath *)indexPath;
-(void)updateWithFeature:(Feature *)feature;
-(void)updateWithItemInfo:(NSDictionary *)itemInfo;
-(void)updateGUI;

@end
