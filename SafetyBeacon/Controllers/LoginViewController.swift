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
        
        logo = UIImage(named: "SafetyBeaconLogo")
        loginMethods = [.email, .custom]
    }
    
    override func createLoginButton(forMethod method: NTLoginMethod) -> NTLoginButton {
        if method == .custom {
            let button = createLoginButton(color: Color.Default.Background.Button, title: "Quick Login", logo: nil)
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
                    self.present(MapViewController(), animated: false, completion: nil)
                }
            }
        }
    }
    
    func authorize(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        controller.showActivityIndicator = true
        User.loginInBackground(email: email, password: password) { (success) in
            controller.showActivityIndicator = false
            if success {
                self.present(MapViewController(), animated: false, completion: nil)
            }
        }
    }
    
    func register(_ controller: NTEmailAuthViewController, email: String, password: String) {
        
        controller.showActivityIndicator = true
        User.registerInBackground(email: email, password: password) { (success) in
            controller.showActivityIndicator = false
            if success {
                self.present(MapViewController(), animated: false, completion: nil)
            }
        }
    }
}



//class LoginViewController: UIViewController {
//
//    // MARK: - Properties
//
//    // MARK: - View Life Cycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let patientButton = UIButton()
//        patientButton.setTitle("Login as Patient", for: .normal)
//        patientButton.addTarget(self, action: #selector(LoginViewController.patientLogin), for: .touchUpInside)
//        view.addSubview(patientButton)
//        patientButton.addConstraints(view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: nil, topConstant: 20, leftConstant: 20, bottomConstant: 0, rightConstant: 0, widthConstant: 200, heightConstant: 30)
//
//        let caretakerButton = UIButton()
//        caretakerButton.setTitle("Login as Caretaker", for: .normal)
//        caretakerButton.addTarget(self, action: #selector(LoginViewController.caretakerLogin), for: .touchUpInside)
//        view.addSubview(caretakerButton)
//        caretakerButton.addConstraints(patientButton.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: nil, topConstant: 20, leftConstant: 20, bottomConstant: 0, rightConstant: 0, widthConstant: 200, heightConstant: 30)
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        LocationManager.shared.requestAlwaysAuthorization()
//    }
//
//    // MARK: - User Actions
//
//    @objc
//    func patientLogin() {
//
//        User.loginInBackground(email: "patient@safetybeacon.ca", password: "password123") { (success) in
//            if success {
//                // perform UI transition
//                self.present(MapViewController(), animated: false, completion: nil)
//            }
//        }
//    }
//
//    @objc
//    func caretakerLogin() {
//
//        User.loginInBackground(email: "caretaker@safetybeacon.ca", password: "password123") { (success) in
//            if success {
//                // perform UI transition
//                self.present(MapViewController(), animated: false, completion: nil)
//            }
//        }
//    }
//}

