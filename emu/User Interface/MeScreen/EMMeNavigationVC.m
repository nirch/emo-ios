//
//  EMMeNavigationVC.m
//  emu
//
//  Created by Aviv Wolf on 10/11/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMMeNavigationVC.h"

@interface EMMeNavigationVC ()

@end

@implementation EMMeNavigationVC


+(EMMeNavigationVC *)meNavigationVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Me" bundle:nil];
    EMMeNavigationVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"me navigation vc"];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


@end
