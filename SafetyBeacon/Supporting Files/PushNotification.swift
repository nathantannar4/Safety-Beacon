//
//  PushNotification.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse

class PushNotication {
    
    class func parsePushUserAssign() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        let installation = PFInstallation.current()!
        installation[PF_INSTALLATION_USER] = PFUser.current()
        installation.saveInBackground(block: { (success, error) in
            if error != nil {
                print("parsePushUserAssign save error.")
            }
        })
    }
    
    class func parsePushUserResign() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        let installation = PFInstallation.current()!
        installation.remove(forKey: PF_INSTALLATION_USER)
        installation.saveInBackground { (succeeded: Bool, error: Error?) -> Void in
            if error != nil {
                print("parsePushUserResign save error")
            }
        }
    }
    
    class func sendPushNotificationMessage(_ groupId: String, text: String) {
        
        var userIDs = groupId
    
        while userIDs.characters.count >= 10 {
            let index = userIDs.index(userIDs.startIndex, offsetBy: 10)
            let sendToID = userIDs[...index]
            if PFUser.current()!.objectId! != sendToID {
                print("Will send PUSH to \(sendToID)")
                PFCloud.callFunction(inBackground: "pushToUser", withParameters: ["user": sendToID, "message": text], block: { (object, error) in
                    if error == nil {
                        print("##### PUSH OK")
                    } else {
                        print("##### ERROR: \(error.debugDescription)")
                    }
                })
            }
            userIDs = String(userIDs[index...]) // TODO
        }
    }
}
