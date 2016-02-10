//
//  PlaceHolderFootage.m
//  emu
//
//  Created by Aviv Wolf on 28/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "PlaceHolderFootage.h"
#import <HomageSDKCore/HomageSDKCore.h>

@implementation PlaceHolderFootage

-(NSMutableDictionary *)hcRenderInfoForHD:(BOOL)forHD
{
    NSMutableDictionary *layer = [NSMutableDictionary new];
    layer[hcrSourceType] = hcrPNG;
    
    NSString *resourceName = [NSString stringWithFormat:@"placeholder%@.png", forHD?@"480":@"240"];
    layer[hcrResourceName] = resourceName;
    
    return layer;
}

-(NSURL *)urlToThumbImage
{
    return nil;
}

-(BOOL)isAvailable
{
    return YES;
}

@end
