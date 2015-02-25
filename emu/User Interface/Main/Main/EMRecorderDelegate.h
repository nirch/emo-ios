//
//  EMRecorderDelegate.h
//  emu
//
//  Created by Aviv Wolf on 2/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMRecorderDelegate <NSObject>

-(void)recorderWantsToBeDismissedWithInfo:(NSDictionary *)info;

@end
