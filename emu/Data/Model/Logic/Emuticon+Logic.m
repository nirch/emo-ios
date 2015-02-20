//
//  Emuticon+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "Emuticon+Logic.h"
#import "NSManagedObject+FindAndCreate.h"

@implementation Emuticon (Logic)

#pragma mark - Find or create
+(Emuticon *)findOrCreateWithID:(NSString *)oid
                           context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_EMU
                                                                   oid:oid
                                                               context:context];
    return (Emuticon *)object;
}

@end
