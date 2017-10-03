//
//  User.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse

class User: NSObject {
    
    private static var currentUser: User?
    
    // MARK: - Properties
    
    let object: PFUser
    
    override var description: String {
        return object.description
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
}
