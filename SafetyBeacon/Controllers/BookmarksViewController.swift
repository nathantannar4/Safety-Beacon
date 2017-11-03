//
//  BookmarksViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17
//  Implemented by Jason Tsang on 10/29/2017
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import AddressBookUI
import Contacts
import CoreLocation
import NTComponents
import Parse
import UIKit

class BookmarksViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    // MARK: - Properties
    
    var bookmarks = [PFObject]()
    
    var provinceOption = ["BC", "AB", "SK", "MB", "ON"]
    let thePicker = UIPickerView()
    var pickerTextField: String = ""
    
    // MARK: - View Life Cycle
    
    // Initial load confirmation
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        self.refreshBookmarks()
    
        thePicker.delegate = self
    }
 
    // MARK: - UIPickerView
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return provinceOption.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return provinceOption[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerTextField = provinceOption[row]
        print("\(pickerTextField)")
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
            
            // Get original bookmark
            let originalName = self.bookmarks[indexPath.row]["name"] as? String
            let concatenatedAddress = self.bookmarks[indexPath.row]["address"] as? String
            var concatenatedAddressArr = concatenatedAddress?.components(separatedBy: ", ")
            let originalStreet = concatenatedAddressArr![0] as String
            let originalCity = concatenatedAddressArr![1] as String
            let originalProvince = concatenatedAddressArr![2] as String
            let originalPostal = concatenatedAddressArr![3] as String
            
            // Text input placeholders
            alertController.addTextField { nameField in nameField.placeholder = "Bookmark Name" }
            alertController.addTextField { streetField in streetField.placeholder = "Street Address" }
            alertController.addTextField { cityField in cityField.placeholder = "City" }
            alertController.addTextField { provinceField in provinceField.placeholder = "Province/ Territory" }
            alertController.addTextField { postalField in postalField.placeholder = "Postal Code" }
            // Put original row content as text input
            alertController.textFields![0].text = originalName
            alertController.textFields![1].text = originalStreet
            alertController.textFields![2].text = originalCity
            alertController.textFields![3].text = originalProvince
            alertController.textFields![4].text = originalPostal
            
            // Change button
            let changeAction = UIAlertAction(title: "Change", style: UIAlertActionStyle.default) { (_: UIAlertAction!) -> Void in
                guard let nameField = alertController.textFields![0].text, !nameField.isEmpty,
                    let streetField = alertController.textFields![1].text, !streetField.isEmpty,
                    let cityField = alertController.textFields![2].text, !cityField.isEmpty,
                    let provinceField = alertController.textFields![3].text, !provinceField.isEmpty,
                    let postalField = alertController.textFields![4].text, !postalField.isEmpty
                    else {
                        let invalidAlert = UIAlertController(title: "Invalid Bookmark", message: "All fields must be entered.", preferredStyle: .alert)
                        invalidAlert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Default action"), style: .`default`, handler: { _ in
                            NSLog("The \"Invalid Bookmark\" alert occured.")
                        }))
                        self.present(invalidAlert, animated: true, completion: nil)
                        return
                }

                // Update only address fields changed
                if originalStreet != streetField || originalCity != cityField || originalProvince != provinceField || originalPostal != postalField {
                    let newAddress = "\(streetField), \(cityField), \(provinceField), \(postalField)"
                    // Convert address to coordinates
                    self.getCoordinates(address: newAddress, completion: { (coordinate) in
                        guard let coordinate = coordinate else {
                            print("\n Failed to getCoordinates() - \(newAddress)")
                            NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                            return
                        }
                        self.bookmarks[indexPath.row]["lat"] = coordinate.latitude
                        self.bookmarks[indexPath.row]["long"] = coordinate.longitude
                    })
                    self.bookmarks[indexPath.row]["address"] = newAddress
                }
                // Update if name changed
                if originalName != nameField {
                    self.bookmarks[indexPath.row]["name"] = nameField
                }
                
                // Save bookmark at same row
                self.bookmarks[indexPath.row].saveInBackground()
                self.refreshBookmarks()
                NTPing(type: .isSuccess, title: "Bookmark successfully updated").show(duration: 3)
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
    
    // Save bookmark to database
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
            self.refreshBookmarks()
            NTPing(type: .isSuccess, title: "Bookmark successfully saved").show(duration: 3)
        }
    }
    
    // MARK: - User Actions
    
    // Add Bookmark
    func addBookmark() {
        let alertController = UIAlertController(title: "Add Bookmark", message: "Input Bookmark name and address:", preferredStyle: UIAlertControllerStyle.alert)

        // Text input placeholders
        alertController.addTextField { nameField in nameField.placeholder = "Bookmark Name" }
        alertController.addTextField { streetField in streetField.placeholder = "Street Address" }
        alertController.addTextField { cityField in cityField.placeholder = "City" }
        alertController.addTextField { provinceField in provinceField.placeholder = "Province/ Territory"
            provinceField.inputView = self.thePicker
        }
        alertController.addTextField { postalField in postalField.placeholder = "Postal Code" }
        
        // Add button
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (_: UIAlertAction!) -> Void in
            guard let nameField = alertController.textFields?[0].text, !nameField.isEmpty,
                  let streetField = alertController.textFields?[1].text, !streetField.isEmpty,
                  let cityField = alertController.textFields?[2].text, !cityField.isEmpty,
//                  let provinceField = alertController.textFields?[3].text = self.pickerTextField,
                  let postalField = alertController.textFields?[4].text, !postalField.isEmpty
            else {
                let invalidAlert = UIAlertController(title: "Invalid Bookmark", message: "All fields must be entered.", preferredStyle: .alert)
                invalidAlert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Default action"), style: .`default`, handler: { _ in
                    NSLog("The \"Invalid Bookmark\" alert occured.")
                }))
                self.present(invalidAlert, animated: true, completion: nil)
                return
            }
            
            // How do I get textFields[3].text to update to what was in the pickerTextField (i.e. show what was chosen from the picker)
            alertController.textFields?[3].text = self.pickerTextField
            
            let address = "\(streetField), \(cityField), \(self.pickerTextField), \(postalField)"
            
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

        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
