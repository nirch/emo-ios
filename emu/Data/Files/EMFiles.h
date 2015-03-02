//
//  EMFiles.h
//  emu
//
//  Created by Aviv Wolf on 2/22/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMFiles : NSObject

+(NSString *)pathForResourceNamed:(NSString *)resourceName;
+(NSURL *)urlForBundledResourceNamed:(NSString *)resourceName
                       withExtension:(NSString *)extension;


+(NSString *)docsPath;
+(NSString *)outputPath;
+(void)ensureOutputPathExists;
+(NSString *)outputPathForFileName:(NSString *)fileName;



@end
