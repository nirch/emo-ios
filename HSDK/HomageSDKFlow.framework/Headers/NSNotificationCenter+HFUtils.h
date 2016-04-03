//
//  NSNotificationCenter+HFUtils.h
//  Misc. Projects
//
//  Created by Aviv Wolf on 10/15/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  Utils category on NSNotificationCenter. Used to add unique observers (so no duplicate observers will be added for the same notification name)
 */
@interface NSNotificationCenter (HFUtils)

/**
 Adds an observer.
 If such an observer already exists,
 will remove the existing one before adding the new one.

 @param observer The observer
 @param selector The selector
 @param name     Name of the notification to observe
 @param object   The related object
*/
-(void)addUniqueObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;


@end
