//
//  PlaceHolderFootage.h
//  emu
//
//  Created by Aviv Wolf on 28/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FootageProtocol.h"


/**
 *  Place holder footage states.
 */
typedef NS_ENUM(NSInteger, PlaceHolderFootageStatus) {
    /**
     *  Neutral state - will show the placeholder with a blue stroke, indicating that it is waiting user's actions.
     */
    PlaceHolderFootageStatusNeutral = 0,
    /**
     *  Negative state - will show the placeholder with a reddish stroke, indicating that footage was declined, failed etc.
     */
    PlaceHolderFootageStatusNegative = 1,
    /**
     *  Positive state - will show the placeholder with a green stroke, indicating that a user was invited etc.
     */
    PlaceHolderFootageStatusPositive = 2
};

@interface PlaceHolderFootage : NSObject<FootageProtocol>

@property (nonatomic) PlaceHolderFootageStatus status;
@property (nonatomic) NSString *label;

@end
