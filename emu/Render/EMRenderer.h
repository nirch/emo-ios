//
//  EMRender.h
//  emu
//
//  Created by Aviv Wolf on 2/23/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#define HM_RENDER_DOMAIN @"EMRenderer"

typedef NS_ENUM(NSInteger, EMRenderError) {
    EMRenderErrorMissingBackLayer       = 1000,
    EMRenderErrorMissingOutputPath      = 2000,
    EMRenderErrorMissingOutputType      = 3000,
    EMRenderErrorMissingUserLayer       = 4000,
    EMRenderErrorMissingOutputFile      = 5000
};


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

@property (nonatomic) BOOL shouldOutputThumb;
@property (nonatomic) BOOL shouldOutputGif;
@property (nonatomic) BOOL shouldOutputVideo;

@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSInteger numberOfFrames;
@property (nonatomic) NSNumber *thumbOfFrame;

@property (nonatomic) NSInteger videoFXLoopsCount;
@property (nonatomic) NSInteger videoFXLoopEffect;
@property (nonatomic) NSURL *audioFileURL;
@property (nonatomic) NSTimeInterval audioStartTime;

/**
 *  Render the emu according to the settings.
 *   - Should be called on a background thread.
 *   - Should be called after checking that the renderer was set properly (use isValid method).
 *
 */
-(void)render;

/**
 * Validate that the renderer was set properly.
 * If a required settings is missing, will return an NSError object.
 */
-(void)validateSetupWithError:(NSError **)error;


/**
 * Returns an NSError object if not all outputs rendered successfully and saved to disk.
 */
-(void)validateOutputResultsWithError:(NSError **)error;

@end
