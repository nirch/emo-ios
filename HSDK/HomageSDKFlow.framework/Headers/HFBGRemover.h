//
//  HFBGRemover.h
//  HomageSDKFlow
//
//  Created by Aviv Wolf on 25/11/2015.
//  Copyright © 2015 Homage LTD. All rights reserved.
//

#import "HFPObject.h"
#import <CoreMedia/CoreMedia.h>
#import "HFProcessingProtocol.h"
#import <HomageSDKCore/HomageSDKCore.h>

@protocol HFProcessingProtocol;

/**
 The default implementation of the HFProcessingProtocol.
 Used by capture session by default, unless some other processor is implemented
 and passed to the capture session object.
 
 This class implements the HFProcessingProtocol and uses Homage SDK Core functionality
 of removing uniform background behind the captured users.
 It also uses the background detection functionality in Homage SDK Core. Information about
 the background quality is posted using notification center and can be captured by any observer
 on notifications named hfNotificationBGDetectionInfo.
 */
@interface HFBGRemover : HFPObject<
    HFProcessingProtocol
>


/**
 *  Initializen for given preset resolution type and silhouette type.
 *
 *  @param resolutionType hcbResolution One of the preset resolutions provided by the SDK.
 *  @param silhouetteType hcbSilhouetteType One of the preset silhouette types provided by the SDK.
 *  @param bgImage        UIImage (optional) an image for the replaced background (if not provided a default BG will be used)
 *
 *  @return HFBGRemover new instance of the HFBGRemover object.
 */
-(instancetype)initWithResolutionType:(hcbResolution)resolutionType
             processingSilhouetteType:(hcbSilhouetteType)silhouetteType
                              bgImage:(UIImage *)bgImage;

/**
 Inspect a frame.
 This will not fully process the frame or change the content.
 Will check the quality of the background and post a notifications with the info about the result, using notification center.
 
 <pre>
 ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== =====
 Background detection notification will be posted after each call:
 ===== ===== ===== ===== ===== ===== ===== ===== ===== ===== =====
 notification name: hfpNotificationBackgroundInfo
 notification info: {
 hfpBGMark: <bg mark value value>
 hfpBGWeight:<weight value>
 }
 </pre>
 
 hfpBGMark: background mark value. 1 is good background and negative number are bad background marks (see HomageSDKCore hcbMark).
 
 hfpBGWeight: a value between 0.0 and 1.0 that is increased or decreased as good and bad background marks are received for a sequence of frames over time.
 
 hfpGoodBGSatisfied: a boolean value indicating if the good background threshold was reached or not. When it is returned as YES, it is OK to start recording.
 
 */
-(NSDictionary *)inspectFrame;

/**
 *  Do some clean up operations.
 */
-(void)cleanUp;


#pragma mark - General Info Keys
/**  @name Constants */

/** A dictionary with constant names and values.

 - **Background detection info**:
    - hfpNotificationBackgroundInfo=**notification_background_info**: Name of the notification that is posted after a frame was inspected and a BGMark is available for that frame. BG info will be available with the notification.
    - hfpBGMark=**bg_mark**: info key for providing a background mark of an inspected frame.
    - hfpBGWeight=**bg_weight**: info key for providing a progress value between 0.0 and 1.0 that indicates the quality of the background in a sequence of inspected frames.
    - hfpGoodBGSatisfied=**good_bg_satisfied**: info key for providing indication if the good background weight reached the threshold that indicates that the background is good enough for starting a recording.
 
 @return NSDictionary list of constants names and values.
 */
+(NSDictionary *)constants;

extern NSString *const hfpNotificationBackgroundInfo;
extern NSString *const hfpBGMark;
extern NSString *const hfpBGWeight;
extern NSString *const hfpGoodBGSatisfied;
extern NSString *const hfpBGMarkDefaultText;
extern NSString *const hfpBGMarkTextKey;


@end
