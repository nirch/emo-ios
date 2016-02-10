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
}

class EmuScreenVC: UIViewController,
    EmuSelectionProtocol,
    EMShareDelegate,
    SlotsSelectionDelegate {
    
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
    }
    
    func removeObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(emkUserSignedIn)
        nc.removeObserver(emkJointEmuNew)
        nc.removeObserver(emkJointEmuRefresh)
        nc.removeObserver(emkJointEmuCreateInvite)
        nc.removeObserver(hmkRenderingFinished)
        nc.removeObserver(hmkDownloadResourceFinished)
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
        if let emu = self.currentEmu() {
            if let info = notification.userInfo {
                if info[emkEmuticonOID] as? String == emu.oid {
                    self.refreshCurrentEmu()
                }
            }
        }
    }
    
    func onDownloadFinished(notification: NSNotification) {
        if let emu = self.currentEmu() {
            if let info = notification.userInfo {
                if info[emkEmuticonOID] as? String == emu.oid {
                    self.refreshCurrentEmu()
                }
            }
        }
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
        if let emu = self.currentEmu() {
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
    }
    
    //
    // MARK: - UI States
    //
    func updateEmuUIStateForEmu() {
        if let emuDef = self.emuDef {
            if emuDef.isJointEmu() {
                self.updateEmuUIStateForJointEmu()
            } else {
                
            }
        }
    }
    
    func updateEmuUIStateForJointEmu() {
        let emu = self.currentEmu()
        if emu != nil && emu?.isJointEmu() == false {return}
        
        self.jointEmuState = JointEmuFlow.stateForEmu(emu)
        self.guiSlotsContainer.hidden = emu == nil
        self.slotsVC?.emu = emu
        
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
    
    //
    // MARK: - EmuSelectionProtocol
    //
    func emuSelected(emu: Emuticon?) {
        self.refreshCurrentEmu()
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
//        "http://api-dev.emu.im/jointemu/invite/\(inviteCode)"
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
        self.uploader = EMUploadPublicFootageForJointEmu()
        uploader?.footage = footage
        uploader?.emu = self.currentEmu()
        uploader?.slotIndex = 1;
        uploader?.delegate = self
        self.uploader?.uploadBeforeSharing()
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
        switch self.jointEmuState {
        case .NoInvitationsSent, .InitiatorWaitingForFriends:
            if let emu = self.currentEmu() {
                if emu.isJointEmuInitiatorAtSlot(slotIndex) {
                    // Initiator wants to change own footage.
                } else {
                    // Initiator wants to invite/cancel/decline friend at slot.
                    self.initiatorActionOnAFriendSlot(slotIndex)
                }
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
        }
    }
    
}
