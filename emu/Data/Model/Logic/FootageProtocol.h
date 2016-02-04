//
//  FootageProtocol.h
//  emu
//
//  Created by Aviv Wolf on 28/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FootageProtocol <NSObject>

-(NSMutableDictionary *)hcRenderInfoForHD:(BOOL)forHD;
-(NSURL *)urlToThumbImage;

@end
