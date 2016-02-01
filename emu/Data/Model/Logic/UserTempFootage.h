//
//  UserTempFootage.h
//  emu
//
//  Created by Aviv Wolf on 28/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FootageProtocol.h"

@interface UserTempFootage : NSObject<FootageProtocol>

+(UserTempFootage *)tempFootageWithInfo:(NSDictionary *)info;
-(instancetype)initWithInfo:(NSDictionary *)info;

@end
