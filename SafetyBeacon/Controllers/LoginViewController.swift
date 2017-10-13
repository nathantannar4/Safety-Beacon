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
        loginMethods = [.email, .custom]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        LocationManager.shared.requestAlwaysAuthorization()
    }
    
    override func createLoginButton(forMethod method: NTLoginMethod) -> NTLoginButton {
        if method == .custom {
            let button = createLoginButton(color: Color.Default.Background.Button, title: "Caretaker Login", logo: nil)
            button.loginMethod = method
            return button
        }
        return super.createLoginButton(forMethod: method)
    }
    
    override func loginLogic(sender: NTLoginButton) {
        
        if sender.loginMethod == .email {
            let vc = NTEmailAuthViewController()
            vc.delegate = self
            present(vc, animated: true, completion: nil)
        } else if sender.loginMethod == .custom {
            User.loginInBackground(email: "caretaker@safetybeacon.ca", password: "password123") { (success) in
                if success {
                    self.loginSuccessful()
                }
            }
        }
    }
    
    func authorize(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        controller.showActivityIndicator = true
        User.loginInBackground(email: email, password: password) { (success) in
            controller.showActivityIndicator = false
            if success {
                self.loginSuccessful()
            }
        }
    }
    
    func register(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        controller.showActivityIndicator = true
        User.registerInBackground(email: email, password: password) { (success) in
            controller.showActivityIndicator = false
            if success {
                self.loginSuccessful()
            }
        }
    }
    
    func loginSuccessful() {
        
        let viewControllers = [MapViewController()]
        let tabBarController = NTScrollableTabBarController(viewControllers: viewControllers)
        appController.setViewController(ContentController(rootViewController: tabBarController), forSide: .center)
    }
}
