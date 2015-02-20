//
//  Emuticon+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EmuticonDef+Logic.h"
#import "NSManagedObject+FindAndCreate.h"

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

@end
