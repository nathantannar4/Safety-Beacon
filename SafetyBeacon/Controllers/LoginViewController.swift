//
//  LoginViewController.swift
//  SafetyBeacon
//
//  Copyright © 2017 Nathan Tannar.
//  Created by Nathan Tannar on 9/25/17.
//

import UIKit
import Parse
import NTComponents

class LoginViewController: NTLoginViewController, NTEmailAuthDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logo = UIImage(named: "SafetyBeaconCircleLogo")
        logoView.layer.cornerRadius = 150 / 2
        loginMethods = [.email]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        LocationManager.shared.requestAlwaysAuthorization()
    }
    
    override func loginLogic(sender: NTLoginButton) {
        
        if sender.loginMethod == .email {
            let vc = NTEmailAuthViewController()
            vc.delegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    func authorize(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        controller.showActivityIndicator = true
        User.loginInBackground(email: email, password: password) { (success) in
            controller.showActivityIndicator = false
            if success {
                self.dismiss(animated: false, completion: {
                    LoginViewController.loginSuccessful()
                })
            }
        }
    }
    
    func register(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        controller.showActivityIndicator = true
        User.registerInBackground(email: email, password: password) { (success) in
            controller.showActivityIndicator = false
            if success {
                self.dismiss(animated: false, completion: {
                    LoginViewController.loginSuccessful()
                })
            }
        }
    }
    
    class func loginSuccessful() {
        
        guard let currentUser = User.current() else { return }
        
        if currentUser.requiresSetup {
            
            // Setup still required
            appController.setViewController(ContentController(rootViewController: AccountSetupViewController()), forSide: .center)
            
        } else {
            if currentUser.isCaretaker {
                
                // Caretaker Views
                
                let viewControllers = [ReportViewController(), BookmarksViewController(), SafeZonesViewController(), HistoryViewController()]
                let tabBarController = NTScrollableTabBarController(viewControllers: viewControllers)
                appController.setViewController(ContentController(rootViewController: tabBarController), forSide: .center)

            } else if currentUser.isPatient {
                
                // Patient Views
                
                let viewControllers = [MapViewController()]
                let tabBarController = NTScrollableTabBarController(viewControllers: viewControllers)
                appController.setViewController(ContentController(rootViewController: tabBarController), forSide: .center)
            }
        }
    }
}
