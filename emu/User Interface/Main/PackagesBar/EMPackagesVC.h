//
//  EMPackagesVC.h
//  emu
//
//  Created by Aviv Wolf on 3/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMPackageSelectionDelegate.h"

@interface EMPackagesVC : UIViewController

@property (nonatomic, weak) id<EMPackageSelectionDelegate> delegate;

-(void)refresh;
-(void)selectThisPackage:(Package *)package;
-(void)selectPackageAtIndex:(NSInteger)index;

-(BOOL)canSelectPrevious;
-(BOOL)canSelectNext;
-(void)selectPrevious;
-(void)selectNext;

@end
