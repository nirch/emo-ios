//
//  EMActionsArray.m
//  emu
//
//  Created by Aviv Wolf on 4/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "EMActionsArray.h"

@interface EMActionsArray()

@property (nonatomic) NSMutableDictionary *actionsTextsPerSection;
@property (nonatomic) NSMutableDictionary *actionsNamesPerSection;

@end

@implementation EMActionsArray

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.actionsTextsPerSection = [NSMutableDictionary new];
        self.actionsNamesPerSection = [NSMutableDictionary new];
    }
    return self;
}

-(void)addAction:(NSString *)actionName
            text:(NSString *)text
         section:(NSInteger)section
{
    if (self.actionsNamesPerSection[@(section)] == nil) {
        self.actionsNamesPerSection[@(section)] = [NSMutableDictionary new];
        self.actionsTextsPerSection[@(section)] = [NSMutableDictionary new];
    }
    NSInteger nextItemNumber = [self.actionsTextsPerSection[@(section)] count];
    self.actionsTextsPerSection[@(section)][@(nextItemNumber)] = text;
    self.actionsNamesPerSection[@(section)][@(nextItemNumber)] = actionName;
}

-(NSArray *)textsForSection:(NSInteger)section
{
    NSDictionary *textsDict = self.actionsTextsPerSection[@(section)];
    if (textsDict == nil) return @[];
    NSMutableArray *texts = [NSMutableArray new];
    for (int i=0; i<textsDict.count; i++) {
        NSString *text = textsDict[@(i)];
        if (text == nil) [texts addObject:@""];
        [texts addObject:text];
    }
    return texts;
}


-(NSString *)actionNameForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *names = self.actionsNamesPerSection[@(indexPath.section)];
    if (names == nil) return nil;
    NSString *actionName = names[@(indexPath.item)];
    return actionName;
}

@end
