//
//  EMPackageSelectionDelegate.h
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class Package;

#import <Foundation/Foundation.h>

@protocol EMPackageSelectionDelegate <NSObject>

-(void)packageWasSelected:(Package *)package;
-(void)packagesAvailableCount:(NSInteger)numberOfPackages;

@end
