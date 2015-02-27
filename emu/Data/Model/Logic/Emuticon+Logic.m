//
//  Emuticon+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "Emuticon+Logic.h"
#import "EMDB.h"
#import "EMFiles.h"

@implementation Emuticon (Logic)

+(Emuticon *)findWithID:(NSString *)oid
                context:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject fetchSingleEntityNamed:E_EMU
                                                               withID:oid
                                                            inContext:context];
    return (Emuticon *)object;
}


+(Emuticon *)previewWithOID:(NSString *)oid
                 footageOID:(NSString *)footageOID
             emuticonDefOID:(NSString *)emuticonDefOID
                    context:(NSManagedObjectContext *)context;
{
    // footage and emuticon definition must exist.
    UserFootage *userFootage = [UserFootage findWithID:footageOID context:context];
    EmuticonDef *emuDef = [EmuticonDef findWithID:emuticonDefOID context:context];
    if (userFootage == nil || emuDef == nil) return nil;
    
    // Create the emuticon preview object.
    Emuticon *emu = (Emuticon *)[NSManagedObject findOrCreateEntityNamed:E_EMU
                                                                     oid:oid
                                                                 context:context];
    emu.userFootage = userFootage;
    emu.emuticonDef = emuDef;
    emu.usageCount = @0;
    emu.isPreview = @YES;
    return emu;
}

-(NSURL *)animatedGifURL
{
    NSString *outputPath = [self animatedGifPath];
    NSURL *url = [NSURL URLWithString:[SF:@"file://%@" , outputPath]];
    return url;
}

-(NSString *)animatedGifPath
{
    NSString *gifName = [SF:@"%@.gif", self.oid];
    NSString *outputPath = [EMFiles outputPathForFileName:gifName];
    return outputPath;
}

-(NSData *)animatedGifData
{
    NSString *path = [self animatedGifPath];
    NSData *gifData = [[NSData alloc] initWithContentsOfFile:path];
    return gifData;
}

@end
