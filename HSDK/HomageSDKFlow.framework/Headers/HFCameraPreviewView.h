/*
 
*/

@class HFBGFeedBackVC;

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CVOpenGLESTextureCache.h>

/**
 *  HFCameraPreviewView The view using GL to display the real time camera feed and processed frames preview.
 */
@interface HFCameraPreviewView : UIView
{
	int renderBufferWidth;
	int renderBufferHeight;
    
	CVOpenGLESTextureCacheRef videoTextureCache;    

	EAGLContext* oglContext;
	GLuint frameBufferHandle;
	GLuint colorBufferHandle;
    GLuint passThroughProgram;
}

/**
 *  Initialize the view.
 *
 *  @return YES if initialized successfully. NO if failed to initialize.
 */
-(BOOL)initializeGL;

/**
 *  Flip the preview view horizontal.
 */
-(void)flipH;

/**
 *  Initialize the user interface showing the sihlouette and bg detection feedback to the user.
 *
 *  @param parentVC The parent view controller calling this method must be provided.
 */
-(void)initializeSilhouetteUIInParentVC:(UIViewController *)parentVC;


/**
 *  The silhouette / bg detection indicator UI view controller (optional)
 *  nil, until initializeSilhouetteUIInParentVC: is called.
 */
@property (nonatomic, readonly, weak) HFBGFeedBackVC *bgFeedBackVC;

/**
 *  Display the passed CVImageBufferRef in this view.
 *
 *  @param pixelBuffer CVImageBufferRef with the data buffer of the image to display.
 */
-(void)displayPixelBuffer:(CVImageBufferRef)pixelBuffer;

@end


