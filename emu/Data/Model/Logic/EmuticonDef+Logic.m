//
//  Emuticon+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuticonDef+Logic.h"
#import "NSManagedObject+FindAndCreate.h"
#import "EMDB.h"
#import "EMDB+Files.h"
#import <HomageSDKCore/HomageSDKCore.h>

@implementation EmuticonDef (Logic)

#pragma mark - Find or create
+(EmuticonDef *)findOrCreateWithID:(NSString *)oid
                           context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_EMU_DEF
                                                                   oid:oid
                                                               context:context];
    return (EmuticonDef *)object;
}


+(EmuticonDef *)findWithID:(NSString *)oid
                   context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_EMU_DEF
                                                               withID:oid
                                                            inContext:context];
    return (EmuticonDef *)object;
}


-(NSArray *)emusOrdered:(NSArray *)sortDescriptors
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"emuDef=%@", self];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = sortDescriptors;
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) return nil;
    return results;
}

#pragma mark - Resources Paths

// User layer mask
-(NSString *)pathForUserLayerMask
{
    return [self pathForUserLayerMaskInHD:NO];
}

-(NSString *)pathForUserLayerMaskInHD:(BOOL)inHD
{
    NSString *path = inHD?self.sourceUserLayerMask2X:self.sourceUserLayerMask;
    return [EMDB pathForResourceNamed:path path:[self.package resourcesPath]];
}

// User layer dynamic mask
-(NSString *)pathForUserLayerDynamicMask
{
    return [self pathForUserLayerDynamicMaskInHD:NO];
}

-(NSString *)pathForUserLayerDynamicMaskInHD:(BOOL)inHD
{
    NSString *path = inHD?self.sourceUserLayerDynamicMask2X:self.sourceUserLayerDynamicMask;
    return [EMDB pathForResourceNamed:path path:[self.package resourcesPath]];
}

// Back layer
-(NSString *)pathForBackLayer
{
    return [self pathForBackLayerInHD:NO];
}

-(NSString *)pathForBackLayerInHD:(BOOL)inHD
{
    NSString *path = inHD?self.sourceBackLayer2X:self.sourceBackLayer;
    return [EMDB pathForResourceNamed:path path:[self.package resourcesPath]];
}

// Front layer
-(NSString *)pathForFrontLayer
{
    return [self pathForFrontLayerInHD:NO];
}

-(NSString *)pathForFrontLayerInHD:(BOOL)inHD
{
    NSString *path = inHD?self.sourceFrontLayer2X:self.sourceFrontLayer;
    return [EMDB pathForResourceNamed:path path:[self.package resourcesPath]];
}

+(NSArray *)createMissingEmuticonsForEmuDefs:(NSArray *)emuDefs
{
    NSMutableArray *emus = [NSMutableArray new];
    for (EmuticonDef *emuDef in emuDefs) {
        if ([[emuDef nonPreviewEmuticons] count] >= 1) continue;
        Emuticon *emu = [emuDef spawn];
        [emus addObject:emu];
    }
    return emus;
}

-(Emuticon *)spawn
{
    Emuticon *emu = [Emuticon newForEmuticonDef:self context:self.managedObjectContext];
    return emu;
}

-(CGFloat)aspectRatio
{
    CGFloat w = self.emuWidth?self.emuWidth.floatValue:EMU_DEFAULT_WIDTH;
    CGFloat h = self.emuHeight?self.emuHeight.floatValue:EMU_DEFAULT_HEIGHT;
    if (h==0 || w==h) return 1.0f;
    return w/h;
}

-(NSInteger)fps
{
    NSTimeInterval duration = self.duration?self.duration.doubleValue:2.0f;
    if (duration==0) duration = 1.0f;
    NSInteger numberOfFrames = self.framesCount?self.framesCount.integerValue:25;
    NSInteger framesPerSecond = numberOfFrames / duration;
    return framesPerSecond;
}

-(CGSize)sizeInHD:(BOOL)inHD
{
    CGFloat w = self.emuWidth?self.emuWidth.floatValue:EMU_DEFAULT_WIDTH;
    CGFloat h = self.emuHeight?self.emuHeight.floatValue:EMU_DEFAULT_HEIGHT;
    if (inHD) {
        w *= 2.0f;
        h *= 2.0f;
    }
    return CGSizeMake(w, h);
}

-(NSArray *)nonPreviewEmuticons
{
    NSMutableArray *emus = [NSMutableArray new];
    for (Emuticon *emu in self.emus) {
        if (emu.isPreview.boolValue) continue;
        [emus addObject:emu];
    }
    return emus;
}

#pragma mark - HSDK related
-(NSMutableDictionary *)hcRenderCFGWithFootages:(NSArray *)footages
                                       oldStyle:(BOOL)oldStyle
                                           inHD:(BOOL)inHD
                                            fps:(NSInteger)fps
{
    NSMutableDictionary *cfg;
    if (oldStyle == YES) {
        cfg = [self hcRenderOldCFGWithFootages:footages inHD:inHD fps:fps];
    } else {
        cfg = [self hcRenderCFGWithFootages:footages inHD:inHD fps:fps];
    }
    return cfg;
}

-(NSMutableDictionary *)hcRenderCFGWithFootages:(NSArray *)footages
                                           inHD:(BOOL)inHD
                                            fps:(NSInteger)fps
{
    // Full render video CFG
    NSMutableDictionary *cfg = [NSMutableDictionary dictionaryWithDictionary:self.fullRenderCFG];
    cfg[hcrResourcesPath] = self.package.resourcesPath;
    
    // Replace placeholder footages with available footages.
    NSMutableArray *sourceLayers = [NSMutableArray new];
    for (NSDictionary *layer in cfg[hcrSourceLayersInfo]) {
        NSDictionary *updatedLayer = layer;
        if (layer[hcrPlaceHolderIndex] != nil && [layer[hcrPlaceHolderIndex] isKindOfClass:[NSNumber class]]) {
            // Get the place holder index and make sure user footage is available for that layer.
            NSInteger index = [layer[hcrPlaceHolderIndex] integerValue] - 1;
            if (index>=0 && index<footages.count) {
                id<FootageProtocol> footage = footages[index];

                // Make the changes required on this layer.
                updatedLayer = [footage updateSourceLayerInfo:layer];
            }
        }
        [sourceLayers addObject:updatedLayer];
    }
    cfg[hcrSourceLayersInfo] = sourceLayers;
    return cfg;
}


#pragma mark - Converting old style emus to HSDK render info
-(NSMutableDictionary *)hcRenderOldCFGWithFootages:(NSArray *)footages
                                              inHD:(BOOL)inHD
                                               fps:(NSInteger)fps
{
    // Old emu def, support only bg layer, users and fg layer.
    // Takes the old style emu definition and builds the CFG required of HSDK HCRender
    
    // All resources must be available, if not will return nil and rendering should be avoided.
    if (![self allResourcesAvailableInHD:inHD])
        return nil;
    
    NSMutableDictionary *cfg = [NSMutableDictionary new];
    CGSize size = [self sizeInHD:inHD];

    // General info
    cfg[hcrWidth] = @(size.width);
    cfg[hcrHeight] = @(size.height);
    cfg[hcrFPS] = @(fps);

    // By default will use the emu def duration
    cfg[hcrDuration] = self.duration?self.duration:@2.0;


    // Start adding the layers
    NSMutableArray *layers = [NSMutableArray new];

    // Background layer
    [self addBackLayerToHCRenderLayers:layers inHD:inHD];

    // User/s layer/s
    [self addUsersLayersToHCRenderLayers:layers footages:footages inHD:inHD];

    // Front layer
    [self addFrontLayerToHCRenderLayers:layers inHD:inHD];

    cfg[hcrSourceLayersInfo] = layers;
    
    return cfg;
}



#pragma mark - Adding User Layers
-(void)addUsersLayersToHCRenderLayers:(NSMutableArray *)layers
                             footages:(NSArray *)footages
                                 inHD:(BOOL)inHD
{
    NSInteger slotIndex = 0;
    for (NSObject<FootageProtocol>* footage in footages) {
        slotIndex += 1;
        NSMutableDictionary *layerInfo = [footage hcRenderInfoForHD:inHD emuDef:self];
        if (layerInfo != nil && [layerInfo count] > 0) {
            
            // Add effects to users layers.
            [self addEffectsToUserLayer:layerInfo slotIndex:slotIndex inHD:inHD];

            // Add the user layer.
            [layers addObject:layerInfo];
        }
    }
}

#pragma mark - Adding Layers
-(void)addBackLayerToHCRenderLayers:(NSMutableArray *)layers inHD:(BOOL)inHD
{
    NSString *path = [self pathForBackLayerInHD:inHD];
    if (path == nil) return;
    
    NSMutableDictionary *layer = [NSMutableDictionary new];
    layer[hcrSourceType] = hcrGIF;
    layer[hcrPath] = path;
    if (self.duration) layer[hcrDuration] = self.duration;
    [layers addObject:layer];
}

-(void)addEffectsToUserLayer:(NSMutableDictionary *)layer slotIndex:(NSInteger)slotIndex inHD:(BOOL)inHD
{
    NSMutableArray *effects = [NSMutableArray new];
    
    // Old effects style to new effects stlye
    NSMutableDictionary *definedEffects = nil;
    
    // Effects defined specifically on the emuDef
    if (self.effects != nil && [self.effects isKindOfClass:[NSDictionary class]]) {
        definedEffects = [NSMutableDictionary dictionaryWithDictionary:self.effects];
    }
    
    // If a joint emu and positioning effect defined on this slot index
    if (self.jointEmu != nil) {
        NSArray *slots = self.jointEmu[@"slots"];
        if ([slots isKindOfClass:[NSArray class]] && [slots count] >= slotIndex) {
            
            
            NSDictionary *slotEffects = slots[slotIndex-1][@"effects"];
            
            if ([slotEffects isKindOfClass:[NSDictionary class]]) {
                NSArray *slotPositioningEffect = slotEffects[@"position"];
                if ([slotPositioningEffect isKindOfClass:[NSArray class]]) {
                    if (definedEffects == nil) definedEffects = [NSMutableDictionary new];
                    definedEffects[@"position"] = slotPositioningEffect;
                }
            }
        }
    }
    
    
    // Positioning effect
    if (definedEffects[@"position"]) {
        NSMutableDictionary *effect = [NSMutableDictionary new];
        effect[hcrEffectType] = hcrEffectTypeTransform;
        effect[hcrTimeUnits] = hcrTimeUnitsFrames;
        effect[hcrPositionUnits] = hcrPositionUnitsPoints;
        effect[hcrAnimation] = definedEffects[@"position"];
        [effects addObject:effect];
    }

    //
    // Old user dynamic mask effect --> HSDK Mask with gif source effect
    //
    NSString *dMaskPath = [self pathForUserLayerDynamicMaskInHD:inHD];
    if (dMaskPath) {
        NSMutableDictionary *effect = [NSMutableDictionary new];
        effect[hcrEffectType] = hcrEffectTypeMask;
        effect[hcrSource] = @{
                              hcrSourceType: hcrGIF,
                              hcrPath: dMaskPath
                              };
        [effects addObject:effect];
    }
    
    //
    // Old user mask effect. Will use the old style image mask effect in CV.
    //
    NSString *maskPath = [self pathForUserLayerMaskInHD:inHD];
    if (maskPath) {
        NSMutableDictionary *effect = [NSMutableDictionary new];
        effect[hcrEffectType] = hcrEffectTypeImageMask;
        effect[hcrPath] = maskPath;
        [effects addObject:effect];
    }
    
    if (effects.count > 0) {
        layer[hcrEffects] = effects;
    }
}

-(void)addFrontLayerToHCRenderLayers:(NSMutableArray *)layers inHD:(BOOL)inHD
{
    NSString *path = [self pathForFrontLayerInHD:inHD];
    if (path == nil) return;
    
    NSMutableDictionary *layer = [NSMutableDictionary new];
    layer[hcrSourceType] = hcrGIF;
    layer[hcrPath] = path;
    if (self.duration) layer[hcrDuration] = self.duration;
    [layers addObject:layer];
}


#pragma mark - Resources required
-(NSInteger)requiredResourcesCount
{
    return [self requiredResourcesCountInHD:NO];
}

-(NSInteger)requiredResourcesCountInHD:(BOOL)inHD
{
    NSInteger count;
    if (inHD) {
        if (self.sourceBackLayer2X) count++;
        if (self.sourceFrontLayer2X) count++;
        if (self.sourceUserLayerMask2X) count++;
        if (self.sourceUserLayerDynamicMask2X) count++;
    } else {
        if (self.sourceBackLayer) count++;
        if (self.sourceFrontLayer) count++;
        if (self.sourceUserLayerMask) count++;
        if (self.sourceUserLayerDynamicMask) count++;
    }
    return count;
}

-(NSArray *)allMissingResourcesNames
{
    return [self allMissingResourcesNamesInHD:NO];
}

-(NSArray *)allMissingResourcesNamesInHD:(BOOL)inHD
{
    NSMutableArray *resourcesNames = [NSMutableArray new];
    if (inHD) {
        if (self.sourceBackLayer2X && [self isMissingResourceNamed:self.sourceBackLayer2X]) [resourcesNames addObject:self.sourceBackLayer2X];
        if (self.sourceFrontLayer2X && [self isMissingResourceNamed:self.sourceFrontLayer2X]) [resourcesNames addObject:self.sourceFrontLayer2X];
        if (self.sourceUserLayerMask2X && [self isMissingResourceNamed:self.sourceUserLayerMask2X]) [resourcesNames addObject:self.sourceUserLayerMask2X];
        if (self.sourceUserLayerDynamicMask2X && [self isMissingResourceNamed:self.sourceUserLayerDynamicMask2X]) [resourcesNames addObject:self.sourceUserLayerDynamicMask2X];
    } else {
        if (self.sourceBackLayer && [self isMissingResourceNamed:self.sourceBackLayer]) [resourcesNames addObject:self.sourceBackLayer];
        if (self.sourceFrontLayer && [self isMissingResourceNamed:self.sourceFrontLayer]) [resourcesNames addObject:self.sourceFrontLayer];
        if (self.sourceUserLayerMask && [self isMissingResourceNamed:self.sourceUserLayerMask]) [resourcesNames addObject:self.sourceUserLayerMask];
        if (self.sourceUserLayerDynamicMask && [self isMissingResourceNamed:self.sourceUserLayerDynamicMask]) [resourcesNames addObject:self.sourceUserLayerDynamicMask];
    }
    return resourcesNames;
}

-(NSArray *)allMissingFullRenderResourcesNames
{
    if (self.fullRender == nil || self.fullRender.boolValue == NO) return @[];
    if (self.fullRenderCFG == nil) return @[];
    
    NSMutableArray *missingResources = [NSMutableArray new];
    for (NSDictionary *layer in self.fullRenderCFG[hcrSourceLayersInfo]) {
        NSString *resourceRelativePath = layer[hcrRelativePath];
        if (resourceRelativePath != nil && [self isMissingResourceNamed:resourceRelativePath]) {
            [missingResources addObject:resourceRelativePath];
        }

        // Also check effects resources (masks etc).
        for (NSDictionary *effect in layer[@"effects"]) {
            if ([effect[hcrEffectType] isEqualToString:hcrEffectTypeMask]) {
                NSDictionary *source = effect[hcrSource];
                if (source) {
                    NSString *maskResourceRelativePath = source[hcrRelativePath];
                    if (maskResourceRelativePath != nil && [self isMissingResourceNamed:maskResourceRelativePath]) {
                        [missingResources addObject:maskResourceRelativePath];
                    }
                }
            }
        }
    }
    
    // If also need an audio file to stich to final rendered result
    if ([self.fullRenderCFG[@"stitched_audio"] isKindOfClass:[NSString class]]) {
        NSString *audioResourceName = self.fullRenderCFG[@"stitched_audio"];
        if ([self isMissingResourceNamed:audioResourceName]) {
            [missingResources addObject:audioResourceName];
        }
    }
    
    return missingResources;
}

-(BOOL)allResourcesAvailable
{
    return [self allResourcesAvailableInHD:NO];
}

-(BOOL)allResourcesAvailableInHD:(BOOL)inHD
{
    if (inHD) {
        if (self.sourceBackLayer2X && [self isMissingResourceNamed:self.sourceBackLayer2X]) return NO;
        if (self.sourceFrontLayer2X && [self isMissingResourceNamed:self.sourceFrontLayer2X]) return NO;
        if (self.sourceUserLayerMask2X && [self isMissingResourceNamed:self.sourceUserLayerMask2X]) return NO;
        if (self.sourceUserLayerDynamicMask2X && [self isMissingResourceNamed:self.sourceUserLayerDynamicMask2X]) return NO;
        return YES;        
    } else {
        if (self.sourceBackLayer && [self isMissingResourceNamed:self.sourceBackLayer]) return NO;
        if (self.sourceFrontLayer && [self isMissingResourceNamed:self.sourceFrontLayer]) return NO;
        if (self.sourceUserLayerMask && [self isMissingResourceNamed:self.sourceUserLayerMask]) return NO;
        if (self.sourceUserLayerDynamicMask && [self isMissingResourceNamed:self.sourceUserLayerDynamicMask]) return NO;
        return YES;
    }
}

-(NSURL *)stichedAudioURLForRelativePath:(NSString *)relativePath
{
    if (relativePath == nil) return nil;
    NSString *path = [self pathForResourceNamed:relativePath];
    if (path) return [NSURL fileURLWithPath:path];
    return nil;
}

-(BOOL)allFullRenderResourcesAvailable
{
    return [[self allMissingFullRenderResourcesNames] count] < 1;
}

-(BOOL)isMissingResourceNamed:(NSString *)resourceName
{
    NSString *resourcePath = [self pathForResourceNamed:resourceName];
    return resourcePath == nil;
}


-(NSString *)pathForResourceNamed:(NSString *)resourceName
{
    NSString *resourcesPath = [self.package resourcesPath];
    NSString *resourcePath = [EMDB pathForResourceNamed:resourceName path:resourcesPath];
    return resourcePath;
}

-(void)removeAllResources
{
    if (self.sourceBackLayer) [self removeResourceNamed:self.sourceBackLayer];
    if (self.sourceFrontLayer) [self removeResourceNamed:self.sourceFrontLayer];
    if (self.sourceUserLayerMask) [self removeResourceNamed:self.sourceUserLayerMask];
    if (self.sourceUserLayerDynamicMask) [self removeResourceNamed:self.sourceUserLayerDynamicMask];
    [self removeAllHDResources];
}

-(void)removeAllHDResources
{
    if (self.sourceBackLayer2X) [self removeResourceNamed:self.sourceBackLayer2X];
    if (self.sourceFrontLayer2X) [self removeResourceNamed:self.sourceFrontLayer2X];
    if (self.sourceUserLayerMask2X) [self removeResourceNamed:self.sourceUserLayerMask2X];
    if (self.sourceUserLayerDynamicMask2X) [self removeResourceNamed:self.sourceUserLayerDynamicMask2X];
}

-(void)removeResourceNamed:(NSString *)resourceName
{
    NSString *resourcesPath = [self.package resourcesPath];
    [EMDB removeResourceNamed:resourceName path:resourcesPath];
}

#pragma mark - Full render related
-(BOOL)isNewStyleLongRender
{
    if (self.fullRenderCFG == nil) return NO;
    return [self newStyleRenderDuration] > 2.0;
}

-(NSTimeInterval)newStyleRenderDuration
{
    if (self.fullRenderCFG == nil) return 0;
    NSNumber *duration = self.fullRenderCFG[hcrDuration];
    if (![duration isKindOfClass:[NSNumber class]]) return 0;
    return duration.doubleValue;
}

-(NSString *)newStyleRenderDurationTitle
{
    NSString *title = LS(@"X_SECONDS_VIDEO");
    NSInteger duration = [self newStyleRenderDuration];
    NSString *durationString = [NSString stringWithFormat:@"%@", @(duration)];
    title = [title stringByReplacingOccurrencesOfString:@"#" withString:durationString];
    return title;
}

-(BOOL)requiresDedicatedCapture
{
    return self.requiredCaptureTime > 2.0;
}

-(NSTimeInterval)requiredCaptureTime
{
    NSTimeInterval duration = self.duration.doubleValue;
    if (self.captureDuration) duration = self.captureDuration.doubleValue;
    return duration;
}

-(NSString *)emuStoryTimeTitle
{
    NSString *title = LS(@"X_SECONDS_VIDEO");
    NSString *durationString = self.captureDuration.stringValue;
    if ([durationString isKindOfClass:[NSString class]]) {
        title = [title stringByReplacingOccurrencesOfString:@"#" withString:durationString];
    }
    return title;
}
@end
