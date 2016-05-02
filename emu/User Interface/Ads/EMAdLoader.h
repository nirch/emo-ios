//
//  EMAdLoader.h
//  emu
//
//  Created by Aviv Wolf on 27/04/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMAdLoader : NSObject

-(void)createOrRefreshInContainer:(UIView *)containerView containerVC:(UIViewController *)containerVC;

@end
