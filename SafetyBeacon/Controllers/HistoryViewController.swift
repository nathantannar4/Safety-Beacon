//
//  HistoryViewController.swift
//  SafetyBeacon
//
//  Created by Nathan Tannar on 9/25/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import Parse
import Mapbox

class HistoryViewController: MapViewController {
    
    // MARK: - Properties
    
    // MARK: - Initialization
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshLocations()
        
        // Declare the marker `hello` and set its coordinates, title, and subtitle.
        //        let hello = MGLPointAnnotation()
        //        hello.coordinate = CLLocationCoordinate2D(latitude: 40.7326808, longitude: -73.9843407)
        //        hello.title = "Hello world!"
        //        hello.subtitle = "Welcome to my marker"
        //
        //        // Add marker `hello` to the map.
        //        mapView.addAnnotation(hello)
        
    }
    
//    for object in objects {
//    var lastActive = object["lastActive"]
//    if lastActive != nil {
//    let dateFormatter = NSDateFormatter()
//    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
//    let date = dateFormatter.stringFromDate(lastActive as NSDate)
//    println(date)
//    }
//    }
    func refreshLocations() {
        
        guard let patient = User.current()?.patient else { return }
        
        let query = PFQuery(className: "History")
        query.whereKey("patient", equalTo: patient)
        query.findObjectsInBackground(block: {(objects, error) in
            guard let objects = objects else {
                return
            }
            self.mapView.annotations?.forEach { self.mapView.removeAnnotation($0) }
            print(objects)
            for location in objects {
                // add to map
                guard let long = location["long"] as? Double, let lat = location["lat"] as? Double, let createdAt = location.createdAt else {
                    Log.write(.warning, "Unable to retrieve the location information")
                    return
                }
//                var createdAt = location["createdAt"]
//                if createdAt != nil {
//                    let dateFormatter = DateFormatter()
//                    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
//                    let date = dateFormatter.stringFromDate(createdAt as? Date)
//                }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
                let date = dateFormatter.string(from: createdAt)
                
                let temp = MGLPointAnnotation()
                temp.coordinate = CLLocationCoordinate2DMake(lat, long)
                temp.title = date
                self.mapView.addAnnotation(temp)
            }
        })
    }
    
    // MARK: - User Actions
}
