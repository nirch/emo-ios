//
//  EMShareProtocol.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

// Specific apps
typedef NS_ENUM(NSInteger, emShareMethod) {
    emShareMethodFacebook                              = 1000,
    emShareMethodWhatsapp                              = 2000,
    emShareMethodSaveToCameraRoll                      = 3000,
    emShareMethodMail                                  = 4000,
    emShareMethodCopy                                  = 5000,
    emShareMethodFacebookMessanger                     = 6000,
    emShareMethodAppleMessages                         = 7000,
};


@protocol EMShareProtocol <NSObject>

@end
