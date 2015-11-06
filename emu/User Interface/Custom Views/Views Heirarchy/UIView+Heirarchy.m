//
//  UIView+Heirarchy.m
//  emu
//
//  Created by Aviv Wolf on 04/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "UIView+Heirarchy.h"

@implementation UIView (Heirarchy)

-(UIView *)viewFindAncestorOfKind:(Class)aClass
{
    UIView *v = self;
    while (![v isKindOfClass:aClass] && v != nil) {
        v = v.superview;
    }
    return v;
}

@end
