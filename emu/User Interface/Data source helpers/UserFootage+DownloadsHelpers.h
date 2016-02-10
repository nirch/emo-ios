//
//  UserFootage+DownloadsHelpers.h
//  emu
//
//  Created by Aviv Wolf on 10/7/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "UserFootage.h"

@interface UserFootage (DownloadsHelpers)

-(BOOL)enqueueIfMissingResourcesWithInfo:(NSDictionary *)info;

@end
