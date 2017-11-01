//
//  BookmarksViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Last modified by Jason Tsang on 10/29/2017
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Contacts
import CoreLocation
import AddressBookUI
import Foundation
import NTComponents
import Parse
import UIKit

class BookmarksViewController: UITableViewController {

    // MARK: - Properties
    
    var bookmarks = [PFObject]()
    
    // MARK: - View Life Cycle
    
    // Initial load confirmation
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        self.refreshBookmarks()
    }
    
    // Updating bookmarks from database
    func refreshBookmarks() {
        // Check that Caretaker is accessing this menu, not Patient
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let query = PFQuery(className: "Bookmarks")
        query.whereKey("patient", equalTo: patient)
        query.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                NTPing(type: .isDanger, title: "Patient currently set bookmarks").show(duration: 5)
                Log.write(.error, error.debugDescription)
                return
            }
            self.bookmarks = objects
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    // Sections within Bookmarks View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // Section titles
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = NTTableViewHeaderFooterView()
        if section == 0 {
            header.textLabel.text = "Add Bookmarks"
        } else if section == 1 {
            header.textLabel.text = "Existing Bookmarks"
        }
        return header
    }

    // Section rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return bookmarks.count
    }
    
    // Table styling
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section <= 1 ? 80 : UITableViewAutomaticDimension
    }
    
    // Populating row content
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        // Add Bookmarks
        if indexPath.section == 0 {
            cell.textLabel?.text = "Enter Address"
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        // Existing Bookmarks
        cell.textLabel?.text = bookmarks[indexPath.row]["name"] as? String
        cell.detailTextLabel?.text = bookmarks[indexPath.row]["address"] as? String
//        // Getting bookmark address from coordinates
//        let latitude = bookmarks[indexPath.row]["lat"] as? Double
//        let longitude = bookmarks[indexPath.row]["long"] as? Double
//        self.getAddress(latitude: latitude!, longitude: longitude!, completion: { (address) in
//            guard let address = address else {
//                print("\n Failed to getAddress() - lat: \(String(describing: latitude)), long: \(String(describing: longitude))")
//                return
//            }
//            // Bookmark address
//            cell.detailTextLabel?.text = address
//        })
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    // Row selectable actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            addBookmark()
        }
    }
    
    // Modifiable rows (not first section)
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    // Modifiable row actions (swipe left)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete") { (_, indexPath) in
            self.bookmarks[indexPath.row].deleteInBackground(block: { (success, error) in
                guard success else {
                    Log.write(.error, error.debugDescription)
                    NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                    return
                }
                self.bookmarks.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                NTPing(type: .isSuccess, title: "Bookmark successfully deleted").show(duration: 3)
            })
        }
        let edit = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (_, indexPath) in
            let alertController = UIAlertController(title: "Edit Bookmark", message: "Change Bookmark name and address:", preferredStyle: UIAlertControllerStyle.alert)
            
            // Get orignal bookmark
            let originalName: String = (self.bookmarks[indexPath.row]["name"] as? String)!
            let concatenatedAddress = self.bookmarks[indexPath.row]["address"] as? String
            var concatenatedAddressArr = concatenatedAddress?.components(separatedBy: ",")
            let originalStreet = concatenatedAddressArr![0] as String
            let originalCity = concatenatedAddressArr![1] as String
            let originalProvince = concatenatedAddressArr![2] as String
            let originalPostal = concatenatedAddressArr![3] as String
            
            // Put originals as text input placeholders
            alertController.addTextField { nameField in nameField.placeholder = originalName }
            alertController.addTextField { streetField in streetField.placeholder = originalStreet }
            alertController.addTextField { cityField in cityField.placeholder = originalCity }
            alertController.addTextField { provinceField in provinceField.placeholder = originalProvince }
            alertController.addTextField { postalField in postalField.placeholder = originalPostal }
            
            // Change button
            let changeAction = UIAlertAction(title: "Change", style: UIAlertActionStyle.default) { (_: UIAlertAction!) -> Void in
                let nameField = alertController.textFields![0] as UITextField
                let streetField = alertController.textFields![1] as UITextField
                let cityField = alertController.textFields![2] as UITextField
                let provinceField = alertController.textFields![3] as UITextField
                let postalField = alertController.textFields![4] as UITextField
            
                var newName = originalName
                var newStreet = originalStreet
                var newCity = originalCity
                var newProvince = originalProvince
                var newPostal = originalPostal
                
                // Update fields if changed
                if nameField.text != "" {
                    newName = nameField.text!
                }
                if streetField.text != "" {
                    newStreet = streetField.text!
                }
                if cityField.text != "" {
                    newCity = cityField.text!
                }
                if provinceField.text != "" {
                    newProvince = provinceField.text!
                }
                if postalField.text != "" {
                    newPostal = postalField.text!
                }
                    
                let newAddress = "\(newStreet),\(newCity),\(newProvince),\(newPostal)"
                
                // Convert address to coordinates
                self.getCoordinates(address: newAddress, completion: { (coordinate) in
                    guard let coordinate = coordinate else {
                        print("\n Failed to getCoordinates() - \(newAddress)")
                        NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                        return
                    }
                    self.bookmarks[indexPath.row].deleteInBackground { (success, error) in
                        guard success else {
                            Log.write(.error, error.debugDescription)
                            NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                            return
                        }
                        self.bookmarks.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        // Save to database
                        self.saveBookmark(name: newName, addressConcatinated: newAddress, addressLatitude: coordinate.latitude, addressLongitude: coordinate.longitude)
                    }
                })
            }
            
            // Cancel button
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(changeAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        return [delete, edit]
    }
    
    // MARK: - Processing Functions
    
    // Get coordinates from address
    func getCoordinates(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        CLGeocoder().geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if error != nil {
                Log.write(.error, error.debugDescription)
                return
            }
            if placemarks?.count != nil {
                let placemark = placemarks?[0]
                let location = placemark?.location
                let coordinate = location?.coordinate
//                if placemark?.areasOfInterest?.count != nil {
//                    let areaOfInterest = placemark!.areasOfInterest![0]
//                    print(areaOfInterest)
//                } else {
//                    print("No area of interest found.")
//                }
                completion(coordinate)
            } else {
                completion(nil)
            }
        })
    }
    
    // Get address from coordinates
    func getAddress(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if error != nil {
                Log.write(.error, error.debugDescription)
                return
            } else if placemarks?.count != nil {
                let placemark = placemarks![0]
                guard let streetField = placemark.postalAddress?.street,
                      let cityField = placemark.postalAddress?.city,
                      let provinceField = placemark.postalAddress?.state,
                      let postalField = placemark.postalAddress?.postalCode
                else {
                    return
                }
                let address = "\(streetField),\(cityField),\(provinceField),\(postalField)"
//                if placemark.areasOfInterest?.count != nil {
//                    let areaOfInterest = placemark.areasOfInterest?[0]
//                    print(areaOfInterest!)
//                } else {
//                    print("No area of interest found.")
//                }
                completion(address)
            } else {
                completion(nil)
            }
        })
    }
    
    // Save bookmark to database (name, coordinates)
    func saveBookmark(name: String, addressConcatinated: String, addressLatitude: Double, addressLongitude: Double) {
        // Check that Caretaker is accessing this menu, not Patient
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let bookmark = PFObject(className: "Bookmarks")
        bookmark["name"] = name
        bookmark["address"] = addressConcatinated
        bookmark["lat"] = addressLatitude
        bookmark["long"] = addressLongitude
        bookmark["patient"] = patient
        bookmark.saveInBackground { (success, error) in
            guard success else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                return
            }
            NTPing(type: .isSuccess, title: "Bookmark successfully saved").show(duration: 3)
            self.refreshBookmarks()
        }
    }
    
    // MARK: - User Actions
    
    // Add Bookmark
    func addBookmark() {
        let alertController = UIAlertController(title: "Add Bookmark", message: "Input Bookmark name and address:", preferredStyle: UIAlertControllerStyle.alert)

        // Add button
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (_: UIAlertAction!) -> Void in
            guard let nameField = alertController.textFields?[0].text,
                  let streetField = alertController.textFields?[1].text,
                  let cityField = alertController.textFields![2].text,
                  let provinceField = alertController.textFields![3].text,
                  let postalField = alertController.textFields![4].text
            else {
                return
            }
            let address = "\(streetField),\(cityField),\(provinceField),\(postalField)"
            
            // Convert address to coordinates
            self.getCoordinates(address: address, completion: { (coordinate) in
                guard let coordinate = coordinate else {
                    print("\n Failed to getCoordinates() - lat: \(address)")
                    NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                    return
                }
                // Save to database
                self.saveBookmark(name: nameField, addressConcatinated: address, addressLatitude: coordinate.latitude, addressLongitude: coordinate.longitude)
            })
        }
//        addAction.isEnabled = false
    
        // Text input placeholders
        alertController.addTextField { nameField in nameField.placeholder = "Bookmark Name" }
        alertController.addTextField { streetField in streetField.placeholder = "Street Address" }
        alertController.addTextField { cityField in cityField.placeholder = "City" }
        alertController.addTextField { provinceField in provinceField.placeholder = "Province/ Territory" }
        alertController.addTextField { postalField in postalField.placeholder = "Postal Code" }

        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
