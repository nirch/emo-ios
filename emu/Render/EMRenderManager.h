//
//  EMRenderManager.h
//  emu
//
//  Created by Aviv Wolf on 6/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

@class UserFootage;
@class EmuticonDef;
@class Emuticon;

@interface EMRenderManager : NSObject

#pragma mark - Initialization
+(EMRenderManager *)sharedInstance;
+(EMRenderManager *)sh;

#pragma mark - Managing rendering queues
/** 
 *  Put an emu on a prioritized queue for rendering.
 *  the emu may or may not already have the required resources locally on the device.
 *  If the emu doesn't have the required resources, the resources will be enqueued for download.
 *
 *  @param emu - The emu that requires rendering.
 *  @return info - extra information about the emu to be rendered. Will be posted back on state notification.
 */
-(void)enqueueEmuOID:(NSString *)emuOID withInfo:(NSDictionary *)info;

#pragma mark - A single render with completion blocks
/**
 *  Render video for a given emu in a background thread.
 *  Calls the passed success/failure blocks when done.
 *  (video rendering also posts progress notifications that can be subscribed to)
 */
-(void)renderVideoForEmu:(Emuticon *)emu
         completionBlock:(void (^)(void))completionBlock
               failBlock:(void (^)(void))failBlock;


/**
 *  Render a preview emu for a given footage.
 *  Used in the preview screen at the end of the recorder flow.
 *
 *  @param footage The footage used for rendering the preview.
 *  @param emuDef  Emuticon definition.
 */
-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef;

@end
