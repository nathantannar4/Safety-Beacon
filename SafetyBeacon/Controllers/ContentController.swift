//
//  AppController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 10/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

class ContentController: NTNavigationController {
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        let settingsButton = NTButton()
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.image = #imageLiteral(resourceName: "icons8-settings")
        settingsButton.backgroundColor = .clear
        rootViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsButton)
        
        let titleLabel = NTLabel()
        titleLabel.text = "Safety Beacon"
        titleLabel.font = Font.Default.Title.withSize(20)
        rootViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func openSettings() {
        let viewController = SettingsViewController()
        let nav = NTNavigationViewController(rootViewController: viewController)
        present(nav, animated: true, completion: nil)
    }
}
