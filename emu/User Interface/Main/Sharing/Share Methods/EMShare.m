//
//  EMShareMethod.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShare.h"

@implementation EMShare

@synthesize view;
@synthesize viewController;
@synthesize delegate;
@synthesize info;
@synthesize objectToShare;
@synthesize shareOption;

/**
 *  Make sure to call [super share] if you override 
 * this method in derived class.
 */
-(void)share{}
-(void)cancel{}
-(void)shareAnimatedGif{}
-(void)shareVideo{}

-(void)selectWhatToShare
{
    UIAlertController *alert = [UIAlertController new];
    alert.title = self.selectionTitle;
    alert.message = self.selectionMessage;
    
    // Animated gif
    UIAlertAction *asAnimatedGif = [UIAlertAction actionWithTitle:LS(@"ANIM_GIF")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self shareAnimatedGif];
                                                          }];
    [alert addAction:asAnimatedGif];
    
    // Video
    UIAlertAction *asVideo = [UIAlertAction actionWithTitle:LS(@"VIDEO")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                        [self shareVideo];
                                                    }];
    [alert addAction:asVideo];
    
    // Cancel
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:LS(@"CANCEL")
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action) {
                                                       [self cancel];
                                                   }];
    [alert addAction:cancel];
    [self.viewController presentViewController:alert
                                      animated:YES
                                    completion:nil];
}

-(void)shareSelection
{
    switch (self.shareOption) {
        case emkShareOptionAnimatedGif:
            [self shareAnimatedGif];
            break;
            
        case emkShareOptionVideo:
            [self shareVideo];
            break;
            
        case emkShareOptionBoth:
            [self selectWhatToShare];
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException
                        format:@"Unimplemented %@", NSStringFromSelector(_cmd)];
            break;
    }
}


@end
