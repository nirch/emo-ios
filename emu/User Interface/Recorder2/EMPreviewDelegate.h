//
//  EMPreviewDelegate.h
//  emu
//
//  Created by Aviv Wolf on 13/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMPreviewDelegate <NSObject>

-(void)previewIsShownWithInfo:(NSDictionary *)info;
-(void)previewDidFailWithInfo:(NSDictionary *)info;

@end
