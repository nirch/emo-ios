//
//  EmuticonDef+DownloadsHelpers.h
//  emu
//
//  Created by Aviv Wolf on 18/04/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "EmuticonDef.h"

@interface EmuticonDef (DownloadsHelpers)

-(BOOL)enqueueIfMissingResourcesWithInfo:(NSDictionary *)info;
-(BOOL)enqueueIfMissingFullRenderResourcesWithInfo:(NSDictionary *)info;

@end
