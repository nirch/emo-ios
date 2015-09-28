//
//  EMTopVCProtocol.h
//  emu
//
//  Created by Aviv Wolf on 9/28/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMTopVCProtocol <NSObject>

/**
 *  Inform the view controller that it was selected by the user and about
 *  to appear on the user's screen.
 *  Good place to start refreshing data and/or handle state/flow.
 */
-(void)vcWasSelected;


@end
