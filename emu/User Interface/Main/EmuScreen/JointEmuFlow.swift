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
    case SendInviteConfirmationRequired
    case InitiatorUploadingFootage
    case InitiatorWaitingForFriends
    case InitiatorCancelInviteOptions
    
    // Receiver
    case ReceiverInvited
    
    case Error
}

class JointEmuFlow: NSObject {
    class func stateForEmu(anEmu: Emuticon?) -> JointEmuState {
        if anEmu == nil {return .NotCreatedYet}

        let emu = anEmu!
        
        // Not a joint emu?
        if !emu.isJointEmu() {return .NotAJointEmu}
        
        // User must be signed in first, before it is possible to start the flow of emu creation.
        let appCFG = AppCFG.cfgInContext(EMDB.sh().context)
        if appCFG.userSignInID == nil {return .UserNotSignedIn}
        
        // Check if required to create the joint emu on the server side.
        if emu.jointEmuInstance == nil {return .InstanceInfoMissing}
        
        // Initiator or receiver?
        if emu.isJointEmuInitiatedByThisUser() {
            
            // Initiator flow

            // Check if no invitations sent yet
            if emu.jointEmuInvitationsSentCount() == 0 {return .NoInvitationsSent}
            
            return .InitiatorWaitingForFriends
            
            
        } else {
            
            // Receiver flow
            if let invitationCode = emu.createdWithInvitationCode {
                let receiverSlotIndex = emu.jointEmuSlotForInvitationCode(invitationCode)
                if receiverSlotIndex > 0 {
                    //let state = emu.jointEmuStateOfSlot(receiverSlotIndex)
                    return .ReceiverInvited
                    
                } else {
                    return .Error
                }
            } else {
                // Error 
                return .Error
            }
        }
        
    }
}