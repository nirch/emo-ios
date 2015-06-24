//
//  PreviewViewController.h
//  emu
//
//  Created by Aviv Wolf on 1/27/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMSDK.h"

@interface EMPreviewVC : UIViewController<
    HMCaptureSessionDisplayDelegate
>

-(void)fakeExtraction;

/**
 Show an animation of a square closing in on a point in the preview view.
 Use of auto focus after user touches the preview screen at a given point.
 The point coordinates should be normalized (0.0-1.0 values for x,y)
 */
-(void)showFocusViewOnPoint:(CGPoint)point;

@end
