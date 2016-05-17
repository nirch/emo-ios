//
//  StoreVC.m
//  emu
//
//  Created by Aviv Wolf on 16/05/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EMStoreVC.h"

@interface EMStoreVC ()

@end

@implementation EMStoreVC


+(EMStoreVC *)storeVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Store" bundle:nil];
    EMStoreVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"store vc"];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
