//
//  HMRecordButton.m
//  emo
//
//  Created by Aviv Wolf on 1/28/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMRecordButton.h"
#import "EmoStyleKit.h"

@implementation EMRecordButton

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)initialize
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect {
    [EmoStyleKit drawRecorderRecordButton];
}

@end
