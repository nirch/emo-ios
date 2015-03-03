//
//  KeyboardViewController.m
//  Emu Keyboard
//
//  Created by Aviv Wolf on 3/1/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMKeyboardVC"

#import "EMKeyboardContainerVC.h"
#import "EMKeyboardVC.h"

@interface EMKeyboardContainerVC () <
    EMKeyboardContainerDelegate
>

@property (nonatomic, weak) EMKeyboardVC *keyboardVC;

@end

@implementation EMKeyboardContainerVC

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self embedKeyboardVC];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.keyboardVC.view.frame = self.view.bounds;
    [self.keyboardVC.view layoutIfNeeded];
}

-(void)embedKeyboardVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Keyboard" bundle:nil];
    EMKeyboardVC *keyboardVC = [storyboard instantiateInitialViewController];
    keyboardVC.view.frame = self.view.bounds;
    keyboardVC.delegate = self;
    [self addChildViewController:keyboardVC];
    [self.view addSubview:keyboardVC.view];
}

#pragma mark - EMKeyboardContainerDelegate
-(void)keyboardShouldAdadvanceToNextInputMode
{
    [self advanceToNextInputMode];
}

-(void)keyboardShouldDeleteBackward
{
    [self.textDocumentProxy deleteBackward];
}

@end
