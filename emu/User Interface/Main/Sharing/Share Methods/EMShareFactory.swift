//
//  EMShareFactory.swift
//  emu
//
//  Created by Aviv Wolf on 21/02/2016.
//  Copyright © 2016 Homage. All rights reserved.
//

import UIKit

class EMShareFactory: NSObject {
    class func sharerForShareMethod(method: EMKShareMethod) -> EMShare? {
        var sharer: EMShare? = nil
        switch method {

        case .emkShareMethodCopy:
            // Copy to clipboard
            sharer = EMShareCopy()
            
        case .emkShareMethodSaveToCameraRoll:
            // Save to camera roll
            sharer = EMShareSaveToCameraRoll()
            
        case .emkShareMethodMail:
            // Mail client
            sharer = EMShareMail()
            
        case .emkShareMethodAppleMessages:
            // Apple messages
            sharer = EMShareAppleMessage()

        case .emkShareMethodFacebookMessanger:
            // Facebook messagenger
            sharer = EMShareFBMessanger()
            
        case .emkShareMethodFacebook:
            // Facebook
            sharer = EMShareFacebook()
            
        case .emkShareMethodDocumentInteraction:
            // Documents interaction
            sharer = EMShareDocumentInteraction()
            
        case .emkShareMethodTwitter:
            // Twitter
            sharer = EMShareTwitter()
            sharer?.requiresUserInput = true
            
        case .emkShareMethodInstagram:
            // Instagram
            sharer = EMShareInstoosh()
            
        default:
            sharer = nil
        }
        return sharer
    }
}
