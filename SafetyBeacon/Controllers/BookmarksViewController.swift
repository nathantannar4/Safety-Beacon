//
//  BookmarksViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse

class BookmarksViewController: UITableViewController {

    // MARK: - Properties
    
    var bookmarks = [PFObject]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func refreshSafeZones() {
        
        // query db
        tableView.reloadData()
        
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return bookmarks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Add Safe Zone"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        cell.textLabel?.text = bookmarks[indexPath.row]["name"] as? String
        //        cell.detailTextLabel?.text = safeZones[indexPath.row]["name"] as? String
        return cell
        
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            saveBookmark(name: "test", addressLongitude: 456, addressLatitude: 45)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
//    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let action = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete") { (action, indexPath) in
//            self.bookmarks[indexPath.row].deleteInBackground(block: { (success, error) in
//                guard success else {
//                    return
//                }
//                self.bookmarks.remove(at: indexPath.row)
//                tableView.deleteRows(at: [indexPath], with: .fade)
//            })
//            return
//        }
//    }
    
    // MARK: - User Actions
    
    func addBookmark() {
        let alertController = UIAlertController(title: "Add Bookmark", message: "Input Bookmark name and address below:", preferredStyle: UIAlertControllerStyle.alert)
        
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (alertAction: UIAlertAction!) -> Void in
            let nameField = alertController.textFields![0] as UITextField
            let addressField = alertController.textFields![1] as UITextField
            print("\(nameField.text ?? "Nothing entered")")
            print("\(addressField.text ?? "Noting entered")")
        }
        addAction.isEnabled = false
        
        alertController.addTextField { nameField in
            nameField.placeholder = "Bookmark Name"
        }
        
        alertController.addTextField { addressField in
            addressField.placeholder = "Address"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    func saveBookmark(name: String, addressLongitude: Double, addressLatitude: Double) {
        
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let bookmark = PFObject(className: "Bookmark")
        bookmark["long"] = LocationManager.shared.currentLocation?.longitude
        bookmark["lat"] = LocationManager.shared.currentLocation?.latitude
        bookmark["name"] = "Test"
        bookmark["patient"] = patient
        bookmark.saveInBackground { (success, error) in
            guard success else {
                // handle error
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                return
            }
            NTPing(type: .isSuccess, title: "Bookmark successfully saved").show(duration: 3)
        }
    }

    
    
}
