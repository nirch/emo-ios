//
//  UIView+Heirarchy.h
//  emu
//
//  Created by Aviv Wolf on 04/11/2015.
//  Copyright © 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Heirarchy)

-(UIView *)viewFindAncestorOfKind:(Class)aClass;

@end
