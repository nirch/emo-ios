//
//  EMMajorRetakeOptionsSheet.h
//  emu
//
//  Created by Aviv Wolf on 10/9/15.
//  Copyright © 2015 Homage. All rights reserved.
//

#import "EMHolySheet.h"

@interface EMMajorRetakeOptionsSheet : EMHolySheet

-(id)initWithPackOID:(NSString *)packOID
           packLabel:(NSString *)packLabel
            packName:(NSString *)packName;
-(void)configureActions;

@property (nonatomic, readonly) NSString *currentPackageOID;
@property (nonatomic, readonly) NSString *currentPackLabel;
@property (nonatomic, readonly) NSString *currentPackName;

@end
