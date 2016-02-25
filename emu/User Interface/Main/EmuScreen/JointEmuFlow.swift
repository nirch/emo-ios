//
//  JointEmuFlow.swift
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//
import Foundation

enum JointEmuState {
    case Undefined
    case NotCreatedYet
    case NotAJointEmu
    case UserNotSignedIn
    
    case InstanceInfoMissing
    
    // Initiator
    case NoInvitationsSent
    case InitiatorNeedsToCreateDedicatedFootage
    case SendInviteConfirmationRequired
    case InitiatorUploadingFootage
    case InitiatorWaitingForFriends
    case InitiatorCancelInviteOptions
    case InitiatorReadyForFinalization
    
    // Receiver
    case ReceiverInvited
    case ReceiverApprovedLocalFootageAndNeedsToUpload
    case ReceiverUploadingFootage
    case ReceiverWaitingForFlowEnd
    
    // Finalized
    case Finalized
    
    case Error
}

class JointEmuFlow: NSObject {
    class func stateForEmu(anEmu: Emuticon?, uploader: EMUploadPublicFootageForJointEmu? = nil) -> JointEmuState {
        guard let emu = anEmu else {return .NotCreatedYet}
        
        // Not a joint emu?
        if !emu.isJointEmu() {return .NotAJointEmu}
        
        // User must be signed in first, before it is possible to start the flow of emu creation.
        let appCFG = AppCFG.cfgInContext(EMDB.sh().context)
        if appCFG.userSignInID == nil {return .UserNotSignedIn}
        
        // Check if required to create the joint emu on the server side.
        if emu.jointEmuInstance == nil {return .InstanceInfoMissing}
        
        // Uploading?
        if let currentUploader = uploader {
            if (currentUploader.finished != true) {
                // If uploader currently exists and still uploading
                if emu.isJointEmuInitiatedByThisUser() {
                    return .InitiatorUploadingFootage
                } else {
                    return .ReceiverUploadingFootage
                }
            }
        }
        
        
        // Finalized emu
        if emu.isJointEmuFinalized() {
            return .Finalized
        }
        
        // Initiator or receiver?
        if emu.isJointEmuInitiatedByThisUser() {
            return self.stateForJointEmuInitiatedByThisUser(emu)
        } else {
            return self.stateForJointEmuReceivedByThisUser(emu)
        }
    }
    
    private class func stateForJointEmuInitiatedByThisUser(emu: Emuticon) -> JointEmuState {
        // Initiator flow
        guard emu.isJointEmuInitiatedByThisUser() else {return .Error}
        guard let emuDef = emu.emuDef else {return .Error}

        // If requires dedicated footage and none selected yet,
        // The initiator will need to create one first.
        if emuDef.jointEmuDefRequiresDedicatedCaptureAtSlot(emu.jointEmuLocalSlotIndex()) {
            if emu.prefferedFootageOID == nil {
                return .InitiatorNeedsToCreateDedicatedFootage
            }
        }
        
        // Check if no invitations sent yet
        if emu.jointEmuInvitationsSentCount() == 0 {
            return .NoInvitationsSent
        }

        // If all footages (including remote footages) downloaded, initiator can finalize the joint emu.
        if emu.jointEmuReadyForFinalization() {
            return .InitiatorReadyForFinalization
        }
        
        
        return .InitiatorWaitingForFriends
    }
    
    private class func stateForJointEmuReceivedByThisUser(emu: Emuticon) -> JointEmuState {
        guard emu.isJointEmuInitiatedByThisUser() == false else {return .Error}
        guard let invitationCode = emu.createdWithInvitationCode else {return .Error}
        let receiverSlotIndex = emu.jointEmuSlotForInvitationCode(invitationCode)
        guard receiverSlotIndex > 0 else {return .Error}
        
        // If no footage chosen specifically by the receiver, the receiver was
        // invited but still need to choose footage or decline.
        if emu.prefferedFootageOID == nil {
            return .ReceiverInvited
        }
        
        if emu.jointEmuReceiverUploadedFootage?.boolValue == true {
            return .ReceiverWaitingForFlowEnd
        }
        
        return .ReceiverApprovedLocalFootageAndNeedsToUpload
    }
    
}
