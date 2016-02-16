//
//  FootageProtocol.h
//  emu
//
//  Created by Aviv Wolf on 28/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EmuticonDef;

@protocol FootageProtocol <NSObject>

-(NSURL *)urlToThumbImage;
-(BOOL)isAvailable;

#pragma mark - HCRender
-(NSMutableDictionary *)hcRenderInfoForHD:(BOOL)forHD emuDef:(EmuticonDef *)emuDef;
-(NSDictionary *)updateSourceLayerInfo:(NSDictionary *)layer;

@end
