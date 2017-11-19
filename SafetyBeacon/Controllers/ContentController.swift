//
//  AppController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//

import NTComponents
import WhatsNew

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
        titleLabel.textAlignment = .center
        titleLabel.text = "Safety Beacon"
        titleLabel.font = Font.Default.Title.withSize(22)
        rootViewController.navigationItem.titleView = titleLabel
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // The major items that are new
        let items = [
            WhatsNewItem.image(title: "Navigation", subtitle: "Turn-by-Turn navigation instructions", image: UIImage(named: "icons8-route")!.withRenderingMode(.alwaysTemplate)),
            WhatsNewItem.image(title: "History", subtitle: "View the patients history and filter locations by date and time", image: UIImage(named: "icons8-clock")!.withRenderingMode(.alwaysTemplate)),
            WhatsNewItem.image(title: "Battery Alerts", subtitle: "The caretaker is updated in the event that the patients battery is low", image: UIImage(named: "icons8-high_battery")!.withRenderingMode(.alwaysTemplate)),
            WhatsNewItem.image(title: "Background Updates", subtitle: "The patients location will now be updated even when their app is closed.", image: UIImage(named: "icons8-refresh")!.withRenderingMode(.alwaysTemplate)),
            ]
        
        // Present the WhatsNew controller
        let whatsNew = WhatsNewViewController(items: items)
        whatsNew.buttonBackgroundColor = .logoBlue
        whatsNew.itemTitleColor = .darkGray
        whatsNew.buttonTextColor = .white
        whatsNew.view.backgroundColor = .logoOffwhite
        whatsNew.presentIfNeeded(on: self)
    }
    
    @objc
    func openSettings() {
        let viewController = SettingsViewController()
        let nav = NTNavigationViewController(rootViewController: viewController)
        present(nav, animated: true, completion: nil)
    }
}
