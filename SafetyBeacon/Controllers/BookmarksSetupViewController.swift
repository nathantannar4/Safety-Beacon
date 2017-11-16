//
//  BookmarksSetupViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Jason Tsang
//          - jrtsang@sfu.ca
//

import AddressBookUI
import Contacts
import CoreLocation
import NTComponents
import Parse
import UIKit
import Mapbox

class BookmarksSetupViewController: UITableViewController {

    // MARK: - Properties
    var bookmarks = [PFObject]()
    
    let provinceList = ["Select Province/ Territory", "BC", "AB", "SK", "MB", "ON", "QC", "NB", "NS", "PE", "NL", "NT", "YT", "NU"]
    
    let provincePicker = UIPickerView()
    var provincePickerInput: UITextField?
    
    // MARK: - View Life Cycle
    
    // Initial load confirmation
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        view.backgroundColor = Color.Default.Background.ViewController
        provincePicker.delegate = self
        tableView.tableFooterView = UIView()
        refreshBookmarks()
        
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshBookmarks), for: .valueChanged)
        tableView.refreshControl = rc
    }
    
    // Updating bookmarks from database
    @objc
    func refreshBookmarks() {
        // Check that Caretaker is accessing this menu, not Patient
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let query = PFQuery(className: "Bookmarks")
        query.whereKey("patient", equalTo: patient)
        query.findObjectsInBackground { (objects, error) in
            self.tableView.refreshControl?.endRefreshing()
            guard let objects = objects else {
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
        return indexPath.section <= 1 ? 44 : UITableViewAutomaticDimension
    }
    
    // Populating row content
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        // Add Bookmarks
        if indexPath.section == 0 {
            cell.textLabel?.text = "Enter new Address"
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
        if indexPath.section == 1 {
            let location = LocationViewController()
            location.title = bookmarks[indexPath.row]["name"] as? String
            let address = bookmarks[indexPath.row]["address"] as? String
            var concatenatedAddressArr = address?.components(separatedBy: ", ")
            let originalStreet = concatenatedAddressArr![0] as String
            
            self.getCoordinates(address: address!, completion: { (coordinate) in
                guard let coordinate = coordinate else {
                    NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                    return
                }
                let navigation = NTNavigationController(rootViewController: location)
                self.present(navigation, animated: true, completion: {
                    let locationMarker = MGLPointAnnotation()
                    locationMarker.coordinate = coordinate
                    locationMarker.title = originalStreet
                    if let currentLocation = LocationManager.shared.currentLocation {
                        // returns distance in meters
                        locationMarker.subtitle = "\(Int(currentLocation.distance(to: coordinate)/1000)) Km"
                    }
                    location.mapView.addAnnotation(locationMarker)
                    location.mapView.setCenter(coordinate, zoomLevel: 12, animated: true)
                })
            })
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
            let alertController = UIAlertController(title: "Edit Bookmark", message: "Change Bookmark name or address:", preferredStyle: UIAlertControllerStyle.alert)
            
            // Get original bookmark
            let originalName = self.bookmarks[indexPath.row]["name"] as? String
            let concatenatedAddress = self.bookmarks[indexPath.row]["address"] as? String
            var concatenatedAddressArr = concatenatedAddress?.components(separatedBy: ", ")
            let originalStreet = concatenatedAddressArr![0] as String
            let originalCity = concatenatedAddressArr![1] as String
            let originalProvince = concatenatedAddressArr![2] as String
            let originalPostal = concatenatedAddressArr![3] as String
            
            // Text input placeholders
            alertController.addTextField { nameField in nameField.placeholder = "Bookmark Name"
                nameField.text = originalName
            }
            alertController.addTextField { streetField in streetField.placeholder = "Street Address"
                streetField.text = originalStreet
            }
            alertController.addTextField { cityField in cityField.placeholder = "City"
                cityField.text = originalCity
            }
            alertController.addTextField { provinceField in provinceField.placeholder = "Province/ Territory"
                provinceField.placeholder = "Province/ Territory"
                self.provincePickerInput = provinceField
                provinceField.inputView = self.provincePicker
                provinceField.text = originalProvince
            }
            alertController.addTextField { postalField in postalField.placeholder = "Postal Code (no space)"
                postalField.delegate = self
                postalField.text = originalPostal
            }
            
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
        edit.backgroundColor = .logoBlue
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
        alertController.addTextField { provinceField in
            provinceField.placeholder = "Province/ Territory"
            self.provincePickerInput = provinceField
            provinceField.inputView = self.provincePicker
        }
        alertController.addTextField { postalField in
            postalField.placeholder = "Postal Code (no space)"
            postalField.delegate = self
        }
        
        // Add button
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (_: UIAlertAction!) -> Void in
            guard let nameField = alertController.textFields?[0].text, !nameField.isEmpty,
                  let streetField = alertController.textFields?[1].text, !streetField.isEmpty,
                  let cityField = alertController.textFields?[2].text, !cityField.isEmpty,
                  let provinceField = alertController.textFields?[3].text, !provinceField.isEmpty,
                  let postalField = alertController.textFields?[4].text, !postalField.isEmpty
            else {
                let invalidAlert = UIAlertController(title: "Invalid Bookmark", message: "All fields must be entered.", preferredStyle: .alert)
                invalidAlert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Default action"), style: .`default`, handler: { _ in
                    NSLog("The \"Invalid Bookmark\" alert occured.")
                }))
                self.present(invalidAlert, animated: true, completion: nil)
                return
            }
            
            let address = "\(streetField), \(cityField), \(provinceField), \(postalField)"
            
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

// MARK: - UIPickerViewDataSource/UIPickerViewDelegate
extension BookmarksSetupViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    // Sections within picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Picker rows
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return provinceList.count
    }
    
    // Picker text return
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return provinceList[row]
    }
    
    // Selecting row options
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        provincePickerInput?.text = row != 0 ? provinceList[row] : String()
    }
}

// MARK: - UITextFieldDelegate
extension BookmarksSetupViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let count = textField.text?.count ?? 0
        let char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")

        // Limit postal code input limit to 6, unless backspace is pressed
        if (isBackSpace == -92) {
            return true
        } else {
            return count < 6
        }
    }
}
