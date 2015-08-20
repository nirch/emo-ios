//
//  EMShareInputViewController.m
//  emu
//
//  Created by Aviv Wolf on 8/18/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShareInputVC.h"
#import "EMFlowButton.h"

@interface EMShareInputVC () <
    UITextViewDelegate
>

@property (weak, nonatomic) IBOutlet UIView *guiTitleBar;

@property (weak, nonatomic) IBOutlet EMFlowButton *guiCancelButton;
@property (weak, nonatomic) IBOutlet EMFlowButton *guiShareButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiTitleImage;
@property (weak, nonatomic) IBOutlet UITextView *guiTextInputView;
@property (weak, nonatomic) IBOutlet UIImageView *guiSharedMediaIcon;



@property (weak, nonatomic) UIView *darkBackView;
@property (weak, nonatomic) UIViewController *parentVC;

@property (nonatomic) BOOL alreadyInitialized;

@end

@implementation EMShareInputVC

+(EMShareInputVC *)shareInputVCInParentVC:(UIViewController *)parentVC
{
    EMShareInputVC *vc = [[EMShareInputVC alloc] initWithNibName:@"EMShareInputBox" bundle:nil];
    vc.parentVC = parentVC;

    // Add a backview with blur effect
    UIView *darkBackView = [[UIView alloc] initWithFrame:parentVC.view.bounds];
    darkBackView.backgroundColor = [UIColor whiteColor];
    [parentVC.view addSubview:darkBackView];
    vc.darkBackView = darkBackView;
    
    // Add the popup view
    CGFloat width = parentVC.view.bounds.size.width - 20;
    CGRect frame = CGRectMake(0, 0, width, 240);
    vc.view.frame = frame;
    
    vc.view.center = parentVC.view.center;
    [parentVC.view addSubview:vc.view];
    [parentVC addChildViewController:vc];
    [vc hideAnimated:NO];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.guiCancelButton.positive = NO;
    self.guiShareButton.positive = YES;
    self.guiTextInputView.delegate = self;
    self.alreadyInitialized = NO;
    self.guiTextInputView.text = @"";
}

-(void)updateUI
{
    if (self.alreadyInitialized == NO) {
        // Add shadow to the popup
        CALayer *layer = self.view.layer;
        layer.shadowRadius = 20;
        layer.shadowOpacity = 0.4;
        layer.shadowOffset = CGSizeMake(0, -30);
        layer.shadowColor = [UIColor blackColor].CGColor;
        layer.shadowPath = [UIBezierPath bezierPathWithRect:layer.bounds].CGPath;
    }

    if (self.titleColor == nil) self.titleColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    self.guiTitleBar.backgroundColor = self.titleColor;
    self.guiTitleImage.image = self.titleIcon;
    self.guiSharedMediaIcon.image = self.sharedMediaIcon;
    if (self.defaultHashTags) self.guiTextInputView.text = [NSString stringWithFormat:@"\n\n%@", self.defaultHashTags];
    self.alreadyInitialized = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initObservers];
}

-(void)cleanup
{
    [self removeObservers];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [self.darkBackView removeFromSuperview];
}

-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // On packages data refresh required.
    [nc addUniqueObserver:self
                 selector:@selector(onKeyboardShown:)
                     name:UIKeyboardDidShowNotification
                   object:nil];
}

-(void)removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:UIKeyboardDidChangeFrameNotification];
}

#pragma mark - Observers handlers
-(void)onKeyboardShown:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    CGRect kbFrame;
    [info[UIKeyboardFrameEndUserInfoKey] getValue:&kbFrame];
    CGFloat kbHeight = kbFrame.size.height;
    CGFloat viewHeight = self.parentVC.view.bounds.size.height;
    
    [UIView animateWithDuration:0.4 animations:^{
        CGPoint newCenter = self.parentVC.view.center;
        newCenter.y = (viewHeight - kbHeight) / 2.0f;
        self.view.center = newCenter;
    }];
}


#pragma mark - Show/Hide
-(void)showAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.7
                              delay:0
             usingSpringWithDamping:0.44
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self showAnimated:NO];
                         } completion:nil];
        return;
    }
    self.view.transform = CGAffineTransformIdentity;
    self.darkBackView.alpha = 0.7;
    self.view.alpha = 1;
}


-(void)hideAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self hideAnimated:NO];
        }];
        return;
    }
    self.view.alpha = 0;
    self.view.transform = CGAffineTransformMakeScale(1.1, 0.3);
    self.darkBackView.alpha = 0.0;
}

#pragma mark - UITextViewDelegate
-(void)textViewDidBeginEditing:(UITextView *)textView
{
    
}

-(NSString *)validatedText
{
    return self.guiTextInputView.text;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedCancel:(UIButton *)sender
{
    [self hideAnimated:YES];
    dispatch_after(DTIME(0.3), dispatch_get_main_queue(), ^{
        [self cleanup];
    });
    [self.delegate shareInputWasCanceled];
}

- (IBAction)onPressedShare:(UIButton *)sender
{
    [self hideAnimated:YES];
    dispatch_after(DTIME(0.3), dispatch_get_main_queue(), ^{
        [self cleanup];
    });
    NSString *validatedText = [self validatedText];
    [self.delegate shareInputWasConfirmedWithText:validatedText];
}

@end
