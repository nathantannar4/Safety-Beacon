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
import NTComponents
import Parse
import UIKit

class BookmarksViewController: UITableViewController {

    // MARK: - Properties
    
    var bookmarks = [PFObject]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        self.refreshBookmarks()
    }
    
    func refreshBookmarks() {
        
        //query db
        guard let user = User.current(), let patient = user.patient else { return }
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = NTTableViewHeaderFooterView()
        if section == 0 {
            header.textLabel.text = "Add Bookmarks"
        } else if section == 1 {
            header.textLabel.text = "Existing Bookmarks"
        }
        return header
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return bookmarks.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section <= 1 ? 80 : UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = "Enter Address"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        cell.textLabel?.text = bookmarks[indexPath.row]["name"] as? String
        let latitude = bookmarks[indexPath.row]["lat"] as? Double
        let longitude = bookmarks[indexPath.row]["long"] as? Double
        self.getAddress(latitude: latitude!, longitude: longitude!, completion: { (address) in
            guard let address = address else {
                // handle error
                return
            }
            cell.detailTextLabel?.text = address
        })
        return cell
        
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            addBookmark()
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
//        }
//        return
//    }
    
    // MARK: - User Actions
    func getCoordinates(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        CLGeocoder().geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if error != nil {
                print(error as Any)
                return
            }
            if placemarks?.count != nil {
                let placemark = placemarks?[0]
                let location = placemark?.location
                let coordinate = location?.coordinate
//                print("\nlat: \(coordinate!.latitude), long: \(coordinate!.longitude)")
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
    
    func getAddress(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if error != nil {
                print(error as Any)
                return
            } else if placemarks?.count != nil {
                let pm = placemarks![0]
                guard let streetField = pm.postalAddress?.street,
                      let cityField = pm.postalAddress?.city,
                      let provinceField = pm.postalAddress?.state,
                      let postalField = pm.postalAddress?.postalCode
                else {
                    return
                }
                let address = "\(streetField), \(cityField), \(provinceField), \(postalField)"
//                if pm.areasOfInterest?.count != nil {
//                    let areaOfInterest = pm.areasOfInterest?[0]
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
    
    func addBookmark() {
        let alertController = UIAlertController(title: "Add Bookmark", message: "Input Bookmark name and address below:", preferredStyle: UIAlertControllerStyle.alert)

        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (alertAction: UIAlertAction!) -> Void in

            guard let nameField = alertController.textFields?[0].text,
                  let streetField = alertController.textFields?[1].text,
                  let cityField = alertController.textFields![2].text,
                  let provinceField = alertController.textFields![3].text,
                  let postalField = alertController.textFields![4].text
            else {
                return
            }
            let address = "\(streetField), \(cityField), \(provinceField), \(postalField)"

            self.getCoordinates(address: address, completion: { (coordinate) in
                guard let coordinate = coordinate else {
                    // handle error
                    return
                }
                self.saveBookmark(name: nameField, addressLatitude: coordinate.latitude, addressLongitude: coordinate.longitude)
            })
        }
//        addAction.isEnabled = false
    
        alertController.addTextField { nameField in nameField.placeholder = "Bookmark Name" }
        alertController.addTextField { streetField in streetField.placeholder = "Street Address" }
        alertController.addTextField { cityField in cityField.placeholder = "City" }
        alertController.addTextField { provinceField in provinceField.placeholder = "Province/ Territory" }
        alertController.addTextField { postalField in postalField.placeholder = "Postal Code" }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    
    }
    
    func saveBookmark(name: String, addressLatitude: Double, addressLongitude: Double) {
        guard let currentUser = User.current(), currentUser.isCaretaker, let patient = currentUser.patient else { return }
        
        let bookmark = PFObject(className: "Bookmarks")
        bookmark["lat"] = addressLatitude
        bookmark["long"] = addressLongitude
        bookmark["name"] = name
        bookmark["patient"] = patient
        bookmark.saveInBackground { (success, error) in
            guard success else {
                // handle error
                Log.write(.error, error.debugDescription)
                NTPing(type: .isDanger, title: error?.localizedDescription).show(duration: 3)
                return
            }
            NTPing(type: .isSuccess, title: "Bookmark successfully saved").show(duration: 3)
            self.refreshBookmarks()
        }
    }
}
