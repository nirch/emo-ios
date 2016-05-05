//
//  EMShareMethod.m
//  emu
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShare.h"
#import "EMDB.h"

@implementation EMShare

@synthesize view;
@synthesize viewController;
@synthesize delegate;
@synthesize info;
@synthesize extraCFG;
@synthesize objectToShare;
@synthesize shareOption;

-(id)init
{
    self = [super init];
    if (self) {
        self.requiresUserInput = NO;
        self.tempGIFRenderedForSharing = NO;
    }
    return self;
}


/**
 *  Make sure to call [super share] if you override 
 * this method in derived class.
 */
-(void)share{}
-(void)cancel{}
-(void)shareAnimatedGif{}
-(void)shareVideo{}
-(void)shareText{}
-(void)shareHTML{}

-(void)shareSelection
{
    switch (self.shareOption) {
        case emkShareOptionAnimatedGif:
            [self shareAnimatedGif];
            break;
            
        case emkShareOptionVideo:
            [self shareVideo];
            break;
            
        case emkShareText:
            [self shareText];
            break;
            
        case emkShareHTML:
            [self shareHTML];
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException
                        format:@"Unimplemented %@", NSStringFromSelector(_cmd)];
            break;
    }
}

-(void)cleanUp
{
    if ([self.objectToShare isKindOfClass:[Emuticon class]]) {
        Emuticon *emu = self.objectToShare;
        [emu cleanTempVideoResources];
    }
}

@end
