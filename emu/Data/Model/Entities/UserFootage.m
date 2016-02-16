//
//  UserFootage.m
//  emu
//
//  Created by Aviv Wolf on 9/25/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "UserFootage.h"
#import "UserFootage+Logic.h"
#import <HomageSDKCore/HomageSDKCore.h>
#import "EMDB+Files.h"

@implementation UserFootage

-(NSString *)pathToDownloadedRemoteFileKey:(NSString *)fileKey
{
    NSDictionary *remoteFiles = self.remoteFootageFiles;
    NSString *filePath = remoteFiles[fileKey];
    if (filePath == nil) return nil;
    filePath = [[EMDB footagesPath] stringByAppendingPathComponent:filePath];
    return filePath;
}

-(NSURL *)urlToThumbImage
{
    if (self.remoteFootage) {
        return [self remoteURLToFile:self.remoteFootageFiles[@"thumb"]];
    } else {
        return [NSURL fileURLWithPath:[self pathToUserThumb]];
    }
}

-(NSURL *)remoteURLToFile:(NSString *)remoteFilePath
{
    AppCFG *appCFG = [AppCFG cfgInContext:self.managedObjectContext];
    return [appCFG remoteURLToFile:remoteFilePath];
}

-(BOOL)isAvailable
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (self.remoteFootage.boolValue == YES) {
        NSArray *missingRemoteFiles = [self allMissingRemoteFiles];
        return missingRemoteFiles.count == 0;
    }
    
    
    if ([self isCapturedVideoAvailable]) {
        // Local user footage
        if ([fm fileExistsAtPath:[self pathToUserVideo]] == NO) return NO;
        if ([fm fileExistsAtPath:[self pathToUserDMaskVideo]] == NO) return NO;
    }
    return YES;
}

#pragma mark - HCRender
-(NSDictionary *)updateSourceLayerInfo:(NSDictionary *)layer
{
    NSMutableDictionary *updatedLayer = [NSMutableDictionary dictionaryWithDictionary:layer];
    
    NSString *pathToUserVideo = nil;
    NSString *pathToUserDMaskVideo = nil;
    
    if (!self.isAvailable) return updatedLayer;
    
    if (self.remoteFootage && self.remoteFootage.boolValue) {
        // Remote capture files available locally.
        pathToUserVideo = [self pathToDownloadedRemoteFileKey:@"raw"];
        pathToUserDMaskVideo = [self pathToDownloadedRemoteFileKey:@"mask"];
    } else {
        // Local capture is available.
        pathToUserVideo = [self pathToUserVideo];
        pathToUserDMaskVideo = [self pathToUserDMaskVideo];
    }
    
    
    if (pathToUserVideo == nil || pathToUserDMaskVideo == nil)
        return updatedLayer;
    
    // Remove the placeholder
    [updatedLayer removeObjectForKey:hcrResourceName];
    
    // Use the user footage source files for this layer.
    updatedLayer[hcrSourceType] = hcrVideo;
    updatedLayer[hcrPath] = pathToUserVideo;
    updatedLayer[hcrDynamicMaskPath] = pathToUserDMaskVideo;
    
    return updatedLayer;
}

-(NSMutableDictionary *)hcRenderInfoForHD:(BOOL)forHD emuDef:(EmuticonDef *)emuDef
{
    NSMutableDictionary *layer = [NSMutableDictionary new];
    if (self.isCapturedVideoAvailable) {
        
        // Captured layers provided by HSDK video writer and persisted to a UserFootage object.
        layer[hcrSourceType] = hcrVideo;
        layer[hcrPath] = [self pathToUserVideo];
        layer[hcrDynamicMaskPath] = [self pathToUserDMaskVideo];
        
    } else if (self.remoteFootage) {
        
        // Remote files downloaded/downloading from server.
        if (self.allMissingRemoteFiles.count==0) {
            NSString *rawPath = [self pathToDownloadedRemoteFileKey:@"raw"];
            NSString *maskPath = [self pathToDownloadedRemoteFileKey:@"mask"];
            if (rawPath != nil && maskPath != nil) {
                layer[hcrSourceType] = hcrVideo;
                layer[hcrPath] = rawPath;
                layer[hcrDynamicMaskPath] = maskPath;
            }
        } else {
            PlaceHolderFootage *placeHolder = [PlaceHolderFootage new];
            placeHolder.status = PlaceHolderFootageStatusPositive;
            placeHolder.label = LS(@"DOWNLOADING");
            layer = [placeHolder hcRenderInfoForHD:forHD emuDef:emuDef];
        }
        
    } else if (self.isPNGSequenceAvailable) {
        
    } else if (self.isGIFAvailable) {
        
    }
    
    if ([layer count] > 0) {
        NSInteger assumedUserLayerSizeInPositining = emuDef.assumedUsersLayersWidth?emuDef.assumedUsersLayersWidth.integerValue:240;
        if (forHD == NO && self.isHD == YES && assumedUserLayerSizeInPositining==240) {
            // Downsample if required.
            layer[hcrDownSample] = @2;
        }
    }
    
    return layer;
}


@end
