//
//  EMRenderManager2.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
@class Emuticon;
@class EmuticonDef;
@class UserFootage;

// events

@interface EMRenderManager2 : NSObject

// TODO: (temp public) hide implementation. 
@property (nonatomic, readonly) dispatch_queue_t renderingQueue;


#pragma mark - Initialization
+(instancetype)sharedInstance;
+(instancetype)sh;

#pragma mark - Resume/Pause
-(void)resume;
-(void)pause;
-(void)clear;

#pragma mark - Enqueue render jobs
/**
 *
 *  @param emu          - An Emu Object that requires rendering.
 *  @param indexPath    - (optional) IndexPath
 *  @param userInfo     - (optional) extra info about the task.
 *  @param inHD         - Indicates if need to render the emu in HD.
 */
-(void)enqueueEmu:(Emuticon *)emu
        indexPath:(NSIndexPath *)indexPath
         userInfo:(NSDictionary *)userInfo
             inHD:(BOOL)inHD;

#pragma mark - Queue management
-(void)updatePriorities:(NSDictionary *)priorities;


#pragma mark - Quick Renders
/**
 *  Render a preview emu for a specific emuDef, with a given footage.
 *
 *  @param footage The user's footage object.
 *  @param emuDef  Emu definition.
 */
-(void)renderPreviewForFootage:(UserFootage *)footage
                    withEmuDef:(EmuticonDef *)emuDef;

/**
 *  Render video for a given emu in a background thread.
 *  Calls the passed success/failure blocks when done.
 *  (video rendering also posts progress notifications that can be subscribed to)
 */
-(void)renderVideoForEmu:(Emuticon *)emu
       requiresWaterMark:(BOOL)requiresWaterMark
         completionBlock:(void (^)(void))completionBlock
               failBlock:(void (^)(void))failBlock
                    inHD:(BOOL)inHD;


@end
