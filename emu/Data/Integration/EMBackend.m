//
//  EMBackend.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//
#define TAG @"EMBackend"

#import "EMBackend.h"
#import "EMDB.h"
#import "EMEmuticonsParser.h"
#import "EMAppCFGParser.h"

@implementation EMBackend

#pragma mark - Initialization
// A singleton
+(EMBackend *)sharedInstance
{
    static EMBackend *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMBackend alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(EMBackend *)sh
{
    return [EMBackend sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - Fetching data
-(NSDictionary *)jsonDataInLocalFile:(NSString *)fileName
{
    // Read emuticons json file
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (error) {
        HMLOG(TAG, ERR, @"NSJSONSerialization failed for emuticonsDefinitions: %@", [error localizedDescription]);
        return nil;
    }
    return json;
}

-(void)refetchEmuticonsDefinitions
{
    NSDictionary *json = [self jsonDataInLocalFile:@"emuticonsDefinitions"];
    if (json == nil)
        return;
    
    // Parse the data
    EMEmuticonsParser *parser = [[EMEmuticonsParser alloc] initWithContext:EMDB.sh.context];
    parser.objectToParse = json;
    [parser parse];
}

-(void)refetchAppCFG
{
    NSDictionary *json = [self jsonDataInLocalFile:@"appCFG"];
    if (json == nil)
        return;
    
    // Parse the data
    EMAppCFGParser *parser = [[EMAppCFGParser alloc] initWithContext:EMDB.sh.context];
    parser.objectToParse = json;
    [parser parse];
}

@end
