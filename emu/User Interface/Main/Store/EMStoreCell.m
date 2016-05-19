//
//  EMStoreCell.m
//  emu
//
//  Created by Aviv Wolf on 17/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMStoreCell.h"
#import "EMDB.h"

@interface EMStoreCell()

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *message;
@property (nonatomic) NSString *price;
@property (nonatomic) NSString *thumbName;
@property (nonatomic) BOOL wasUnlocked;

// UI
@property (weak, nonatomic) IBOutlet UIImageView *guiThumb;
@property (weak, nonatomic) IBOutlet UILabel *guiTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiBuyButton;
@property (weak, nonatomic) IBOutlet UILabel *guiMessage;
@property (weak, nonatomic) IBOutlet UILabel *guiPurchaseLabel;


@end

@implementation EMStoreCell

-(void)updateWithIndexPath:(NSIndexPath *)indexPath
{
    self.guiBuyButton.tag = indexPath.item;
}

-(void)updateWithItemInfo:(NSDictionary *)itemInfo
{
    self.title = itemInfo[@"productTitle"];
    self.price = itemInfo[@"priceLabel"];
    self.message = itemInfo[@"productDescription"];
    self.thumbName = itemInfo[@"thumbName"];
}

-(void)updateWithFeature:(Feature *)feature
{
    self.wasUnlocked = [feature wasUnlocked];
}

-(void)updateGUI
{
    [self resetCellGUI];
    
    self.guiThumb.image = [UIImage imageNamed:self.thumbName];
    self.guiTitleLabel.text = self.title?self.title:@"?";
    self.guiMessage.text = self.message?self.message:@"?";
    
    self.guiBuyButton.hidden = self.wasUnlocked;
    self.guiPurchaseLabel.text = self.wasUnlocked?LS(@"UNLOCKED"):self.price;
}

-(void)resetCellGUI
{
    self.guiThumb.image = nil;
    self.guiPurchaseLabel.text = @"?";
    self.guiBuyButton.hidden = YES;
    self.guiTitleLabel.text = @"";
    self.guiMessage.text = @"";    
}

@end
