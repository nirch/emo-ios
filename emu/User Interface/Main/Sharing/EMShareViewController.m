//
//  EMShareViewController.m
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShareViewController.h"
#import "EMShareProtocol.h"

@interface EMShareViewController ()

@property (nonatomic) NSArray *shareMethods;
@property (nonatomic) NSDictionary *shareIcons;

@end

@implementation EMShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
}

-(void)initData
{
    // A priorized list of share methods.
    self.shareMethods = @[
                          EMK_SHARE_APPLE_MESSAGES,
                          EMK_SHARE_WHATSAPP,
                          EMK_SHARE_FACEBOOK_MESSANGER,
                          EMK_SHARE_FACEBOOK,
                          EMK_SHARE_MAIL,
                          EMK_SHARE_SAVE_TO_CR,
                          EMK_SHARE_COPY
                          ];
    
    self.shareIcons = @{
                        EMK_SHARE_APPLE_MESSAGES:@"iMessage",
                        EMK_SHARE_WHATSAPP:@"whatsapp",
                        EMK_SHARE_FACEBOOK_MESSANGER:@"facebookm",
                        EMK_SHARE_FACEBOOK:@"facebook",
                        EMK_SHARE_MAIL:@"mail",
                        EMK_SHARE_SAVE_TO_CR:@"savetocm",
                        EMK_SHARE_COPY:@"copy"
                        };
}

@end
