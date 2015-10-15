//
//  EMEmuticonScreen.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMEmuticonScreenVC : UIViewController

+(EMEmuticonScreenVC *)emuticonScreenForEmuticonOID:(NSString *)emuticonOID;

@property (nonatomic) NSString *emuticonOID;
@property (nonatomic) UIColor *themeColor;
@property (nonatomic) NSString *originUI;

@end
