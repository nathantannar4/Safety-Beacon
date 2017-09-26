//
//  LoginViewController.swift
//  SafetyBeacon
//
//  Copyright © 2017 Nathan Tannar.
//  Created by Nathan Tannar on 9/25/17.
//

import UIKit
import Parse

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let patientButton = UIButton()
        patientButton.setTitle("Login as Patient", for: .normal)
        patientButton.addTarget(self, action: #selector(LoginViewController.patientLogin), for: .touchUpInside)
        view.addSubview(patientButton)
        patientButton.addConstraints(view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: nil, topConstant: 20, leftConstant: 20, bottomConstant: 0, rightConstant: 0, widthConstant: 200, heightConstant: 30)
        
        let caretakerButton = UIButton()
        caretakerButton.setTitle("Login as Caretaker", for: .normal)
        caretakerButton.addTarget(self, action: #selector(LoginViewController.caretakerLogin), for: .touchUpInside)
        view.addSubview(caretakerButton)
        caretakerButton.addConstraints(patientButton.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: nil, topConstant: 20, leftConstant: 20, bottomConstant: 0, rightConstant: 0, widthConstant: 200, heightConstant: 30)
    }
    
    // MARK: - User Actions
    
    @objc
    func patientLogin() {
        
        User.loginInBackground(email: "patient@safetybeacon.ca", password: "password123") { (success) in
            if success {
                // perform UI transition
            }
        }
    }
    
    @objc
    func caretakerLogin() {
        
        User.loginInBackground(email: "caretaker@safetybeacon.ca", password: "password123") { (success) in
            if success {
                // perform UI transition
            }
        }
    }
}
