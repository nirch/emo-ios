//
//  EMShare.h
//  emu
//
//  Don't use this class directly. Implement subclasses to this class.
//
//  Created by Aviv Wolf on 2/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMShareProtocol.h"
#import "EMDB.h"

@interface EMShare : NSObject<
    EMShareProtocol
>

/**
 *  Make sure to call [super share] if you override
 *  this method in derived class.
 */
-(void)share;

@property (nonatomic) NSString *selectionTitle;
@property (nonatomic) NSString *selectionMessage;

-(void)shareSelection;

-(void)shareAnimatedGif;
-(void)shareVideo;
-(void)shareText;
-(void)shareHTML;

-(void)cancel;

@end
