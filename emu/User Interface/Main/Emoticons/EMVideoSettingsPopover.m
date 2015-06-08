//
//  EMVideoSettingsPopover.m
//  emu
//
//  Created by Aviv Wolf on 6/2/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMVideoSettingsPopover.h"
#import "EMDB.h"

@interface EMVideoSettingsPopover () 

@property (weak, nonatomic) IBOutlet UISegmentedControl *guiLoopTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *guiLoopCountLabel;
@property (weak, nonatomic) IBOutlet UISlider *guiLoopCountSlider;



@end

@implementation EMVideoSettingsPopover

- (instancetype)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationPopover;
        self.popoverPresentationController.delegate = self;
    }
    return self;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone; //You have to specify this particular value in order to make it work on iPhone.
}

#pragma mark - VC lifecycle
-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUI];
}


#pragma mark - updates
-(void)updateUI
{
    // Loop effect
    NSNumber *loopFX = self.emu.videoLoopsEffect? self.emu.videoLoopsEffect:@0;
    if (loopFX.integerValue==0) {
        self.guiLoopTypeSegmentedControl.selectedSegmentIndex = 0;
    } else {
        self.guiLoopTypeSegmentedControl.selectedSegmentIndex = 1;
    }
    
    // Loop count
    NSInteger loopCount = self.emu.videoLoopsCount?self.emu.videoLoopsCount.integerValue:EMU_DEFAULT_VIDEO_LOOPS_COUNT;
    if (loopCount==0) loopCount = EMU_DEFAULT_VIDEO_LOOPS_COUNT;
    self.guiLoopCountSlider.value = loopCount;
    NSString *numberString = [SF:@"%@", @(loopCount)];
    self.guiLoopCountLabel.text = [LS(@"N_TIMES") stringByReplacingOccurrencesOfString:@"#" withString:numberString];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onLoopFXValueChanged:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        self.emu.videoLoopsEffect = nil;
    } else {
        self.emu.videoLoopsEffect = @1;
    }
    [self updateUI];
}

- (IBAction)onLoopCountSliderValueChanged:(UISlider *)sender
{
    NSInteger val = sender.value;
    if (val == EMU_DEFAULT_VIDEO_LOOPS_COUNT) {
        self.emu.videoLoopsCount = nil;
    } else {
        self.emu.videoLoopsCount = @(val);
    }
    [self updateUI];
}


@end
