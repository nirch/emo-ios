//
//  EMImageInspector.h
//  emu
//
//  Created by Aviv Wolf on 6/15/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface EMImageInspector : NSObject

-(instancetype)initWithImage:(UIImage *)image;

-(UIColor *)colorAtPointArr:(NSArray *)pointArr;
-(UIColor *)colorAtPoint:(CGPoint)point;

@end
