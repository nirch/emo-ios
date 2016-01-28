//
//  UserFootagePlaceHolder.h
//  emu
//
//  Created by Aviv Wolf on 27/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EMFootagePHType) {
    EMFootagePHTypeNeutral          = 0,
    EMFootagePHTypeNegative         = 1,
    EMFootagePHTypePositive         = 2
};



@interface UserFootagePlaceHolder : NSObject

@property (nonatomic) EMFootagePHType placeholderType;
@property (nonatomic) NSString *text;

@end
