//
//  KeyboardViewController.m
//  Emu Keyboard
//
//  Created by Aviv Wolf on 3/1/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define TAG @"EMKeyboardVC"

#import "EMKeyboardVC.h"
#import "EMDB.h"

@interface EMKeyboardVC ()

@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessError;
@property (weak, nonatomic) IBOutlet UILabel *guiFullAccessInstructions;

@property (nonatomic) BOOL isFullAccessGranted;

@end

@implementation EMKeyboardVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isFullAccessGranted = NO;
    [self initGUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self checkForFullAccess];
    [self updateGUI];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.isFullAccessGranted) {
        [self initData];
    }
}

#pragma mark - Initializations
-(void)initGUI
{
    // Load the UI from nib
    UINib *nib = [UINib nibWithNibName:@"EMKeyboard" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:self options:nil];
    self.view = views[0];
}

-(void)updateGUI
{
    // Full access error messages and instructions
    self.guiFullAccessError.hidden = self.isFullAccessGranted;
    self.guiFullAccessInstructions.hidden = self.isFullAccessGranted;
}

#pragma mark - Data
-(void)initData
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    Package *package = [appCFG packageForOnboarding];
    
//    HMLOG(TAG, <#level, ...#>)
}

#pragma mark - KB helpers
-(void)checkForFullAccess
{
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    if (pasteBoard == nil) self.isFullAccessGranted = NO;
    self.isFullAccessGranted = YES;
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNectKBButton:(id)sender
{
    [self advanceToNextInputMode];
}


@end
