//
//  EMFiles.h
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMFiles : NSObject

+(NSString *)docsPath;
+(void)savePNGSequence:(NSArray *)pngs toFolderNamed:(NSString *)folderName;


@end
