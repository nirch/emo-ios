//
//  KBKeyButton.h
//  emu
//
//  Created by Aviv Wolf on 4/6/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KBKeyButton : UIButton

@property (nonatomic) BOOL strongKey;
@property (nonatomic) BOOL unmovingKey;

#pragma mark - UI States
-(void)released;

@end
