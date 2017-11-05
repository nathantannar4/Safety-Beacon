//
//  LocationManager.swift
//  SafetyBeacon
//
//  Changes tracked by git: github.com/nathantannar4/Safety-Beacon
//
//  Edited by:
//      Nathan Tannar
//           - ntannar@sfu.ca
//      Kim Youjung
//          - youjungk@sfu.ca
//

import CoreLocation
import Parse
import NTComponents

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static var shared = LocationManager()
    var counter = 0
    // MARK: - Properties
    
    var currentLocation: CLLocationCoordinate2D? {
        guard let location = coreLocationManager.location else {
            Log.write(.warning, "Failed to get the users current location. Was auth given?")
            return nil
        }
        return CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
    }
    
    // MARK: - Private Properties
    
    private lazy var coreLocationManager: CLLocationManager = { [weak self] in
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Functions
    
    /// Promts the user for location accesss authorization
    func requestAlwaysAuthorization() {
        coreLocationManager.requestAlwaysAuthorization()
    }
    
    /// Saves the current users location to the server for processing
    ///
    /// - Returns: If the push was successful
    func saveCurrentLocation() -> Bool {
        
//        guard let location = currentLocation, let user = User.current() else {
//            Log.write(.warning, "Failed to save the users current location")
//            return false
//        }
        
        // save to DB here
        return true
    }
    
    // MARK: - Private Functions
    
    func beginTracking() {
        DispatchQueue.main.async {
            self.coreLocationManager.startUpdatingLocation()
            self.coreLocationManager.startMonitoringVisits()
        }
    }
    
    func endTracking() {
        DispatchQueue.main.async {
            self.coreLocationManager.stopUpdatingLocation()
            self.coreLocationManager.stopMonitoringVisits()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        Log.write(.status, "locationManagerDidResumeLocationUpdates")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        Log.write(.status, "locationManagerDidPauseLocationUpdates")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.write(.error, "locationManagerDidFailWithError: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        Log.write(.status, "locationManagerDidVisit: \(visit)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Log.write(.status, "locationManagerDidEnterRegion: \(region)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Log.write(.status, "locationManagerDidExitRegion: \(region)")
    }
    
//    let zone = PFObject(className: "SafeZones")
//    zone["long"] = 121276.1212
//    zone.saveInBackground { (success, error) in
//    guard success else {
//    //print error
//    return
//    }
//    // success
//    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let user = User.current(), user.isPatient else {return}
        if counter % 300 == 0 {
            guard let long = locations.first?.coordinate.longitude, let lat = locations.first?.coordinate.latitude else {
                Log.write(.warning, "Failed to write the patient's current location")
                return
            }
            let location_history = PFObject(className: "History")
            location_history["long"] = long
            location_history["lat"] = lat
            location_history["patient"] = user.object
            location_history.saveInBackground(block: {(success, error) in
                guard success else {
                    NTPing(type: .isSuccess, title: "Unable to save location to the database").show(duration: 5)
                    Log.write(.error, error.debugDescription)
                    return
                }
            })
            counter = 1
        }
        Log.write(.status, "\(counter)locationManagerDidUpdateLocations: \(locations)")
        counter+=1
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Log.write(.status, "locationManagerDidChangeAuthorizationStatus: \(status)")
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            // Location services are authorised, track the user.
            beginTracking()
        case .denied, .restricted:
            // Location services not authorised, stop tracking the user.
            endTracking()
        default:
            // Location services pending authorisation.
            // Alert requesting access is visible at this point.
            break
        }
    }
}
