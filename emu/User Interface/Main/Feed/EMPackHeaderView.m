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


@end

@implementation EMPackHeaderView

-(void)updateGUI
{
    self.guiLabel.text = self.label;
}

@end
