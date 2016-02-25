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
    SlotsSelectionDelegate,
    EMInterfaceDelegate,
    EMPreviewDelegate,
    EMRecorderDelegate {
    
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
    @IBOutlet weak var guiMessage: UILabel!
    
    // Sharing
    @IBOutlet weak var guiShareMediaTypeSelector: UISegmentedControl!
    @IBOutlet weak var guiSharingContainer: UIView!
    
    // Slots
    @IBOutlet weak var guiSlotsContainer: UIView!
    
    // Progress
    @IBOutlet weak var guiActivity: UIActivityIndicatorView!
    @IBOutlet weak var guiProgressView: UIProgressView!
    
    // Actions
    @IBOutlet weak var guiActionButtonContainer: UIView!
    @IBOutlet weak var guiActionButton: EMFlowButton!
    
    @IBOutlet weak var guiFlowButtonsContainer: UIView!
    @IBOutlet weak var guiPositiveButton: EMFlowButton!
    @IBOutlet weak var guiNegativeButton: EMFlowButton!
    
    // Layout outlets
    @IBOutlet weak var slotsContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var indicatorsContainerHeight: NSLayoutConstraint!
    
    // Long videos renders
    @IBOutlet weak var guiVideoPlayerContainer: UIView!
    @IBOutlet weak var guiLongVideoIndicator: UIView!
    @IBOutlet weak var guiRenderPreviewButton: UIButton!
    @IBOutlet weak var guiLongRenderProgress: YLProgressBar!
    @IBOutlet weak var guiLongRenderLabel: EMLabel!

    //
    // Properties
    //

    // Long videos renders
    var renderPreviewIndicatorTimer: NSTimer?
    var renderer: HCRender?

    // Alerts
    var alertView: SIAlertView?
    
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
    var jointEmuState: JointEmuState = JointEmuState.Undefined
    var slotIndex: Int = 0 {
        didSet {
            if let cv = self.slotsVC {
                cv.highlightedSlot = self.slotIndex
            }
        }
    }
    
    // Uploaders and sharer
//    var uploader: EMUploadPublicFootageForJointEmu?
    
    var uploaders: [String:EMUploadPublicFootageForJointEmu] = [String:EMUploadPublicFootageForJointEmu]()
    
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
        self.guiProgressView.hidden = true
        self.guiMessage.hidden = true
        self.guiActivity.stopAnimating()
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
        
        // Slots hidden by default
        self.guiSlotsContainer.hidden = true
        
        // Video output
        self.guiVideoPlayerContainer.hidden = true
        
        // Buttons
        self.guiActionButtonContainer.hidden = true
        self.guiFlowButtonsContainer.hidden = true
        
        // Long render indicator
        EmuStyle.sh().styleYLProgressBar(self.guiLongRenderProgress)
        self.updateLongRenderIndicator()
    }
    
    func updateLongRenderIndicator() {
        // By default, hide it all.
        self.guiLongVideoIndicator.hidden = true
        self.guiLongRenderProgress.hidden = true
        self.guiRenderPreviewButton.hidden = true

        // Interesting only if this is a new style long render emu.
        guard let emuDef = self.emuDef where emuDef.isNewStyleLongRender() else {return}
        
        // Not interesting if no emu in focus
        guard let emu = self.currentEmu() else {return}
        
        // If video already available
        if emu.videoURL() != nil {
            self.guiLongVideoIndicator.hidden = true
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
            self.renderPreviewIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: "updateLongRenderIndicator", userInfo: nil, repeats: true)
        }
    }
    
    //
    // MARK: - Observers
    //
    func initObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addUniqueObserver(
            self,
            selector: "onUserSignIn:",
            name: emkUserSignedIn,
            object: nil)
        
        nc.addUniqueObserver(
            self,
            selector: "onJointEmuNew:",
            name: emkJointEmuNew,
            object: nil)

        nc.addUniqueObserver(
            self,
            selector: "onJointEmuRefresh:",
            name: emkJointEmuRefresh,
            object: nil)

        nc.addUniqueObserver(
            self,
            selector: "onJointEmuInviteCreated:",
            name: emkJointEmuCreateInvite,
            object: nil)
        
        nc.addUniqueObserver(
            self,
            selector: "onRenderingFinished:",
            name: hmkRenderingFinished,
            object: nil)
        
        nc.addUniqueObserver(
            self,
            selector: "onDownloadFinished:",
            name: hmkDownloadResourceFinished,
            object: nil)
        
        nc.addUniqueObserver(
            self,
            selector: "onLongRenderProgress:",
            name: hcrNotificationRenderProgress,
            object: nil)

        nc.addUniqueObserver(
            self,
            selector: "onLongRenderFinished:",
            name: hcrNotificationRenderFinished,
            object: nil)
    }
    
    func removeObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(emkUserSignedIn)
        nc.removeObserver(emkJointEmuNew)
        nc.removeObserver(emkJointEmuRefresh)
        nc.removeObserver(emkJointEmuCreateInvite)
        nc.removeObserver(hmkRenderingFinished)
        nc.removeObserver(hmkDownloadResourceFinished)
        nc.removeObserver(hcrNotificationRenderProgress)
        nc.removeObserver(hcrNotificationRenderFinished)
    }
    
    // MARK: - Observers handlers
    func onUserSignIn(notification: NSNotification) {
        self.updateEmuUIStateForEmu()
    }
    
    func onJointEmuNew(notification: NSNotification) {
        self.emusVC?.refresh()
        self.updateEmuUIStateForEmu()
    }
    
    func onJointEmuRefresh(notification: NSNotification) {
        self.emusVC?.refresh()
        self.updateEmuUIStateForEmu()
    }
    
    func onJointEmuInviteCreated(notification: NSNotification) {
        self.sendInviteToFriend()
    }
    
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
        
        // Show the result of the render.
        if let url = self.renderer?.outputURL() {
            self.showVideoAtURL(url)
        }
        
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
            case "joint emu slots segue":
                self.slotsVC = segue.destinationViewController as? SlotsVC
                self.slotsVC?.delegate = self
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
        guard let emu = self.currentEmu() else {
            // No emu instance? update UI to indicate that no emu is in focus.
            self.updateEmuUIStateForEmu()
            return
        }
        
        if emu.isJointEmu() == true && emu.jointEmuOID() != nil {
            // Refresh joint emu (but not more than once a minute)
            let lastTime = self.timeRefetchedFromServer[emu.jointEmuOID()]
            let now = NSDate()
            if lastTime == nil || now.timeIntervalSinceDate(lastTime!) > 60 || forcedRefresh {
                self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_LOADING"))
                EMBackend.sh().server.jointEmuRefetch(emu.jointEmuOID(), emuOID: emu.oid)
                self.timeRefetchedFromServer[emu.jointEmuOID()] = now
            } else {
                self.updateEmuUIStateForEmu()
            }
        } else {
            // Update regular emu
            self.updateEmuUIStateForEmu()
        }
    }
    
    //
    // MARK: - UI States
    //
    func updateEmuUIStateForEmu() {
        guard let emuDef = self.emuDef else {return}
        
        if emuDef.isJointEmu() {
            self.updateEmuUIStateForJointEmu()
        } else {
            self.updateEmuUIStateForNormalEmu()
        }
        
        // Hide tab bar if shown.
        let nc = NSNotificationCenter.defaultCenter()
        nc.postNotificationName(emkUIShouldHideTabsBar, object: self, userInfo: [emkUIAnimated:true])
    }
    
    func updateEmuUIStateForNormalEmu() {
        guard let emu = self.currentEmu() else {return}
        guard let emuDef = self.emuDef else {return}

        // Show the share UI.
        self.jointEmuState = .NotAJointEmu
        self.guiSlotsContainer.hidden = true
        self.emusVC?.refresh()
        self.showSharing()

        // Play full rendered video, if required.
        if emuDef.fullRenderCFG != nil {
            if emu.videoURL() != nil {
                self.showVideoAtURL(emu.videoURL())
            } else {
                if self.renderer != nil {
                    // Cancel previous renders.
                    self.renderer?.cancel()
                }
                self.fullRenderForCurrentEmu(keepResult: true)
            }
        }
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
    
    func updateEmuUIStateForJointEmu() {
        guard let emuDef = self.emuDef where emuDef.isJointEmu() else {return}

        // Current joint emu instance may be nil, if no emu instance is currently in focus.
        let emu = self.currentEmu()
        var relatedUploader: EMUploadPublicFootageForJointEmu? = nil
        if let anEmu = emu {
            if let jeOID = anEmu.jointEmuInstanceOID {
                relatedUploader = self.uploaders[jeOID]
            }
        }
        
        // Get the state
        self.jointEmuState = JointEmuFlow.stateForEmu(emu, uploader: relatedUploader)
        self.guiSlotsContainer.hidden = emu == nil
        self.slotsVC?.emu = emu
        self.updateLongRenderIndicator()
        self.hideSharing()
        
        // Handle the state
        switch self.jointEmuState {
        case .NotCreatedYet:
            self.showActionButton(EML.s("CREATE_NEW"))
            self.showUserMessage(EML.s("JOINT_EMU_INFO_CREATE_NEW"), messageText: EML.s("NO_INVITATION_SENT"))
            
        case .UserNotSignedIn:
            self.showActionButton(EML.s("JOINT_EMU_SIGN_IN_REQUIRED"))
            self.showUserMessage(EML.s("JOINT_EMU"), messageText: EML.s("NO_INVITATION_SENT"))
            
        case .InstanceInfoMissing:
            self.createJointEmuInstance()
            
        case .Finalized:
            self.guiSlotsContainer.hidden = true
            self.showSharing()
            guard let theEmu = self.currentEmu() else {break}
            
            // Full rendered video
            if theEmu.emuDef!.fullRenderCFG == nil {break}
            if let videoURL = theEmu.videoURL() {
                // Already rendered full video. Show it.
                self.showVideoAtURL(videoURL)
                return
            }
            
            // Full render required but not available.
            self.fullRenderForCurrentEmu(keepResult: true)
            
        // Initiator flow
        case .InitiatorNeedsToCreateDedicatedFootage:
            self.showUserMessage("", messageText: EML.s("NO_INVITATION_SENT"))
            self.showActionButton(EML.s("EMU_SCREEN_CHOICE_RETAKE_EMU"))
            
        case .NoInvitationsSent:
            self.showUserMessage(EML.s("JOINT_EMU_INFO_INVITE_FRIEND"), messageText: EML.s("NO_INVITATION_SENT"))
            self.showActionButton(EML.s("INVITE_FRIEND"))
            
        case .InitiatorWaitingForFriends:
            let invitationsSentCount = self.currentEmu()?.jointEmuInvitationsSentCount()
            var invitationsSentText = EML.s("INVITATION_SENT")
            if invitationsSentCount > 1 {
                invitationsSentText = EML.s("INVITATIONS_SENT").stringByReplacingOccurrencesOfString("#", withString: "\(invitationsSentCount)")
            }
            self.showUserMessage(EML.s("JOINT_EMU_INFO_WAIT_FOR_FRIENDS"), messageText: invitationsSentText)
            self.showActionButton(EML.s("WAIT_FOR_YOU_FRIENDS"), buttonDisabled: true)
        
        case .InitiatorReadyForFinalization:
            self.showUserMessage(EML.s("LOOKS_GREAT"), messageText: "")
            self.showActionButton(EML.s("FINALIZE"))
            
        case .InitiatorUploadingFootage:
            self.showActivity(
                "",
                messageText: EML.s("JOINT_EMU_UPLOADING_FOOTAGE"),
                withProgress: true)
            
        // Receiver
        case .ReceiverInvited:
            self.showUserMessage(EML.s("JOINT_EMU_INFO_JOIN_NEW_INVITE"), messageText: EML.s(""))
            self.showFlowButtons(EML.s("CHOOSE_TAKE"), negativeButtonText: EML.s("DECLINE"))
            
        case .ReceiverApprovedLocalFootageAndNeedsToUpload:
            self.showUserMessage(EML.s("JOINT_EMU_INFO_JOIN_NEW_INVITE"), messageText: EML.s(""))
            self.showFlowButtons(EML.s("SEND"), negativeButtonText: EML.s("EMU_SCREEN_CHOICE_REPLACE_TAKE"))
            
        case .ReceiverUploadingFootage:
            self.showActivity(
                "",
                messageText: EML.s("JOINT_EMU_UPLOADING_FOOTAGE"),
                withProgress: true)

        case .ReceiverWaitingForFlowEnd:
            self.showUserMessage(EML.s("JOINT_EMU_INFO_YOUR_PART_DONE"), messageText: "")
            self.showActionButton(EML.s("WAIT_TILL_EMU_FINISHED"), buttonDisabled: true)
            
        case .Error:
            self.epicFail()
            
        default:
            break
        }
    }

    func showActionButton(actionText: String? = nil, buttonDisabled: Bool = false, color: UIColor? = nil) {
        self.guiActionButtonContainer.hidden = false
        self.guiFlowButtonsContainer.hidden = true
        self.slotIndex = 0
        
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
//        self.guiEmusContainer.userInteractionEnabled = true
        self.guiActionButton.setBGColor(color != nil ? color : EmuStyle.colorButtonBGPositive())
    }
    
    func showUserMessage(titleText: String, messageText: String) {
        self.guiActivity.stopAnimating()
        self.guiUserGuidanceTitle.text = titleText
        self.guiMessage.text = messageText
        self.guiProgressView.hidden = true
    }
    
    func showActivity(titleText: String, messageText: String, withProgress: Bool = false) {
        self.guiActionButtonContainer.hidden = true
        self.guiFlowButtonsContainer.hidden = true
        self.guiProgressView.setProgress(0, animated: false)
        self.guiProgressView.hidden = !withProgress
        self.guiActivity.startAnimating()
        self.guiMessage.text = messageText
        self.guiMessage.hidden = false
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
    
    func showInviteConfirmUI() {
        self.jointEmuState = JointEmuState.SendInviteConfirmationRequired
        self.showUserMessage(EML.s("JOINT_EMU_INFO_INVITE_FRIEND"), messageText: "Your footage will be sent to your friend")
        self.showFlowButtons(EML.s("SEND").uppercaseString, negativeButtonText: EML.s("CANCEL").uppercaseString)
    }

    func showInviteCancelUI() {
        self.jointEmuState = .InitiatorCancelInviteOptions
        self.showUserMessage(EML.s("JOINT_EMU_INFO_KEEP_CANCEL_INVITE"), messageText: "")
        self.showFlowButtons(EML.s("KEEP_INVITATION"), negativeButtonText: EML.s("CANCEL_INVITATION"))
    }
    
    func askAboutFootageOptions() {
        guard let emu = self.currentEmu() else {return}
        let slotIndex = emu.jointEmuLocalSlotIndex()
        if emu.isJointEmu() {
            guard slotIndex > 0 else {return}
        }
        
        let emuDef = emu.emuDef!
        
        let duration = emuDef.jointEmuDefCaptureDurationAtSlot(slotIndex)
        let dedicatedFootageRequired = emuDef.jointEmuDefRequiresDedicatedCaptureAtSlot(slotIndex)
        
        // New take or replace take?
        var message = EML.s("CHANGE_FOOTAGE_FROM")
        var title = ""
        if dedicatedFootageRequired {
            title = emuDef.jointEmuDefCaptureDurationStringAtSlot(slotIndex)
            message = EML.s("DEDICATED_FOOTAGE_REQUIRED_MESSAGE")
        }
        
        let alertView = SIAlertView(title: title, andMessage: message)
        alertView.buttonColor = EmuStyle.colorButtonBGPositive()
        alertView.cancelButtonColor = EmuStyle.colorButtonBGNegative()
        
        if dedicatedFootageRequired == false {
            // If no dedicate footage required, allow to choose footage from the footage screen.
            alertView.addButtonWithTitle(EML.s("CHOOSE_TAKE"), type: SIAlertViewButtonType.Default, handler: {alert in
                let footageVC = EMFootagesVC(forFlow: .ChooseFootage)
                footageVC.hdFootagesOnly = true
                footageVC.videoFootagesOnly = true
                footageVC.delegate = self
                self.presentViewController(footageVC, animated: true, completion: nil)
            })
        }
        
        // New take option.
        alertView.addButtonWithTitle(EML.s("EMU_SCREEN_CHOICE_RETAKE_EMU"), type: SIAlertViewButtonType.Default, handler: {alert in
            //
            // Open the recorder for a new take.
            // Recorder should be opened for a retake.
            //
            let oids = [emu.oid as! AnyObject]
            let requestInfo = [
                emkRetakeEmuticonsOID:oids,
                emkDuration:duration,
                emkDedicatedFootage:dedicatedFootageRequired,
                emkJEmuSlot:slotIndex
                ] as [NSObject:AnyObject]
            
            // Notify main navigation controller that the recorder should be opened.
            let recorder = EMRecorderVC2.recorderVCWithConfigInfo(requestInfo)
            recorder.delegate = self
            self.presentViewController(recorder, animated: true, completion: nil)
        })
        
        // Cancel option
        alertView.addButtonWithTitle(EML.s("CANCEL"), type: SIAlertViewButtonType.Cancel, handler:nil)
        
        // Show the alert.
        alertView.show()
        self.alertView = alertView
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
        if emu == nil {
            self.createJointEmuInstance()
        } else {
            if emu!.wasRendered?.boolValue == true {
                self.askAboutFootageOptions()
            }
        }
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
    // MARK: - Actions
    //
    func signIn() {
        dispatch_async(dispatch_get_main_queue(), {
            self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_LOADING"))
            EMBackend.sh().server.signInUser()
        })
    }
    
    func createJointEmuInstance() {
        dispatch_async(dispatch_get_main_queue(), {
            self.showActivity(EML.s("JOINT_EMU_INFO_CREATE_NEW"), messageText: EML.s("JOINT_EMU_LOADING"))
            var emu = self.currentEmu()
            if (emu == nil) {
                // Emu instance is missing. Create a new emu and give it focus.
                let newEmu = Emuticon.newForEmuticonDef(self.emuDef, context: EMDB.sh().context)
                emu = newEmu
            }
            EMBackend.sh().server.jointEmuNewForEmuOID(emu!.oid)
        })
    }
    
    func jointEmuInviteLink(inviteCode: String) -> String {
        if AppManagement.sh().isDevApp() {
            return "jointemubeta://invite/\(inviteCode)"
        } else {
            return "jointemubeta://invite/\(inviteCode)"
        }
    }
    
    func sendInviteToFriend() {
        guard let emu = self.currentEmu() else {return}
        if (self.slotIndex < 1) {
            // No slot selected?
            // Choose first available one.
            self.slotIndex = emu.jointEmuFirstUninvitedSlotIndex()
        }
        guard self.slotIndex > 0 else {return}
        guard let inviteCode = emu.jointEmuInviteCodeAtSlot(self.slotIndex) else {return}

        let textToShare = EML.s("DEEPLINK_INVITE_JOINT_EMU_PTN") + self.jointEmuInviteLink(inviteCode)
        let objectsToShare = [textToShare]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.completionWithItemsHandler = {activity, success, items, error in
            if (success == true) {
                self.updateEmuUIStateForEmu()
            } else {
                self.cancelInvite()
            }
        }
        self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
    func uploadEmuFootageBeforeSendingInvite() {
        guard let emu = self.currentEmu() else {return}
        guard let jeOID = emu.jointEmuInstanceOID else {return}
        guard let footage = self.currentEmu()?.mostPrefferedUserFootage() else {return}
        
        self.showActivity(
            EML.s("JOINT_EMU_INFO_INVITE_FRIEND"),
            messageText: EML.s("JOINT_EMU_UPLOADING_FOOTAGE"),
            withProgress: true)
        self.jointEmuState = .InitiatorUploadingFootage

        // Cancel previous uploads for this joint emu
        if let uploader = self.uploaders[jeOID] {
            uploader.cancel()
        }
        
        // Start the upload
        let uploader = EMUploadPublicFootageForJointEmu()
        uploader.footage = footage as! UserFootage
        uploader.emu = emu
        uploader.slotIndex = emu.jointEmuInitiatorSlot()
        uploader.delegate = self
        uploader.uploadBeforeSharing()
        uploader.view = self.guiSlotsContainer
        self.uploaders[jeOID] = uploader
    }

    func uploadRecieverFootageBeforeFinishingReceiverFlow() {
        guard let emu = self.currentEmu() else {return}
        guard let jeOID = emu.jointEmuInstanceOID else {return}
        guard let footage = emu.mostPrefferedUserFootage() else {return}
        let slotIndex = emu.jointEmuSlotForInvitedReceiver()
        guard slotIndex > 0 else {return}
        
        self.showActivity(
            "",
            messageText: EML.s("JOINT_EMU_UPLOADING_FOOTAGE"),
            withProgress: true)
        self.jointEmuState = .ReceiverUploadingFootage
        
        // Cancel previous uploads
        if let uploader = self.uploaders[jeOID] {
            uploader.cancel()
        }
        
        // Start the upload
        let uploader = EMUploadPublicFootageForJointEmu()
        uploader.footage = footage as! UserFootage
        uploader.emu = emu
        uploader.slotIndex = slotIndex
        uploader.delegate = self
        uploader.uploadBeforeSharing()
        uploader.view = self.guiSlotsContainer
        self.uploaders[jeOID] = uploader
    }
    
    func inviteAfterInitiatorUploadedFootage() {
//        self.uploader = nil
        self.showActivity(EML.s("JOINT_EMU_INFO_INVITE_FRIEND"), messageText: EML.s("JOINT_EMU_CREATING_INVITATION"))
        let emu = self.currentEmu()!
        EMBackend.sh().server.jointEmuCreateInvite(emu.jointEmuOID(), slot: self.slotIndex, emuOID: emu.oid)
    }
    
    func cancelInvite() {
        guard self.slotIndex > 0 else {return}
        guard let emu = self.currentEmu() where emu.isJointEmu() else {return}
        guard let inviteCode = emu.jointEmuInviteCodeAtSlot(self.slotIndex) else {return}

        // Cancel the invite.
        self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_CANCELING"))
        EMBackend.sh().server.jointEmuCancelInvite(
            inviteCode,
            cancelCode: EMJEmuCancelInvite.CanceledByInitiator,
            emuOID: emu.oid)
    }
    
    func declineInvite() {
        guard let emu = self.currentEmu() else {return}
        guard let inviteCode = emu.createdWithInvitationCode else {return}
        
        self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_CANCELING"))
        EMBackend.sh().server.jointEmuCancelInvite(
            inviteCode,
            cancelCode: EMJEmuCancelInvite.DeclinedByReceiver,
            emuOID: emu.oid)
    }
    
    func finalizeJointEmu() {
        guard let emu = self.currentEmu() else {return}
        guard emu.isJointEmuInitiatedByThisUser() else {return}
        guard emu.jointEmuReadyForFinalization() else {return}
        guard let jeOID = emu.jointEmuOID() else {return}
        
        // Finalize the joint emu.
        self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_FINISHING_EMU"))
        EMBackend.sh().server.jointEmuFinalize(jeOID, emuOID: emu.oid)
    }
    
    //
    // MARK: - EMShareDelegate
    //    
    func sharerDidProgress(progress: Float, info: [NSObject : AnyObject]!) {
        guard let emu = self.currentEmu() else {return}
        guard let jeOID = info[emkJEmuOID] as? String else {return}
        guard let currentJEOID = emu.jointEmuInstanceOID where currentJEOID == jeOID else {return}
        
        // Upload progress for the footage of currently viewed joint emu.
        self.guiProgressView.setProgress(progress, animated: true)
    }
    
    func sharerDidFinishWithInfo(info: [NSObject : AnyObject]!) {
        guard let jeOID = info[emkJEmuOID] else {return}
//        if self.uploader != nil && self.uploader!.finishedSuccessfully {
//            switch self.jointEmuState {
//            case .InitiatorUploadingFootage:
//                // Successful upload by the initiator.
//                self.inviteAfterInitiatorUploadedFootage()
//            case .ReceiverUploadingFootage:
//                // Successful upload by the receiver.
//                self.currentEmu()?.jointEmuReceiverUploadedFootage = true
//                self.refreshCurrentEmu(forcedRefresh: true)
//            default:
//                break
//            }
//        }
    }
    
    func sharerDidFailWithInfo(info: [NSObject : AnyObject]!) {
//        self.updateEmuUIStateForEmu()
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
    
        // Reveal
        if animated {
            UIView.animateWithDuration(0.2) {
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
        if self.uploaders.count > 0 {
            // Are you sure you want to cancel upload?
            let alertView = SIAlertView(title: "Uploading footage...", andMessage: "Are you sure you want to cancel?")
            alertView.buttonColor = EmuStyle.colorButtonBGPositive()
            alertView.cancelButtonColor = EmuStyle.colorButtonBGNegative()
            alertView.addButtonWithTitle(EML.s("YES"), type: SIAlertViewButtonType.Default, handler: {alert in
                for uploader in self.uploaders.values {
                    uploader.cancel()
                }
                self.navigationController?.popViewControllerAnimated(true)
                self.uploaders.removeAll()
                self.alertView = nil
            })
            alertView.addButtonWithTitle(EML.s("NO"), type: SIAlertViewButtonType.Cancel, handler: {alert in
                self.refreshCurrentEmu()
            })
            alertView.show()
            self.alertView = alertView
            return
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //
    // MARK: - SlotsSelectionDelegate
    //
    func slotWasPressed(slotIndex: Int) {
        guard let emu = self.currentEmu() else {return}
        guard emu.isJointEmuInitiatedByThisUser() else {return}

        switch self.jointEmuState {
        case .InitiatorNeedsToCreateDedicatedFootage:
            if emu.isJointEmuInitiatorAtSlot(slotIndex) {
                // Initiator wants to change own footage.
                self.askAboutFootageOptions()
            }
        case .NoInvitationsSent, .InitiatorWaitingForFriends:
            if emu.isJointEmuInitiatorAtSlot(slotIndex) {
                // Initiator wants to change own footage.
                self.askAboutFootageOptions()
            } else {
                // Initiator wants to invite/cancel/decline friend at slot.
                self.initiatorActionOnAFriendSlot(slotIndex)
            }
        default:
            break
        }
    }
    
    //
    // MARK: - Actions on slots (yes it sounds funny)
    //
    func initiatorActionOnAFriendSlot(slotIndex: NSInteger) {
        let emu = self.currentEmu()!
        let slotState = emu.jointEmuStateOfSlot(slotIndex)
        switch slotState {
        case .Uninvited, .DeclinedByReceiver, .CanceledByInitiator:
            self.slotIndex = slotIndex
            self.showInviteConfirmUI()
        case .Invited:
            self.slotIndex = slotIndex
            self.showInviteCancelUI()
        default:
            break
        }
    }
    
    func fullRenderForCurrentEmu(keepResult keepResult: Bool = false) {
        guard let emuDef = self.emuDef where emuDef.isNewStyleLongRender() else {return}
        guard let emu = self.currentEmu() else {return}
        
        // Show progress
        self.guiLongRenderProgress.hidden = false
        self.guiLongRenderProgress.setProgress(0, animated: false)
        self.guiLongRenderProgress.alpha = 1
        self.guiLongRenderLabel.hidden = false
        self.guiLongRenderLabel.text = "Rendering preview"
        
        // Cancel preview long renders
        if self.renderer != nil {
            self.renderer?.cancel()
        }
        
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
    
    // MARK: - IB Actions
    // ===========
    // IB Actions.
    // ===========
    @IBAction func onPressedBackButton(sender: AnyObject) {
        self.goBack()
    }
    
    @IBAction func onPressedActionButton(sender: AnyObject) {
        EMUISound.sh().playSoundNamed(SND_SOFT_CLICK)
        let emu = self.currentEmu()

        if emu != nil && emu!.isJointEmu() == false {
            // Not a joint emu. Just share result.
            self.shareCurrentEmu()
            return
        }
        
        self.jointEmuState = JointEmuFlow.stateForEmu(emu)

        switch jointEmuState {
        case .UserNotSignedIn:
            self.signIn()

        case .NotCreatedYet:
            self.createJointEmuInstance()
            
        case .InitiatorNeedsToCreateDedicatedFootage:
            self.askAboutFootageOptions()
            
        case .NoInvitationsSent:
            guard let emu = self.currentEmu() else {return}
            self.slotIndex = emu.jointEmuFirstUninvitedSlotIndex()
            if slotIndex > 0 {
                self.showInviteConfirmUI()
            }
            
        case .InitiatorReadyForFinalization:
            self.finalizeJointEmu()
            
        case .Error:
            self.refreshCurrentEmu(forcedRefresh: true)
            
        default:
            break
        }
    }

    
    @IBAction func onPressedPositiveButton(sender: AnyObject) {
        EMUISound.sh().playSoundNamed(SND_SOFT_CLICK)

        // Joint Emu
        switch self.jointEmuState {
        case .SendInviteConfirmationRequired:
            self.uploadEmuFootageBeforeSendingInvite()
            
        case .InitiatorCancelInviteOptions:
            self.updateEmuUIStateForEmu()
            
        case .ReceiverInvited:
            self.askAboutFootageOptions()
            
        case .ReceiverApprovedLocalFootageAndNeedsToUpload:
            self.uploadRecieverFootageBeforeFinishingReceiverFlow()
            
        default:
            break
        }
    }
    
    @IBAction func onPressedNegativeButton(sender: AnyObject) {
        switch self.jointEmuState {
            
        case .SendInviteConfirmationRequired:
            self.updateEmuUIStateForEmu()
            
        case .InitiatorCancelInviteOptions:
            self.cancelInvite()
            
        case .ReceiverInvited:
            self.declineInvite()
            
        case .ReceiverApprovedLocalFootageAndNeedsToUpload:
            self.askAboutFootageOptions()
            
        default:
            break
        }
    }
    
    
    @IBAction func onPressedDebugButton(sender: AnyObject)
    {
    }
    
    @IBAction func onPressedLongPreviewRenderButton(sender: AnyObject)
    {
        // Full long render preview
        self.fullRenderForCurrentEmu()
    }
    
    @IBAction func onPrefferedMediaTypeChanged(sender: AnyObject) {
        self.updatePrefferedSharingMediaType()
    }
    
}
