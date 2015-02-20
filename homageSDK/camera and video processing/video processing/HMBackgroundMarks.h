//
//  HMBackgroundMarks.h
//  emu
//
//  Created by Aviv Wolf on 2/5/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@interface HMBackgroundMarks : NSObject

#pragma mark - Marks
/**
 *  Background detection marks.
 */
typedef NS_ENUM(NSInteger, HMBGMark){

    /**
     *  An unknown / new mark. 
     */
    HMBGMarkUnrecognized = -9999,

    /**
     *  Noisy background.
     *  A more uniform BG should be used.
     */
    HMBGMarkNoisy = -11,

    /**
     *  Very low light.
     *  User should shoot in well lit areas.
     */
    HMBGMarkDark = -10,

    /**
     *  User is out of the silhouette.
     */
    HMBGMarkSilhouette = -5,
    
    /**
     *  A shadow was detected behind the user.
     */
    HMBGMarkShadow = -4,
    
    /**
     *  The user's is wearing something that is too
     *  similar to the background.
     */
    HMBGMarkCloth = -2,
    
    /**
     *  Good uniform background. Hazah!
     */
    HMBGMarkGood = 1,
};

#pragma mark - Texts
/**
 *  Given a background mark, returns a key that can be used
 *  to retrieve a localized text title or message to the user.
 *
 *  @param mark HMBGMark of a background
 *
 *  @return An NSString key that can be used to get the related localized string.
 */
-(NSString *)textKeyForMark:(HMBGMark)mark;

/**
 *  Given a background mark, returns a key that can be used
 *  to retrieve a localized text title or message to the user.
 *  Given a keyPrefix, will add it to the returned key.
 *
 *  @param mark HMBGMark of a background
 *  @param keyPrefix Will add this prefix to the returned key.
 *
 *  @return An NSString key that can be used to get the related localized string.
 */
-(NSString *)textKeyForMark:(HMBGMark)mark keyPrefix:(NSString *)keyPrefix;

@end
