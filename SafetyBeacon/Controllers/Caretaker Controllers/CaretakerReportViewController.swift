//
//  CaretakerReportViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTComponents
import Parse

class CaretakerReportViewController: NTTableViewController {
    
    // MARK: - Properties
    
    var locations = [String:[PFObject]]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report"
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        let rc = UIRefreshControl()
        rc.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        rc.addTarget(self, action: #selector(getRecentLocationsInBackground), for: .valueChanged)
        tableView.refreshControl = rc
        getRecentLocationsInBackground()
    }
    
    // MARK: - Data Refresh
    
    /// Gets locations
    ///
    /// - Parameter completion: Callback function
    @objc
    func getRecentLocationsInBackground() {
        
        guard let patient = User.current()?.patient else { return }
        let query = PFQuery(className: "History")
        query.addDescendingOrder("createdAt")
        query.whereKey("patient", equalTo: patient)
        query.findObjectsInBackground { (objects, error) in
            self.tableView.refreshControl?.endRefreshing()
            guard let objects = objects, error == nil else {
                print(error.debugDescription)
                DispatchQueue.main.async {
                    NTPing(type: .isDanger, title: error?.localizedDescription).show()
                    self.locations.removeAll()
                    self.tableView.reloadData()
                }
                return
            }
            self.filterObjects(objects)
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    /// Filters the previous locations and groups them by date and time
    ///
    /// - Parameter objects: Objects to sort
    func filterObjects(_ objects: [PFObject]) {
        
        locations.removeAll()
        for object in objects {
            if let createdAt = object.createdAt {
                let key = createdAt.string(dateStyle: .long, timeStyle: .none)
                if locations[key] == nil {
                    locations[key] = []
                }
                if let lat = object["lat"] as? Double, let long = object["long"] as? Double {
                    getAddress(latitude: lat, longitude: long) { (address) in
                        object["address"] = address
                    }
                }
                locations[key]?.append(object)
            }
        }
    }
    
    // Returns the locations for a section index
    func locations(for section: Int) -> [PFObject] {
        let keys = Array(locations.keys)
        let indexKey = keys[section]
        return locations[indexKey] ?? []
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(locations.keys)[section]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return locations.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations(for: section).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let object = locations(for: indexPath.section)[indexPath.row]
        
        let cell =  NTTimelineTableViewCell(style: .detailed)
        cell.isInitial = indexPath.row == 0
        cell.isFinal = indexPath.row + 1 == self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        
        cell.timeLabel.text = object.createdAt?.string(dateStyle: .none, timeStyle: .short)
        
        cell.durationLabel.text = "\(Int.random(min: 3, max: 15)) minutes"
        cell.locationLabel.text = object["address"] as? String ?? "Unknown Address"
        
        
        return cell
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
}
