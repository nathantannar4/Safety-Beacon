//
//  SettingsViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//

import UIKit
import SafariServices
import NTComponents
import AcknowList

class SettingsViewController: UITableViewController {
    
    // MARK: - Properties
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parent?.title = "Settings"
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .groupTableViewBackground
        setupLogoutButton()
    }
    
    // MARK: - Setup
    
    func setupLogoutButton() {
        
        guard let parent = parent as? NTNavigationViewController else { return }
        let button = NTButton()
        button.title = "Logout"
        button.layer.cornerRadius = 8
        button.titleFont = Font.Default.Subtitle.withSize(15)
        parent.navigationBar.addSubview(button)
        button.addTarget(self, action: #selector(logout), for: .touchUpInside)
        button.addConstraints(parent.navigationBar.topAnchor, left: nil, bottom: parent.navigationBar.bottomAnchor, right: parent.navigationBar.rightAnchor, topConstant: 40, leftConstant: 0, bottomConstant: 8, rightConstant: 16, widthConstant: 100, heightConstant: 0)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = NTTableViewHeaderFooterView()
        if section == 0 {
            header.textLabel.text = "Your Account"
        } else if section == 1 {
            header.textLabel.text = "Linked Account"
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 2 {
            let footer = NTTableViewHeaderFooterView()
            footer.textLabel.textAlignment = .center
            footer.textLabel.text = "Safety Beacon Version " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? String())
            return footer
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 2 ? 28 : 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section <= 1 ? 80 : UITableViewAutomaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section <= 1 {
            return 1
        }
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let currentUser = User.current() else { return NTTableViewCell() }
        
        switch indexPath.section {
        case 0:
            let cell = NTTableViewCell(style: .subtitle, reuseIdentifier: nil)
            
            cell.textLabel?.text = User.current()?.username
            if !currentUser.requiresSetup {
                cell.detailTextLabel?.text = User.current()?.isCaretaker ?? true ? "Caretaker" : "Paient"
                cell.imageView?.image = User.current()?.isCaretaker ?? false ? #imageLiteral(resourceName: "ic_heart") : #imageLiteral(resourceName: "ic_BothPatients")
            }
            cell.selectionStyle = .none
            return cell
        case 1:
            let cell = NTTableViewCell(style: .subtitle, reuseIdentifier: nil)
            if currentUser.requiresSetup {
                cell.textLabel?.text = "No user linked"
            } else {
                cell.textLabel?.text = User.current()?.isCaretaker ?? false ? User.current()?.patient?.username : User.current()?.caretaker?.username
                cell.detailTextLabel?.text = User.current()?.isPatient ?? false ? "Caretaker" : "Paient"
                cell.imageView?.image = User.current()?.isPatient ?? false ? #imageLiteral(resourceName: "ic_heart") : #imageLiteral(resourceName: "ic_BothPatients")
            }
            cell.selectionStyle = .none
            return cell
        case 2:
            let cell = NTTableViewCell()
            if indexPath.row == 0 {
                cell.textLabel?.text = "Submit Feedback"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Credits"
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Acknowledgements"
            }
            return cell
        default:
            break
        }
        fatalError("Invalid IndexPath")
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                // Feedback
                guard let url = URL(string: "https://github.com/nathantannar4/Safety-Beacon/issues/new") else { return }
                let vc = SFSafariViewController(url: url)
                present(vc, animated: true, completion: nil)
            } else if indexPath.row == 1 {
                // Credits
                guard let url = URL(string: "https://github.com/nathantannar4/Safety-Beacon/graphs/contributors") else { return }
                let vc = SFSafariViewController(url: url)
                present(vc, animated: true, completion: nil)
            } else if indexPath.row == 2 {
                // Acknowledgements
                let path = Bundle.main.path(forResource: "Pods-SafetyBeacon-acknowledgements", ofType: "plist")
                let vc = AcknowListViewController(acknowledgementsPlistPath: path).addDismissalBarButtonItem()
                let navVC = UINavigationController(rootViewController: vc)
                present(navVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - User Actions
    
    @objc
    func logout() {
        
        let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            User.logoutInBackground(nil)
            self.dismiss(animated: false, completion: {
                appController.setViewController(LoginViewController(), forSide: .center)
            })
        }))
        alert.view.tintColor = .logoBlue
        present(alert, animated: true, completion: nil)
    }
}
