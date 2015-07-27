//
//  EMKBOptionsDrawer.m
//  emu
//
//  Created by Aviv Wolf on 7/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMKBOptionsDrawer.h"
#import "EMDB.h"

@interface EMKBOptionsDrawer ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *guiRenderingTypeSelector;


@end

@implementation EMKBOptionsDrawer

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initLocalization];
}

-(void)initLocalization
{
    [self.guiRenderingTypeSelector setTitle:LS(@"ANIM_GIF") forSegmentAtIndex:0];
    [self.guiRenderingTypeSelector setTitle:LS(@"VIDEO") forSegmentAtIndex:1];
}


-(void)initializeState
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    EMMediaDataType predderedRenderingType = appCFG.userPrefferedShareType.integerValue;
    self.guiRenderingTypeSelector.selectedSegmentIndex = predderedRenderingType==EMMediaDataTypeGIF?EMMediaDataTypeGIF:EMMediaDataTypeVideo;

}

-(NSInteger)prefferedRenderMediaType
{
    EMMediaDataType prefferedRenderingType = self.guiRenderingTypeSelector.selectedSegmentIndex == EMMediaDataTypeGIF?EMMediaDataTypeGIF:EMMediaDataTypeVideo;
    return prefferedRenderingType;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPrefferedRenderTypeChanged:(UISegmentedControl *)sender
{
    AppCFG *appCFG = [AppCFG cfgInContext:EMDB.sh.context];
    EMMediaDataType prefferedRenderingType = sender.selectedSegmentIndex == EMMediaDataTypeGIF?EMMediaDataTypeGIF:EMMediaDataTypeVideo;
    appCFG.userPrefferedShareType = @(prefferedRenderingType);
    [EMDB.sh save];
}

- (IBAction)onPressedOKButton:(id)sender
{
    [self.delegate controlSentActionNamed:@"ok" info:nil];
}

- (IBAction)onPressedTutorialMessage:(id)sender
{
    [self.delegate controlSentActionNamed:@"show whatsapp tutorial" info:nil];
}

@end
