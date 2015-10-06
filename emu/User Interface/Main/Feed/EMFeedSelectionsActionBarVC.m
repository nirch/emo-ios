//
//  EMFeedSelectionsActionBarVC.m
//  emu
//
//  Created by Aviv Wolf on 10/5/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMFeedSelectionsActionBarVC.h"

@interface EMFeedSelectionsActionBarVC ()

@property (weak, nonatomic) IBOutlet UIView *guiBlurredBG;
@property (weak, nonatomic) IBOutlet UILabel *guiSelectedCountLabel;

@property (nonatomic) BOOL alreadyInitializedOnAppearance;

@end

@implementation EMFeedSelectionsActionBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.alreadyInitializedOnAppearance = NO;
    self.selectedCount = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    if (!self.alreadyInitializedOnAppearance) {
        //
        // Add blur effect to the background.
        //
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        
        UIVisualEffectView *visualEffectView;
        visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        visualEffectView.frame = self.guiBlurredBG.bounds;
        [self.guiBlurredBG addSubview:visualEffectView];
        
        self.alreadyInitializedOnAppearance = YES;
    }
}

#pragma mark - Selections count
-(void)setSelectedCount:(NSInteger)value
{
    _selectedCount = value;
    self.guiSelectedCountLabel.text = [SF:LS(@"SELECTED_COUNT"),@(value)];
}

@end
