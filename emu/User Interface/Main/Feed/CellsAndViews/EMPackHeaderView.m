//
//  EMPackHeaderView.m
//  emu
//
//  Created by Aviv Wolf on 9/29/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMPackHeaderView.h"

@interface EMPackHeaderView()

@property (weak, nonatomic) IBOutlet UIButton *guiHeaderButton;
@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiPriceButton;
@property (weak, nonatomic) IBOutlet UIButton *guiHDButton;


@end

@implementation EMPackHeaderView

-(void)updateGUI
{
    self.guiLabel.text = self.label;
    self.guiHeaderButton.tag = self.sectionIndex;
    self.guiPriceButton.tag = self.sectionIndex;
    self.guiHDButton.tag = self.sectionIndex;
    self.guiHDButton.hidden = !self.hdAvailable;
    self.guiPriceButton.hidden = YES;
    
    if (self.hdProductValided && self.hdAvailable && !self.hdUnlocked) {
        // HD Product is available, validated and still locked.
        // Offer it for sale.
        self.guiPriceButton.hidden = NO;
        [self.guiPriceButton setTitle:self.hdPriceLabel forState:UIControlStateNormal];
    }
}

@end
