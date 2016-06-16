//
//  NSNotificationCenter+Utils.m
//  Misc. Projects
//
//  Created by Aviv Wolf on 10/15/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

#import "NSNotificationCenter+Utils.h"

@implementation NSNotificationCenter (Utils)

-(void)addUniqueObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:aName object:anObject];
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:aName object:anObject];
}


@end
