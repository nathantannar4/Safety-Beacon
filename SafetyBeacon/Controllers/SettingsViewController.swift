//
//  SettingsViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 10/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parent?.title = "Settings"
        view.backgroundColor = .white
        setupLogoutButton()
    }
    
    func setupLogoutButton() {
        
        guard let parent = parent as? NTNavigationViewController else { return }
        let button = NTButton()
        button.title = "Logout"
        button.layer.cornerRadius = 8
        parent.navigationBar.addSubview(button)
        button.addTarget(self, action: #selector(logout), for: .touchUpInside)
        button.addConstraints(parent.navigationBar.topAnchor, left: nil, bottom: parent.navigationBar.bottomAnchor, right: parent.navigationBar.rightAnchor, topConstant: 40, leftConstant: 0, bottomConstant: 10, rightConstant: 16, widthConstant: 100, heightConstant: 0)
    }
    
    // MARK: - User Actions
    
    @objc
    func logout() {
        
        let alert = NTAlertViewController(title: "Are you sure?", subtitle: nil, type: NTAlertType.isInfo)
        alert.confirmButton.title = "Logout"
        alert.onConfirm = {
            User.logoutInBackground { (success) in
                if success {
                    self.dismiss(animated: false, completion: {
                        appController.setViewController(LoginViewController(), forSide: .center)
                    })
                }
            }
        }
        present(alert, animated: true, completion: nil)
    }
}
