//
//  EMActionsArray.h
//  emu
//
//  Created by Aviv Wolf on 4/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMActionsArray : NSObject

-(void)addAction:(NSString *)actionName
            text:(NSString *)text
         section:(NSInteger)section;

-(NSArray *)textsForSection:(NSInteger)section;

-(NSString *)actionNameForIndexPath:(NSIndexPath *)indexPath;

@end
