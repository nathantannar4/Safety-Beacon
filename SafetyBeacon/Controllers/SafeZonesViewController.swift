//
//  SafeZonesViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 10/2/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse
import CoreLocation
import AddressBookUI

class SafeZonesViewController: UITableViewController {
    
    // MARK: - Properties
    
    var safeZones = [PFObject]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func refreshSafeZones() {
        
        //query db
        guard let user = User.current(), let patient = user.patient else { return }
        let query = PFQuery(className: "SafeZones")
        query.whereKey("patient", equalTo: patient)
        query.findObjectsInBackground { (objects, error) in
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return safeZones.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Add Safe Zone"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        
        cell.textLabel?.text = safeZones[indexPath.row]["name"] as? String
//        cell.detailTextLabel?.text = safeZones[indexPath.row]["name"] as? String
        return cell
        
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            addSafeZone()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
//    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let action = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete") { (action, indexPath) in
//            self.safeZones[indexPath.row].deleteInBackground(block: { (success, error) in
//                guard success else {
//                    NTPing(type: .isDanger, title: "Unable to delete Safe Zone").show(duration: 5)
//                    Log.write(.error, error.debugDescription)
//                    return
//                }
//                self.safeZones.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: .fade)
//            })
//        }
//        return action[]
//    }
    
    // MARK: - User Actions
    
    @objc
    func addSafeZone() {
        let alertController = UIAlertController(title: "Add SafeZone", message: "Input Safe Zone Information Below", preferredStyle: UIAlertControllerStyle.alert)
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (alertAction: UIAlertAction) -> Void in
            guard let nameField = alertController.textFields?[0].text, let streetField = alertController.textFields?[1].text, let cityField = alertController.textFields?[2].text, let provinceField = alertController.textFields?[3].text, let postalField = alertController.textFields?[4].text, let radiusField = alertController.textFields?[5].text else{
                return
            }
            guard let radius = Double(radiusField) else { return }
            let address = "\(streetField ?? "Null"), \(cityField ?? "Null"), \(provinceField ?? "Null"), \(postalField ?? "Null")"
            print ("\(address)")
            self.getCoordinates(address: address, completion: { (coordinate) in
                guard let coordinate = coordinate else {
                    // handle error
                    return
                }
                self.saveSafeZone(safeZoneName: nameField, safeZoneAddress: address, safeZoneRadius: radius, safeZoneLatitude: coordinate.latitude, safeZoneLongitude: coordinate.longitude)
            })
        }
        alertController.addTextField { nameField in nameField.placeholder = "Safe Zone Name" }
        alertController.addTextField { streetField in streetField.placeholder = "Street Address" }
        alertController.addTextField { cityField in cityField.placeholder = "City" }
        alertController.addTextField { provinceField in provinceField.placeholder = "Province/ Territory" }
        alertController.addTextField { postalField in postalField.placeholder = "Postal Code" }
        alertController.addTextField { postalField in postalField.placeholder = "Safe Zone Radius" }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
    }
    func getCoordinates(address: String, completion: @escaping (CLLocationCoordinate2D?)->Void) {
        CLGeocoder().geocodeAddressString(address, completionHandler: { (placemarks, error) in
            
            if error != nil {
                print(error as Any)
                return
            }
            if placemarks?.count != nil {
                let placemark = placemarks?[0]
                let location = placemark?.location
                let coordinate = location?.coordinate
                print("\nlat: \(coordinate!.latitude), long: \(coordinate!.longitude)")
                if placemark?.areasOfInterest?.count != nil {
                    let areaOfInterest = placemark!.areasOfInterest![0]
                    print(areaOfInterest)
                    completion(coordinate)
                } else {
                    print("No area of interest found.")
                    completion(nil)
                }
            }
            
        })
    }
    func saveSafeZone(safeZoneName: String, safeZoneAddress: String, safeZoneRadius: Double, safeZoneLatitude : Double, safeZoneLongitude: Double) {
        
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let zone = PFObject(className: "SafeZones")
        //zone["lat"] = LocationManager.shared.currentLocation?.latitude
        zone["address"] = safeZoneAddress
        zone["name"] = safeZoneName
        zone["patient"] = patient
        zone["radius"] = safeZoneRadius
        zone.saveInBackground { (success, error) in
            guard success else {
                // handle error
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                return
            }
            NTPing(type: .isSuccess, title: "Safe Zone Successfully Saved").show(duration: 3)
        }
    }
}


