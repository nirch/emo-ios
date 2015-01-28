/*
 */

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "HMCaptureSession.h"

#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Gpw/Vtool/Vtool.h"
#import "Image3/Image3Tool.h"
#import "ImageType/ImageTool.h"
#import "ImageMark/ImageMark.h"
#import "Utime/GpTime.h"

//#import "Data.h"

#define BYTES_PER_PIXEL 4

@interface HMCaptureSession () {
    
    //int counter;
    CUniformBackground *m_foregroundExtraction;
    image_type *m_original_image;
    image_type *m_foreground_image;
    image_type *m_output_image;
    image_type *m_background_image;
    
}


// Redeclared as readwrite so that we can write to the property and still be atomic with external readers.
@property (readwrite) Float64 videoFrameRate;
@property (readwrite) CMVideoDimensions videoDimensions;
@property (readwrite) CMVideoCodecType videoType;

@property (readwrite, getter=isRecording) BOOL recording;

@property (readwrite) AVCaptureVideoOrientation videoOrientation;

@end

@implementation HMCaptureSession

@synthesize delegate;
@synthesize videoFrameRate, videoDimensions, videoType;
@synthesize referenceOrientation;
@synthesize videoOrientation;
@synthesize recording;

- (id) init
{
    if (self = [super init]) {
        previousSecondTimestamps = [[NSMutableArray alloc] init];
        referenceOrientation = AVCaptureVideoOrientationPortrait;
        [self initObservers];
    }
    return self;
}

#pragma mark - Observers
-(void)initObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addUniqueObserver:self
                 selector:@selector(onCaptureSessionRuntimeError:)
                     name:AVCaptureSessionRuntimeErrorNotification
                   object:nil];
}

#pragma mark - Observers handlers
-(void)onCaptureSessionRuntimeError:(NSNotification *)notification
{
    NSLog(@"%@", notification);
}

#pragma mark - capture session
- (void)setupAndStartCaptureSession
{
    // Create a shallow queue for buffers going to the display for preview.
    OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);
    if (err)
        [self showError:[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]];
    
    // Create serial queue for movie writing
    movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    if ( !captureSession )
        [self setupCaptureSession];
    
    
    
    if ( !captureSession.isRunning )
        [captureSession startRunning];
}

-(BOOL)setupCaptureSession
{
    /*
	 * Create capture session
	 */
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    /*
	 * Create audio connection
	 */
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    if ([captureSession canAddInput:audioIn])
        [captureSession addInput:audioIn];

	AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
	dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
	[audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];

    if ([captureSession canAddOutput:audioOut])
		[captureSession addOutput:audioOut];
	audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];

	/*
	 * Create video connection
	 */
    videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionFront] error:nil];
    
    if ([captureSession canAddInput:videoIn])
        [captureSession addInput:videoIn];

	AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
	/*
     RosyWriter prefers to discard late video frames early in the capture pipeline, since its
     processing can take longer than real-time on some platforms (such as iPhone 3GS).
     Clients whose image processing is faster than real-time should consider setting AVCaptureVideoDataOutput's
     alwaysDiscardsLateVideoFrames property to NO.
	 */
	[videoOut setAlwaysDiscardsLateVideoFrames:YES];
	[videoOut setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];

    if ([captureSession canAddOutput:videoOut])
		[captureSession addOutput:videoOut];
	videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
	self.videoOrientation = [videoConnection videoOrientation];

	return YES;
}

#pragma mark - Audio capture device
- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if (devices.count > 0) {
        return devices[0];
    }
    
    // No capture devices found.
    return nil;
}

#pragma mark - Video capture device
-(AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position)
            return device;
    }
    
    // No device found that match position.
    return nil;
}


#pragma mark - Capture
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMSampleBufferRef processedSampleBuffer = nil;

    if ( connection == videoConnection ) {
        
		// Get framerate
		CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
		[self calculateFramerateAtTimestamp:timestamp];

		// Get frame dimensions (for onscreen display)
		if (self.videoDimensions.width == 0 && self.videoDimensions.height == 0)
			self.videoDimensions = CMVideoFormatDescriptionGetDimensions( formatDescription );

		// Get buffer type
		if ( self.videoType == 0 )
			self.videoType = CMFormatDescriptionGetMediaSubType( formatDescription );

        // GreenMachine
        processedSampleBuffer = [self processFrame:sampleBuffer];

		// Enqueue it for preview.  This is a shallow queue, so if image processing is taking too long,
		// we'll drop this frame for preview (this keeps preview latency low).
		OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, processedSampleBuffer);

		if ( !err ) {
			dispatch_async(dispatch_get_main_queue(), ^{
				//CVPixelBufferRef pixBuf = (CVPixelBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
                CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
                if (sbuf) {
                    CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);

					[self.delegate pixelBufferReadyForDisplay:pixBuf];
					CFRelease(sbuf);
                }
			});
        }
    }

    CFRetain(sampleBuffer);
    CFRetain(formatDescription);
    
    dispatch_async(movieWritingQueue, ^{

        if ( assetWriter && NO) {

//            BOOL wasReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
//
//            if (connection == videoConnection) {
//
//                // Initialize the video input if this is not done yet
//                if (!readyToRecordVideo)
//                {
//                    CMFormatDescriptionRef processedFormatDesc = CMSampleBufferGetFormatDescription(processedSampleBuffer);
//                    readyToRecordVideo = [self setupAssetWriterVideoInput:processedFormatDesc];
//                }
//
//                // Write video data to file
//                if (readyToRecordVideo && readyToRecordAudio)
//                {
//                    //[self saveSampleBuffer:processedSampleBuffer withName:@"beforewriting"];
//                    CVPixelBufferRef processedPixelBuffer = CMSampleBufferGetImageBuffer(processedSampleBuffer);
//                    CVPixelBufferRetain(processedPixelBuffer);
//                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo withPixelBuffer:processedPixelBuffer];
//                    CVPixelBufferRelease(processedPixelBuffer);
//                }
//            }
//            else if (connection == audioConnection) {
//
//                // Initialize the audio input if this is not done yet
//                if (!readyToRecordAudio)
//                    readyToRecordAudio = [self setupAssetWriterAudioInput:formatDescription];
//
//                // Write audio data to file
//                if (readyToRecordAudio && readyToRecordVideo)
//                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio withPixelBuffer:nil];
//            }
//
//            BOOL isReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
//            if ( !wasReadyToRecord && isReadyToRecord ) {
//                recordingWillBeStarted = NO;
//                self.recording = YES;
//                [self.delegate recordingDidStart];
//            }
        }
        CFRelease(sampleBuffer);
        CFRelease(formatDescription);
        if ( m_foregroundExtraction != NULL)
            if (connection == videoConnection && processedSampleBuffer) CFRelease(processedSampleBuffer);
    });
}











//- ( void ) initGreenMachine {
//
//    // Lock focus
//    dispatch_async(movieWritingQueue, ^{
//        CGPoint point = CGPointMake(100,100);
//        AVCaptureDevice *device = [videoIn device];
//        NSError *error = nil;
//        if ([device lockForConfiguration:&error])
//        {
//            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeLocked])
//            {
//                [device setFocusMode:AVCaptureFocusModeLocked];
//                [device setFocusPointOfInterest:point];
//            }
//            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeLocked])
//            {
//                [device setExposureMode:AVCaptureExposureModeLocked];
//                [device setExposurePointOfInterest:point];
//            }
//            [device setSubjectAreaChangeMonitoringEnabled:false];
//            [device unlockForConfiguration];
//        }
//        else
//        {
//            NSLog(@"%@", error);
//        }
//    });
//
//    
//    m_foregroundExtraction = new CUniformBackground();
//    
//    
//    
//    NSString *backgroundImageName = [NSString stringWithFormat:@"LANDSCAPE %d 640x360.png", [[Data shared].currentBackground intValue]+1];
//    NSString * backgroundImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:backgroundImageName ofType:nil];
//    UIImage *backgroundImage = [UIImage imageWithContentsOfFile:backgroundImagePath];
//    image_type *background_image4 = CVtool::DecomposeUIimage(backgroundImage);
//    m_background_image = image3_from(background_image4, NULL);
//    image_destroy(background_image4, 1);
//    
//    NSString * countourFileName = [[Data shared].contours objectAtIndex:[[Data shared].currentFormat intValue]];
//                                   
//    NSString *contourFile = [[NSBundle mainBundle] pathForResource:countourFileName ofType:@"ctr"];
//    
//    m_foregroundExtraction->ReadMask((char*)contourFile.UTF8String, 640, 360);
//    
//    m_original_image = NULL;
//    m_foreground_image = NULL;
//    m_output_image = NULL;
//}
//


#pragma mark Utilities
-(void)calculateFramerateAtTimestamp:(CMTime) timestamp
{
	[previousSecondTimestamps addObject:[NSValue valueWithCMTime:timestamp]];
    
	CMTime oneSecond = CMTimeMake( 1, 1 );
	CMTime oneSecondAgo = CMTimeSubtract( timestamp, oneSecond );
    
	while( CMTIME_COMPARE_INLINE( [[previousSecondTimestamps objectAtIndex:0] CMTimeValue], <, oneSecondAgo ) )
		[previousSecondTimestamps removeObjectAtIndex:0];
    
	Float64 newRate = (Float64) [previousSecondTimestamps count];
	self.videoFrameRate = (self.videoFrameRate + newRate) / 2;
}

#pragma mark - Video processing
- (CMSampleBufferRef)processFrame:(CMSampleBufferRef)sampleBuffer
{
    return sampleBuffer;
    
//    if ( m_foregroundExtraction == NULL ) {
//        return sampleBuffer;
//    }
//    else {
//        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//        
//        
//        //[self savePixelBuffer:pixelBuffer withName:@"Original"];
//        
//        // Converting the given PixelBuffer to image_type (and then converting it to BGR)
//        m_original_image = CVtool::CVPixelBufferRef_to_image_sample2(pixelBuffer, m_original_image);
//        //m_original_image = CVtool::CVPixelBufferRef_to_image(pixelBuffer, m_original_image);
//        image_type* original_bgr_image = image3_to_BGR(m_original_image, NULL);
//        
//        // Extracting the foreground
//        
//        //    // SAVING IMAGE TO DISK
//        //    static int counter = 0;
//        //    counter++;
//        //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        //    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
//        //    NSString *path = [NSString stringWithFormat:@"/%d.jpg" , counter];
//        //    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:path];
//        //    image_type *image = image4_from(original_bgr_image, NULL);
//        //    UIImage *bgImage = CVtool::CreateUIImage(image);
//        //    [UIImageJPEGRepresentation(bgImage, 1.0) writeToFile:dataPath atomically:YES];
//        //    image_destroy(image, 1);
//        
//        //[self saveImageType3:original_bgr_image];
//        
//        
//        m_foregroundExtraction->Process(original_bgr_image, 1, &m_foreground_image);
//        
//        // Stitching the foreground and the background together (and then converting to RGB)
//        m_output_image = m_foregroundExtraction->GetImage(m_background_image, m_output_image);
//        image3_bgr2rgb(m_output_image);
//        
//        // Destroying the temp image
//        image_destroy(original_bgr_image, 1);
//        
//        //[self saveImageType3:m_output_image withName:@"before"];
//        
//        // Converting the result of the algo into CVPixelBuffer
//        CVImageBufferRef processedPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_output_image);
//        
//        //image_type *processedImageType = CVtool::CVPixelBufferRef_to_image(processedPixelBuffer, NULL);
//        //[self savePixelBuffer:processedPixelBuffer withName:@"afterPixel"];
//        //[self saveImageType3:processedImageType withName:@"afterImageType"];
//        
//        // Getting the sample timing info from the sample buffer
//        CMSampleTimingInfo sampleTimingInfo = kCMTimingInfoInvalid;
//        CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &sampleTimingInfo);
//        
//        CMVideoFormatDescriptionRef videoInfo = NULL;
//        CMVideoFormatDescriptionCreateForImageBuffer(NULL, processedPixelBuffer, &videoInfo);
//        
//        CMSampleBufferRef processedSampleBuffer = NULL;
//        CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, processedPixelBuffer, true, NULL, NULL, videoInfo, &sampleTimingInfo, &processedSampleBuffer);
//        
//        CFRelease(processedPixelBuffer);
//        //CFRelease(videoInfo);
//        
//        return processedSampleBuffer;
//        
//        // Updating the current pixelbuffer with the new foreground/background image
//        //[self updatePixelBuffer:pixelBuffer fromImageType:m_output_image];
//    }
    
}



//
//- (void)removeFile:(NSURL *)fileURL
//{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *filePath = [fileURL path];
//    if ([fileManager fileExistsAtPath:filePath]) {
//        NSError *error;
//        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
//		if (!success)
//			[self showError:error];
//    }
//}
//
//- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
//{
//	CGFloat angle = 0.0;
//	
//	switch (orientation) {
//		case AVCaptureVideoOrientationPortrait:
//			angle = 0.0;
//			break;
//		case AVCaptureVideoOrientationPortraitUpsideDown:
//			angle = M_PI;
//			break;
//		case AVCaptureVideoOrientationLandscapeRight:
//			angle = -M_PI_2;
//			break;
//		case AVCaptureVideoOrientationLandscapeLeft:
//			angle = M_PI_2;
//			break;
//		default:
//			break;
//	}
//    
//	return angle;
//}
//
//- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
//{
//	CGAffineTransform transform = CGAffineTransformIdentity;
//    
//	// Calculate offsets from an arbitrary reference orientation (portrait)
//	CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
//	CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:self.videoOrientation];
//	
//	// Find the difference in angle between the passed in orientation and the current video orientation
//	CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
//	transform = CGAffineTransformMakeRotation(angleOffset);
//	
//	return transform;
//}
//
//#pragma mark Recording
//
//- (void)saveMovieToCameraRoll
//{
//	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//	[library writeVideoAtPathToSavedPhotosAlbum:movieURL
//								completionBlock:^(NSURL *assetURL, NSError *error) {
//									if (error)
//										[self showError:error];
//									else
//										[self removeFile:movieURL];
//									
//									dispatch_async(movieWritingQueue, ^{
//										recordingWillBeStopped = NO;
//										self.recording = NO;
//										
//										[self.delegate recordingDidStop];
//									});
//								}];
//	[library release];
//}
//
//- (void) writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType withPixelBuffer:(CVPixelBufferRef)processedPixelBuffer
//{
//	if ( assetWriter.status == AVAssetWriterStatusUnknown ) {
//		
//        if ([assetWriter startWriting]) {
//			[assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
//		}
//		else {
//			[self showError:[assetWriter error]];
//		}
//	}
//	
//	if ( assetWriter.status == AVAssetWriterStatusWriting ) {
//		
//		if (mediaType == AVMediaTypeVideo) {
//			if (assetWriterVideoIn.readyForMoreMediaData) {
//				//if (![assetWriterVideoIn appendSampleBuffer:sampleBuffer]) {
//                if (![_assetWriterPixelBufferIn appendPixelBuffer:processedPixelBuffer withPresentationTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)]) {
//					[self showError:[assetWriter error]];
//				}
//			}
//		}
//		else if (mediaType == AVMediaTypeAudio) {
//			if (assetWriterAudioIn.readyForMoreMediaData) {
//				if (![assetWriterAudioIn appendSampleBuffer:sampleBuffer]) {
//					[self showError:[assetWriter error]];
//				}
//			}
//		}
//	}
//}


//
//- (BOOL) setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
//{
//	const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
//    
//	size_t aclSize = 0;
//	const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
//	NSData *currentChannelLayoutData = nil;
//	
//	// AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
//	if ( currentChannelLayout && aclSize > 0 )
//		currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
//	else
//		currentChannelLayoutData = [NSData data];
//	
//	NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//											  [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
//											  [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
//											  [NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
//											  [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
//											  currentChannelLayoutData, AVChannelLayoutKey,
//											  nil];
//	if ([assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
//		assetWriterAudioIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
//		assetWriterAudioIn.expectsMediaDataInRealTime = YES;
//		if ([assetWriter canAddInput:assetWriterAudioIn])
//			[assetWriter addInput:assetWriterAudioIn];
//		else {
//			NSLog(@"Couldn't add asset writer audio input.");
//            return NO;
//		}
//	}
//	else {
//		NSLog(@"Couldn't apply audio output settings.");
//        return NO;
//	}
//    
//    return YES;
//}
//
//- (BOOL) setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
//{
//	float bitsPerPixel;
//	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
//	int numPixels = dimensions.width * dimensions.height;
//	int bitsPerSecond;
//	
//	// Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
//	if ( numPixels < (640 * 480) )
//		bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
//	else
//		bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
//	
//	bitsPerSecond = numPixels * bitsPerPixel;
//	
//	NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//											  AVVideoCodecH264, AVVideoCodecKey,
//											  [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
//											  [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
//											  [NSDictionary dictionaryWithObjectsAndKeys:
//											   [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
//											   [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
//											   nil], AVVideoCompressionPropertiesKey,
//											  nil];
//	if ([assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
//		assetWriterVideoIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
//		assetWriterVideoIn.expectsMediaDataInRealTime = YES;
//		assetWriterVideoIn.transform = [self transformFromCurrentVideoOrientationToOrientation:self.referenceOrientation];
//        _assetWriterPixelBufferIn = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoIn sourcePixelBufferAttributes:nil];
//        [_assetWriterPixelBufferIn retain];
//		if ([assetWriter canAddInput:assetWriterVideoIn])
//			[assetWriter addInput:assetWriterVideoIn];
//		else {
//			NSLog(@"Couldn't add asset writer video input.");
//            return NO;
//		}
//	}
//	else {
//		NSLog(@"Couldn't apply video output settings.");
//        return NO;
//	}
//    
//    return YES;
//}
//
//- (void) startRecording
//{
//	dispatch_async(movieWritingQueue, ^{
//        
//		if ( recordingWillBeStarted || self.recording )
//			return;
//        
//		recordingWillBeStarted = YES;
//        
//		// recordingDidStart is called from captureOutput:didOutputSampleBuffer:fromConnection: once the asset writer is setup
//		[self.delegate recordingWillStart];
//        
//		// Remove the file if one with the same name already exists
//		[self removeFile:movieURL];
//        
//		// Create an asset writer
//		NSError *error;
//		assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:(NSString *)kUTTypeQuickTimeMovie error:&error];
//		if (error)
//			[self showError:error];
//	});
//}
//
//- (void) stopRecording
//{
//	dispatch_async(movieWritingQueue, ^{
//		
//		if ( recordingWillBeStopped || (self.recording == NO) )
//			return;
//		
//		recordingWillBeStopped = YES;
//		
//		// recordingDidStop is called from saveMovieToCameraRoll
//		[self.delegate recordingWillStop];
//        
//		if ([assetWriter finishWriting]) {
//			[assetWriterAudioIn release];
//			[assetWriterVideoIn release];
//			[assetWriter release];
//            [_assetWriterPixelBufferIn release];
//			assetWriter = nil;
//			
//			readyToRecordVideo = NO;
//			readyToRecordAudio = NO;
//			
//			[self saveMovieToCameraRoll];
//		}
//		else {
//			[self showError:[assetWriter error]];
//		}
//	});
//}
//
//#pragma mark Processing
//
//- (void)processPixelBuffer: (CVImageBufferRef)pixelBuffer
//{
//	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
//	
//	int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
//	int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
//	unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
//    
//	for( int row = 0; row < bufferHeight; row++ ) {
//		for( int column = 0; column < bufferWidth; column++ ) {
//			pixel[1] = 0; // De-green (second pixel in BGRA is green)
//			pixel += BYTES_PER_PIXEL;
//		}
//	}
//	
//	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
//}
//
//-(void)updatePixelBuffer:(CVImageBufferRef)pixelBuffer fromImageType:(image_type *)im
//{
//    int i,   j;
//	
//	u_char *sp = im->data;
//    
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0 );
//	unsigned char *buffer = (u_char *)CVPixelBufferGetBaseAddress(pixelBuffer);
//    int k;
//	for( i = 0, k = 0 ; i < im->height ; i++ ){
//		for( j = 0 ; j < im->width ; j++, sp += 3, k+= 4 ){
//			buffer[k] = sp[0];   // R
//			buffer[k+1] = sp[1]; // G
//			buffer[k+2] = sp[2]; // B
//			buffer[k+3] = 0;     // A
//            
//            
//		}
//	}
//    
//    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
//}
//


//
//- (UIImage*) UIImageFromPixelBuffer:(CVPixelBufferRef) pixelBuffer
//{
//    
//    size_t width = CVPixelBufferGetWidth(pixelBuffer);
//    size_t height = CVPixelBufferGetHeight(pixelBuffer);
//    
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0 );
//    unsigned char *pixels = (u_char *)CVPixelBufferGetBaseAddress(pixelBuffer);
//    
//    int size = (int)(width * height * 4);
//    
//    //   size_t width                    = width;
//    //   size_t height                   = height;
//    size_t bitsPerComponent         = 8;
//    size_t bitsPerPixel             = 32;
//    size_t bytesPerRow              = width * 4;
//    
//    CGColorSpaceRef colorspace      = CGColorSpaceCreateDeviceRGB();
//    CGBitmapInfo bitmapInfo         = kCGBitmapByteOrderDefault;
//    
//    NSData* newPixelData = [NSData dataWithBytes:pixels length:size];
//    CFDataRef imgData = (CFDataRef)newPixelData;
//    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData(imgData);
//    
//    CGImageRef newImageRef = CGImageCreate (
//                                            width,
//                                            height,
//                                            bitsPerComponent,
//                                            bitsPerPixel,
//                                            bytesPerRow,
//                                            colorspace,
//                                            bitmapInfo,
//                                            imgDataProvider,
//                                            NULL,
//                                            NO,
//                                            kCGRenderingIntentDefault
//                                            );
//    
//    UIImage *newImage   = [[UIImage alloc] initWithCGImage:newImageRef];//[UIImage imageWithCGImage:newImageRef];
//    
//    CGColorSpaceRelease(colorspace);
//    CGDataProviderRelease(imgDataProvider);
//    CGImageRelease(newImageRef);
//    
//    
//    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
//    
//    
//    return [newImage autorelease];
//}
//- (void)saveImageType3:(image_type *)image3 withName:(NSString *)name
//{
//    image_type* image4 = image4_from(image3, NULL);
//    UIImage *imageToSave = CVtool::CreateUIImage(image4);
//    [self saveImage:imageToSave withName:name];
//    image_destroy(image4, 1);
//}
//     
//- (void)savePixelBuffer:(CVPixelBufferRef)pixelBuffer withName:(NSString *)name
//{
//    UIImage *image = [self imageFromPixelBuffer:pixelBuffer];
//    //UIImage *image = [self UIImageFromPixelBuffer:pixelBuffer];
//    [self saveImage:image withName:name];
//}
//
//- (void)saveSampleBuffer:(CMSampleBufferRef)samlpleBuffer withName:(NSString *)name
//{
//    UIImage *bgImage = [self imageFromSampleBuffer:samlpleBuffer];
//    [self saveImage:bgImage withName:name];
//}
//
//- (void)saveImage:(UIImage *) image withName:(NSString *)name
//{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
//
//    static int counter = 0;
//    ++counter;
//    
//    NSString *path = [NSString stringWithFormat:@"%@-%d.jpg" , name, counter];
//    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:path];
//    
//    [UIImageJPEGRepresentation(image, 1.0) writeToFile:dataPath atomically:YES];
//}
//
//// Create a UIImage from sample buffer data
//- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
//{
//    // Get a CMSampleBuffer's Core Video image buffer for the media data
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//    return [self imageFromPixelBuffer:imageBuffer];
//}
//
//// Create a UIImage from sample buffer data
//- (UIImage *) imageFromPixelBuffer:(CVImageBufferRef) imageBuffer
//{
//    // Lock the base address of the pixel buffer
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    
//    // Get the number of bytes per row for the pixel buffer
//    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//    
//    // Get the number of bytes per row for the pixel buffer
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    // Get the pixel buffer width and height
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    
//    // Create a device-dependent RGB color space
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    // Create a bitmap graphics context with the sample buffer data
//    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
//                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    // Create a Quartz image from the pixel data in the bitmap graphics context
//    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
//    // Unlock the pixel buffer
//    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//    
//    // Free up the context and color space
//    CGContextRelease(context);
//    CGColorSpaceRelease(colorSpace);
//    
//    // Create an image object from the Quartz image
//    UIImage *image = [UIImage imageWithCGImage:quartzImage];
//    
//    // Release the Quartz image
//    CGImageRelease(quartzImage);
//    
//    return (image);
//}
//
//

//
//
//- (BOOL) setupCaptureSession
//{
//	/*
//     Overview: RosyWriter uses separate GCD queues for audio and video capture.  If a single GCD queue
//     is used to deliver both audio and video buffers, and our video processing consistently takes
//     too long, the delivery queue can back up, resulting in audio being dropped.
//     
//     When recording, RosyWriter creates a third GCD queue for calls to AVAssetWriter.  This ensures
//     that AVAssetWriter is not called to start or finish writing from multiple threads simultaneously.
//     
//     RosyWriter uses AVCaptureSession's default preset, AVCaptureSessionPresetHigh.
//	 */
//    
//    /*
//	 * Create capture session
//	 */
//    captureSession = [[AVCaptureSession alloc] init];
//    
//    captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
//    
//    /*
//	 * Create audio connection
//	 */
//    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
//    if ([captureSession canAddInput:audioIn])
//        [captureSession addInput:audioIn];
//	[audioIn release];
//	
//	AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
//	dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
//	[audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];
//	dispatch_release(audioCaptureQueue);
//	if ([captureSession canAddOutput:audioOut])
//		[captureSession addOutput:audioOut];
//	audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
//	[audioOut release];
//    
//	/*
//	 * Create video connection
//	 */
//    videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionBack] error:nil];
//
//    
//    if ([captureSession canAddInput:videoIn])
//        [captureSession addInput:videoIn];
////	[videoIn release];
//    
//	AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
//	/*
//     RosyWriter prefers to discard late video frames early in the capture pipeline, since its
//     processing can take longer than real-time on some platforms (such as iPhone 3GS).
//     Clients whose image processing is faster than real-time should consider setting AVCaptureVideoDataOutput's
//     alwaysDiscardsLateVideoFrames property to NO.
//	 */
//	[videoOut setAlwaysDiscardsLateVideoFrames:YES];
//	[videoOut setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
//	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
//	[videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
//	dispatch_release(videoCaptureQueue);
//	if ([captureSession canAddOutput:videoOut])
//		[captureSession addOutput:videoOut];
//	videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
//	self.videoOrientation = [videoConnection videoOrientation];
//	[videoOut release];
//    
//    
//    
//
//    
//    
//	return YES;
//}
//

//
//- (void) pauseCaptureSession
//{
//	if ( captureSession.isRunning )
//		[captureSession stopRunning];
//}
//
//- (void) resumeCaptureSession
//{
//	if ( !captureSession.isRunning )
//		[captureSession startRunning];
//}
//
//- (void)captureSessionStoppedRunningNotification:(NSNotification *)notification
//{
//	dispatch_async(movieWritingQueue, ^{
//		if ( [self isRecording] ) {
//			[self stopRecording];
//		}
//	});
//}
//
//- (void) stopAndTearDownCaptureSession
//{
//    [captureSession stopRunning];
//	if (captureSession)
//		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:captureSession];
//	[captureSession release];
//	captureSession = nil;
//	if (previewBufferQueue) {
//		CFRelease(previewBufferQueue);
//		previewBufferQueue = NULL;
//	}
//	if (movieWritingQueue) {
//		dispatch_release(movieWritingQueue);
//		movieWritingQueue = NULL;
//	}
//}
//
//#pragma mark Error Handling
//
//- (void)showError:(NSError *)error
//{
//    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
//                                                            message:[error localizedFailureReason]
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//        [alertView show];
//        [alertView release];
//    });
//}

@end