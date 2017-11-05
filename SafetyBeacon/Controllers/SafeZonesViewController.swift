//
//  SafeZonesViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Josh Shercliffe
//          - jshercli@sfu.ca
//

import AddressBookUI
import Contacts
import CoreLocation
import NTComponents
import Parse
import UIKit

class SafeZonesViewController: UITableViewController {
    
    // MARK: - Properties
    var safeZones = [PFObject]()
    
    let provinceList = ["Select Province/ Territory", "BC", "AB", "SK", "MB", "ON", "QC", "NB", "NS", "PE", "NL", "NT", "YT", "NU"]
    let provincePicker = UIPickerView()
    var provincePickerInput: UITextField?
    
    // MARK: - View Life Cycle
    
    // Initial load confirmation
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Safe Zones"
        view.backgroundColor = Color.Default.Background.ViewController
        tableView.tableFooterView = UIView()
        provincePicker.delegate = self
        refreshSafeZones()
        
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshSafeZones), for: .valueChanged)
        tableView.refreshControl = rc
    }
    
    // Updating Safe Zones from database
    @objc
    func refreshSafeZones() {
        //query db
        guard let user = User.current(), let patient = user.patient else { return }
        
        let query = PFQuery(className: "SafeZones")
        query.whereKey("patient", equalTo: patient)
        query.findObjectsInBackground { (objects, error) in
            self.tableView.refreshControl?.endRefreshing()
            guard let objects = objects else {
                NTPing(type: .isDanger, title: "Patient currently set safe zones").show(duration: 5)
                Log.write(.error, error.debugDescription)
                return
            }
            self.safeZones = objects
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = NTTableViewHeaderFooterView()
        if section == 0 {
            header.textLabel.text = "Add Safe Zones"
        } else if section == 1 {
            header.textLabel.text = "Existing Safe Zones"
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return safeZones.count
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
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Enter new Safe Zone"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        cell.textLabel?.text = safeZones[indexPath.row]["name"] as? String
        cell.detailTextLabel?.text = safeZones[indexPath.row]["address"] as? String
        return cell
    }
    
    // Row selectable actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            addSafeZone()
        }
    }
    
    // Modifiable rows (not first section)
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    // Modifiable row actions (swipe left)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete") { (_, indexPath) in
            self.safeZones[indexPath.row].deleteInBackground(block: { (success, error) in
                guard success else {
                    Log.write(.error, error.debugDescription)
                    NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                    return
                }
                self.safeZones.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                NTPing(type: .isSuccess, title: "Safe Zone successfully deleted").show(duration: 3)
            })
        }
        
        let edit = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (_, indexPath) in
            let alertController = UIAlertController(title: "Edit Safe Zone", message: "Change Safe Zone name and address:", preferredStyle: UIAlertControllerStyle.alert)
            
            // Get original bookmark
            let originalName = self.safeZones[indexPath.row]["name"] as? String
            let radiusDouble = self.safeZones[indexPath.row]["radius"] as? Double ?? 0
            let concatenatedAddress = self.safeZones[indexPath.row]["address"] as? String
            var concatenatedAddressArr = concatenatedAddress?.components(separatedBy: ", ")
            let originalStreet = concatenatedAddressArr![0] as String
            let originalCity = concatenatedAddressArr![1] as String
            let originalProvince = concatenatedAddressArr![2] as String
            let originalPostal = concatenatedAddressArr![3] as String
            let originalRadius = String(radiusDouble)

            // Text input placeholders
            alertController.addTextField { nameField in nameField.placeholder = "Safe Zone Name"
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
            alertController.addTextField { radiusField in radiusField.placeholder = "Radius"
                radiusField.delegate = self
                radiusField.text = originalRadius
            }
            
            // Change button
            let changeAction = UIAlertAction(title: "Change", style: UIAlertActionStyle.default) { (_: UIAlertAction!) -> Void in
                guard let nameField = alertController.textFields![0].text, !nameField.isEmpty,
                    let streetField = alertController.textFields![1].text, !streetField.isEmpty,
                    let cityField = alertController.textFields![2].text, !cityField.isEmpty,
                    let provinceField = alertController.textFields![3].text, !provinceField.isEmpty,
                    let postalField = alertController.textFields![4].text, !postalField.isEmpty,
                    let radiusField = alertController.textFields![5].text, !radiusField.isEmpty
                    else {
                        let invalidAlert = UIAlertController(title: "Invalid Safe Zone", message: "All fields must be entered.", preferredStyle: .alert)
                        invalidAlert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Default action"), style: .`default`, handler: { _ in
                            NSLog("The \"Invalid Safe Zone\" alert occured.")
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
                        self.safeZones[indexPath.row]["lat"] = coordinate.latitude
                        self.safeZones[indexPath.row]["long"] = coordinate.longitude
                    })
                    self.safeZones[indexPath.row]["address"] = newAddress
                }
                guard let radius = Double(radiusField) else { return }
                // Update if name changed
                if originalName != nameField {
                    self.safeZones[indexPath.row]["name"] = nameField
                }
                if originalRadius != radiusField {
                    self.safeZones[indexPath.row]["radius"] = radius
                }
                
                // Save bookmark at same row
                self.safeZones[indexPath.row].saveInBackground()
                self.refreshSafeZones()
                NTPing(type: .isSuccess, title: "Safe Zone successfully updated").show(duration: 3)
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
    
    // Get address from coordinates
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
    
    // Save safe zone to database
    func safeSafeZone(name: String, addressConcatinated: String, addressLatitude: Double, addressLongitude: Double, addressRadius: Double) {
        
        // Check that Caretaker is accessing this menu, not Patient
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let zone = PFObject(className: "SafeZones")
        zone["name"] = name
        zone["address"] = addressConcatinated
        zone["lat"] = addressLatitude
        zone["long"] = addressLongitude
        zone["patient"] = patient
        zone["radius"] = addressRadius
        zone.saveInBackground { (success, error) in
            guard success else {
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                return
            }
            self.refreshSafeZones()
            NTPing(type: .isSuccess, title: "Safe Zone successfully saved").show(duration: 3)
        }
    }
    
    // MARK: - User Actions
    
    // Add safe zone
    func addSafeZone() {
        let alertController = UIAlertController(title: "Add Safe Zone", message: "Input Safe Zone name and address:", preferredStyle: UIAlertControllerStyle.alert)
        
        // Text input placeholders
        alertController.addTextField { nameField in nameField.placeholder = "Safe Zone Name" }
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
        alertController.addTextField { radiusField in radiusField.placeholder = "Radius Field" }
        
        // Add button
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (_: UIAlertAction!) -> Void in
            guard let nameField = alertController.textFields?[0].text, !nameField.isEmpty,
                let streetField = alertController.textFields?[1].text, !streetField.isEmpty,
                let cityField = alertController.textFields?[2].text, !cityField.isEmpty,
                let provinceField = alertController.textFields?[3].text, !provinceField.isEmpty,
                let postalField = alertController.textFields?[4].text, !postalField.isEmpty,
                let radiusField = alertController.textFields?[5].text, !radiusField.isEmpty
                else {
                    let invalidAlert = UIAlertController(title: "Invalid Safe Zone", message: "All fields must be entered.", preferredStyle: .alert)
                    invalidAlert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Default action"), style: .`default`, handler: { _ in
                        NSLog("The \"Invalid Safe Zone\" alert occured.")
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
                guard let radius = Double(radiusField) else { return }
                self.safeSafeZone(name: nameField, addressConcatinated: address, addressLatitude: coordinate.latitude, addressLongitude: coordinate.longitude, addressRadius: radius)
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
extension SafeZonesViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return provinceList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return provinceList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        provincePickerInput?.text = row != 0 ? provinceList[row] : String()
    }
}

// MARK: - UITextFieldDelegate
extension SafeZonesViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let count = textField.text?.count ?? 0
        return count < 6
    }
}
