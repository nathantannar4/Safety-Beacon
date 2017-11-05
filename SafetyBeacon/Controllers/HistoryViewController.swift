//
//  HistoryViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Kim Youjung
//          - youjungk@sfu.ca
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
        
    }
    
    func refreshLocations() {
        
        guard let patient = User.current()?.patient else { return }
        
        let query = PFQuery(className: "History")
        query.whereKey("patient", equalTo: patient)
//        query.whereKey("createdAt", lessThan: Date())
//        query.whereKey("createdAt", greaterThan: Date().addMonth(-1))
        query.findObjectsInBackground(block: {(objects, error) in
            guard let objects = objects else {
                return
            }
            self.mapView.annotations?.forEach { self.mapView.removeAnnotation($0) }
//            print(objects)
            for location in objects {
                // add to map
                guard let long = location["long"] as? Double, let lat = location["lat"] as? Double, let createdAt = location.createdAt else {
                    Log.write(.warning, "Unable to retrieve the location information")
                    return
                }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm:ss a" //"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
                let date = dateFormatter.string(from: createdAt)
                let location_info = MGLPointAnnotation()
                location_info.coordinate = CLLocationCoordinate2DMake(lat, long)
                location_info.title = date
                self.mapView.addAnnotation(location_info)
            }
        })
    }
    
    // MARK: - User Actions
}
