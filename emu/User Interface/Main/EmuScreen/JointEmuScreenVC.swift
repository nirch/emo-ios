//
//  JointEmuScreenVC.swift
//  emu
//
//  Created by Aviv Wolf on 03/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

extension EmuScreenVC {

    //
    // MARK: - Joint emu UI updates
    //
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
        
        //
        // Get the state
        //
        self.jointEmuState = JointEmuFlow.stateForEmu(emu, uploader: relatedUploader)
        self.guiSlotsContainer.hidden = emu == nil
        self.slotsVC?.emu = emu

        // Long renders indicator
        self.updateLongRenderIndicator()
        
        // By default hide the sharing UI
        // Show it, only if the emu is finalized.
        self.hideSharing()
        
        // Allow, by default, to brose joint emu instances
        self.guiEmusContainer.alpha = 1
        self.guiEmusContainer.userInteractionEnabled = true
        
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

    //
    // MARK: - Joint emu actions
    //
    func jointEmuInviteLink(inviteCode: String) -> String {
        if AppManagement.sh().isTestApp() || AppManagement.sh().isDevApp() {
            return "jointemubeta://invite/\(inviteCode)"
//            return "http://api.emu.im/invite/\(inviteCode)"
        } else {
            return "jointemu://invite/\(inviteCode)"
//            return "http://api-dev.emu.im/jointemu/invite/\(inviteCode)"
        }
    }
}