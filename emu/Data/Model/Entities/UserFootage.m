//
//  UserFootage.m
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "UserFootage.h"
#import "UserFootage+Logic.h"
#import <HomageSDKCore/HomageSDKCore.h>

@implementation UserFootage

-(NSMutableDictionary *)hcRenderInfoForHD:(BOOL)forHD
{
    NSMutableDictionary *layer = [NSMutableDictionary new];
    if (self.isCapturedVideoAvailable) {
        
        // Captured layers provided by HSDK video writer and persisted to a UserFootage object.
        layer[hcrSourceType] = hcrVideo;
        layer[hcrPath] = [self pathToUserVideo];
        layer[hcrDynamicMaskPath] = [self pathToUserDMaskVideo];
        
    } else if (self.isPNGSequenceAvailable) {
        
    } else if (self.isGIFAvailable) {
        
    }
    
    if ([layer count] > 0) {
        // Downsample if required.
        if (forHD == NO && self.isHD == YES) {
            // Downsample if required.
            layer[hcrDownSample] = @2;
        }
    }
    
    return layer;
}

-(NSURL *)urlToThumbImage
{
    return [NSURL fileURLWithPath:[self pathToUserThumb]];
}

@end
