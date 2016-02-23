//
//  EMRecorderVC2.swift
//  emu
//
//  Created by Aviv Wolf on 05/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import UIKit

class EMRecorderVC2: UIViewController, HFCaptureSessionDelegate, EMOnboardingDelegate, EMPreviewDelegate {
    //
    // MARK: - IB Outlets
    //
    
    // Camera preview
    @IBOutlet weak var guiCameraPreviewViewContainer: HFCameraPreviewView!
    
    // Recording preview
    @IBOutlet weak var guiRecordingPreviewContainer: UIView!

    // Messages
    @IBOutlet weak var guiMessageContainer: UIView!
    @IBOutlet weak var guiMessageBlurry: UIView!
    @IBOutlet weak var guiMessageLabel: UILabel!
    
    // Buttons
    @IBOutlet weak var guiRecordButton: EMRecordButton!
    @IBOutlet weak var guiContinueAnywayButton: EMFlowButton!
    @IBOutlet weak var guiRestartButton: UIButton!
    @IBOutlet weak var guiHelpButton: UIButton!
    @IBOutlet weak var guiCancelButton: UIButton!
    
    // Record timing
    @IBOutlet weak var guiTimingContainer: UIView!
    @IBOutlet weak var guiTimingLabel: UILabel!
    @IBOutlet weak var guiTimingProgress: EMTickingProgressView!
    
    // Long render progress
    @IBOutlet weak var guiLongRenderProgressView: YLProgressBar!
    
    // Review buttons
    @IBOutlet weak var guiPositiveButton: EMFlowButton!
    @IBOutlet weak var guiNegativeButton: EMFlowButton!
    
    // Questions label
    @IBOutlet weak var guiQuestionLabel: EMLabel!
    
    
    //
    // MARK: - Properties
    //
    
    // info
    var info : NSDictionary?
    var package : Package?
    var emuticonsOID : NSArray?
    var msgUUID: String = ""
    var latestRecordingInfo : [NSObject:AnyObject]?
    var shouldRecordAudio : Bool = false
    
    // Timing
    var duration : NSTimeInterval = 2.0
    
    // Slots (joint emu)
    var slotIndex: Int = 0
    var isDedicatedFootage: Bool = false
    
    // delegate
    weak var delegate: EMRecorderDelegate?
    
    // capture session
    var captureSession : HFCaptureSession?
    
    // recording preview
    var emuticonDefOIDForPreview : NSString?
    var emuticonDefNameForPreview : NSString?
    var previewEmuticon : Emuticon?
    var emuDefForPreviewLastUsed : EmuticonDef?
    var recordingPreviewVC: EMVideoVC?
    
    //
    // onboarding & flow (will always show onboarding in this implementation)
    //
    weak var onBoardingVC : EMOnboardingVC?
    var flowType : EMRecorderFlowType = EMRecorderFlowType.Invalid
    
    
    // MARK: - Factories
    class func recorderVCWithConfigInfo(info: NSDictionary!) -> EMRecorderVC2
    {
        let storyBoard = UIStoryboard.init(name: "EMRecorder2", bundle: nil)
        let vc = storyBoard.instantiateViewControllerWithIdentifier("recorder vc 2") as! EMRecorderVC2
        vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        vc.configureWithInfo(info)
        vc.reportOpeningRecorder()
        return vc
    }
    
    // MARK: - Initialization
    func initGUI() {
        self.guiRecordButton.hidden = true
        self.guiContinueAnywayButton.hidden = true
        self.guiContinueAnywayButton.setTitle(EML.s("RECORDER_CONTINUE_BUTTON"), forState: UIControlState.Normal)

        //
        // Review buttons
        //
        self.guiPositiveButton.positive = true
        self.guiNegativeButton.positive = false
        
        //
        // Messages bar
        //
        self.guiMessageBlurry.backgroundColor = UIColor.clearColor()
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = self.guiMessageBlurry.bounds
        self.guiMessageBlurry.addSubview(visualEffectView)
        self.guiMessageContainer.layer.cornerRadius = 15
        self.guiMessageContainer.clipsToBounds = true
        self.hideMessage(false)
        
        //
        // The timing bar (replace with YLProgress? it looks much better)
        //
        let layer = self.guiTimingContainer.layer
        layer.borderColor = EmuStyle.colorMain1().CGColor
        layer.backgroundColor = EmuStyle.colorMainBG1().CGColor
        layer.borderWidth = 2
        layer.cornerRadius = 15
        self.guiTimingLabel.text = "3 seconds"
        self.guiTimingLabel.textColor = EmuStyle.colorMain1()
        self.hideRecordingPreviewAnimated(false)
        
        //
        // The long render progress bar
        //
        EmuStyle.sh().styleYLProgressBar(self.guiLongRenderProgressView)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.guiCameraPreviewViewContainer.alpha = 0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.initGUI()
        self.guiCameraPreviewViewContainer.initializeGL()
        self.initCaptureSession()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.guiCameraPreviewViewContainer.initializeSilhouetteUIInParentVC(self)
        self.initObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeObservers()
    }
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch(segue.identifier!) {
            case "onboarding segue 2":
                self.onBoardingVC = segue.destinationViewController as? EMOnboardingVC
                self.onBoardingVC?.flowType = self.flowType
                self.onBoardingVC?.delegate = self
            case "recording preview segue":
                self.recordingPreviewVC = segue.destinationViewController as? EMVideoVC
                self.recordingPreviewVC?.previewDelegate = self
            default:
                break
        }
    }
    
    // MARK: - Capture session
    func initCaptureSession() {
        if self.captureSession != nil {return}

        // Initialize the capture session for this recorder.
        let bgNum = 3
        let imageName = "replaced-bg\(bgNum)-480.png"
        let bgImage = UIImage(named: imageName)
        
        let hfc = HFCaptureSession(forBGRemovalWithPreset: AVCaptureSessionPreset640x480,
            processingResolutionType: hcbResolution.Square480,
            processingSilhouetteType: hcbSilhouetteType.Default,
                             bgImage: bgImage)
        hfc.cameraPreviewView = self.guiCameraPreviewViewContainer
        hfc.setupAndStartCaptureSession()
        hfc.delegate = self
        self.captureSession = hfc
    }
    
    // MARK: - Configuration
    
    /**
    Given info about the required retake, will return the flow type corresponding
    to that recorder configuration info.
    
    - parameter info: NSDictionary holding info about what to retake.
    
    - returns: EMRecorderFlowType the flow type corresponding to the provided configuration info.
    */
    class func chooseFlowTypeByProvidedInfo(info: NSDictionary) -> EMRecorderFlowType {
        
        // First take ever! - onboarding flow.
        if info[emkFirstTake]?.boolValue == true {
            return EMRecorderFlowType.Onboarding
        }
        
        // Retake all flow.
        if info[emkRetakeAll]?.boolValue == true {
            return EMRecorderFlowType.RetakeAll
        }
        
        // Retake a list of emuticons (all in a given pack)
        if info[emkRetakePackageOID] != nil {
            return EMRecorderFlowType.RetakeForSpecificEmuticons
        }
        
        // Retake a list of emuticons
        if let emuticonsList = info[emkRetakeEmuticonsOID] as? NSArray {
            if emuticonsList.count > 0 {
                return EMRecorderFlowType.RetakeForSpecificEmuticons
            }
        }
        
        return EMRecorderFlowType.NewTake
    }
    
    
    func configureWithInfo(info: NSDictionary!) {
        self.info = info;
        self.flowType = EMRecorderVC2.chooseFlowTypeByProvidedInfo(info)
        switch self.flowType {
            case EMRecorderFlowType.Onboarding:
                self.configureForOnboarding()
            case EMRecorderFlowType.RetakeForSpecificEmuticons:
                self.configureForRetakeEmuticons()
            case EMRecorderFlowType.NewTake:
                self.configureForNewTake()
            default:
                break
        }
    }
    
    func configureForOnboarding() {
        if let info = self.info {
            self.emuticonDefNameForPreview = info[emkEmuticonDefName] as? NSString;
            self.emuticonDefOIDForPreview = info[emkEmuticonDefOID] as? NSString;
        }
    }
    
    func configureForRetakeEmuticons() {
        let info = self.info!
        
        if let specificEmuticonDefOID = info[emkEmuticonDefOID] as? String {
            //
            // Specic emu def requested to be used for preview.
            //
            self.emuticonDefNameForPreview = info[emkEmuticonDefName] as? NSString
            self.emuticonDefOIDForPreview = specificEmuticonDefOID
        } else if let emuticonsOID = info[emkRetakeEmuticonsOID] as? NSArray {
            //
            // A list of emus provided to be retaken.
            //
            self.emuticonsOID = emuticonsOID
        } else if let packageOID = info[emkRetakePackageOID] as? String {
            //
            // A package was requested to be retaken.
            //
            let package = Package.findWithID(packageOID, context: EMDB.sh().context)
            self.emuticonsOID = package?.emuticonsOIDS()
        }
        
        if let emusOIDS = self.emuticonsOID where emusOIDS.count > 0 {
            // If list of emus set, use one of them for the preview.
            let emuOID = emusOIDS.lastObject as! String
            if let emu = Emuticon.findWithID(emuOID, context: EMDB.sh().context) {
                self.emuticonDefNameForPreview = emu.emuDef?.name
                self.emuticonDefOIDForPreview = emu.emuDef?.oid
            }
        }
        
        //
        // More configurations.
        //
        
        if info[emkDedicatedFootage] != nil {
            // Dedicated footage.
            self.isDedicatedFootage = info[emkDedicatedFootage] as! Bool
        }
        
        if info[emkDuration] != nil {
            // Specific duration.
            self.duration = info[emkDuration] as! NSTimeInterval
        }
        
        if info[emkJEmuSlot] != nil {
            // Slot index in joint emus.
            self.slotIndex = info[emkJEmuSlot] as! Int
        }
    }
    
    func configureForNewTake() {
        guard let info = self.info else {return}
        if info[emkRetakePackageOID] != nil {
            if let package = Package.findWithID(
                info[emkRetakePackageOID] as? String,
                context: EMDB.sh().context) {
                    self.package = package
                    self.emuticonsOID = self.package?.emuticonsOIDS()
            }
        }
        if info[emkEmuticonDefOID] != nil {
            self.emuticonDefOIDForPreview = info[emkEmuticonDefOID] as? String
            self.emuticonDefNameForPreview = info[emkEmuticonDefName] as? String
        }
    }

    //
    // MARK: - Observers
    //
    func initObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addUniqueObserver(
            self,
            selector: "onBGMarkUpdate:",
            name: hfpNotificationBackgroundInfo,
            object: nil)
        
        nc.addUniqueObserver(
            self,
            selector: "onRenderProgress:",
            name: hcrNotificationRenderProgress,
            object: nil)
    }
    
    func removeObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(hfpNotificationBackgroundInfo)
        nc.removeObserver(hcrNotificationRenderProgress)
    }

    // MARK: - Observers handlers
    func onBGMarkUpdate(notification: NSNotification) {
        guard let info = notification.userInfo else {return}
        guard let bgMark = info[hfpBGMark] as? Int else {return}
        guard let key = info[hfpBGMarkTextKey] as? String else {return}
        
        let text = EML.s(key)
        self.showMessage("\(text)", positive: (bgMark > 0))
        
        let button = self.guiContinueAnywayButton
        if bgMark > 0 {
            button.setTitle(EML.s("RECORDER_CONTINUE_BUTTON"), forState: .Normal)
        } else {
            button.setTitle(EML.s("RECORDER_CONTINUE_ANYWAY_BUTTON"), forState: .Normal)
        }
    }
    
    func onRenderProgress(notification: NSNotification) {
        guard let renderer = self.recordingPreviewVC?.renderer else {return}
        guard let info = notification.userInfo else {return}
        guard let moreInfo = info["userInfo"] as? [NSObject:AnyObject] else {return}
        guard renderer.uuid == moreInfo["uuid"] as? String else {return}
        guard let progress = info[hcrProgress] as? CGFloat else {return}
        
        self.guiLongRenderProgressView.setProgress(progress, animated: true)
    }
    
    // MARK: - Status bar & Orientation
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    // MARK: - Reporting
    func reportOpeningRecorder() {
        
    }
    
    //
    // MARK: - Messages
    //
    func showMessage(msg: String, positive: Bool) {
        let uuid = NSUUID().UUIDString
        self.msgUUID = uuid;
        if !self.messageIsShown() {
            self.guiMessageContainer.alpha = 1
        }
        
        self.guiMessageLabel.text = msg
        var bgColor = positive ? EmuStyle.colorButtonBGPositive():EmuStyle.colorButtonBGNegative()
        bgColor = bgColor.colorWithAlphaComponent(0.5)
        self.guiMessageContainer.backgroundColor = bgColor
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue(), {
            if self.msgUUID == uuid {
                self.hideMessage(true)
            }
        })
    }
    
    func hideMessage(animated: Bool) {
        if animated {
            UIView.animateWithDuration(0.3, animations: {
                self.hideMessage(false)
            })
            return
        }
        self.guiMessageContainer.alpha = 0
    }
    
    func messageIsShown() -> Bool {
        return self.guiMessageContainer.alpha == 1
    }
    
    //
    // MARK: - EMOnboardingDelegate
    //
    func onboardingDidGoBackToStageNumber(stageNumber: Int) {
        
    }
    
    func onboardingUserWantsToCancel() {
        self.delegate?.recorderCanceledByTheUserInFlow(self.flowType, info: self.info as? [NSObject:AnyObject])
    }
    
    func onboardingWantsToSwitchCamera() {
        self.captureSession?.switchCamera()
    }
    
    //
    // MARK: - States
    //
    func updateToState(toState: HFProcessingState) {
        switch toState {
        case HFProcessingState.Idle:
            self.hideItAll()
            if self.guiCameraPreviewViewContainer.alpha != 1 {
                UIView.animateWithDuration(0.3, delay: 0.2, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.guiCameraPreviewViewContainer.alpha = 1
                }, completion:nil)
            }
            self.onBoardingVC?.setOnBoardingStage(EMOnBoardingStage.Welcome, animated: true)
        case HFProcessingState.InspectFrames:
            self.hideItAll()
            self.guiContinueAnywayButton.hidden = false
            self.onBoardingVC?.setOnBoardingStage(EMOnBoardingStage.Align, animated: true)
        case HFProcessingState.ProcessFrames:
            self.hideItAll()
            self.guiRecordButton.hidden = false
            self.guiRestartButton.hidden = false
            self.guiTimingContainer.hidden = false
            self.guiHelpButton.hidden = false
            self.updateTimingIndicator()
            self.onBoardingVC?.setOnBoardingStage(EMOnBoardingStage.ExtractionPreview, animated: true)
        default:
            break
        }
    }
    
    func hideItAll() {
        self.guiTimingProgress.reset()
        self.guiRecordButton.hidden = true
        self.guiContinueAnywayButton.hidden = true
        self.guiRestartButton.hidden = true
        self.guiTimingContainer.hidden = true
        self.guiCancelButton.hidden = true
        self.guiHelpButton.hidden = true
        self.guiPositiveButton.hidden = true
        self.guiNegativeButton.hidden = true
        self.guiQuestionLabel.hidden = true
        self.guiLongRenderProgressView.hidden = true
    }
    
    func renderingUI() {
        self.onBoardingVC?.setOnBoardingStage(EMOnBoardingStage.Review, animated: true)
        self.guiRecordButton.hidden = true
        self.guiContinueAnywayButton.hidden = true
        self.guiRestartButton.hidden = true
        self.guiCancelButton.hidden = true
        self.guiHelpButton.hidden = true

        // Rendering message
        self.guiTimingContainer.hidden = false
        self.guiTimingProgress.reset()
        self.guiTimingLabel.text = "Please wait while rendering video"
        
        // Progress bar
        if self.duration > 2.0 {
            self.guiLongRenderProgressView.hidden = false
            self.guiLongRenderProgressView.setProgress(0, animated: false)
        }
    }

    
    //
    // MARK: - HFCaptureSessionDelegate
    //
    func sessionUpdatedFromState(fromState: HFProcessingState, toState: HFProcessingState) {
        if fromState != HFProcessingState.ProcessFrames && toState == HFProcessingState.ProcessFrames {
            EMUISound.sh().playSoundNamed(SND_HAPPY)
        }
        self.updateToState(toState)
    }
    
    func sessionUsingCameraPosition(position: AVCaptureDevicePosition) {
        
    }
    
    func recordingDidFailWithError(error: NSError!) {
        self.updateToState(HFProcessingState.ProcessFrames)
    }
    
    func recordingDidStartWithInfo(info: [NSObject : AnyObject]!) {
    }
    
    func recordingDidStopWithInfo(info: [NSObject : AnyObject]!) {
        dispatch_async(dispatch_get_main_queue()) {
            EMUISound.sh().playSoundNamed(SND_RECORDING_ENDED)
        }

        self.captureSession?.stopAndTearDownCaptureSession()
        self.captureSession = nil
        self.updateToState(HFProcessingState.ProcessFrames)
        
        // Will show preview screen.
        self.renderingUI()
        self.guiCameraPreviewViewContainer.alpha = 0
        self.showRecordingPreviewAnimated(true)
        self.latestRecordingInfo = info
        self.recordingPreviewVC?.renderEmuDef(
            self.emuticonDefOIDForPreview as! String,
            captureInfo: info,
            slotIndex: self.slotIndex
        )
    }
    
    func recordingWasCanceledWithInfo(info: [NSObject : AnyObject]!) {
        self.updateToState(HFProcessingState.ProcessFrames)
    }
    
    //
    // MARK: - Timing
    //
    func updateTimingIndicator() {
        let durationInSeconds = Int(self.duration)
        var title = EML.s("X_SECONDS_VIDEO")
        title = title.stringByReplacingOccurrencesOfString("#", withString: String(durationInSeconds))
        self.guiTimingLabel.text = title
        self.guiTimingLabel.animateQuickPopIn()
    }
    
    //
    // MARK: - Restart & Failures
    //
    func epicFail() {
        let alert = UIAlertController(
            title: EML.s("ERROR_TITLE"),
            message: EML.s("SOMETHING_WENT_WRONG"),
            preferredStyle: UIAlertControllerStyle.Alert)
        
        
        if self.flowType != EMRecorderFlowType.Onboarding {
            alert.addAction(UIAlertAction(title: EML.s("CANCEL"), style: UIAlertActionStyle.Cancel, handler:{(UIAlertAction) -> Void in
                
            }))
        }

        alert.addAction(UIAlertAction(title: EML.s("TRY_AGAIN"), style: UIAlertActionStyle.Default, handler:{(UIAlertAction) -> Void in
            self.restartItAll()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func restartItAll() {
        // Delete temp files and restart recorder session
        self.recordingPreviewVC!.stop()
        self.hideRecordingPreviewAnimated(false)
        self.initCaptureSession()
        self.captureSession?.resetAndStartAutoFlow()
    }
    
    //
    // MARK: - Recording
    //
    func startRecording() {
        self.latestRecordingInfo = nil
        if self.captureSession?.isRecording == true {return}

        //
        // Writer
        //
        self.shouldRecordAudio = false
        let writer = HFWriterVideo()
        writer.videoBitsPerPixel = 21.0
        if self.shouldRecordAudio {
            writer.includingAudio = true
            writer.audioSampleRate = 21000
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
            } catch {}
        }
        self.captureSession?.startRecordingUsingWriter(writer, duration: self.duration)
        
        //
        // Onboarding UI
        //
        self.onBoardingVC?.setOnBoardingStage(EMOnBoardingStage.Recording, animated: true)
    }
    
    //
    // MARK: - Recording preview
    //
    func showRecordingPreviewAnimated(animated : Bool) {
        self.guiRecordingPreviewContainer.hidden = false
        if animated {
            UIView.animateWithDuration(0.4, animations: {
                self.showRecordingPreviewAnimated(false)
            })
            return
        }
        self.guiRecordingPreviewContainer.alpha = 1;
    }
    
    func hideRecordingPreviewAnimated(animated : Bool) {
        if animated {
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.hideRecordingPreviewAnimated(false)
            })
            return
        }
        self.guiRecordingPreviewContainer.alpha = 0;
    }
    
    func confirmFootageUI() {
        self.guiPositiveButton.hidden = false
        self.guiNegativeButton.hidden = false
        self.guiQuestionLabel.hidden = false
        self.guiTimingContainer.hidden = true
        
        // texts
        self.guiPositiveButton.setTitle(EML.s("RECORDER_PREVIEW_CONFIRM"), forState: UIControlState.Normal)
        self.guiNegativeButton.setTitle(EML.s("RECORDER_PREVIEW_TRY_AGAIN_BUTTON"), forState: UIControlState.Normal)
        self.guiQuestionLabel.text = EML.s("RECORDER_MESSAGE_REVIEW_PREVIEW")
    }
    
    //
    // MARK: - EMPreviewDelegate
    //
    func previewIsShownWithInfo(info : [NSObject:AnyObject]) {
        self.confirmFootageUI()
        
        if self.guiLongRenderProgressView.hidden == false {
            self.guiLongRenderProgressView.setProgress(1, animated: true)
            UIView.animateWithDuration(0.3, animations: {
                self.guiLongRenderProgressView.alpha = 0
            }, completion: {finished in
                self.guiLongRenderProgressView.alpha = 1
                self.guiLongRenderProgressView.hidden = true
            })
        }
    }
    
    func previewDidFailWithInfo(info : [NSObject:AnyObject]) {
    }
    
    // MARK: - IB Actions
    // ===========
    // IB Actions.
    // ===========
    @IBAction func onPressedContinueButton(sender: EMFlowButton) {
        self.captureSession?.continueAnyway()
    }

    @IBAction func onPressedRecordButton(sender: AnyObject) {
        if self.captureSession?.isRecording == true {return}

        // UI
        self.guiRecordButton.hidden = true
        
        // Don't play sound when starting to record with audio.
        if self.shouldRecordAudio {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
        } else {
            EMUISound.sh().playSoundNamed(SND_START_RECORDING)            
        }

        self.guiTimingProgress.startTickingForDuration(self.duration, ticksPerSecond: 2)
        self.guiCancelButton.hidden = false
        self.hideMessage(false)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.startRecording()
        }
    }
    
    @IBAction func onPressedRestartButton(sender: UIButton) {
        self.captureSession?.resetAndStartAutoFlow()
    }
    
    @IBAction func onPressedCancelButton(sender: AnyObject) {
        if (self.captureSession?.isRecording == false) {return}
        EMUISound.sh().playSoundNamed(SND_CANCEL)
        self.guiTimingProgress.done()
        self.guiCancelButton.hidden = true
        self.captureSession?.cancelRecording()
    }

    @IBAction func onPressedHelpButton(sender: AnyObject) {
        
    }
    
    @IBAction func onPressedPositiveButton(sender: UIButton) {
        sender.hidden = true
        
        // Create a new footage object
        let oid = NSUUID().UUIDString
        let footage = UserFootage.newFootageWithID(oid, captureInfo: self.latestRecordingInfo, context: EMDB.sh().context)
        if footage == nil || footage.isAvailable() == false {
            self.epicFail()
            return
        }
        let appCFG = AppCFG.cfgInContext(EMDB.sh().context)
        
        // Apply the footage according to flow type.
        if (self.flowType == EMRecorderFlowType.Onboarding) {
            
            // Make it the default footage.
            appCFG.prefferedFootageOID = footage.oid
            appCFG.onboardingPassed = true
            
        } else if (self.flowType == EMRecorderFlowType.RetakeForSpecificEmuticons) {
            
            // Set the preffered footage for all emus in the list to the new footage
            if let emusOID = self.emuticonsOID {
                for emuOID in emusOID as! [String] {
                    let emu = Emuticon.findWithID(emuOID, context: EMDB.sh().context)
                    if emu == nil {continue}
                    
                    if let previousFootageOID = emu.prefferedFootageOID {
                        if let previousFootage = UserFootage.findWithID(previousFootageOID, context: EMDB.sh().context) {
                            if previousFootage.isDedicatedCapture() {
                                previousFootage.deleteAndCleanUp()
                            }
                        }
                    }
                    
                    emu.prefferedFootageOID = footage.oid
                    
                    // And clean previous renders so the emu will render
                    // with the new footage.
                    emu.cleanUp()
                }
            }
        }

        // Save
        EMDB.sh().save()

        self.delegate?.recorderWantsToBeDismissedAfterFlow(
            self.flowType,
            info: self.info! as [NSObject : AnyObject])

        // Render gif for the
//        EMRenderManager3.sh().renderGifForFootage(footage) {sucess in
//            if (success == true) {
//                // Dismiss the recorder
//            } else {
//                self.epicFail()
//            }
//        }

    }

    @IBAction func onPressedNegativeButton(sender: AnyObject) {
        self.restartItAll()
    }
    
}
