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

@property (nonatomic) BOOL cellSizeByHeight;
@property (nonatomic) BOOL onlyRenderedPackages;
@property (nonatomic) BOOL showMixedPackage;
@property (nonatomic) BOOL shouldAnimateScroll;
@property (nonatomic) BOOL scrollSelectedToCenter;

-(void)refresh;

-(BOOL)isEmpty;

-(void)selectThisPackage:(Package *)package;
-(void)selectThisPackage:(Package *)package highlightOnly:(BOOL)highlightOnly;

-(void)selectPackageAtIndex:(NSInteger)index;
-(void)selectPackageAtIndex:(NSInteger)index highlightOnly:(BOOL)highlightOnly;

-(void)selectPrevious;
-(void)selectNext;

@end
