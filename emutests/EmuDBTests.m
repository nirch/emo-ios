//
//  EmuDBTests.m
//  emu
//
//  Created by Aviv Wolf on 6/15/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "EMDB.h"

@interface EmuDBTests : XCTestCase

@end

@implementation EmuDBTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}


-(void)testFakeStoreInstances
{
    [self measureBlock:^{
        EMDB *db = [EMDB new];
        NSString *fakeDBName = [NSString stringWithFormat:@"test_%@", [self genRandStringLength:10]];
        [db initFakeDBNamed:fakeDBName];
        
        // Create a random number (n) of emu defs
        NSInteger count = arc4random() % 10 + 1;
        for (NSInteger i=0;i<count;i++) {
            EmuticonDef *emuDef = [EmuticonDef findOrCreateWithID:[NSString stringWithFormat:@"emuDef%@", @(i)] context:db.context];
            emuDef.name = fakeDBName;
            
            // Add some emuticons
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            [Emuticon newForEmuticonDef:emuDef context:db.context];
            
            [db save];
        }
        
        // Check that indeed n emudefs exist in this fake store instance.
        NSError *error;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:E_EMU_DEF];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name=%@", fakeDBName];
        NSArray *emuDefs = [db.context executeFetchRequest:fetchRequest error:&error];
        XCTAssertNil(error, @"Failed fetch request on db %@: %@", fakeDBName, [error localizedDescription]);
        
        // Check fetch request results
        XCTAssertNotNil(emuDefs, @"No results for fetch of emuDefs");
        XCTAssert(emuDefs.count == count, @"Unexpected number (%@) of emuDefs fetched. Expected %@.", @(emuDefs.count), @(count));
        
        for (EmuticonDef *emuDef in emuDefs) {
            XCTAssert(emuDef.emus.count == 10, @"Unexpected number of emus.");
        }
        
        // Remove fake store.
        [db deleteStoreWithError:&error];
        XCTAssertNil(error, @"Failed clearing fake store file: %@", [error localizedDescription]);
    }];
}


#pragma mark - Helper methods
// Generates alpha-numeric-random string
- (NSString *)genRandStringLength:(int)len {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    return randomString;
}

@end
