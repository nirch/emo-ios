//
//  UserTempFootage.m
//  emu
//
//  Created by Aviv Wolf on 28/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

#import "UserTempFootage.h"
#import <HomageSDKCore/HomageSDKCore.h>

@interface UserTempFootage()

@property (nonatomic) NSString *path;
@property (nonatomic) NSString *capturedVideo;
@property (nonatomic) NSString *maskVideo;
@property (nonatomic) NSString *audio;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSString *uuid;

@end

@implementation UserTempFootage

+(UserTempFootage *)tempFootageWithInfo:(NSDictionary *)info
{
    UserTempFootage *tf = [[UserTempFootage alloc] initWithInfo:info];
    return tf;
}

-(instancetype)initWithInfo:(NSDictionary *)info
{
    self = [self init];
    if (self) {
        self.path = info[@"output_path"];
        
        self.capturedVideo = nil;
        if (info[@"output_files"][@"captured"])
            self.capturedVideo = [self.path stringByAppendingPathComponent:info[@"output_files"][@"captured"]];

        self.maskVideo = nil;
        if (info[@"output_files"][@"mask"])
            self.maskVideo = [self.path stringByAppendingPathComponent:info[@"output_files"][@"mask"]];

        self.audio = nil;
        if (info[@"output_files"][@"audio"])
            self.audio = [self.path stringByAppendingPathComponent:info[@"output_files"][@"audio"]];

        self.duration = info[@"duration"]? [info[@"duration"] doubleValue]:2.0;
        self.uuid = info[@"uuid"];
    }
    return self;
}

-(NSMutableDictionary *)hcRenderInfoForHD:(BOOL)forHD emuDef:(EmuticonDef *)emuDef
{
    NSMutableDictionary *layer = [NSMutableDictionary new];
    layer[hcrSourceType] = hcrVideo;
    layer[hcrPath] = self.capturedVideo;
    layer[hcrDynamicMaskPath] = self.maskVideo;
    //if (!forHD) layer[hcrDownSample] = @2;
    return layer;
}

-(void)cleanFiles
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (self.capturedVideo) {
        [fm removeItemAtPath:self.capturedVideo error:nil];
    }
    
    if (self.maskVideo) {
        [fm removeItemAtPath:self.maskVideo error:nil];
    }
    
    if (self.audio) {
        [fm removeItemAtPath:self.audio error:nil];
    }
}

-(NSURL *)urlToThumbImage
{
    return nil;
}

-(BOOL)isAvailable
{
    return YES;
}

@end
