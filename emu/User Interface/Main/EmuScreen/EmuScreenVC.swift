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

class EmuScreenVC: UIViewController, EmuSelectionProtocol, EMShareDelegate {
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
    
    // Progress
    @IBOutlet weak var guiActivity: UIActivityIndicatorView!
    @IBOutlet weak var guiProgressView: UIProgressView!
    
    // Actions
    @IBOutlet weak var guiActionButtonContainer: UIView!
    @IBOutlet weak var guiActionButton: EMFlowButton!
    
    @IBOutlet weak var guiFlowButtonsContainer: UIView!
    @IBOutlet weak var guiPositiveButton: EMFlowButton!
    @IBOutlet weak var guiNegativeButton: EMFlowButton!
    
    // User invite
    @IBOutlet weak var guiInviteStateButton: UIButton!
    
    // Alerts
    var alertView: SIAlertView?
    
    // Child VCs
    var emusVC: EmusVC?
    
    // Emu definition oid
    var emuDefOID: String = ""
    var emuDef: EmuticonDef?
    var jointEmuState: JointEmuState = JointEmuState.Undefined {
        didSet {
            
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
        
        //
        self.showActivity(EML.s("JOINT_EMU_LOADING"), messageText: EML.s("JOINT_EMU_LOADING"))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.initObservers()
        
        // Refresh joint emu
        if let emu = self.currentEmu() {
            if emu.isJointEmu() == true && emu.jointEmuOID() != nil {
                self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_LOADING"))
                EMBackend.sh().server.jointEmuRefetch(emu.jointEmuOID(), emuOID: emu.oid)
            } else {
                self.updateEmuUIStateForEmu()
            }
        }
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
        
        
        if let l = self.guiInviteStateButton?.layer {
            l.cornerRadius = self.guiInviteStateButton.bounds.width/2.0
            l.borderColor = UIColor.lightGrayColor().CGColor
            l.borderWidth = 2.0
            self.guiInviteStateButton.backgroundColor = UIColor.clearColor()
            self.guiInviteStateButton.setImage(UIImage(named: "placeholder480.png"), forState: .Normal)
        }

    }
    
    //
    // MARK: - Observers
    //
    // MARK: - Observers
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
    }
    
    func removeObservers() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(emkUserSignedIn)
        nc.removeObserver(emkJointEmuNew)
        nc.removeObserver(emkJointEmuRefresh)
        nc.removeObserver(emkJointEmuCreateInvite)
    }
    
    // MARK: - Observers handlers
    func onUserSignIn(notification: NSNotification) {
        self.updateEmuUIStateForEmu()
    }
    
    func onJointEmuNew(notification: NSNotification) {
        self.updateEmuUIStateForEmu()
    }
    
    func onJointEmuRefresh(notification: NSNotification) {
        self.updateEmuUIStateForEmu()
    }
    
    func onJointEmuInviteCreated(notification: NSNotification) {
        self.sendInviteToFriend()
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
    // MARK: - State
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
        self.jointEmuState = JointEmuFlow.stateForEmu(emu)
        
        switch self.jointEmuState {
            
        case .UserNotSignedIn:
            self.showActionButton(EML.s("JOINT_EMU_SIGN_IN_REQUIRED"))
            self.showUserMessage(EML.s("JOINT_EMU"), messageText: EML.s("NO_INVITATION_SENT"))
            
        case .InstanceInfoMissing:
            self.createJointEmuInstance()
            
        case .NoInvitationsSent:
            self.showUserMessage(EML.s("JOINT_EMU_INFO_INVITE_FRIEND"), messageText: EML.s("NO_INVITATION_SENT"))
            self.showActionButton(EML.s("INVITE_FRIEND"))
            
        case .InitiatorWaitingForFriends:
            self.showUserMessage(EML.s("JOINT_EMU_INFO_WAIT_FOR_FRIENDS"), messageText: EML.s("INVITED"))
            self.showActionButton(EML.s("WAIT_FOR_YOU_FRIENDS"), buttonDisabled: true)
            self.guiInviteStateButton.tintColor = EmuStyle.colorButtonBGPositive()
            
        case .Error:
            self.showActivity("error :-(", messageText: "Epic FAIL!!!")
            
        default:
            break
        }
    }

    func showActionButton(actionText: String, buttonDisabled: Bool = false) {
        self.guiActionButtonContainer.hidden = false
        self.guiFlowButtonsContainer.hidden = true
        self.guiProgressView.hidden = true
        
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
        
        self.guiProgressView.hidden = !withProgress
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
    
    //
    // MARK: - EmuSelectionProtocol
    //
    func emuSelected(emu: Emuticon?) {
        self.updateEmuUIStateForEmu()
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
            EMBackend.sh().server.jointEmuNewForEmuOID(self.currentEmu()?.oid)
        })
    }
    
    func showInviteConfirmUI() {
        self.jointEmuState = JointEmuState.SendInviteConfirmationRequired
        self.showUserMessage(EML.s("JOINT_EMU_INFO_INVITE_FRIEND"), messageText: "Your footage will be sent to your friend")
        self.showFlowButtons(EML.s("SEND").uppercaseString, negativeButtonText: EML.s("CANCEL").uppercaseString)
    }
    
    func sendInviteToFriend() {
        var textToShare = "I'm inviting you to join my Emu\n"
        if let invitecode = self.currentEmu()?.jointEmuInviteCodeAtSlot(2) {
            textToShare += "emubetaopen://invite/\(invitecode)"
            
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
        EMBackend.sh().server.jointEmuCreateInvite(emu.jointEmuOID(), slot: 2, emuOID: emu.oid)
    }
    
    func askIfToCancelInvite() {
        self.jointEmuState = .InitiatorCancelInviteOptions
        self.showUserMessage(EML.s("JOINT_EMU_INFO_KEEP_CANCEL_INVITE"), messageText: "")
        self.showFlowButtons(EML.s("KEEP_INVITATION"), negativeButtonText: EML.s("CANCEL_INVITATION"))
    }
    
    func cancelInvite() {
        self.showActivity(EML.s("JOINT_EMU"), messageText: EML.s("JOINT_EMU_CANCELING"))
        let emu = self.currentEmu()!
        let inviteCode = emu.jointEmuInviteCodeAtSlot(2)!
        EMBackend.sh().server.jointEmuCancelInvite(
            inviteCode,
            cancelCode: EMJEmuCancelInvite.CanceledByInitiator,
            emuOID: emu.oid)
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
    
    // MARK: - IB Actions
    // ===========
    // IB Actions.
    // ===========
    @IBAction func onPressedBackButton(sender: AnyObject) {
        self.goBack()
    }
    
    @IBAction func onPressedActionButton(sender: AnyObject) {
        let emu = self.currentEmu()
        self.jointEmuState = JointEmuFlow.stateForEmu(emu)

        switch jointEmuState {
            case .UserNotSignedIn:
                self.signIn()
            
            case .NoInvitationsSent:
                self.showInviteConfirmUI()
            
            case .Error:
                self.showUserMessage("epic fail!", messageText: "Error. Try again later.")
            
            default:
                break
        }
    }

    
    @IBAction func onPressedPositiveButton(sender: AnyObject) {
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
        default:
            break
        }
    }
    
    @IBAction func onPressedUserButton(sender: AnyObject) {
        switch self.jointEmuState {
        case .InitiatorWaitingForFriends:
            self.askIfToCancelInvite()
        default:
            break
        }
    }
    
}
