//
//  AppController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 10/12/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import NTComponents

class ContentController: UINavigationController {
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        let settingsButton = NTButton()
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.image = #imageLiteral(resourceName: "icons8-settings")
        settingsButton.backgroundColor = .clear
        settingsButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        rootViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsButton)
        
        let titleLabel = NTLabel()
        titleLabel.text = "Safety Beacon"
        titleLabel.font = Font.Default.Title.withSize(22)
        rootViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.tintColor = Color.Default.Tint.NavigationBar
        navigationBar.barTintColor = Color.Default.Background.NavigationBar
        navigationBar.backgroundColor = Color.Default.Background.NavigationBar
        navigationBar.isTranslucent = false
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    }
    
    @objc
    func openSettings() {
        let viewController = SettingsViewController()
        let nav = NTNavigationViewController(rootViewController: viewController)
        present(nav, animated: true, completion: nil)
    }
}
