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


-(NSString *)pathForUserLayerMask
{
    return [EMDB pathForResourceNamed:self.sourceUserLayerMask path:[self.package resourcesPath]];
}


-(NSString *)pathForBackLayer
{
    return [EMDB pathForResourceNamed:self.sourceBackLayer path:[self.package resourcesPath]];
}


-(NSString *)pathForFrontLayer
{
    return [EMDB pathForResourceNamed:self.sourceFrontLayer path:[self.package resourcesPath]];
}


-(NSString *)pathForUserLayerDynamicMask
{
    return [EMDB pathForResourceNamed:self.sourceUserLayerDynamicMask path:[self.package resourcesPath]];
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


-(NSArray *)nonPreviewEmuticons
{
    NSMutableArray *emus = [NSMutableArray new];
    for (Emuticon *emu in self.emus) {
        if (emu.isPreview.boolValue) continue;
        [emus addObject:emu];
    }
    return emus;
}

-(BOOL)allResourcesAvailable
{
    // If should have a back layer, check if available.
    if (self.sourceBackLayer &&
        [self isMissingResourceNamed:self.sourceBackLayer]) {
        return NO;
    }
    
    // If should have a front layer, check if available.
    if (self.sourceFrontLayer &&
        [self isMissingResourceNamed:self.sourceFrontLayer]) {
        return NO;
    }
    
    // If should have a user mask, check if available.
    if (self.sourceUserLayerMask &&
        [self isMissingResourceNamed:self.sourceUserLayerMask]) {
        return NO;
    }
    
    // If should have a dynamic user mask, check if available.
    if (self.sourceUserLayerDynamicMask &&
        [self isMissingResourceNamed:self.sourceUserLayerDynamicMask]) {
        return NO;
    }
    
    return YES;
}

-(BOOL)isMissingResourceNamed:(NSString *)resourceName
{
    NSString *resourcesPath = [self.package resourcesPath];
    NSString *resourcePath = [EMDB pathForResourceNamed:resourceName path:resourcesPath];
    return resourcePath == nil;
}

-(void)removeAllResources
{
    if (self.sourceBackLayer)
        [self removeResourceNamed:self.sourceBackLayer];
    
    if (self.sourceFrontLayer)
        [self removeResourceNamed:self.sourceFrontLayer];
    
    if (self.sourceUserLayerMask)
        [self removeResourceNamed:self.sourceUserLayerMask];
    
    if (self.sourceUserLayerDynamicMask)
        [self removeResourceNamed:self.sourceUserLayerDynamicMask];
}

-(void)removeResourceNamed:(NSString *)resourceName
{
    NSString *resourcesPath = [self.package resourcesPath];
    [EMDB removeResourceNamed:resourceName path:resourcesPath];
}

@end
