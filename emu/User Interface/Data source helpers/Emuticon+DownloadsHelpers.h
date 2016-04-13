//
//  Emuticon+DownloadsHelpers.h
//  emu
//
//  Created by Aviv Wolf on 10/7/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "Emuticon.h"

@interface Emuticon (DownloadsHelpers)

/**
 *  Just a general helper method that can be used in data source object
 *  with a fetched results controller of emus.
 *
 *  given a fetched results controller of emus and a list of index paths
 *  checks what emus related to the index paths require download of resources.
 *  enques downloads as required
 *  and updates the download managers and render managers about prioritized emus.
 *
 *  @param indexPaths NSArray of index paths to check in the fetched results controller of emus.
 *  @param frc        NSFetchedResultsController the fetched results controller of emus (Must be Emuticon objects)
 *  @param forUI      NSString some extra info about the related UI (required. must not be nil).
 */
+(void)enqueueRequiredDownloadsForIndexPaths:(NSArray *)indexPaths
                                         frc:(NSFetchedResultsController *)frc
                                       forUI:(NSString *)forUI;

-(BOOL)enqueueIfMissingResourcesWithInfo:(NSDictionary *)info;
-(BOOL)enqueueIfMissingFullRenderResourcesWithInfo:(NSDictionary *)info;
-(void)enqueueMissingRemoteFootageFilesWithInfo:(NSDictionary *)info;

@end
