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


-(NSArray *)nonPreviewEmuticons
{
    NSMutableArray *emus = [NSMutableArray new];
    for (Emuticon *emu in self.emus) {
        if (emu.isPreview.boolValue) continue;
        [emus addObject:emu];
    }
    return emus;
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

@end
