//
//  PatientSafeZonesViewController.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Jason Tsang
//          - jrtsang@sfu.ca
//

// TEST: Run SafetyTrackerTests under Debug -> Simulate Location
// TODO: Notification on caretaker's (only log right now)
//       Refresh monitoredRegions when Caretaker deletes
//       Implement integer only keyboard on radius parameter
//       Fix viewController init for patient
//       Enter/ Exit parameter?

import CoreLocation
import NTComponents
import MapKit
import Parse

class PatientSafeZonesViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: - Properties
    var locationManager = CLLocationManager()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove all previously cached regions to monitor
        for object in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: object)
        }
        
        // Set all Safe Zones to monitor
        getSafeZones()
        
        // Set geofencing properies
        locationManager.distanceFilter = 10 // Minimum distance device moves in meters to generate an update
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Highest level of accuracy
        locationManager.requestAlwaysAuthorization() // Always use location
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = true // Automatically pause to save power
    }
    
    // MARK: - CLLocationManagerDelegate
    
    // DEBUG - Lists all the monitored regions
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("The monitored regions are: \(manager.monitoredRegions)")
    }
    
    // DEBUG - Show location change
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
    // Method to handle enter region notification
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)  {
        NSLog("Entered")
    }
    
    // Method to handle exit region notification
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NSLog("Exited")
    }
    
    // MARK: - Processing Functions
    
    // Get Safe Zones from database
    @objc
    func getSafeZones() {
        // Check that Patient is accessing this menu, not Caretaker
        guard let currentUser = User.current(), currentUser.isPatient else { return }
        
        let query = PFQuery(className: "SafeZones")
        query.whereKey("patient", equalTo: currentUser.object)
        query.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                Log.write(.error, error.debugDescription)
                return
            }
            // Iterate through all the Safe Zones
            for zone in objects {
                let address = zone["address"] as! String
                let radius = zone["radius"] as! Double
                let identifier = zone["name"] as! String
                self.getCoordinates(address: address, completion: { (coordinate) in
                    guard let coordinate = coordinate else {
                        NTPing(type: .isDanger, title: "Invalid Address").show(duration: 5)
                        return
                    }
                    // Add to monitored regions
                    self.addMonitoring(coordinate: coordinate, radius: radius, identifier: identifier)
                })
            }
        }
    }
    
    // Add Safe Zones to monitored regions automatically managed by iOS
    func addMonitoring(coordinate: CLLocationCoordinate2D, radius: Double, identifier: String) {
        // Set parameters
        let radius: CLLocationDistance = CLLocationDistance(radius)
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
        // Notify on both exit and enter
        region.notifyOnEntry = true
        region.notifyOnExit = true
        // Add and refresh list
        locationManager.startMonitoring(for: region)
        locationManager.startUpdatingLocation()
    }
    
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
}
