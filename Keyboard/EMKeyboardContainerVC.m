//
//  KeyboardViewController.m
//  Emu Keyboard
//
//  Created by Aviv Wolf on 3/1/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMKeyboardVC"

#import "EMKeyboardContainerVC.h"
#import "EMEmusKeyboardVC.h"

@interface EMKeyboardContainerVC () <
    EMKeyboardContainerDelegate
>

@property (nonatomic, weak) EMEmusKeyboardVC *emuKeyboardVC;

@property (nonatomic) NSLayoutConstraint *heightConstraint;

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

    self.emuKeyboardVC.view.frame = self.view.bounds;
    [self.emuKeyboardVC.view layoutIfNeeded];
}

-(void)embedKeyboardVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Keyboard" bundle:nil];
    EMEmusKeyboardVC *emusKeyboardVC = [storyboard instantiateInitialViewController];
    emusKeyboardVC.view.frame = self.view.bounds;
    emusKeyboardVC.delegate = self;
    [self addChildViewController:emusKeyboardVC];
    [self.view addSubview:emusKeyboardVC.view];
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

-(void)keyboardTypedString:(NSString *)typedString
{
    [self.textDocumentProxy insertText:typedString];
}

@end
