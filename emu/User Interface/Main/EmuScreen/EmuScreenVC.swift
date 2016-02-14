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
    EMInterfaceDelegate {
    
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
    var uploader: EMUploadPublicFootageForJointEmu?
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Apply theme
        self.applyTheme()

        // Init data
        self.initData()
        
        // Init gui state
        self.initGUI()
        
        // Loading emu...
        self.showActivity(EML.s("JOINT_EMU_LOADING"), messageText: EML.s("JOINT_EMU_LOADING"))
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
        guard self.currentEmu() != nil else {return}
        
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
        NSLog("..... >>>> \(notification.userInfo)")

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
    
    func refreshCurrentEmu() {
        guard let emu = self.currentEmu() else {
            // No emu instance? update UI to indicate that no emu is in focus.
            self.updateEmuUIStateForEmu()
            return
        }
        
        if emu.isJointEmu() == true && emu.jointEmuOID() != nil {
            // Refresh joint emu (but not more than once a minute)
            let lastTime = self.timeRefetchedFromServer[emu.jointEmuOID()]
            let now = NSDate()
            if lastTime == nil || now.timeIntervalSinceDate(lastTime!) > 60 {
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
    }
    
    func updateEmuUIStateForNormalEmu() {
        
    }
    
    func updateEmuUIStateForJointEmu() {
        guard let emuDef = self.emuDef where emuDef.isJointEmu() else {return}

        // Current joint emu instance may be nil, if no emu instance is currently in focus.
        let emu = self.currentEmu()
        
        // Get the state
        self.jointEmuState = JointEmuFlow.stateForEmu(emu)
        self.guiSlotsContainer.hidden = emu == nil
        self.slotsVC?.emu = emu
        self.updateLongRenderIndicator()
        
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
         
        // Initiator flow
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
        
        // Receiver
        case .ReceiverInvited:
            self.showUserMessage(EML.s("JOINT_EMU_INFO_JOIN_NEW_INVITE"), messageText: EML.s(""))
            self.showFlowButtons(EML.s("CHOOSE_TAKE"), negativeButtonText: EML.s("DECLINE"))
        case .Error:
            self.showActivity("error :-(", messageText: "Epic FAIL!!!")
            
        default:
            break
        }
    }

    func showActionButton(actionText: String, buttonDisabled: Bool = false) {
        self.guiActionButtonContainer.hidden = false
        self.guiFlowButtonsContainer.hidden = true
        self.guiProgressView.progress = 0.0
        self.slotIndex = 0
        
        if buttonDisabled {
            self.guiActionButtonContainer.userInteractionEnabled = false
            self.guiActionButtonContainer.alpha = 0.6
        } else {
            self.guiActionButtonContainer.userInteractionEnabled = true
            self.guiActionButtonContainer.alpha = 1.0
        }
        
        self.guiActionButton.setTitle(actionText.uppercaseString, forState: .Normal)
        self.guiEmusContainer.userInteractionEnabled = true
    }
    
    func showUserMessage(titleText: String, messageText: String) {
        self.guiActivity.stopAnimating()
        self.guiUserGuidanceTitle.text = titleText
        self.guiMessage.text = messageText
        self.guiEmusContainer.userInteractionEnabled = true
    }
    
    func showActivity(titleText: String, messageText: String, withProgress: Bool = false) {
        self.guiActionButtonContainer.hidden = true
        self.guiFlowButtonsContainer.hidden = true
        
        self.guiProgressView.setProgress(0, animated: false)
        
        self.guiActivity.startAnimating()
        self.guiMessage.text = messageText
        self.guiUserGuidanceTitle.text = titleText
        self.guiEmusContainer.userInteractionEnabled = false
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
        guard slotIndex > 0 else {return}
        let emuDef = emu.emuDef!
        
        let duration = emuDef.jointEmuDefCaptureDurationAtSlot(slotIndex)
        let dedicatedFootageRequired = emuDef.jointEmuDefRequiresDedicatedCaptureAtSlot(slotIndex)
        
        // New take or replace take?
        var message = "dsfgsdfgdsfg"
        if dedicatedFootageRequired {
            message = "xxxxxxxxxxxxxx long"
        }
        
        let alertView = SIAlertView(title: nil, andMessage: message)
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
            let nc = NSNotificationCenter.defaultCenter()
            nc.postNotificationName(emkUIUserRequestToOpenRecorder, object: self, userInfo: requestInfo)
        })
        
        // Cancel option
        alertView.addButtonWithTitle(EML.s("CANCEL"), type: SIAlertViewButtonType.Cancel, handler:nil)
        
        // Show the alert.
        alertView.show()
        self.alertView = alertView
    }
    
    //
    // MARK: - EmuSelectionProtocol
    //
    func emuSelected(emu: Emuticon?) {
        self.refreshCurrentEmu()
    }
    
    func emuPressed(emu: Emuticon?) {
        self.refreshCurrentEmu()
        if emu == nil {
            
        } else {
            self.askAboutFootageOptions()
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
        var textToShare = "I'm inviting you to join my Emu\n"
        if let inviteCode = self.currentEmu()?.jointEmuInviteCodeAtSlot(self.slotIndex) {
            textToShare += self.jointEmuInviteLink(inviteCode)
            
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
        } else {
            self.cancelInvite()
        }
    }
    
    func uploadEmuFootageBeforeSendingInvite() {
        self.showActivity(
            EML.s("JOINT_EMU_INFO_INVITE_FRIEND"),
            messageText: EML.s("JOINT_EMU_UPLOADING_FOOTAGE"),
            withProgress: true)
        
        self.jointEmuState = .InitiatorUploadingFootage
        let footage = self.currentEmu()?.mostPrefferedUserFootage()

        if footage is UserFootage {
            self.uploader = EMUploadPublicFootageForJointEmu()
            uploader?.footage = footage as! UserFootage
            uploader?.emu = self.currentEmu()
            uploader?.slotIndex = 1;
            uploader?.delegate = self
            self.uploader?.uploadBeforeSharing()
        }
    }
    
    func inviteAfterInitiatorUploadedFootage() {
        self.uploader = nil
        self.showActivity(EML.s("JOINT_EMU_INFO_INVITE_FRIEND"), messageText: EML.s("JOINT_EMU_CREATING_INVITATION"))
        let emu = self.currentEmu()!
        EMBackend.sh().server.jointEmuCreateInvite(emu.jointEmuOID(), slot: self.slotIndex, emuOID: emu.oid)
    }
    
    func cancelInvite() {
        self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_CANCELING"))
        let emu = self.currentEmu()!
        let inviteCode = emu.jointEmuInviteCodeAtSlot(self.slotIndex)!
        EMBackend.sh().server.jointEmuCancelInvite(
            inviteCode,
            cancelCode: EMJEmuCancelInvite.CanceledByInitiator,
            emuOID: emu.oid)
    }
    
    func declineInvite() {
        if let emu = self.currentEmu() {
            if let inviteCode = emu.createdWithInvitationCode {
                self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_CANCELING"))
                EMBackend.sh().server.jointEmuCancelInvite(
                    inviteCode,
                    cancelCode: EMJEmuCancelInvite.DeclinedByReceiver,
                    emuOID: emu.oid)
            }
        }
        
    }
    
    //
    // MARK: - EMShareDelegate
    //    
    func sharerDidProgress(progress: Float, info: [NSObject : AnyObject]!) {
        self.guiProgressView.setProgress(progress, animated: true)
    }
    
    func sharerDidFinishWithInfo(info: [NSObject : AnyObject]!) {
        if self.uploader != nil && self.uploader!.finishedSuccessfully {
            if self.jointEmuState == JointEmuState.InitiatorUploadingFootage {
                // Successful upload
                self.inviteAfterInitiatorUploadedFootage()
            }
        }
    }
    
    func sharerDidFailWithInfo(info: [NSObject : AnyObject]!) {
        self.updateEmuUIStateForEmu()
    }
    
    //
    // MARK: - EMInterfaceDelegate
    //
    func controlSentActionNamed(actionName: String!, info: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true) {
            guard actionName == emkUIFootageSelectionApply else {return}
            guard let footageOID = info[emkFootageOID] as? String else {return}
            guard let footage = UserFootage.findWithID(footageOID, context: EMDB.sh().context) else {return}
            guard let emu = self.currentEmu() else {return}
            
            // Update the preffered footage of this emu.
            emu.prefferedFootageOID = footage.oid
            emu.cleanUp()
            self.emusVC?.refresh()
            self.updateEmuUIStateForEmu()
        }
    }
    
    //
    // MARK: - Going back
    //
    func goBack() {
        if self.uploader != nil {
            // Are you sure you want to cancel upload?
            let alertView = SIAlertView(title: "Uploading footage...", andMessage: "Are you sure you want to cancel?")
            alertView.buttonColor = EmuStyle.colorButtonBGPositive()
            alertView.cancelButtonColor = EmuStyle.colorButtonBGNegative()
            alertView.addButtonWithTitle(EML.s("YES"), type: SIAlertViewButtonType.Default, handler: {alert in
                self.uploader?.cancel()
                self.navigationController?.popViewControllerAnimated(true)
                self.alertView = nil
                self.uploader = nil
            })
            alertView.addButtonWithTitle(EML.s("NO"), type: SIAlertViewButtonType.Cancel, handler: {alert in
                if self.uploader != nil && self.uploader!.finishedSuccessfully {
                    if self.jointEmuState == JointEmuState.InitiatorUploadingFootage {
                        // Successful upload
                        self.inviteAfterInitiatorUploadedFootage()
                    }
                }
                self.alertView = nil
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
        case .Uninvited, .DeclinedByReceiver:
            self.slotIndex = slotIndex
            self.showInviteConfirmUI()
        case .Invited:
            self.slotIndex = slotIndex
            self.showInviteCancelUI()
        default:
            break
        }
    }
    
    func previewFullRenderForCurrentEmu() {
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
        
        // Render a preview
        let rm = EMRenderManager3.sh()
        self.renderer = rm.renderPreviewForEmuDefOID(
            emuDef.oid!,
            footagesForPreview: emu.relatedFootages() as! [FootageProtocol]
        )
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
        self.jointEmuState = JointEmuFlow.stateForEmu(emu)

        switch jointEmuState {
        case .UserNotSignedIn:
            self.signIn()

        case .NotCreatedYet:
            self.createJointEmuInstance()
            
        case .NoInvitationsSent:
            if let emu = self.currentEmu() {
                self.slotIndex = emu.jointEmuFirstUninvitedSlotIndex()
                if slotIndex > 0 {
                    self.showInviteConfirmUI()
                }
            }
            
        case .Error:
            self.showUserMessage("epic fail!", messageText: "Error. Try again later.")
            
        default:
            break
        }
    }

    
    @IBAction func onPressedPositiveButton(sender: AnyObject) {
        EMUISound.sh().playSoundNamed(SND_SOFT_CLICK)
        switch self.jointEmuState {
            
        case .SendInviteConfirmationRequired:
            self.uploadEmuFootageBeforeSendingInvite()
            
        case .InitiatorCancelInviteOptions:
            self.updateEmuUIStateForEmu()
            
        case .ReceiverInvited:
            self.askAboutFootageOptions()
            break
            
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
        default:
            break
        }
    }
    
    
    @IBAction func onPressedDebugButton(sender: AnyObject)
    {
        if let emu = self.currentEmu() {
            emu.cleanUp()
            self.emusVC?.refresh()
            
//            let footage = emu.jointEmuFootageAtSlot(1)
//            footage.cleanDownloadedRemoteFiles()
        }
    }
    
    @IBAction func onPressedLongPreviewRenderButton(sender: AnyObject)
    {
        // Full long render preview
        self.previewFullRenderForCurrentEmu()
    }
    
    
}
