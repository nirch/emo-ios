//
//  JointEmuFlow.swift
//  emu
//
//  Created by Aviv Wolf on 31/01/2016.
//  Copyright © 2016 Homage. All rights reserved.
//
import Foundation

enum JointEmuState {
    case NotCreatedYet
    case NotAJointEmu
    case UserNotSignedIn
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
        
        // :-(
        return .Error
    }
}
