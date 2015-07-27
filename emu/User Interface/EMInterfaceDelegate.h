//
//  EMInterfaceDelegate.h
//  emu
//
//  Created by Aviv Wolf on 3/3/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMInterfaceDelegate <NSObject>

-(void)controlSentActionNamed:(NSString *)actionName
                         info:(NSDictionary *)info;

@end
