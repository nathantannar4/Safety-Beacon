//
//  LoginViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
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
            
            // Present the email input view
            let vc = NTEmailAuthViewController()
            vc.delegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    // Logs a user in
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
    
    // Registers a user with the database
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
    
    // Changes the UI to the correct view
    class func loginSuccessful() {
        
        guard let currentUser = User.current() else { return }
        
        if currentUser.requiresSetup {
            
            // Setup still required
            appController.setViewController(ContentController(rootViewController: AccountSetupViewController()), forSide: .center)
            
        } else {
            if currentUser.isCaretaker {
                
                // Caretaker Views
                
                // This sets up how we want the DynamicTabBarController to look like
                let viewControllers = [ReportViewController(), BookmarksViewController(), SafeZonesViewController(), HistoryViewController()]
                let tabBarController = DynamicTabBarController(viewControllers: viewControllers)
                tabBarController.isScrollEnabled = false
                tabBarController.tabBar.activeTintColor = .logoBlue
                tabBarController.tabBar.backgroundColor = Color.Default.Background.NavigationBar
                tabBarController.tabBarPosition = .top
                tabBarController.tabBar.scrollIndicatorPosition = .bottom
                tabBarController.tabBar.setDefaultShadow()
                tabBarController.updateTabBarHeight(to: 40, animated: false)
                appController.setViewController(ContentController(rootViewController: tabBarController), forSide: .center)

            } else if currentUser.isPatient {
                
                // Patient Views
                
                // This sets up how we want the DynamicTabBarController to look like
                let viewControllers = [NavigationMapViewController(), BookmarksViewController()]
                let tabBarController = DynamicTabBarController(viewControllers: viewControllers)
                tabBarController.isScrollEnabled = false
                tabBarController.tabBar.activeTintColor = .logoBlue
                tabBarController.tabBar.backgroundColor = Color.Default.Background.NavigationBar
                tabBarController.tabBarPosition = .top
                tabBarController.tabBar.scrollIndicatorPosition = .bottom
                tabBarController.tabBar.setDefaultShadow()
                tabBarController.updateTabBarHeight(to: 40, animated: false)
                appController.setViewController(ContentController(rootViewController: tabBarController), forSide: .center)
            }
        }
    }
}
