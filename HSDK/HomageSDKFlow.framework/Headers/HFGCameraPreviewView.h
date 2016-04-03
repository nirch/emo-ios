//
//  HFGCameraPreviewView.h
//  HomageSDKFlow
//
//  Created by Aviv Wolf on 29/02/2016.
//  Copyright © 2016 Homage LTD. All rights reserved.
//

@import UIKit;

@class HFBGFeedBackVC;

/**
 *  HFGCameraPreviewView The view to display the real time camera feed and processed frames preview.
 */
@interface HFGCameraPreviewView : UIView

/**
 *  The sub view UIImageView displaying the camera feed (read only).
 */
@property (nonatomic, weak, readonly) UIImageView *resultImageView;

/**
 *  (optional) BG Feedback UI
 */
@property (nonatomic) HFBGFeedBackVC *bgFeedBackVC;

/**
 *  Initialize the user interface showing the sihlouette and bg detection feedback to the user.
 *
 *  @param parentVC The parent view controller calling this method must be provided.
 */
-(void)initializeSilhouetteUIInParentVC:(UIViewController *)parentVC;

@end
