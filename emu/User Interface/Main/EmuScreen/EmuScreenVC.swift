//
//  EmuScreenVC.swift
//  emu
//
//  Created by Aviv Wolf on 29/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import UIKit

protocol EmuSelectionProtocol: class {
    func emuSelected(emu: Emuticon?)
    func emuPressed(emu: Emuticon?)
    func emuSelectionScrolled()
}

class EmuScreenVC: UIViewController,
    EmuSelectionProtocol,
    EMShareDelegate,
    EMInterfaceDelegate,
    EMPreviewDelegate,
    EMRecorderDelegate,
    EMHolySheetDelegate {
    
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //
    // Outlets
    //
    
    // Nav
    @IBOutlet weak var guiTitle: EMLabel!
    @IBOutlet weak var guiNavBarView: UIView!
    
    // Emus carousel container
    @IBOutlet weak var guiEmusContainer: UIView!
    
    // User messages
    @IBOutlet weak var guiUserGuidanceTitle: EMLabel!
    
    // Sharing
    @IBOutlet weak var guiShareMediaTypeSelector: UISegmentedControl!
    @IBOutlet weak var guiSharingContainer: UIView!
    
    // Actions
    @IBOutlet weak var guiActionButtonContainer: UIView!
    @IBOutlet weak var guiActionButton: EMFlowButton!
    
    @IBOutlet weak var guiFlowButtonsContainer: UIView!
    @IBOutlet weak var guiPositiveButton: EMFlowButton!
    @IBOutlet weak var guiNegativeButton: EMFlowButton!
    
    @IBOutlet weak var guiFavButton: UIButton!
    @IBOutlet weak var guiMuteToggleButton: UIButton!

    
    // Layout outlets
    @IBOutlet weak var containerAspectRatio1_1: NSLayoutConstraint!
    @IBOutlet weak var containerAspectRatio16_9: NSLayoutConstraint!
    
    // Long videos renders
    @IBOutlet weak var guiVideoPlayerContainer: UIView!
    @IBOutlet weak var guiLongVideoIndicator: UIView!
    @IBOutlet weak var guiRenderPreviewButton: UIButton!
    @IBOutlet weak var guiLongRenderProgress: YLProgressBar!
    @IBOutlet weak var guiLongRenderLabel: EMLabel!

    //
    // Properties
    //
    weak var footagesVC: EMFootagesVC? = nil
    
    // Long videos renders
    var renderPreviewIndicatorTimer: NSTimer?
    var renderer: HCRender?

    // Alerts & actions
    var alertView: SIAlertView?
    var anActionSheet: EMHolySheet?
    
    // Child VCs
    var emusVC: EmusVC?
    var slotsVC: SlotsVC?
    var videoVC: EMVideoVC?
    var sharingOptionsVC: EMSharingOptionsVC?
    
    //
    var timeRefetchedFromServer: [String: NSDate] = [String: NSDate]()
    
    // Emu definition oid
    var emuDefOID: String = ""
    var emuDef: EmuticonDef?
    
    // theme color
    var themeColor = EmuStyle.colorThemeFeed()
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //
    // MARK: - Factories
    //
    class func emuScreenVC(emuDefOID: String, themeColor: UIColor) -> EmuScreenVC {
        let storyBoard = UIStoryboard.init(name: "EmuScreen", bundle: nil)
        let vc = storyBoard.instantiateViewControllerWithIdentifier("emu screen vc") as! EmuScreenVC
        vc.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        vc.themeColor = themeColor
        vc.emuDefOID = emuDefOID
        return vc
    }

    //
    // MARK: - Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emusVC?.refresh()
        
        // Messeges hidden by default
        self.hideSharing()
        self.showUserMessage("", messageText: "")
        self.guiSharingContainer.alpha = 0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Apply theme
        self.applyTheme()

        // Init data
        self.initData()
        
        // Init gui state
        self.initGUI()
        
        // Init Ads
        self.initAds()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.initObservers()
        self.refreshCurrentEmu()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if self.renderPreviewIndicatorTimer != nil {
            self.renderPreviewIndicatorTimer?.invalidate()
        }
        if let renderer = self.renderer {
            renderer.cancel()
            self.renderer = nil
        }
        self.removeObservers()
    }
    
    //
    // MARK: - Initializations
    //
    func initData() {
        if let emuDef = EmuticonDef.findWithID(self.emuDefOID, context: EMDB.sh().context) {
            self.emuDef = emuDef
        }
    }
    
    func initGUI() {
        // Hide tab bar.
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(emkUIShouldHideTabsBar, object: self, userInfo: [emkUIAnimated:true])
        
        // Actions and flow buttons
        self.guiActionButton.positive = true
        self.guiPositiveButton.positive = true
        self.guiNegativeButton.positive = false
        
        // Video output
        self.guiVideoPlayerContainer.hidden = true
        self.hideVideo()
        
        // Buttons
        self.guiActionButtonContainer.hidden = true
        self.guiFlowButtonsContainer.hidden = true
        
        // Long render indicator
        EmuStyle.sh().styleYLProgressBar(self.guiLongRenderProgress)
        self.updateLongRenderIndicator()
        
        // Emu aspect ratio
        self.updateAspectRatio()
        
        // Fav
        self.updateFavButton()
        
        // Mute/Unmute
        self.updateMuteButton()
    }
    
    func initAds() {
    }

    func updateAspectRatio() {
        // On 3.5 inch phones, there is never enough screen space for 1:1 aspect ratio.
        // In that case always use the 16:9 aspect ratio in the layout.
        guard let emuDef = self.emuDef else {return}
        let aspectRatio = emuDef.aspectRatio()
        var wideAspectRatio = aspectRatio >= 1.3
        if AppManagement.sh().isVerySmallScreen {
            wideAspectRatio = true
        }
        
        if wideAspectRatio {
            self.containerAspectRatio1_1.priority = UILayoutPriority(1)
            self.containerAspectRatio16_9.priority = UILayoutPriority(1000)
        } else {
            self.containerAspectRatio1_1.priority = UILayoutPriority(1000)
            self.containerAspectRatio16_9.priority = UILayoutPriority(1)
        }
    }
    
    func updateLongRenderIndicator() {
        // By default, hide it all.
        self.guiLongVideoIndicator.hidden = true
        self.guiLongRenderProgress.hidden = true
        self.guiRenderPreviewButton.hidden = true

        // Interesting only if this is a new style long render emu. If not, return.
        guard let emuDef = self.emuDef where emuDef.isNewStyleLongRender() else {return}
        guard let emu = self.currentEmu() else {return}
        
        // If video already available
        if emu.videoURL() != nil {
            // Result already available, no render required so no indicator required.
            self.guiLongVideoIndicator.hidden = true
            return
        }
        
        // If download of resources required
        if emuDef.allFullRenderResourcesAvailable() == false {
            // Missing resources for full render.
            // Will need to download the resources before rendering.
            self.guiLongVideoIndicator.hidden = false
            self.guiLongRenderProgress.hidden = false
            self.guiLongRenderProgress.setProgress(0, animated: false)
            self.guiLongRenderProgress.alpha = 1
            self.guiLongRenderLabel.hidden = false
            self.guiLongRenderLabel.text = "Downloading... (preview shown)"
            return
        }
        
        // A long render.
        // If already rendering something, show the progress bar but hide the render button.
        if self.renderer != nil {
            self.guiLongVideoIndicator.hidden = false
            self.guiLongRenderProgress.hidden = false
            self.guiRenderPreviewButton.hidden = true
            if self.renderPreviewIndicatorTimer != nil {
                self.renderPreviewIndicatorTimer?.invalidate()
                self.renderPreviewIndicatorTimer = nil
            }
            return
        }
        
        if self.guiLongVideoIndicator.alpha != 1 {
            UIView.animateWithDuration(0.2, animations: {
                self.guiLongVideoIndicator.alpha = 1
            })
        }
        
        // If downloading resources for the full render, show download progress.
        
        
        // Not rendering yet. Allow the user to start rendering and show the length of the new style long video.
        var buttonTitle = ""
        if self.guiLongVideoIndicator.tag == 0 {
            self.guiLongVideoIndicator.tag = 1
            buttonTitle = emuDef.newStyleRenderDurationTitle()
        } else {
            self.guiLongVideoIndicator.tag = 0
            buttonTitle = "Tap to render a preview"
        }
        self.guiRenderPreviewButton.setTitle(buttonTitle, forState: .Normal)
        self.guiRenderPreviewButton.alpha = 1
        self.guiLongVideoIndicator.hidden = false
        self.guiRenderPreviewButton.hidden = false
        self.guiLongRenderLabel.hidden = true
        
        // Update once in a while
        if self.renderPreviewIndicatorTimer == nil {
            self.renderPreviewIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(EmuScreenVC.updateLongRenderIndicator), userInfo: nil, repeats: true)
        }
    }
    
    //
    // MARK: - Observers
    //
    func initObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        
        nc.addUniqueObserver(
            self,
            selector: #selector(EmuScreenVC.onRenderingFinished(_:)),
            name: hmkRenderingFinished,
            object: nil)
        
        nc.addUniqueObserver(
            self,
            selector: #selector(EmuScreenVC.onDownloadFinished(_:)),
            name: hmkDownloadResourceFinished,
            object: nil)
        
        nc.addUniqueObserver(
            self,
            selector: #selector(EmuScreenVC.onLongRenderProgress(_:)),
            name: hcrNotificationRenderProgress,
            object: nil)

        nc.addUniqueObserver(
            self,
            selector: #selector(EmuScreenVC.onLongRenderFinished(_:)),
            name: hcrNotificationRenderFinished,
            object: nil)
    }
    
    func removeObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(hmkRenderingFinished)
        nc.removeObserver(hmkDownloadResourceFinished)
        nc.removeObserver(hcrNotificationRenderProgress)
        nc.removeObserver(hcrNotificationRenderFinished)
    }
    
    // MARK: - Observers handlers
    func onRenderingFinished(notification: NSNotification) {
        guard let emu = self.currentEmu() else {return}
        guard let info = notification.userInfo else {return}
        guard let emuOID = info[emkEmuticonOID] as? String else {return}
        guard emuOID == emu.oid else {return}

        self.emusVC?.refresh()
        self.refreshCurrentEmu()
    }
    
    func onDownloadFinished(notification: NSNotification) {
        guard let emu = self.currentEmu() else {return}
        guard let info = notification.userInfo else {return}
        guard let emuOID = info[emkEmuticonOID] as? String else {return}
        guard emuOID == emu.oid else {return}
        let taskType = info[emkDLTaskType] as? String

        if emu.allMissingRemoteFootageFiles().count == 0 && taskType == emkDLTaskTypeFootages {
            emu.cleanUp()
        }

        self.emusVC?.refresh()
        self.refreshCurrentEmu()
    }
    
    func onLongRenderProgress(notification: NSNotification) {
        // Guard that notification is related to current long render.
        guard let renderer = self.renderer else {return}
        guard let info = notification.userInfo else {return}
        guard let userInfo = info["userInfo"] else {return}
        guard let uuid = userInfo["uuid"] as? String where renderer.uuid == uuid else {return}

        // Update the long render progress bar
        guard let progress = info[hcrProgress] as? CGFloat else {return}
        self.guiLongRenderProgress.setProgress(progress, animated: true)
        let percentage = Int(progress*100.0)
        self.guiLongRenderLabel.text = "Rendering preview \(percentage)%"
    }
    
    func onLongRenderFinished(notification: NSNotification) {
        // Guard that notification is related to current long render.
        guard let renderer = self.renderer else {return}
        guard let info = notification.userInfo else {return}
        guard let uuid = info[hcrUUID] as? String where renderer.uuid == uuid else {return}

        // Update the long render progress bar
        self.guiLongRenderProgress.setProgress(1, animated: true)
        self.guiLongRenderLabel.text = ""
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.guiLongRenderProgress.alpha = 0
        }) {finished in
            self.guiLongRenderProgress.hidden = true
            self.guiLongRenderProgress.alpha = 1
            self.updateLongRenderIndicator()
        }
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue(), {
            self.updateFullRenderStateIfRequired()
        })
            
        // Clear up
        self.renderer = nil
    }
    
    //
    // MARK: - Theme
    //
    func applyTheme() {
        self.guiNavBarView.backgroundColor = self.themeColor
    }

    //
    // MARK: - Segues
    //
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        
        case "emus instances segue":
                self.emusVC = segue.destinationViewController as? EmusVC
                self.emusVC?.emuDefOID = self.emuDefOID
                self.emusVC?.delegate = self
        
        case "emu screen video preview segue":
                self.videoVC = segue.destinationViewController as? EMVideoVC
                self.videoVC?.previewDelegate = self

        case "sharing options vc segue":
                self.sharingOptionsVC = segue.destinationViewController as? EMSharingOptionsVC
                self.sharingOptionsVC?.delegate = self

        default:
            break
        }
    }
    
    //
    // MARK: - status bar
    //
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    //
    // MARK: - Current emu
    //
    func refreshCurrentEmu(forcedRefresh forcedRefresh: Bool = false) {
        guard self.currentEmu() != nil else {
            // No emu instance? update UI to indicate that no emu is in focus.
            self.updateEmuUIStateForEmu()
            return
        }
        self.updateEmuUIStateForEmu()
    }
    
    //
    // MARK: - UI States
    //
    func updateMuteButton() {
        // Hide the mute button when it is irrelevent
        let shouldHideMuteButton = !self.isVideoShown()
        self.guiMuteToggleButton.hidden = shouldHideMuteButton
        
        guard let appCFG = AppCFG.cfgInContext(EMDB.sh().context) else {return}
        guard let isMuted = appCFG.shouldMuteLoopingVideos?.boolValue else {return}

        let imageName = isMuted ? "soundMuted" : "soundPlays"
        self.guiMuteToggleButton.setImage(UIImage(named:imageName), forState: .Normal)
    }
    
    func toggleMute() {
        guard let appCFG = AppCFG.cfgInContext(EMDB.sh().context) else {return}
        appCFG.toggleShouldMuteLoopingVideos()
        EMDB.sh().save()
    }
    
    func updateVideoPlayerMuteState() {
        guard let appCFG = AppCFG.cfgInContext(EMDB.sh().context) else {return}
        if let isMuted = appCFG.shouldMuteLoopingVideos?.boolValue {
            self.videoVC?.player?.muted = isMuted
        }
    }
    
    func updateFavButton() {
        guard let emu = self.currentEmu() else {return}
        guard let isFav = emu.isFavorite?.boolValue else {return}
        
        let favButtonImageName = isFav ? "favIconOn" : "favIconOff"
        self.guiFavButton.setImage(UIImage(named: favButtonImageName), forState: .Normal)
        
    }
    
    func updateEmuUIStateForEmu() {
        guard self.emuDef != nil else {return}
        self.updateEmuUIStateForNormalEmu()
        
        // Hide tab bar if shown.
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(emkUIShouldHideTabsBar, object: self, userInfo: [emkUIAnimated:true])
    }
    
    func updateEmuUIStateForNormalEmu() {
        // Show the share UI.
        self.emusVC?.refresh()
        self.showSharing()

        // Play full rendered video, if required.
        self.updateFullRenderStateIfRequired()
    }

    func updateFullRenderStateIfRequired() {
        guard let emu = self.currentEmu() else {return}
        guard let emuDef = self.emuDef else {return}
        guard let fullRender = emuDef.fullRender where fullRender.boolValue == true else {return}
        
        // If an output video already rendered, show it
        if emu.videoURL() != nil {
            self.showVideoAtURL(emu.videoURL(), animated: true)
            self.updateMuteButton()
            return
        }
        
        // Full render required but not rendered yet.
        
        // Cancel current render (if ongoing render exist).
        if self.renderer != nil {
            self.renderer?.cancel()
            self.renderer = nil
        }
        self.fullRenderForCurrentEmu(keepResult: true)
        self.updateMuteButton()
    }
    
    func showSharing() {
        self.guiShareMediaTypeSelector.setTitle(EML.s("GIF"), forSegmentAtIndex: 0)
        self.guiShareMediaTypeSelector.setTitle(EML.s("VIDEO"), forSegmentAtIndex: 1)
        self.guiShareMediaTypeSelector.hidden = false
        self.updateToPrefferedSharingMediaType()
        
        self.showUserMessage(EML.s(""), messageText: EML.s(""))
        self.guiSharingContainer.hidden = false
        self.guiActionButtonContainer.hidden = false
        
        // Select the preffered shared media type
        if self.guiSharingContainer.alpha == 0 {
            UIView.animateWithDuration(0.3, animations: {
                self.guiSharingContainer.alpha = 1
            })
        }
    }
    
    func hideSharing() {
        self.guiShareMediaTypeSelector.hidden = true
        self.guiNegativeButton.setBGColor(EmuStyle.colorButtonBGNegative())
        self.guiSharingContainer.hidden = true
        self.guiSharingContainer.alpha = 0
    }
    
    func epicFail() {
        self.showUserMessage(EML.s("ERROR_TITLE"), messageText: EML.s("ALERT_CHECK_INTERNET_MESSAGE"))
        self.showActionButton(EML.s("TRY_AGAIN"))
    }
    
    func showActionButton(actionText: String? = nil, buttonDisabled: Bool = false, color: UIColor? = nil) {
        self.guiActionButtonContainer.hidden = false
        self.guiFlowButtonsContainer.hidden = true
        
        if buttonDisabled {
            self.guiActionButtonContainer.userInteractionEnabled = false
            self.guiActionButtonContainer.alpha = 0.6
        } else {
            self.guiActionButtonContainer.userInteractionEnabled = true
            self.guiActionButtonContainer.alpha = 1.0
        }
        
        if (actionText != nil) {
            let text = actionText?.uppercaseStringWithLocale(NSLocale.currentLocale())
            self.guiActionButton.setTitle(text, forState: .Normal)
        }
        self.guiActionButton.setBGColor(color != nil ? color : EmuStyle.colorButtonBGPositive())
    }
    
    func showUserMessage(titleText: String, messageText: String) {
        self.guiUserGuidanceTitle.text = titleText
    }
    
    func showActivity(titleText: String, messageText: String, withProgress: Bool = false) {
        self.guiActionButtonContainer.hidden = true
        self.guiFlowButtonsContainer.hidden = true
        self.guiUserGuidanceTitle.text = titleText
    }
    
    func showFlowButtons(positiveButtonText: String, negativeButtonText: String) {
        self.guiActionButtonContainer.hidden = true
        self.guiFlowButtonsContainer.hidden = false
        
        self.guiPositiveButton.setTitle(positiveButtonText, forState: .Normal)
        self.guiNegativeButton.setTitle(negativeButtonText, forState: .Normal)
    }
    
    func currentEmu() -> Emuticon? {
        if let emu = self.emusVC?.currentEmu() {
            return emu
        }
        return nil
    }
    
    func askAboutFootageOptions() {
        guard let emu = self.currentEmu() else {return}
        guard let emuOID = emu.oid else {return}
        
        // The action sheet.
        self.anActionSheet = EMEmuOptionsSheet(emuOID: emuOID)
        self.anActionSheet?.holyDelegate = self
        self.anActionSheet?.showModalOnTopAnimated(true)
    }
    
    
    //
    // MARK: - Sharing
    //
    func updatePrefferedSharingMediaType() {
        let appCFG = AppCFG.cfgInContext(EMDB.sh().context)
        let prefferedRenderingType = self.guiShareMediaTypeSelector.selectedSegmentIndex == 0 ? EMMediaDataType.GIF:EMMediaDataType.Video
        appCFG.userPrefferedShareType = prefferedRenderingType.rawValue
        EMDB.sh().save()
        self.sharingOptionsVC!.update()
    }
    
    func updateToPrefferedSharingMediaType() {
        self.guiShareMediaTypeSelector.userInteractionEnabled = true
        let appCFG = AppCFG.cfgInContext(EMDB.sh().context)
        if appCFG.userPrefferedShareType?.integerValue == 1 {
            self.guiShareMediaTypeSelector.selectedSegmentIndex = 1
        } else {
            self.guiShareMediaTypeSelector.selectedSegmentIndex = 0
        }
        
        // Full render emus will not allow to share gifs
        var forceVideoOnly = false
        if let emuDef = self.emuDef {
            if emuDef.fullRenderCFG != nil {
                self.guiShareMediaTypeSelector.selectedSegmentIndex = 1
                self.guiShareMediaTypeSelector.hidden = true
                self.guiShareMediaTypeSelector.userInteractionEnabled = false
                forceVideoOnly = true
            }
        }
        
        self.sharingOptionsVC!.update(forceVideoOnly: forceVideoOnly)
    }
    
    func shareCurrentEmu() {
        guard let emu = self.currentEmu() else {return}
        
        if emu.emuDef?.fullRenderCFG != nil && emu.videoURL() == nil {
            // Still didn't render the fully renderer video. 
            self.pleaseWaitWhileRenderingVideo()
            self.showSharing()
            return
        }
        
        if emu.emuDef?.fullRenderCFG == nil && emu.wasRendered?.boolValue != true {
            // Still didn't render the old style GIF
            self.pleaseWaitWhileRenderingVideo()
            self.showSharing()
            return
        }
        
        // Please wait while sharing.
        self.showActivity("", messageText: EML.s("PLEASE_WAIT"))
        
        // Share the emu
        self.sharingOptionsVC?.emuToShare = emu
        self.sharingOptionsVC?.shareCurrentEmu()
    }
    
    func pleaseWaitWhileRenderingVideo() {
        let textMessage = EML.s("RENDERING_VIDEO")  + "\n" + EML.s("PLEASE_WAIT")
        self.view.makeToast(textMessage)
    }
    
    //
    // MARK: - EmuSelectionProtocol
    //
    func emuSelected(emu: Emuticon?) {
        self.refreshCurrentEmu()
    }
    
    func emuPressed(emu: Emuticon?) {
        guard emu != nil else {return}
        guard let wasRendered = emu!.wasRendered where wasRendered.boolValue == true else {return}
        
        self.askAboutFootageOptions()
    }
    
    func emuSelectionScrolled() {
        // Cancel any long processes
        if let renderer = self.renderer {
            renderer.cancel()
            self.renderer = nil
        }
        
        if self.guiLongVideoIndicator.alpha != 0 {
            UIView.animateWithDuration(0.2, animations: {
                self.guiLongVideoIndicator.alpha = 0
            })
        }
        
        if self.isVideoShown() {
            self.hideVideo(animated: false)
        }
    }
    
    //
    // MARK: - EMShareDelegate
    //    
    func sharerDidProgress(progress: Float, info: [NSObject : AnyObject]!) {
    }
    
    func sharerDidFinishWithInfo(info: [NSObject : AnyObject]!) {
        self.updateEmuUIStateForEmu()
    }
    
    func sharerDidFailWithInfo(info: [NSObject : AnyObject]!) {
        self.updateEmuUIStateForEmu()
    }
    
    //
    // MARK: - EMInterfaceDelegate
    //
    func controlSentActionNamed(actionName: String!, info: [NSObject : AnyObject]!) {
        switch actionName {
        case EMSharingOptionsVC.emkUIActionShare:
            // Pressed a share option.
            // Share the current emu.
            self.shareCurrentEmu()
            return
            
        case EMSharingOptionsVC.emkUIActionShareMethodChanged:
            // The user focused on another share option.
            // Update the action button.
            guard let shareTitle = info[EMSharingOptionsVC.emkShareButtonTitle] as? String else {return}
            guard let shareColor = info[EMSharingOptionsVC.emkShareButtonColor] as? UIColor else {return}
            self.showActionButton(shareTitle, buttonDisabled: false, color: shareColor)
            return
            
        case EMSharingOptionsVC.emkUIActionShareDone:
            // A share flow is done (successful, failed or canceled)
            self.updateEmuUIStateForEmu()
            self.showActionButton()
            return
            
        case emkUIFootageSelectionApply:
            guard actionName == emkUIFootageSelectionApply else {return}
            guard let footageOID = info[emkFootageOID] as? String else {return}
            guard let footage = UserFootage.findWithID(footageOID, context: EMDB.sh().context) else {return}
            guard let emu = self.currentEmu() else {return}

            // Update the preffered footage of this emu.
            emu.prefferedFootageOID = footage.oid
            emu.cleanUp()

            self.dismissViewControllerAnimated(true) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.updateEmuUIStateForEmu()
                    self.emusVC?.refresh()
                })
            }
            
        case emkUIFootageSelectionCancel:
            self.dismissViewControllerAnimated(true) {}
            
        default:
            break
        }
    }
    
    //
    // MARK: - Video player
    //
    func showVideoAtURL(url: NSURL, animated: Bool = false) {
        // Show the video
        self.videoVC?.setVideoURL(url)
        self.guiVideoPlayerContainer.hidden = false
        self.updateVideoPlayerMuteState()
        
        // Reveal
        if animated {
            UIView.animateWithDuration(0.3) {
                self.guiVideoPlayerContainer.alpha = 1
            }
        } else {
            self.guiVideoPlayerContainer.alpha = 1
        }

        self.emusVC?.seeThroughAnimated(animated: true)
    }
    
    func hideVideo(animated animated: Bool = false) {
        // Hide
        if animated {
            UIView.animateWithDuration(0.3) {
                self.guiVideoPlayerContainer.alpha = 0
            }
        } else {
            self.guiVideoPlayerContainer.alpha = 0
        }
        self.videoVC?.stop()
        self.emusVC?.opaqueAnimated(animated: true)
    }
    
    func isVideoShown() -> Bool {
        return self.guiVideoPlayerContainer.alpha > 0
    }
    
    //
    // MARK: - EMPreviewDelegate
    //
    func previewIsShownWithInfo(info: [NSObject : AnyObject]!) {
    }
    
    func previewDidFailWithInfo(info: [NSObject : AnyObject]!) {
    }
    
    //
    // MARK: - Going back
    //
    func goBack() {
        if let emu = self.currentEmu() {
            emu.cleanUpTempRenders()
        }
        self.guiSharingContainer.hidden = true
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func fullRenderForCurrentEmu(keepResult keepResult: Bool = false) {
        guard let emuDef = self.emuDef where emuDef.isNewStyleLongRender() else {return}
        guard let emu = self.currentEmu() else {return}
        
        // Cancel preview long renders
        if self.renderer != nil {
            self.renderer?.cancel()
        }

        // Ensure all resources downloaded / cached in local storage
        // Before sending to full render.
        if emuDef.allFullRenderResourcesAvailable() == false {
            // Missing resources for full render.
            // Will need to download the resources before rendering.
            self.updateLongRenderIndicator()
            
            // Download missing resources
            let info = [
                emkEmuticonOID:emu.oid!,
                emkPackageOID:emuDef.oid!,
                emkDLTaskType:emkDLTaskTypeFullRenderResources
                ] as [NSObject: AnyObject]
            emu.enqueueIfMissingFullRenderResourcesWithInfo(info)
            return
        }

        
        // Show progress
        self.guiLongRenderProgress.hidden = false
        self.guiLongRenderProgress.setProgress(0, animated: false)
        self.guiLongRenderProgress.alpha = 1
        self.guiLongRenderLabel.hidden = false
        self.guiLongRenderLabel.text = "Rendering preview"
        
        //
        var keepResultForEmuAtPath: String? = nil
        if keepResult {
            keepResultForEmuAtPath = emu.videoPath()
        }
        
        // Render a preview
        let rm = EMRenderManager3.sh()
        self.renderer = rm.renderPreviewForEmuDefOID(
            emuDef.oid!,
            footagesForPreview: emu.relatedFootages() as! [FootageProtocol],
            slotIndex: 0,
            keepResultAtPath: keepResultForEmuAtPath)
    }
    
    //
    // MARK: - EMRecorderDelegate
    //
    func recorderWantsToBeDismissedAfterFlow(flowType: EMRecorderFlowType, info: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.updateEmuUIStateForEmu()
        }
    }
    
    func recorderCanceledByTheUserInFlow(flowType: EMRecorderFlowType, info: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.updateEmuUIStateForEmu()
        }
    }
    
    // MARK: - EMHolySheetDelegate
    func handleSheetActionWithIndexPath(indexPath: NSIndexPath, actionsMapping: EMActionsArray) {
        guard let emu = self.currentEmu() else {return}
        guard let emuDef = emu.emuDef else {return}
        guard let actionName = actionsMapping.actionNameForIndexPath(indexPath) else {return}
        
        let duration = emuDef.requiredCaptureTime()
        let dedicatedFootageRequired = emuDef.requiresDedicatedCapture()
        
        // Handle actions
        switch actionName {
            
        case EMK_EMU_FOOTAGE_ACTION_RETAKE:
            
            //
            // Open the recorder for a new take.
            // Recorder should be opened for a retake.
            //
            let oids = [emu.oid as! AnyObject]
            let requestInfo = [
                emkRetakeEmuticonsOID:oids,
                emkDuration:duration,
                emkDedicatedFootage:dedicatedFootageRequired
                ] as [NSObject:AnyObject]
            
            // Notify main navigation controller that the recorder should be opened.
            let recorder = EMRecorderVC2.recorderVCWithConfigInfo(requestInfo)
            recorder.delegate = self
            self.presentViewController(recorder, animated: true, completion: nil)
            
        case EMK_EMU_FOOTAGE_ACTION_CHOOSE:

            //
            // Open the footages screen
            //
            let footagesVC = EMFootagesVC(forFlow: .ChooseFootage)
            footagesVC.delegate = self
            footagesVC.selectedEmusOID = [emu.oid!]
            self.footagesVC = footagesVC
            self.presentViewController(footagesVC, animated: true, completion: nil)
            
            
        default:
            break
        }
    }
        
    // MARK: - IB Actions
    // ===========
    // IB Actions.
    // ===========
    @IBAction func onPressedFavButton(sender: AnyObject) {
        guard let emu = self.currentEmu() else {return}
        emu.toggleFavorite()
        self.updateFavButton()
    }
    
    
    @IBAction func onPressedBackButton(sender: AnyObject) {
        self.goBack()
    }
    
    @IBAction func onPressedActionButton(sender: AnyObject) {
        EMUISound.sh().playSoundNamed(SND_SOFT_CLICK)
        guard self.currentEmu() != nil else {return}
        self.shareCurrentEmu()
    }

    @IBAction func onPressedLongPreviewRenderButton(sender: AnyObject)
    {
        // Full long render preview
        self.fullRenderForCurrentEmu()
    }
    
    @IBAction func onPrefferedMediaTypeChanged(sender: AnyObject) {
        self.updatePrefferedSharingMediaType()
    }
    
    @IBAction func onPressedRetakeOptionsButton(sender: AnyObject) {
        guard let emu = self.currentEmu() else {return}
        if emu.wasRendered?.boolValue == true {
            self.askAboutFootageOptions()
        }
    }
    
    @IBAction func onRecognizedSwipeRight(sender: UISwipeGestureRecognizer) {
        self.goBack()
    }
    
    @IBAction func onPressedMuteToggleButton(sender: AnyObject) {
        self.toggleMute()
        self.updateMuteButton()
        self.updateVideoPlayerMuteState()
    }
}
