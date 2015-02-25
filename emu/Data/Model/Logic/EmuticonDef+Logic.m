//
//  Emuticon+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuticonDef+Logic.h"
#import "NSManagedObject+FindAndCreate.h"
#import "EMFiles.h"

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


+(EmuticonDef *)findEmuDefForPreviewInContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"useForPreview=%@", @YES];
    EmuticonDef *emuDef = (EmuticonDef *)[NSManagedObject fetchSingleEntityNamed:E_EMU_DEF
                                                                   withPredicate:predicate
                                                                       inContext:context];
    return emuDef;
}


-(NSString *)pathForUserLayerMask
{
    return [EMFiles pathForResourceNamed:self.sourceUserLayerMask];
}


-(NSString *)pathForBackLayer
{
    return [EMFiles pathForResourceNamed:self.sourceBackLayer];
}


-(NSString *)pathForFrontLayer
{
    return [EMFiles pathForResourceNamed:self.sourceFrontLayer];
}

@end
