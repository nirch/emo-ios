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
    return [EMDB pathForResourceNamed:self.sourceUserLayerMask];
}


-(NSString *)pathForBackLayer
{
    return [EMDB pathForResourceNamed:self.sourceBackLayer];
}


-(NSString *)pathForFrontLayer
{
    return [EMDB pathForResourceNamed:self.sourceFrontLayer];
}

-(Emuticon *)spawn
{
    Emuticon *emu = [Emuticon newForEmuticonDef:self
                                        context:self.managedObjectContext];
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

@end
