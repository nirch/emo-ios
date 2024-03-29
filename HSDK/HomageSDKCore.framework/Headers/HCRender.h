#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "HCRenderError.h"
#import "HCCVRendererProtocol.h"
#import "HCRObject.h"


/**
 The render engine configuration object.
 The workflow with this object is:
 
 - Instantiate object, giving it configuration info. @see initWithConfigurationInfo:userInfo:
 - Call setup method.
 - Check for errors.
 - If no errors encountered, call process method for rendering.

        // Read the config from data base, config files or generate it dynamically.
        NSDictionary *renderCFG = [self renderConfigWithID:@"SOME_ID_3456"];
 
        // Set up the renderer.
        HCRender *renderer = [HCRenderer initWithConfigurationInfo:renderCFG];
        [renderer setup];
 
        // Check for errors.
        if (renderer.error) {
            // Inspect the error code and do some error handling here.
            return;
        }

        // Render
        [renderer process];
 
*/
@interface HCRender : HCRObject<
    HCCVRendererProtocol
>

#pragma mark - Initialization
/**  @name Initialization & Configuration */

/** 
 *  Configures the HCRender object, given a configuration NSDictionary.
 *
 *  High level structure of the configuration dictionary:
 *
 *  @param configInfo NSDictionary containing all the configuration info for the new HCRender instance.
 *
 *      {
 *          "width":1280,
 *          "height":720,
 *          "source_layers_info":[layer1Info, layer2Info, layer3Info, ...],
 *          "outputs_info":[output1, output2, output3, ...]
 *      }
 *
 *  @param userInfo NSDictionary (optional) extra user info. For external use. The renderer itself will not do anything with this extra info.
 *
 *  @return Newly created HCRender object
 */
-(id)initWithConfigurationInfo:(NSDictionary *)configInfo userInfo:(NSDictionary *)userInfo;

/**
 *  A UUID to identify this uuid.
 *  By default, a UUID is generated on instanciation, but it is possible to set any string on this property at any time.
 */
@property (nonatomic) NSString *uuid;

/**
 *  Given info about dynamic resources (resources generated / created / captured selected on the client side)
 *  this method will replace the configuration of one or more a layers that are marked with the relevant dynamic_resource_id identifier.
 *
 *  Must be called before the call to the setup method.
 *  (If called after setup was already called, the call to applyDynamicResources: will be silently ignored.
 *
 *  @param dynamicResourcesInfo NSDictionary of <dynamic_resource_id>:<dynamic_resource_info>
 *
 *  The dynamic_resource_info is a dictionary with key/values to override on the related source_info.
 */
-(void)applyDynamicResources:(NSDictionary *)dynamicResourcesInfo;

/** 
 *  Reads the passed configuration info and sets up the renderer for rendering.
 *  If a problem is encountered during setup, the setup will stop and an error object
 *  will be set on the self.error property.
 */
-(void)setup;

#pragma mark - Rendering
/**  @name Rendering */

/** 
 *  Render results using current configuration.
 *
 *  @note The process method is blocking. It is the responsibility of the caller
 *  to make sure it is run or queued for background work.
 *  It makes sense to always run this in a background thread.
 */
-(void)process;

/**
 *  YES if output should post notifications during rendering about the progress of the render.
 *  NO by default.
 */
@property (nonatomic) BOOL outputProgressNotifications;

/**
 *  Returns NSURL to the first output in outputs array. May return nil if info not available yet / not rendered yet.
 *
 *  @return NSURL pointing to the first output file in outputs array.
 */
-(NSURL *)outputURL;

/**
 *  Render results using current configuration.
 *
 *  @param info NSDictionary with extra user info.
 *
 *  @note The process method is blocking. It is the responsibility of the caller
 *  to make sure it is run or queued for background work.
 *  It makes sense to always run this in a background thread.
 */
-(void)processWithInfo:(NSDictionary *)info;

/**
 *  Cancel rendering in progress.
 *  (sliently ignored if called not currently rendering)
 */
-(void)cancel;

/**
 *  Will attempt to delete any produced output file (if exists).
 *  (Will fail silently on errors or if files don't exist)
 */
-(void)clearOutputFiles;

#pragma mark - Properties
/**  @name Properties */

/**
 *  The default size of sources and outputs in this render instance.
 */
@property (nonatomic, readonly) CGSize baseSize;

/**
 *  The duration of the render in seconds (fractions allowed)
 *  If not set, 2.0 seconds is assumed by default.
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 *  Frames per second.
 *  If not set, 12 frames per second is assumed by default.
 */
@property (nonatomic, readonly) NSInteger fps;

/**
 *  YES/true only after a valid configuration was passed and setup method was called.
 *  when readyForProcessing is NO/false the call to process is ignored and you should
 *  check correctness of your configuration and setup of the renderer.
 */
@property (nonatomic, readonly) BOOL readyForProcessing;

/**
 *  Extra (and optional) general use information.
 *  Used to pass extra info around that is attached to the renderer instance.
 *
 */
@property (nonatomic, readonly) NSDictionary *userInfo;

/**
 *  The base path for all outputs using a relative path.
 *  this is set to app's documents directory by default.
 */
@property (nonatomic, readonly) NSString *baseOutputsPath;

/**
 *  The base path for all sources' resources using a relative path.
 *  this is set to the app's documents directory by default.
 */
@property (nonatomic, readonly) NSString *baseResourcesPath;

/**
 *  An array of source layers configuration info.
 *  The layers are provided in order from the most back layer to the front layer.
 *  Different layers can each define a different kind of source (gif source, image source, video source etc).
 *  Each layer can have its own set of effects and configurations.
 *
 *  At least a single layer must be provided.
 */
@property (nonatomic, readonly) NSMutableArray *sourceLayersInfo;

/**
 *  An array of full paths to output files.
 */
@property (nonatomic, readonly) NSMutableArray *outputFiles;

/**
 *  An error object. nil by default. Will be set to an error if an error occured when
 *  the renderer was setup with bad configuration info.
 */
@property (nonatomic, readonly) HCRenderError *error;


#pragma mark - General Info Keys
/**  @name Constants */

/**
 - Render Notifications:
    - hcrNotificationRenderProgress=**notification_render_progress**: Notification 
    - hcrRenderProgress=**render_progress**: A value between 0.0 - 1.0 indicating the progress of a specific render.
    - hcrRenderedFramesCount=**rendered_frames_count**: A counter of the number of frames rendered for a specific render
 - General Info:
    - hcrWidth=**width**: width of an input, output or resource.
    - hcrHeight=**height**: height of an input, output or resource.
    - hcrDuration=**duration**: duration time interval in seconds.
    - hcrFPS=**fps**: frames per second.
    - hcrInfo=**info**: extra user info attached to this render. info is not used by the renderer, only passed to notifications about progress or finished renders.
 - Main config info:
    - hcrSourceLayersInfo=**source_layers_info**: Array of all source layers and their config information.
    - hcrOutputsInfo=**outputs_info**: Array of all outputs and their config information.
 - Paths & Resources:
    - hcrResourcesPath=**resources_path**: (optional) when this path is set, relative resources paths are relative to this path.
    - hcrResourcesBundle=**resources_bundle**: (optional) if this object is not set, named bundled resources will use the application's default NSBundle to load named resources. if this object is set, will use that bundle instead to determine the bundled named resource local path.
    - hcrOutputsPath=**outputs_path**: (optional) when this path is set, relative output paths are relative to this path. If not set, relative paths will be relative to NSDocument directory by default.
    - hcrResourceName=**resource_name**: The name of a bundled resource (for resources bundled on device).
    - hcrPath=**path**: Absolute file path.
    - hcrRelativePath=**relative_path**: Relative file path.
 - Sources & Outputs Types:
     - hcrSourceType=**source_type**: The type of a source layer.
     - hcrOutputType=**output_type**: The type of an output.
     - hcrGIF=**gif**: Animated gif image.
     - hcrPNG=**png**: PNG image.
     - hcrPNGSequence=**png_sequence**: A sequence of PNG images.
     - hcrJPG=**jpg**: JPG image.
     - hcrVideo=**video**: Video.
 - Effects
    - hcrEffects=**effects**: A dictionary of effects. Key value pairs - key=effect type and value=effect data.
    - hcrTransform=**transform**: A transform effect. An array of key frames data.
    - hcrFrame=**frame**: A key frame index.
    - hcrPos=**pos**: 2D Position (x,y)
    - hcrScale=**scale**: Scale
    - hcrRotate=**rotate**: Rotation value in 3 axis (x,y,z)
    - hcrPalette=**palette**: palette string forcing output to include certain colors (for example in gif output)
 */
+(NSDictionary *)constants;

#pragma mark - Notifications
/**
 * Notification providing info about a specific render progress.
 */
extern NSString* const hcrNotificationRenderProgress;

/**
 * Notification providing info about a specific finished render.
 */
extern NSString* const hcrNotificationRenderFinished;

/**
 * A value between 0.0 - 1.0 indicating the progress of a specific render.
 */
extern NSString* const hcrRenderProgress;

/**
 * A counter of the number of frames rendered for a specific render
 */
extern NSString* const hcrRenderedFramesCount;

/**
 * Paths and other info about the rendering final output
 */
extern NSString* const hcrRenderResults;


#pragma mark - General info
/**
 *  Info
 */
extern NSString* const hcrInfo;

/**
 *  width of an input, output or resource.
 */
extern NSString* const hcrWidth;

/**
 *  height of an input, output or resource.
 */
extern NSString* const hcrHeight;

/**
 *  duration time interval in seconds of an input, output or resource.
 */
extern NSString* const hcrDuration;

/**
 *  Down sample images 
 *  default=1: meaning no downscaling.
 *  2: meaning frame will be halved in width and height.
 */
extern NSString* const hcrDownSample;

/**
 *  frames per second of an input, output or resource.
 */
extern NSString* const hcrFPS;

/**
 *  Array of all source layers and their config information.
 */
extern NSString* const hcrSourceLayersInfo;

/**
 *  Array of all outputs and their config information.
 */
extern NSString* const hcrOutputsInfo;

/**
 *  (optional) when this path is set, relative resources paths are relative to this path.
 */
extern NSString* const hcrResourcesPath;

/**
 *  (optional) if this object is not set, named bundled resources will use the application's default NSBundle to load named resources. if this object is set, will use that bundle instead to determine the bundled named resource local path.
 */
extern NSString* const hcrResourcesBundle;

/**
 *  (optional) when this path is set, relative output paths are relative to this path. If not set, relative paths will be relative to NSDocument directory by default.
 */
extern NSString* const hcrOutputsPath;

/**
 *  Progress of long processes (0.0 - 1.0 value)
 */
extern NSString* const hcrProgress;

/**
 *  UUID string.
 */
extern NSString* const hcrUUID;

#pragma mark - Resources and files info
/**
 *  The name of a bundled resource (for resources bundled on device)
 */
extern NSString* const hcrResourceName;

/**
 *  The name of a dynamic mask
 */
extern NSString* const hcrDynamicMaskName;

/**
 *  The absolute path to a dynamic mask.
 */
extern NSString* const hcrDynamicMaskPath;

/**
 *  The relative path to a dynamic mask.
 */
extern NSString* const hcrDynamicMaskRelativePath;

/**
 *  Absolute file path
 */
extern NSString* const hcrPath;

/**
 *  Array of absolute file paths
 */
extern NSString* const hcrPaths;

/**
 *  Relative file path.
 */
extern NSString* const hcrRelativePath;

/**
 *  Paths pattern. A pattern for a range of resources - will be used to produce a list of paths with a "running number".
 */
extern NSString* const hcrPathsPattern;

/**
 *  Number of frames.
 */
extern NSString* const hcrFramesCount;

#pragma mark - Audio
/**
 *  NSURL pointing to an audio file.
 */
extern NSString* const hcrAudioURL;

/**
 *  A name of an audio resource.
 */
extern NSString* const hcrAudioNamed;


#pragma mark - Colors
/**
 *  A color value.
 */
extern NSString* const hcrColorValue;

/**
 *  A background color value.
 */
extern NSString* const hcrBackgroundColor;


#pragma mark - Effects
/**
 *  Effects.
 */
extern NSString* const hcrEffects;


#pragma mark - Sources & Outputs Types Keys
/**
 *  Source
 *  used as key when a single source needs to be defined outside the sources array.
 */
extern NSString* const hcrSource;

/**
 *  A place holder index. Used to mark certain layers that their content should be
 *  replaced in run time with some dynamic content generated by the app etc.
 *  (For example, a layer that should be replaced with a user's footage)
 */
extern NSString* const hcrPlaceHolderIndex;

/**
 *  The type of a source layer.
 */
extern NSString* const hcrSourceType;

/**
 *  The type of an output.
 */
extern NSString* const hcrOutputType;

/**
 *  GIF Image
 */
extern NSString* const hcrGIF;

/**
 *  PNG Image.
 */
extern NSString* const hcrPNG;

/**
 *  PNG Sequence.
 */
extern NSString* const hcrPNGSequence;

/**
 *  JPG Image.
 */
extern NSString* const hcrJPG;

/**
 *  Video.
 */
extern NSString* const hcrVideo;

/**
 *  Color.
 */
extern NSString* const hcrColor;

/**
 *  Palette string forcing a list of colors to be used in output (used in gif output)
 */
extern NSString* const hcrPalette;

@end
