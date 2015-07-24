//
//  EMRenderManager.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
@class Emuticon;

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

#pragma mark - Enqueue render jobs
/**
 *  <#Description#>
 *
 *  @param emu          - An Emu Object that requires rendering.
 *  @param indexPath    - (optional) IndexPath
 *  @param userInfo     - (optional) extra info about the task.
 */
-(void)enqueueEmu:(Emuticon *)emu
        indexPath:(NSIndexPath *)indexPath
         userInfo:(NSDictionary *)userInfo;

#pragma mark - Queue management
-(void)updatePriorities:(NSDictionary *)priorities;

@end
