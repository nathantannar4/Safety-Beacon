//
//  User.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse

class User: NSObject {
    
    private static var currentUser: User? {
        didSet {
            // Loads the linked user
            currentUser?.caretaker?.fetchInBackground()
            currentUser?.patient?.fetchInBackground()
        }
    }
    
    // MARK: - Properties
    
    let object: PFUser
    
    override var description: String {
        return object.description
    }
    
    var id: String? {
        return object.objectId
    }
    
    var username: String? {
        return object.username
    }
    
    var email: String? {
        return object.email
    }
    
    var fullname: String? {
        get {
            return object[PF_USER_FULLNAME] as? String
        }
        set {
            return object[PF_USER_FULLNAME] = newValue
        }
    }
    
    var caretaker: PFUser? {
        return object[PF_USER_CARETAKER] as? PFUser
    }
    
    var patient: PFUser? {
        return object[PF_USER_PATIENT] as? PFUser
    }
    
    var isCaretaker: Bool {
        return caretaker == nil
    }
    
    var isPatient: Bool {
        return patient == nil
    }
    
    var requiresSetup: Bool {
        return !isPatient && !isCaretaker
    }
    
    var image: PFFile? {
        return object[PF_USER_PICTURE] as? PFFile
    }
    
    // MARK: - Initialization
    
    init(fromPFUser user: PFUser) {
        object = user
        super.init()
    }
    
    // MARK: - Class Functions
    
    /// Trys to return the current user
    ///
    /// - Returns: The current user that is logged in
    class func current() -> User? {

        guard let user = currentUser else {
            // _current was nil, try loading from the cache
            guard let cachedUser = PFUser.current() else {
                return nil
            }
            let user = User(fromPFUser: cachedUser)
            
            // Save for later use
            currentUser = user
            return user
        }
        return user
    }
    
    /// Logs in a user and sets them as the current user
    ///
    /// - Parameters:
    ///   - email: Email Credentials
    ///   - password: Password Credentials
    ///   - completion: A completion block with a result indicating if the login was successful
    class func loginInBackground(email: String, password: String, completion: ((Bool) -> Void)?) {
        PFUser.logInWithUsername(inBackground: email, password: password) { (user, error) in
            guard let user = user else {
                Log.write(.error, error.debugDescription)
                completion?(false)
                return
            }
            currentUser = User(fromPFUser: user)
            completion?(true)
        }
    }
    
    class func registerInBackground(email: String, password: String, completion: ((Bool) -> Void)?) {
        
        let user = PFUser()
        user.email = email
        user.username = email
        user.password = password
        user.signUpInBackground { (success, error) in
            guard success else {
                Log.write(.error, error.debugDescription)
                completion?(false)
                return
            }
            currentUser = User(fromPFUser: user)
            completion?(true)
        }
    }
    
    class func logoutInBackground(_ completion: ((Bool) -> Void)?) {
        PFUser.logOutInBackground { (error) in
            guard error == nil else {
                Log.write(.error, error.debugDescription)
                completion?(false)
                return
            }
            currentUser = nil
            completion?(true)
        }
    }
}
