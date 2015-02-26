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

@property (nonatomic) NSString *userMaskPath;
@property (nonatomic) NSString *userImagesPath;
@property (nonatomic) NSString *backLayerPath;
@property (nonatomic) NSString *frontLayerPath;

@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSInteger numberOfFrames;

-(void)render;

@end
