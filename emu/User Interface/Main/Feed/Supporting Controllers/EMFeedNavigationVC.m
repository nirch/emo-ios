//
//  EMFeedNavigationVC.m
//  emu
//
//  Created by Aviv Wolf on 9/8/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMFeedNavigationVC.h"

@interface EMFeedNavigationVC ()

@end

@implementation EMFeedNavigationVC

+(EMFeedNavigationVC *)feedNavigationVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EMFeedNavigationVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"feed navigation vc"];
    return vc;
}

@end
