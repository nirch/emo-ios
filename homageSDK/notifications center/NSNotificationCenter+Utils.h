//
//  NSNotificationCenter+Utils.h
//  Misc. Projects
//
//  Created by Aviv Wolf on 10/15/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

@interface NSNotificationCenter (Utils)

/** Adds an observer.
    If such an observer already exists, 
    will remove the existing one before adding the new one.
 */
-(void)addUniqueObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;


@end
