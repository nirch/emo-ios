//
//  PlaceHolderFootage.m
//  emu
//
//  Created by Aviv Wolf on 28/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "PlaceHolderFootage.h"
#import <HomageSDKCore/HomageSDKCore.h>
#import "EMDB.h"

@implementation PlaceHolderFootage

-(NSMutableDictionary *)hcRenderInfoForHD:(BOOL)forHD emuDef:(EmuticonDef *)emuDef
{
    NSMutableDictionary *layer = [NSMutableDictionary new];
    layer[hcrSourceType] = hcrPNG;

    NSString *sizeUsed=@"240";
    if (emuDef.assumedUsersLayersWidth) {
        if (emuDef.assumedUsersLayersWidth.integerValue == 480) {
            sizeUsed = @"480";
        }
    }
    
    NSString *resourceName;
    switch (self.status) {
        case PlaceHolderFootageStatusPositive:
            resourceName = [SF:@"placeholderPositive%@.png", sizeUsed];
            break;
        case PlaceHolderFootageStatusNegative:
            resourceName = [SF:@"placeholderNegative%@.png", sizeUsed];
            break;
        default:
            resourceName = [SF:@"placeholder%@.png", sizeUsed];
    }
    
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
