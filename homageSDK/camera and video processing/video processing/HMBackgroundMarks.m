//
//  HMBackgroundMarks.m
//  emu
//
//  Created by Aviv Wolf on 2/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMBackgroundMarks.h"

@interface HMBackgroundMarks()

@property (nonatomic) NSDictionary *bgMarksTexts;

@end

@implementation HMBackgroundMarks

-(id)init
{
    self = [super init];
    if (self) {
        
        // Initialize
        self.bgMarksTexts = @{
                              @(HMBGMarkNoisy):@"BGM_NOISY",
                              @(HMBGMarkDark):@"BGM_DARK",
                              @(HMBGMarkSilhouette):@"BGM_SILHOUETTE",
                              @(HMBGMarkShadow):@"BGM_SHADOW",
                              @(HMBGMarkCloth):@"BGM_CLOTH",
                              @(HMBGMarkUnrecognized):@"BGM_GENERAL_MESSAGE",
                              };

    }
    return self;
}

#pragma mark - Texts
-(NSString *)textKeyForMark:(HMBGMark)mark
{
    return [self textKeyForMark:mark keyPrefix:nil];
}

-(NSString *)textKeyForMark:(HMBGMark)mark keyPrefix:(NSString *)keyPrefix
{
    // Get the key from the marks to texts mapping.
    NSString *key = self.bgMarksTexts[@(mark)];
    
    // Just in case a mapping is missing for some reason.
    if (!key) key = self.bgMarksTexts[@(HMBGMarkUnrecognized)];
    
    // Add a prefix if requested.
    if (keyPrefix) {
        key = [NSString stringWithFormat:@"%@_%@", keyPrefix, key];
    }
    
    // Return the key that should be used for get localized strings.
    return key;
}

@end
