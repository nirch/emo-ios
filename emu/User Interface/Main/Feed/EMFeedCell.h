//
//  EMFeedCell.h
//  emu
//
//  Created by Aviv Wolf on 6/12/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class Emuticon;

#import <UIKit/UIKit.h>


@interface EMFeedCell : UICollectionViewCell

-(void)updateCellForEmu:(Emuticon *)emu info:(NSDictionary *)info;

@end
