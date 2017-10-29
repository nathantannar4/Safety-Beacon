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
            guard let nameText = alertController.textFields?[0].text, let addressText = alertController.textFields?[1].text, let radiusText = alertController.textFields?[2].text else{
                return
            }
            guard let radius = Double(radiusText) else { return }
            self.saveSafeZone(safeZoneName: nameText, safeZoneAddress: addressText, safeZoneRadius: radius)
        }
        alertController.addTextField { nameText in
            nameText.placeholder = "Name"
        }
        alertController.addTextField { addressText in
            addressText.placeholder = "Address"
      }
//        alertController.addTextField { cityText in
//            cityText.placeholder = "City"
//        }
//        alertController.addTextField { postalCodeText in
//            postalCodeText.placeholder = "Postal Code"
//        }
        alertController.addTextField { radiusText in
            radiusText.placeholder = "Radius"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
    }
    func saveSafeZone(safeZoneName: String, safeZoneAddress: String, safeZoneRadius: Double) {
        
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


