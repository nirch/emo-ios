//
//  AppCFG+Logic.m
//  emu
//
//  Created by Aviv Wolf on 2/14/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "AppCFG+Logic.h"
#import "NSManagedObject+FindAndCreate.h"
#import "EMDB.h"

@implementation AppCFG (Logic)

+(AppCFG *)cfgInContext:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [NSManagedObject findOrCreateEntityNamed:E_APP_CFG
                                                                   oid:@"default"
                                                               context:context];
    return (AppCFG *)object;
}

-(Package *)packageForOnboarding
{
    NSString *oid = self.onboardingUsingPackage;
    Package *package = [Package findWithID:oid
                                   context:self.managedObjectContext];
    return package;
}

-(BOOL)isPackageUsedForOnboarding:(Package *)package
{
    if (package == nil) return NO;
    return [package.oid isEqualToString:self.onboardingUsingPackage];
}

@end
