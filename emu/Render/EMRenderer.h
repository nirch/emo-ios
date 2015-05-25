//
//  EMRender.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//



@interface EMRenderer : NSObject

@property (nonatomic) NSString *emuticonDefOID;
@property (nonatomic) NSString *footageOID;
@property (nonatomic) NSString *outputOID;
@property (nonatomic) NSString *outputPath;
@property (nonatomic) NSString *userMaskPath;
@property (nonatomic) NSString *userImagesPath;
@property (nonatomic) NSArray *userImagesPathsArray;
@property (nonatomic) NSString *backLayerPath;
@property (nonatomic) NSString *frontLayerPath;
@property (nonatomic) NSString *paletteString;

@property (nonatomic) BOOL shouldOutputGif;
@property (nonatomic) BOOL shouldOutputVideo;

@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSInteger numberOfFrames;

@property (nonatomic) NSInteger videoFXLoopsCount;
@property (nonatomic) BOOL videoFXLoopPingPong;
@property (nonatomic) NSURL *audioFileURL;

-(void)render;

@end
