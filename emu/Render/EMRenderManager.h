//
//  EMRenderManager.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class UserFootage;
@class EmuticonDef;
@class Emuticon;

@interface EMRenderManager : NSObject

#pragma mark - Initialization
+(EMRenderManager *)sharedInstance;
+(EMRenderManager *)sh;

@property (atomic) NSString *prioritizedPackageOID;

#pragma mark - Rendering
/**
 *  Inform the rendering manager that an emu requires rendering.
 *
 *  @param emu  The emuticon that reqires rendering.
 *  @param info More info about the required rendering.
 */
-(void)renderingRequiredForEmu:(Emuticon *)emu
                          info:(NSDictionary *)info;


/**
 *  Render a preview emu for a given footage. 
 *  Used in the preview screen at the end of the recorder flow.
 *
 *  @param footage The footage used for rendering the preview.
 *  @param emuDef  Emuticon definition.
 */
-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef;


/**
 *  Enqueue the actual rendering on the IO background thread.
 *
 *  @param emu  The emuticon to render.
 *  @param info More info about the render.
 */
-(void)enqueueEmu:(Emuticon *)emu
             info:(NSDictionary *)info;


@end
