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

class EmuScreenVC: UIViewController, EmuSelectionProtocol {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //
    // Outlets
    //
    
    // Nav
    @IBOutlet weak var guiTitle: EMLabel!
    @IBOutlet weak var guiNavBarView: UIView!
    
    // User messages
    @IBOutlet weak var guiUserGuidanceTitle: EMLabel!
    @IBOutlet weak var guiMessage: UILabel!
    @IBOutlet weak var guiActivity: UIActivityIndicatorView!
    
    // Actions
    @IBOutlet weak var guiActionButton: EMFlowButton!
    
    
    // Child VCs
    var emusVC: EmusVC?
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Apply theme
        self.applyTheme()

        // Init data
        self.initData()
        
        // Init gui state
        self.initGUI()
        
        
        // Update UI state
        self.updateEmuUIStateForEmu()
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
        
        self.guiActionButton.positive = true
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
        let jointEmuState = JointEmuFlow.stateForEmu(emu)
        
        switch jointEmuState {
            case .UserNotSignedIn:
                self.guiUserGuidanceTitle.text = EML.s("JOINT_EMU")
                self.guiMessage.text = EML.s("NO_INVITATION_SENT")
                self.guiActionButton.setTitle(EML.s("JOINT_EMU_SIGN_IN_REQUIRED"), forState: .Normal)
            default:
                break
        }
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
        self.guiActionButton.hidden = true
        self.guiActivity.startAnimating()
        self.guiMessage.text = EML.s("JOINT_EMU_LOADING")
    }
    
    // MARK: - IB Actions
    // ===========
    // IB Actions.
    // ===========
    @IBAction func onPressedBackButton(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func onPressedActionButton(sender: AnyObject) {
        let emu = self.currentEmu()
        let jointEmuState = JointEmuFlow.stateForEmu(emu)

        switch jointEmuState {
            case .UserNotSignedIn:
                self.signIn()
            default:
                break
        }
    }

}
